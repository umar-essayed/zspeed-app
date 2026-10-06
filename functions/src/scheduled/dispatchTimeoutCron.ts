import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

export const dispatchTimeoutCron = onSchedule("every 1 minutes", async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const expiredRequests = await db.collection("deliveryRequests")
    .where("status", "==", "pending")
    .where("expiresAt", "<", now)
    .get();

  if (expiredRequests.empty) {
    console.log("No expired requests found.");
    return;
  }

  const batch = db.batch();

  expiredRequests.forEach((doc) => {
    console.log(`Expiring delivery request ${doc.id}`);
    batch.update(doc.ref, {
      status: "expired",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log(`Successfully expired ${expiredRequests.size} requests.`);
});
