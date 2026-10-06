import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { PaylinkService } from "../services/paylink/paylinkService";
import { AuditLogger } from "../services/logging/auditLogger";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

export const paylinkWebhook = onRequest(
  { timeoutSeconds: 60, memory: "256MiB" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const rawBody = req.body;
    if (!rawBody || typeof rawBody !== "object") {
      res.status(400).send("Invalid payload");
      return;
    }

    logger.info("[Paylink Webhook] Incoming event:", {
      event: rawBody.event,
      invoice_id: rawBody.invoice_id,
      invoice_status: rawBody.invoice_status,
      success: rawBody.success,
    });

    // 1. HMAC Signature Verification
    let verifiedEvent: any;
    try {
      verifiedEvent = await PaylinkService.verifyWebhook(rawBody);
    } catch (err: any) {
      logger.error("[Paylink Webhook] Signature verification failed:", err);
      res.status(400).send("Invalid HMAC Signature");
      return;
    }

    const eventType = String(verifiedEvent.event || rawBody.event || "");
    const invoiceId = Number(verifiedEvent.invoice_id || rawBody.invoice_id);
    const invoiceStatus = String(verifiedEvent.invoice_status || rawBody.invoice_status || "");
    const isSuccess = Boolean(verifiedEvent.success == 1 || invoiceStatus === "PAID");
    const authCode = verifiedEvent.auth_code || rawBody.auth_code || null;

    const db = admin.firestore();

    await AuditLogger.log({
      event: "PAYLINK_WEBHOOK_RECEIVED",
      invoiceId,
      status: "INFO",
      metadata: {
        eventType,
        invoiceStatus,
        isSuccess,
        authCode,
      },
    });

    // 2. Correlate invoice with Order or Ride
    let orderId: string | null = null;
    let rideId: string | null = null;

    // A. Check payments collection mapping
    const paymentDoc = await db.collection("payments").doc(String(invoiceId)).get();
    if (paymentDoc.exists) {
      const pData = paymentDoc.data()!;
      orderId = pData.orderId || null;
      rideId = pData.rideId || null;
    }

    // B. Fallback query if paymentDoc doesn't exist
    if (!orderId && !rideId) {
      const orderQuery = await db
        .collection("orders")
        .where("paymentInvoiceId", "==", invoiceId)
        .limit(1)
        .get();
      if (!orderQuery.empty) {
        orderId = orderQuery.docs[0].id;
      } else {
        const rideQuery = await db
          .collection("rides")
          .where("paymentInvoiceId", "==", invoiceId)
          .limit(1)
          .get();
        if (!rideQuery.empty) {
          rideId = rideQuery.docs[0].id;
        }
      }
    }

    if (!orderId && !rideId) {
      logger.warn(`[Paylink Webhook] No matching order or ride found for invoice ${invoiceId}`);
      res.status(200).send("No matching transaction found");
      return;
    }

    // ── 3. Process Delivery Order ─────────────────────────────
    if (orderId) {
      const orderRef = db.collection("orders").doc(orderId);
      const paymentRef = db.collection("payments").doc(String(invoiceId));

      await db.runTransaction(async (tx) => {
        const oDoc = await tx.get(orderRef);
        if (!oDoc.exists) return;
        const oData = oDoc.data()!;

        // Idempotency: Ignore if already marked paid/completed
        if (oData.paymentStatus === "completed" && oData.paymentState === "paid") {
          logger.info(`[Paylink Webhook] Order ${orderId} already paid, skipping duplicate.`);
          return;
        }

        if (isSuccess || eventType === "invoice.paid") {
          tx.update(orderRef, {
            status: "pending", // Transition from pending_payment to pending for vendor!
            paymentStatus: "completed",
            paymentState: "paid",
            paymentAuthCode: authCode,
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          tx.set(
            paymentRef,
            {
              invoiceId,
              orderId,
              status: "completed",
              authCode,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        } else {
          tx.update(orderRef, {
            paymentStatus: "failed",
            paymentState: "failed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          tx.set(
            paymentRef,
            {
              invoiceId,
              orderId,
              status: "failed",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      });

      if (isSuccess || eventType === "invoice.paid") {
        await AuditLogger.log({
          event: "PAYLINK_INVOICE_PAID",
          orderId,
          invoiceId,
          status: "SUCCESS",
        });

        // Notify Vendor ONLY NOW that payment has succeeded
        try {
          const freshDoc = await orderRef.get();
          const orderData = freshDoc.data();
          const vendorId = orderData?.vendorId || orderData?.restaurantId;
          const customerName = orderData?.customerName || "Customer";

          if (vendorId) {
            const vendorDoc = await db.collection("vendors").doc(vendorId).get();
            const ownerId = vendorDoc.data()?.ownerId;
            if (ownerId) {
              const methodLabel = orderData?.paymentMethod === "wallet" ? "Wallet" : "Card";
              const title = "New Order (Paid)!";
              const body = `${customerName} placed order #${orderId.substring(0, 8)} • ${methodLabel}`;
              await sendPushToUser(ownerId, title, body, { orderId, screen: "restaurant_orders" });
              await storeNotification({
                userId: ownerId,
                type: orderData?.paymentMethod === "wallet" ? "new_order_wallet_paid" : "new_order_card_paid",
                title,
                body,
                data: { orderId },
              });
            }
          }
        } catch (err) {
          logger.error(`[Paylink Webhook] Failed to notify vendor after payment:`, err);
        }
      } else {
        await AuditLogger.log({
          event: "PAYLINK_INVOICE_NOT_PAID",
          orderId,
          invoiceId,
          status: "WARNING",
        });
      }
    }

    // ── 4. Process Transportation Ride ────────────────────────
    if (rideId) {
      const rideRef = db.collection("rides").doc(rideId);
      const paymentRef = db.collection("payments").doc(String(invoiceId));

      await db.runTransaction(async (tx) => {
        const rDoc = await tx.get(rideRef);
        if (!rDoc.exists) return;

        if (isSuccess || eventType === "invoice.paid") {
          tx.update(rideRef, {
            paymentStatus: "completed",
            paymentState: "paid",
            paymentAuthCode: authCode,
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          tx.set(
            paymentRef,
            {
              invoiceId,
              rideId,
              status: "completed",
              authCode,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        } else {
          tx.update(rideRef, {
            paymentStatus: "failed",
            paymentState: "failed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          tx.set(
            paymentRef,
            {
              invoiceId,
              rideId,
              status: "failed",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      });

      await AuditLogger.log({
        event: isSuccess ? "RIDE_PAYMENT_PROCESSED" : "PAYLINK_INVOICE_NOT_PAID",
        rideId,
        invoiceId,
        status: isSuccess ? "SUCCESS" : "WARNING",
      });
    }

    res.status(200).send("OK");
  }
);
