import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { PaylinkService } from "../services/paylink/paylinkService";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";
import { AuditLogger } from "../services/logging/auditLogger";

export const paylinkInitCheckout = onCall(
  { timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const db = admin.firestore();
    const userData = await assertUserNotBlocked(uid, db);

    const { orderId, rideId } = request.data || {};
    if (!orderId && !rideId) {
      throw new HttpsError("invalid-argument", "Either orderId or rideId is required.");
    }

    let amount = 0;
    let orderTitle = "";
    let isRide = false;
    let targetDocRef: admin.firestore.DocumentReference;

    const customerName = (userData?.name || userData?.displayName || userData?.fullName || "Valued Customer").toString().trim();
    const customerPhone = (userData?.phone || userData?.phoneNumber || "").toString().trim();
    const customerEmail = userData?.email || undefined;

    if (orderId) {
      const orderRef = db.collection("orders").doc(orderId);
      const orderDoc = await orderRef.get();
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "Order not found.");
      }

      const oData = orderDoc.data()!;
      if (oData.customerId !== uid && oData.userId !== uid) {
        throw new HttpsError("permission-denied", "You do not own this order.");
      }

      // Check if already paid
      if (oData.paymentStatus === "completed" || oData.paymentState === "paid") {
        throw new HttpsError("failed-precondition", "Order has already been paid.");
      }

      amount = Number(oData.total) || 0;
      if (amount <= 0) {
        throw new HttpsError("failed-precondition", "Order total must be greater than zero.");
      }

      orderTitle = `Order #${orderId.substring(0, 8).toUpperCase()}`;
      targetDocRef = orderRef;
    } else {
      isRide = true;
      const rideRef = db.collection("rides").doc(rideId);
      const rideDoc = await rideRef.get();
      if (!rideDoc.exists) {
        throw new HttpsError("not-found", "Ride not found.");
      }

      const rData = rideDoc.data()!;
      if (rData.customerId !== uid) {
        throw new HttpsError("permission-denied", "You do not own this ride.");
      }

      if (rData.paymentStatus === "completed" || rData.paymentState === "paid") {
        throw new HttpsError("failed-precondition", "Ride has already been paid.");
      }

      amount = Number(rData.totalFare) || 0;
      if (amount <= 0) {
        throw new HttpsError("failed-precondition", "Ride fare must be greater than zero.");
      }

      orderTitle = `Z-SPEED Ride #${rideId.substring(0, 8).toUpperCase()}`;
      targetDocRef = rideRef;
    }

    // Call PayLink to initialize checkout
    const invoiceResult = await PaylinkService.createInvoice({
      orderId: orderId || rideId,
      amount,
      currency: "EGP",
      orderTitle,
      customerName,
      customerEmail,
      customerPhone,
      userId: uid,
      isRide,
    });

    // Save invoice reference to target doc and payments collection
    await db.runTransaction(async (tx) => {
      tx.update(targetDocRef, {
        paymentInvoiceId: invoiceResult.invoiceId,
        paymentInvoiceUrl: invoiceResult.checkoutUrl,
        paymentState: "pending_gateway",
        paymentMethod: "card",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const paymentRef = db.collection("payments").doc(String(invoiceResult.invoiceId));
      tx.set(paymentRef, {
        invoiceId: invoiceResult.invoiceId,
        checkoutUrl: invoiceResult.checkoutUrl,
        orderId: orderId || null,
        rideId: rideId || null,
        customerId: uid,
        amount,
        currency: "EGP",
        status: "initiated",
        expiresAt: invoiceResult.expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return {
      success: true,
      checkoutUrl: invoiceResult.checkoutUrl,
      invoiceId: invoiceResult.invoiceId,
      expiresAt: invoiceResult.expiresAt,
    };
  }
);
