import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { sendPushToUser, sendPushToUsers } from "../notifications/send";
import { storeNotification, storeNotificationForUsers } from "../notifications/store";
import { dispatchNextDriver } from "../services/dispatchService";

interface StatusNotification {
  title: string;
  body: string;
}

function buildStatusNotification(
  newStatus: string,
  shortId: string,
): StatusNotification {
  switch (newStatus) {
  case "accepted":
    return {
      title: "Order Accepted ✅",
      body: `Great news! Vendor confirmed order #${shortId} and will start preparing it shortly.`,
    };
  case "preparing":
    return {
      title: "Order Being Prepared 👨‍🍳",
      body: `Your order #${shortId} is now being prepared. Won't be long!`,
    };
  case "ready":
    return {
      title: "Order Ready 📦",
      body: `Order #${shortId} is ready and waiting for a driver to pick it up.`,
    };
  case "driverAssigned":
    return {
      title: "Driver Assigned 🏍️",
      body: `A driver has been assigned to your order #${shortId} and is heading to pick it up.`,
    };
  case "pickedUp":
    return {
      title: "Order Picked Up 🛵",
      body: `Your order #${shortId} has been picked up! The driver is on the way.`,
    };
  case "onTheWay":
    return {
      title: "On The Way 🚀",
      body: `Your order #${shortId} is on its way to you. Get ready!`,
    };
  case "delivered":
    return {
      title: "Order Delivered 🎉",
      body: `Your order #${shortId} has been delivered. Enjoy your meal!`,
    };
  case "cancelled":
    return {
      title: "Order Cancelled ❌",
      body: `Your order #${shortId} has been cancelled.`,
    };
  case "refunded":
    return {
      title: "Order Refunded 💰",
      body: `Your order #${shortId} has been refunded. The amount will appear in your account shortly.`,
    };
  default:
    return {
      title: "Order Update",
      body: `Your order #${shortId} status has been updated.`,
    };
  }
}

export const onOrderStatusChanged = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const oldStatus = before.status as string;
    const newStatus = after.status as string;
    if (oldStatus === newStatus) return;

    const orderId = event.params.orderId;
    // Support both field names — placeOrder writes 'customerId', legacy writes 'userId'
    const customerId = (after.customerId ?? after.userId) as string | undefined;
    const shortId = orderId.substring(0, 8).toUpperCase();

    logger.info(
      `[onOrderStatusChanged] orderId=${orderId} | ${oldStatus} → ${newStatus} | customerId=${customerId ?? "MISSING"}`,
    );

    // Statuses that we skip notification for (either internal dispatch states
    // or handled with richer detail by onDeliveryRequestStatusUpdated).
    const skippedStatuses = ["searching", "unassigned", "driverAssigned", "pickedUp", "delivered"];
    const skipCustomerNotification = skippedStatuses.includes(newStatus);

    // 1. Notify customer of status change
    if (!customerId) {
      logger.error(
        `[onOrderStatusChanged] No customerId for order ${orderId} — skipping customer notification`,
      );
    } else if (skipCustomerNotification) {
      logger.info(
        `[onOrderStatusChanged] Skipping customer notification for ${newStatus} (sent by onDeliveryRequestStatusUpdated)`,
      );
    } else {
      const isRetryReady = newStatus === "ready" && (oldStatus === "unassigned" || oldStatus === "searching");
      if (isRetryReady) {
        logger.info(
          `[onOrderStatusChanged] Skipping duplicate "Order Ready" notification on retry/re-assign (transition from ${oldStatus} to ready)`,
        );
      } else {
        const { title, body } = buildStatusNotification(newStatus, shortId);
        const data = { orderId, screen: "order_tracking" };

        await sendPushToUser(customerId, title, body, data);
        await storeNotification({
          userId: customerId,
          type: `order_${newStatus}`,
          title,
          body,
          data,
        });
        logger.info(
          `[onOrderStatusChanged] Notification sent to customer ${customerId}: "${title}"`,
        );
      }
    }

    // 2. If status changed to 'ready', initiate automatic driver dispatch
    if (newStatus === "ready") {
      await dispatchNextDriver(orderId);
    }

    // 3. Auto-complete COD payment when order is delivered (Phase 8.9)
    if (newStatus === "delivered" && after.paymentMethod === "cash") {
      await autoCompleteCODPayment(orderId, after);
    }
  },
);

async function notifyNearbyDrivers(
  order: admin.firestore.DocumentData,
  orderId: string,
): Promise<void> {
  const vendorId = (order.vendorId ?? order.restaurantId) as string | undefined;
  if (!vendorId) return;
  const vendorDoc = await admin.firestore()
    .collection("vendors").doc(vendorId).get();
  if (!vendorDoc.exists) return;

  const vendor = vendorDoc.data()!;
  const rLat = vendor.latitude as number;
  const rLng = vendor.longitude as number;
  const radiusKm = (vendor.deliveryRadiusKm as number) ?? 15.0;
  const vendorName = vendor.name as string ?? "A vendor";

  // Query online drivers
  const driversSnap = await admin.firestore()
    .collection("driverProfiles")
    .where("status", "in", ["online", "busy"])
    .get();

  const nearbyDriverIds: string[] = [];
  for (const doc of driversSnap.docs) {
    const dLat = doc.data().currentLat as number | undefined;
    const dLng = doc.data().currentLng as number | undefined;
    if (dLat == null || dLng == null) continue;
    const dist = haversineKm(rLat, rLng, dLat, dLng);
    if (dist <= radiusKm) {
      nearbyDriverIds.push(doc.id);
    }
  }

  if (nearbyDriverIds.length === 0) return;

  const title = "Order Ready for Pickup";
  const body = `Order at ${vendorName} is ready — ${(radiusKm).toFixed(0)} km radius`;
  const data = { orderId, screen: "delivery_request" };

  await sendPushToUsers(nearbyDriverIds, title, body, data);
  await storeNotificationForUsers(
    nearbyDriverIds, "order_ready", title, body, data,
  );
}

/** Haversine distance in km */
function haversineKm(
  lat1: number, lon1: number, lat2: number, lon2: number,
): number {
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Auto-complete Cash on Delivery payment when order is delivered (Phase 8.9)
 *
 * When order status → delivered AND paymentMethod = cash:
 * 1. Find payment document by orderId
 * 2. Update payment status to 'completed'
 * 3. Update order.paymentStatus to 'completed'
 */
async function autoCompleteCODPayment(
  orderId: string,
  _orderData: admin.firestore.DocumentData,
): Promise<void> {
  try {
    const db = admin.firestore();
    const paymentsSnap = await db
      .collection("payments")
      .where("orderId", "==", orderId)
      .limit(1)
      .get();

    if (paymentsSnap.empty) {
      logger.warn(`No payment found for COD order ${orderId}`);
      return;
    }

    const paymentRef = paymentsSnap.docs[0].ref;
    const orderRef = db.collection("orders").doc(orderId);

    await db.runTransaction(async (tx) => {
      const paymentDoc = await tx.get(paymentRef);
      if (!paymentDoc.exists) return;
      if (paymentDoc.data()?.status === "completed") {
        return;
      }

      tx.update(paymentRef, {
        status: "completed",
        transactionId: `COD-${orderId.substring(0, 8).toUpperCase()}`,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(orderRef, {
        paymentStatus: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    logger.info(
      `COD payment auto-completed: ${paymentRef.id} for order ${orderId}`,
    );
  } catch (error) {
    logger.error("Error auto-completing COD payment:", error);
  }
}
