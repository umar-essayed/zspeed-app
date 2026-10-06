import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";
import { checkRateLimit } from "../middleware/rateLimit";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";

export const onOrderCreated = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const order = snapshot.data();
    const orderId = event.params.orderId;

    // Fix: use ?? directly (not after "as string" cast) to avoid TS precedence bug
    const customerId: string | undefined = order.customerId ?? order.userId;
    const vendorId: string | undefined = order.vendorId ?? order.restaurantId;
    const customerName: string = order.customerName ?? "A customer";
    const paymentMethod: string = order.paymentMethod ?? "cash";

    logger.info(
      `[onOrderCreated] orderId=${orderId} | vendorId=${vendorId} | customerId=${customerId}`,
    );

    const db = getFirestore();

    // Safety net: If order was created by a banned/blacklisted customer, auto-cancel immediately
    if (customerId) {
      try {
        await assertUserNotBlocked(customerId, db);
      } catch (err) {
        logger.warn(`[onOrderCreated] Auto-cancelling order ${orderId} because customer ${customerId} is blocked:`, err);
        await db.collection("orders").doc(orderId).update({
          status: "cancelled",
          cancellationReason: "Account suspended or blacklisted",
          cancelledBy: "system",
          cancelledAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }
    }

    // Look up the restaurant to find the owner
    if (!vendorId) {
      logger.error(
        `[onOrderCreated] Order ${orderId} has no vendorId/restaurantId`,
      );
      return;
    }

    const vendorDoc = await getFirestore()
      .collection("vendors")
      .doc(vendorId)
      .get();

    if (!vendorDoc.exists) {
      logger.error(
        `[onOrderCreated] Vendor ${vendorId} not found for order ${orderId}`,
      );
      return;
    }

    const ownerId: string | undefined = vendorDoc.data()?.ownerId;
    if (!ownerId) {
      logger.error(
        `[onOrderCreated] Vendor ${vendorId} has no ownerId`,
      );
      return;
    }

    logger.info(`[onOrderCreated] ownerId=${ownerId}`);

    // Phase 8.10: Rate limit check (non-blocking)
    try {
      if (customerId) {
        await checkRateLimit({
          action: "order_creation",
          userId: customerId,
          maxAttempts: 5,
          windowSeconds: 3600,
        });
      }
    } catch (error) {
      logger.error(`Rate limit exceeded for user ${customerId}:`, error);
      // Continue — log for monitoring/abuse detection only
    }

    // Format payment method label
    const paymentLabel =
      paymentMethod === "cash" ? "COD" :
        paymentMethod === "card" ? "Card" :
          paymentMethod === "wallet" ? "Wallet" : "COD";

    // If online payment (card or wallet) is still pending, DO NOT notify the vendor yet!
    // The vendor will be notified automatically once the payment succeeds (via webhook or charge).
    const isOnlineMethod = paymentMethod === "card" || paymentMethod === "wallet";
    const isPaymentPending =
      order.status === "pending_payment" ||
      (isOnlineMethod &&
        order.paymentStatus !== "completed" &&
        order.paymentState !== "paid");

    if (isPaymentPending) {
      logger.info(
        `[onOrderCreated] Order ${orderId} is awaiting online payment (${paymentMethod}). Skipping vendor notification until payment is confirmed.`
      );
      return;
    }

    // ── 1. Notify vendor owner ────────────────────────────────────
    const ownerTitle = "New Order!";
    const ownerBody = `${customerName} placed order #${orderId.substring(0, 8)} • ${paymentLabel}`;
    const ownerData = { orderId, screen: "vendor_order_detail" };

    await sendPushToUser(ownerId, ownerTitle, ownerBody, ownerData);
    await storeNotification({
      userId: ownerId,
      type: "order_created",
      title: ownerTitle,
      body: ownerBody,
      data: ownerData,
    });
    logger.info(`[onOrderCreated] Owner notification stored for ${ownerId}`);

    // ── 2. Notify customer — order received confirmation ──────────────
    if (customerId) {
      const customerTitle = "Order Received! 🎉";
      const customerBody = `Your order #${orderId.substring(0, 8)} has been placed and is waiting for vendor confirmation.`;
      const customerData = { orderId, screen: "order_detail" };

      await sendPushToUser(customerId, customerTitle, customerBody, customerData);
      await storeNotification({
        userId: customerId,
        type: "order_received",
        title: customerTitle,
        body: customerBody,
        data: customerData,
      });
      logger.info(
        `[onOrderCreated] Customer notification stored for ${customerId}`,
      );
    }
  },
);
