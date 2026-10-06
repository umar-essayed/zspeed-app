import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

/**
 * Triggered when a vendor document is updated.
 * When a vendor transitions from Busy (or Closed) back to Available (isOpen: true, isBusy: false),
 * sends push & in-app notifications to all active subscriptions (created within 2 hours).
 */
export const onVendorUpdated = onDocumentUpdated(
  "vendors/{vendorId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    const wasUnavailable = before.isBusy === true || before.isOpen === false;
    const isNowAvailable = after.isBusy !== true && after.isOpen === true;

    // Only fire when vendor transitions back to available
    if (!wasUnavailable || !isNowAvailable) return;

    const vendorId = event.params.vendorId;
    const vendorName = after.name || "Vendor";

    logger.info(`[onVendorUpdated] Vendor ${vendorId} (${vendorName}) is now available! Checking subscriptions...`);

    const db = getFirestore();
    const now = Timestamp.now();

    try {
      const subscriptionsSnap = await db
        .collection("vendor_notify_subscriptions")
        .where("vendorId", "==", vendorId)
        .where("expiresAt", ">", now)
        .get();

      if (subscriptionsSnap.empty) {
        logger.info(`[onVendorUpdated] No active subscribers for vendorId=${vendorId}`);
        return;
      }

      logger.info(`[onVendorUpdated] Found ${subscriptionsSnap.size} subscriber(s) for vendorId=${vendorId}`);

      const title = `${vendorName} is available now! 🎉`;
      const body = `You can now place your order from ${vendorName}.`;
      const notificationData = { screen: "vendor_menu", vendorId: vendorId };

      const batch = db.batch();

      for (const doc of subscriptionsSnap.docs) {
        const subData = doc.data();
        const userId = subData.userId;

        if (userId) {
          // Send FCM push notification
          await sendPushToUser(userId, title, body, notificationData);

          // Store in-app notification
          await storeNotification({
            userId,
            type: "vendor_available",
            title,
            body,
            data: notificationData,
          });
        }

        // Delete processed subscription record
        batch.delete(doc.ref);
      }

      await batch.commit();
      logger.info(`[onVendorUpdated] Successfully notified and cleaned up ${subscriptionsSnap.size} subscribers.`);
    } catch (error) {
      logger.error(`[onVendorUpdated] Error notifying subscribers for vendorId=${vendorId}:`, error);
    }
  },
);
