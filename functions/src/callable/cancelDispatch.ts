import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const cancelDispatch = onCall(async (request) => {
  try {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();

    const { orderId } = request.data || {};
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const orderData = orderDoc.data();

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
        const uData = userDoc.data();
        const dbType = uData?.type;
        if (
          dbType === "vendor" ||
          dbType === "restaurant" ||
          dbType === "admin" ||
          dbType === "superAdmin" ||
          dbType === "vendor_owner" ||
          (uData?.vendorId && (uData.vendorId === orderData?.vendorId || uData.vendorId === orderData?.restaurantId))
        ) {
          isAuthorized = true;
        }
      }
    }

    if (!isAuthorized) {
      throw new HttpsError("permission-denied", "Only vendor owners or admins can cancel dispatch.");
    }

    if (orderData?.status === "unassigned") {
      console.log(`[cancelDispatch] Order ${orderId} is already in unassigned status. Returning success.`);
      return { success: true };
    }

    if (orderData?.status !== "searching" && orderData?.status !== "ready" && orderData?.status !== "pending") {
      throw new HttpsError("failed-precondition", `Order is not in a cancellable search state (current status: ${orderData?.status})`);
    }

    // Update order status back to unassigned
    await orderRef.update({
      status: "unassigned",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Query pending requests for this order
    const pendingRequestsSnap = await db.collection("deliveryRequests")
      .where("orderId", "==", orderId)
      .where("status", "==", "pending")
      .get();

    if (!pendingRequestsSnap.empty) {
      const batch = db.batch();
      pendingRequestsSnap.forEach((doc) => {
        batch.update(doc.ref, {
          status: "cancelled",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const driverId = doc.data().driverId;
        if (driverId) {
          const orderDriverRef = db.collection("orders")
            .doc(orderId)
            .collection("orderDrivers")
            .doc(driverId);
          batch.set(orderDriverRef, {
            status: "cancelled",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        }
      });
      await batch.commit();
    }

    return { success: true };
  } catch (error: any) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("[cancelDispatch] Internal error:", error);
    throw new HttpsError("internal", error.message || "An internal error occurred while cancelling auto-dispatch.");
  }
});
