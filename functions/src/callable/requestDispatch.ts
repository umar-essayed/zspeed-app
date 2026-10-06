import { dispatchNextDriver } from "../services/dispatchService";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const requestDispatch = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();

  // Check custom claim role first
  let isAuthorized = false;
  const claimRole = request.auth.token?.role;
  if (claimRole === "vendor" || claimRole === "restaurant" || claimRole === "admin" || claimRole === "superAdmin") {
    isAuthorized = true;
  }

  // Fallback: Check user profile type in Firestore
  if (!isAuthorized) {
    const userDoc = await db.collection("users").doc(uid).get();
    if (userDoc.exists) {
      const dbType = userDoc.data()?.type;
      if (dbType === "vendor" || dbType === "restaurant" || dbType === "admin" || dbType === "superAdmin") {
        isAuthorized = true;
      }
    }
  }

  if (!isAuthorized) {
    throw new HttpsError("permission-denied", "Only vendor owners or admins can initiate dispatch.");
  }

  const { orderId } = request.data;
  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId is required");
  }

  const orderRef = db.collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();
  if (!orderDoc.exists) {
    throw new HttpsError("not-found", "Order not found");
  }

  const orderData = orderDoc.data();
  if (orderData?.status !== "pending" && orderData?.status !== "ready" && orderData?.status !== "searching") {
    throw new HttpsError("failed-precondition", "Order is not in a dispatchable state");
  }

  // Set to searching if not already
  if (orderData.status !== "searching") {
    await orderRef.update({
      status: "searching",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  const driverId = await dispatchNextDriver(orderId);

  return { success: !!driverId, driverId };
});
