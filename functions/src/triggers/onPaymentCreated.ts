import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Cloud Function: onPaymentCreated
 *
 * Triggered when a new payment document is created in Firestore.
 *
 * Phase 8.9: Payment Integration
 *
 * Responsibilities:
 * 1. Verify payment amount matches linked order total
 * 2. Update order.paymentStatus to 'pending'
 * 3. Mark payment as 'failed' if amount mismatch detected
 *
 * Security:
 * - Server-side validation prevents tampered payment amounts
 * - Order total is source of truth
 */
export const onPaymentCreated = onDocumentCreated(
  "payments/{paymentId}",
  async (event) => {
    const paymentData = event.data?.data();
    if (!paymentData) return;

    const paymentId = event.params.paymentId;
    const orderId = paymentData.orderId as string;
    const paymentAmount = paymentData.amount as number;

    logger.info(`Payment created: ${paymentId} for order: ${orderId}, amount: ${paymentAmount}`);

    try {
      // 1. Fetch linked order
      const orderRef = admin.firestore().collection("orders").doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        logger.error(`Order not found: ${orderId}`);
        await markPaymentFailed(paymentId, "Order not found");
        return;
      }

      const orderData = orderSnap.data()!;
      const orderTotal = orderData.total as number;

      // 2. Verify amount matches order total
      // Allow 0.01 EGP tolerance for floating-point precision
      const amountDiff = Math.abs(paymentAmount - orderTotal);
      if (amountDiff > 0.01) {
        logger.error(
          `Payment amount mismatch! Payment: ${paymentAmount} EGP, Order: ${orderTotal} EGP`,
        );
        await markPaymentFailed(
          paymentId,
          `Amount mismatch: expected ${orderTotal} EGP, got ${paymentAmount} EGP`,
        );
        await orderRef.update({
          paymentStatus: "failed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // 3. Update order.paymentStatus to 'pending'
      await orderRef.update({
        paymentStatus: "pending",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Payment ${paymentId} verified successfully. Order ${orderId} paymentStatus → pending`);
    } catch (error) {
      logger.error("Error in onPaymentCreated:", error);
      await markPaymentFailed(paymentId, "Server error during verification");
    }
  },
);

/**
 * Mark payment as failed with error message
 */
async function markPaymentFailed(
  paymentId: string,
  errorMessage: string,
): Promise<void> {
  await admin.firestore().collection("payments").doc(paymentId).update({
    status: "failed",
    transactionId: `ERROR: ${errorMessage}`,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
