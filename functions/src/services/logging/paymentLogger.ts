import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

type PaymentEventName =
  | "payment.session.created"
  | "payment.session.rejected"
  | "payment.webhook.received"
  | "payment.webhook.invalid_signature"
  | "payment.webhook.amount_mismatch"
  | "payment.webhook.duplicate"
  | "payment.webhook.resolved"
  | "payment.status.read"
  | "payment.reconciler.run";

interface LogFields {
  name: PaymentEventName;
  orderId?: string;
  attemptId?: string;
  customerIdHash?: string;
  amount?: number;
  currency?: string;
  maskedCardBrand?: string;
  maskedCardLast4?: string;
  resultCode?: string;
  reasonCode?: string;
  decision?: string;
  resolvedBy?: string;
  durationMs?: number;
  triggeredFallbackQuery?: boolean;
  resolvedStateTransition?: string;
  emailHash?: string;
  phoneHash?: string;
  [key: string]: unknown;
}

const ALLOWLIST = new Set<string>([
  "name",
  "orderId",
  "attemptId",
  "customerIdHash",
  "amount",
  "currency",
  "maskedCardBrand",
  "maskedCardLast4",
  "resultCode",
  "reasonCode",
  "decision",
  "resolvedBy",
  "durationMs",
  "triggeredFallbackQuery",
  "resolvedStateTransition",
  "emailHash",
  "phoneHash",
]);

let pepper = "";

export async function initPaymentLogger(env: "test" | "prod"): Promise<void> {
  const projectId = process.env.GCP_PROJECT || admin.instanceId().app.options.projectId;
  const client = new SecretManagerServiceClient();
  const secretName = `projects/${projectId}/secrets/payment-log-pepper-${env}/versions/latest`;

  try {
    const [accessResponse] = await client.accessSecretVersion({ name: secretName });
    pepper = accessResponse.payload?.data?.toString() || "";
  } catch {
    const doc = await admin.firestore().collection("sys_settings").doc("secrets").get();
    pepper = doc.data()?.["payment-log-pepper-" + env] || "";
  }
}

export function hashPii(value: string, pepperOverride?: string): string {
  const p = pepperOverride || pepper;
  return crypto.createHash("sha256").update(value + p).digest("hex");
}

function sanitizeFields(fields: LogFields): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const key of Object.keys(fields)) {
    if (ALLOWLIST.has(key)) {
      const value = fields[key];
      if (key === "emailHash" || key === "phoneHash") {
        result[key] = value;
      } else {
        result[key] = value;
      }
    }
  }
  return result;
}

export function logPaymentEvent(fields: LogFields): void {
  const sanitized = sanitizeFields(fields);
  console.log(JSON.stringify({ ...sanitized, timestamp: new Date().toISOString() }));
}
