import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

const ORDER_TIMEOUT_MINUTES = 15;

export const scheduledOrderCleanup = onSchedule(
  "every 5 minutes",
  async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - ORDER_TIMEOUT_MINUTES * 60 * 1000),
    );

    const staleOrders = await admin.firestore()
      .collection("orders")
      .where("status", "==", "pending")
      .where("createdAt", "<", cutoff)
      .get();

    if (staleOrders.empty) return;

    const batch = admin.firestore().batch();
    const notificationPromises: Promise<void>[] = [];

    for (const doc of staleOrders.docs) {
      const order = doc.data();
      const orderId = doc.id;
      const customerId = (order.customerId ?? order.userId) as string | undefined;
      if (!customerId) continue;

      // Cancel the order
      batch.update(doc.ref, {
        status: "cancelled",
        cancelReason: "timeout",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Queue notification to customer
      const title = "Order Cancelled";
      const body = `Order #${orderId.substring(0, 8)} was cancelled — vendor did not accept within ${ORDER_TIMEOUT_MINUTES} minutes`;
      const data = { orderId, screen: "order_detail" };

      notificationPromises.push(
        sendPushToUser(customerId, title, body, data),
      );
      notificationPromises.push(
        storeNotification({
          userId: customerId,
          type: "order_timeout",
          title,
          body,
          data,
        }).then(() => {}),
      );
    }

    await batch.commit();
    await Promise.all(notificationPromises);

    console.log(`Cancelled ${staleOrders.size} stale orders`);
  },
);
