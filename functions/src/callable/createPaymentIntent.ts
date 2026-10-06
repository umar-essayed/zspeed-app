import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";

export const createPaymentIntent = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const db = admin.firestore();
  await assertUserNotBlocked(uid, db);

  const { amount, currency = "EGP", orderId } = request.data;

  if (!amount || !orderId) {
    throw new Error("amount and orderId are required");
  }

  // TODO: Integrate actual Payment Gateway API (e.g., Stripe, Paymob)
  // For Paymob:
  // 1. Authenticate to get token
  // 2. Register order to get Paymob order ID
  // 3. Get Payment Key (client secret)

  // Simulation: return a mock client secret
  const clientSecret = `mock_secret_${Date.now()}`;

  // Store the mock intent in firestore for webhook testing
  await db.collection("paymentIntents").doc(orderId).set({
    amount,
    currency,
    status: "created",
    clientSecret,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    clientSecret,
  };
});
