import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { PaylinkService } from "../services/paylink/paylinkService";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";
import { AuditLogger } from "../services/logging/auditLogger";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

export const paylinkChargeSavedCard = onCall(
  { timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const db = admin.firestore();
    const userData = await assertUserNotBlocked(uid, db);

    const { cardId, orderId, rideId } = request.data || {};
    if (!cardId) {
      throw new HttpsError("invalid-argument", "cardId is required.");
    }
    if (!orderId && !rideId) {
      throw new HttpsError("invalid-argument", "Either orderId or rideId is required.");
    }

    // 1. Get saved card token from users/{uid}/savedCards/{cardId}
    const cardDoc = await db.collection("users").doc(uid).collection("savedCards").doc(cardId).get();
    if (!cardDoc.exists) {
      throw new HttpsError("not-found", "Saved card not found.");
    }

    const cardData = cardDoc.data()!;
    const cardToken = cardData.cardToken;
    if (!cardToken) {
      throw new HttpsError("failed-precondition", "Invalid card token.");
    }

    let amount = 0;
    let productTitle = "";
    let isRide = false;
    let targetDocRef: admin.firestore.DocumentReference;

    const customerName = (userData?.name || userData?.displayName || userData?.fullName || "Valued Customer").toString().trim();
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

      if (oData.paymentStatus === "completed" || oData.paymentState === "paid") {
        throw new HttpsError("failed-precondition", "Order has already been paid.");
      }

      amount = Number(oData.total) || 0;
      productTitle = `Order #${orderId.substring(0, 8).toUpperCase()}`;
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
      productTitle = `Ride #${rideId.substring(0, 8).toUpperCase()}`;
      targetDocRef = rideRef;
    }

    if (amount <= 0) {
      throw new HttpsError("failed-precondition", "Payment amount must be greater than zero.");
    }

    // 2. Perform server-side charge
    const chargeResult = await PaylinkService.chargeSavedCard({
      cardToken,
      amount,
      currency: "EGP",
      product: productTitle,
      orderId: orderId || rideId,
      userId: uid,
      customerName,
      customerEmail,
      isRide,
    });

    const isPaid = chargeResult.paidStatus === "PAID";

    if (isPaid) {
      await db.runTransaction(async (tx) => {
        if (orderId) {
          tx.update(targetDocRef, {
            status: "pending", // Transition order to pending for vendor!
            paymentStatus: "completed",
            paymentState: "paid",
            paymentMethod: "card",
            paymentInvoiceId: chargeResult.invoiceId,
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(targetDocRef, {
            paymentStatus: "completed",
            paymentState: "paid",
            paymentMethod: "card",
            paymentInvoiceId: chargeResult.invoiceId,
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        const paymentRef = db.collection("payments").doc(String(chargeResult.invoiceId));
        tx.set(paymentRef, {
          invoiceId: chargeResult.invoiceId,
          orderId: orderId || null,
          rideId: rideId || null,
          customerId: uid,
          amount,
          currency: "EGP",
          status: "completed",
          cardLast4: cardData.last4 || null,
          cardBrand: cardData.brand || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // If it's an order, notify the vendor now
      if (orderId) {
        try {
          const freshOrder = await targetDocRef.get();
          const oData = freshOrder.data();
          const vendorId = oData?.vendorId || oData?.restaurantId;
          if (vendorId) {
            const vendorDoc = await db.collection("vendors").doc(vendorId).get();
            const ownerId = vendorDoc.data()?.ownerId;
            if (ownerId) {
              const title = "New Order (Paid)!";
              const body = `${customerName} placed order #${orderId.substring(0, 8)} • Card`;
              await sendPushToUser(ownerId, title, body, { orderId, screen: "restaurant_orders" });
              await storeNotification({
                userId: ownerId,
                type: "new_order_card_paid",
                title,
                body,
                data: { orderId },
              });
            }
          }
        } catch (err) {
          console.error("Failed to notify vendor on saved card charge:", err);
        }
      }

      return {
        success: true,
        invoiceId: chargeResult.invoiceId,
        paidStatus: chargeResult.paidStatus,
      };
    } else {
      throw new HttpsError("cancelled", `Payment declined: ${chargeResult.paidStatus}`);
    }
  }
);
