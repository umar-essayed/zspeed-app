import * as admin from "firebase-admin";

export interface AttemptCapResult {
  locked: boolean;
}

export async function applyAttemptCapIfNeeded(
  orderRef: admin.firestore.DocumentReference,
  tx: admin.firestore.Transaction
): Promise<AttemptCapResult> {
  const orderDoc = await tx.get(orderRef);
  const orderData = orderDoc.data()!;

  const paymentAttemptCount = orderData.paymentAttemptCount || 0;

  if (paymentAttemptCount >= 3) {
    const cooldownUntil = new Date(Date.now() + 30 * 60 * 1000);
    tx.update(orderRef, {
      paymentState: "locked_for_cooldown",
      cooldownUntil: cooldownUntil,
    });
    return { locked: true };
  }

  return { locked: false };
}
