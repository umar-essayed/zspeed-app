import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

/**
 * Scheduled cron function running every 24 hours to purge stale records:
 * - Notifications older than 30 days (1 month)
 * - Mail older than 7 days (1 week)
 * - Email verifications older than 24 hours (1 day)
 */
export const cleanupStaleData = onSchedule(
  "every 24 hours",
  async () => {
    const db = admin.firestore();
    const now = Date.now();

    // 1. Purge notifications older than 30 days (1 month)
    const notificationCutoff = admin.firestore.Timestamp.fromMillis(
      now - 30 * 24 * 60 * 60 * 1000
    );
    const notificationsQuery = db
      .collection("notifications")
      .where("createdAt", "<", notificationCutoff);
    const deletedNotifications = await deleteQueryBatch(db, notificationsQuery);
    console.log(`[cleanupStaleData] Deleted ${deletedNotifications} stale notifications.`);

    // 2. Purge mail older than 7 days (1 week)
    const mailCutoff = admin.firestore.Timestamp.fromMillis(
      now - 7 * 24 * 60 * 60 * 1000
    );
    const mailQuery = db
      .collection("mail")
      .where("createdAt", "<", mailCutoff);
    const deletedMails = await deleteQueryBatch(db, mailQuery);
    console.log(`[cleanupStaleData] Deleted ${deletedMails} stale mails.`);

    // 3. Purge email verifications older than 24 hours (1 day)
    const verificationCutoff = admin.firestore.Timestamp.fromMillis(
      now - 24 * 60 * 60 * 1000
    );
    const verificationsQuery = db
      .collection("emailVerifications")
      .where("expiresAt", "<", verificationCutoff);
    const deletedVerifications = await deleteQueryBatch(db, verificationsQuery);
    console.log(`[cleanupStaleData] Deleted ${deletedVerifications} stale email verifications.`);

    // 4. Purge expired vendor notify subscriptions (expiresAt < now)
    const nowTimestamp = admin.firestore.Timestamp.fromMillis(now);
    const subscriptionsQuery = db
      .collection("vendor_notify_subscriptions")
      .where("expiresAt", "<", nowTimestamp);
    const deletedSubscriptions = await deleteQueryBatch(db, subscriptionsQuery);
    console.log(`[cleanupStaleData] Deleted ${deletedSubscriptions} expired vendor notify subscriptions.`);
  }
);

/**
 * Helper function to safely delete documents matching a query in batches of 500.
 */
async function deleteQueryBatch(
  db: admin.firestore.Firestore,
  query: admin.firestore.Query
): Promise<number> {
  let deletedCount = 0;
  let hasMore = true;
  while (hasMore) {
    const snapshot = await query.limit(500).get();
    if (snapshot.empty) {
      break;
    }
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    deletedCount += snapshot.size;
    if (snapshot.size < 500) {
      hasMore = false;
    }
  }
  return deletedCount;
}
