import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Send push notification to a user's devices via FCM.
 * Reads fcmTokens from the user's document.
 * Silently removes invalid/expired tokens.
 */
export async function sendPushToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const userDoc = await admin.firestore()
    .collection("users").doc(userId).get();
  if (!userDoc.exists) {
    logger.warn(`[sendPushToUser] User document not found for userId=${userId}`);
    return;
  }

  const fcmTokens: string[] = userDoc.data()?.fcmTokens ?? [];
  if (fcmTokens.length === 0) {
    logger.warn(`[sendPushToUser] No FCM tokens for userId=${userId} — notification not delivered`);
    return;
  }
  logger.info(`[sendPushToUser] Sending "${title}" to userId=${userId} (${fcmTokens.length} token(s))`);

  const isRideRequest = data?.type === "ride_request" || data?.screen === "delivery_request" || data?.screen === "ride_request";
  const channelId = isRideRequest ? "driver_ride_requests" : "order_updates";
  const sound = isRideRequest ? "driver_alert" : "default";

  const message: admin.messaging.MulticastMessage = {
    tokens: fcmTokens,
    notification: { title, body },
    data: data ?? {},
    android: {
      priority: "high",
      notification: {
        channelId: channelId,
        sound: sound,
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: isRideRequest ? "driver_alert.caf" : "default",
          badge: 1,
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  // Clean up invalid tokens
  const tokensToRemove: string[] = [];
  response.responses.forEach((resp, index) => {
    if (resp.error?.code === "messaging/invalid-registration-token" ||
        resp.error?.code === "messaging/registration-token-not-registered") {
      tokensToRemove.push(fcmTokens[index]);
    }
  });

  if (tokensToRemove.length > 0) {
    await admin.firestore().collection("users").doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
    });
  }
}

/**
 * Send push notification to multiple users.
 */
export async function sendPushToUsers(
  userIds: string[],
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  await Promise.all(
    userIds.map((uid) => sendPushToUser(uid, title, body, data)),
  );
}
