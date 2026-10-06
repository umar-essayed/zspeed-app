import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";
import { dispatchNextDriver } from "../services/dispatchService";

export const onDeliveryRequestStatusUpdated = onDocumentUpdated("deliveryRequests/{requestId}", async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();

  if (!beforeData || !afterData) return;
  // Proceed only if the status actually changed
  if (beforeData.status === afterData.status) return;

  const orderId = afterData.orderId;
  const newStatus = afterData.status;
  const driverId = afterData.driverId as string | undefined;
  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    logger.warn(`[onDeliveryRequestStatusUpdated] Order ${orderId} not found`);
    return;
  }
  const orderData = orderDoc.data()!;
  const customerId = (orderData.customerId ?? orderData.userId) as string | undefined;
  const shortId = orderId.substring(0, 8).toUpperCase();

  logger.info(
    `[onDeliveryRequestStatusUpdated] orderId=${orderId} | ${beforeData.status} → ${newStatus} | driverId=${driverId}`,
  );

  // Fetch driver name once (used in notification bodies below)
  let driverName = "Your driver";
  if (driverId) {
    const driverDoc = await db.collection("driverProfiles").doc(driverId).get();
    if (driverDoc.exists) {
      driverName = (driverDoc.data()?.name as string) || driverName;
    }
  }

  try {
    if (newStatus === "accepted") {
      // Driver accepted the request. Sync order to assigned.
      await orderRef.update({
        status: "driverAssigned",
        driverId: afterData.driverId,
        driverIds: admin.firestore.FieldValue.arrayUnion(afterData.driverId),
        driverAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.info(`Order ${orderId} assigned to driver ${afterData.driverId}`);

      // Notify customer directly with driver name
      if (customerId) {
        const title = "Driver On The Way 🏍️";
        const body = `${driverName} accepted your order #${shortId} and is heading to pick it up.`;
        const data = { orderId, screen: "order_tracking" };
        await sendPushToUser(customerId, title, body, data);
        await storeNotification({
          userId: customerId,
          type: "driver_accepted",
          title,
          body,
          data,
        });
      }
    } else if (newStatus === "pickedUp") {
      // For multi-driver scenarios, check if ALL assigned drivers have picked up
      const activeRequests = await db.collection("deliveryRequests")
        .where("orderId", "==", orderId)
        .where("status", "in", ["accepted", "pickedUp", "delivered"])
        .get();

      let allReady = true;
      activeRequests.forEach((r) => {
        if (r.data().status === "accepted") allReady = false;
      });

      if (allReady) {
        await orderRef.update({ status: "pickedUp", updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        logger.info(`Order ${orderId} status shifted to pickedUp`);
      }

      // Notify customer that driver picked up the order (driver-specific message)
      if (customerId) {
        const title = "Order Picked Up 🛵";
        const body = `${driverName} picked up your order #${shortId} and is heading to you. Track live!`;
        const data = { orderId, screen: "order_tracking" };
        await sendPushToUser(customerId, title, body, data);
        await storeNotification({
          userId: customerId,
          type: "driver_picked_up",
          title,
          body,
          data,
        });
      }
    } else if (newStatus === "delivered") {
      // Finalize order
      await orderRef.update({
        status: "delivered",
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Order ${orderId} delivered! Writing to ledger...`);

      // Notify customer that driver delivered the order
      if (customerId) {
        const title = "Order Delivered 🎉";
        const body = `${driverName} delivered your order #${shortId}. Enjoy your meal!`;
        const data = { orderId, screen: "order_tracking" };
        await sendPushToUser(customerId, title, body, data);
        await storeNotification({
          userId: customerId,
          type: "driver_delivered",
          title,
          body,
          data,
        });
      }

      // 1. Write Split Ledger Tracking payout for the driver
      await db.collection("ledger").add({
        orderId,
        driverId: afterData.driverId,
        type: "delivery_fee_payout",
        amount: orderData.deliveryFee || 0,
        status: "pending", // Waiting for cron or admin approval
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Check for partial failures (multi-driver mode) requiring refunds
      // E.g., if one driver failed their leg of the delivery
      if (orderData.multiDriver && orderData.failedSubOrdersTotal > 0) {
        await db.collection("refund_queue").add({
          orderId,
          customerId,
          amount: orderData.failedSubOrdersTotal,
          reason: "partial_delivery_failure",
          status: "pending_review",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Pushed partial refund to queue for Order ${orderId}`);
      }
    } else if (newStatus === "rejected") {
      logger.info(`[onDeliveryRequestStatusUpdated] Delivery request rejected. Rebouncing order ${orderId}`);
      await dispatchNextDriver(orderId);
    } else if (newStatus === "expired") {
      if (driverId) {
        logger.info(`[onDeliveryRequestStatusUpdated] Marking orderDriver ${driverId} as rejected due to timeout on order ${orderId}`);
        const driverDoc = await db.collection("driverProfiles").doc(driverId).get();
        const driverData = driverDoc.exists ? driverDoc.data() : null;

        await db.collection("orders")
          .doc(orderId)
          .collection("orderDrivers")
          .doc(driverId)
          .set({
            driverUserId: driverId,
            driverName: driverData?.name || driverId,
            driverPhone: driverData?.phoneNumber || "",
            vehicleModel: driverData?.vehicleModel || "",
            licensePlate: driverData?.licensePlate || "",
            status: "rejected",
            rejectionReason: "Request timed out",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
      }
    }
  } catch (error) {
    console.error("Failed to aggregate status for Order " + orderId, error);
  }
});
