import * as admin from "firebase-admin";

export interface NotificationPayload {
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Persist a notification document in the notifications collection.
 */
export async function storeNotification(
  payload: NotificationPayload,
): Promise<string> {
  const docRef = await admin.firestore().collection("notifications").add({
    userId: payload.userId,
    type: payload.type,
    title: payload.title,
    body: payload.body,
    data: payload.data ?? {},
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return docRef.id;
}

/**
 * Store the same notification for multiple users.
 */
export async function storeNotificationForUsers(
  userIds: string[],
  type: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const batch = admin.firestore().batch();
  for (const userId of userIds) {
    const ref = admin.firestore().collection("notifications").doc();
    batch.set(ref, {
      userId,
      type,
      title,
      body,
      data: data ?? {},
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}
