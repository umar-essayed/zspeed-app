import * as admin from "firebase-admin";
import * as crypto from "crypto";

export type AuditEventName =
  | "PAYLINK_INIT_REQUESTED"
  | "PAYLINK_INIT_SUCCESS"
  | "PAYLINK_INIT_FAILED"
  | "PAYLINK_WEBHOOK_RECEIVED"
  | "PAYLINK_WEBHOOK_VERIFIED"
  | "PAYLINK_WEBHOOK_SIGNATURE_INVALID"
  | "PAYLINK_INVOICE_PAID"
  | "PAYLINK_INVOICE_NOT_PAID"
  | "PAYLINK_CARD_CHARGE_REQUESTED"
  | "PAYLINK_CARD_CHARGE_SUCCESS"
  | "PAYLINK_CARD_CHARGE_FAILED"
  | "PAYLINK_CARD_TOKENIZED"
  | "PAYLINK_CARD_REVOKED"
  | "SUSPICIOUS_AMOUNT_MISMATCH"
  | "ORDER_STATUS_TRANSITION"
  | "RIDE_PAYMENT_PROCESSED";

export interface AuditLogPayload {
  event: AuditEventName;
  orderId?: string;
  rideId?: string;
  userId?: string;
  amount?: number;
  currency?: string;
  invoiceId?: number | string;
  cardLast4?: string;
  cardBrand?: string;
  status: "INFO" | "SUCCESS" | "WARNING" | "FAILURE" | "SECURITY_ALERT";
  reasonCode?: string;
  clientIp?: string;
  metadata?: Record<string, unknown>;
}

/**
 * Enterprise Audit Logger for Payment Operations.
 * 
 * 1. Outputs structured JSON for Google Cloud Logging with appropriate severity levels.
 * 2. Writes an immutable audit trail entry in Firestore `payment_audit_logs/{id}`.
 * 3. Hashes sensitive user references (PII protection).
 * 4. Ensures strict Zero-Card-Data policy (never logs PAN, CVV, or Expiry).
 */
export class AuditLogger {
  private static hashUserId(userId?: string): string | undefined {
    if (!userId) return undefined;
    return crypto.createHash("sha256").update(userId).digest("hex").substring(0, 16);
  }

  public static async log(payload: AuditLogPayload): Promise<void> {
    const timestamp = new Date().toISOString();
    const customerHash = this.hashUserId(payload.userId);

    const logEntry = {
      event: payload.event,
      orderId: payload.orderId || null,
      rideId: payload.rideId || null,
      customerHash: customerHash || null,
      amount: payload.amount ?? null,
      currency: payload.currency || "EGP",
      invoiceId: payload.invoiceId ? String(payload.invoiceId) : null,
      cardLast4: payload.cardLast4 || null,
      cardBrand: payload.cardBrand || null,
      status: payload.status,
      reasonCode: payload.reasonCode || null,
      clientIp: payload.clientIp || null,
      metadata: payload.metadata || {},
      timestamp,
    };

    // 1. Google Cloud Structured Logging
    const severityMap: Record<AuditLogPayload["status"], string> = {
      INFO: "INFO",
      SUCCESS: "NOTICE",
      WARNING: "WARNING",
      FAILURE: "ERROR",
      SECURITY_ALERT: "CRITICAL",
    };

    const severity = severityMap[payload.status] || "INFO";
    console.log(JSON.stringify({
      severity,
      message: `[PAYMENT_AUDIT] ${payload.event} - Status: ${payload.status}${payload.orderId ? ` | Order: ${payload.orderId}` : ""}${payload.rideId ? ` | Ride: ${payload.rideId}` : ""}`,
      ...logEntry,
    }));

    // 2. Persistent Firestore Audit Collection
    try {
      const db = admin.firestore();
      await db.collection("payment_audit_logs").add({
        ...logEntry,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error("[PAYMENT_AUDIT_ERROR] Failed to persist audit log to Firestore:", err);
    }
  }
}
