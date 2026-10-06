import * as admin from "firebase-admin";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

export interface PaylinkConfig {
  publicToken: string;
  hashToken: string;
  baseUrl: string;
  appReturnScheme: string;
}

let cachedConfig: PaylinkConfig | null = null;

async function fetchSecret(secretName: string): Promise<string | null> {
  // 1. Process environment variables first
  const envName = secretName.toUpperCase().replace(/-/g, "_");
  if (process.env[envName]) {
    return process.env[envName]!;
  }

  // 2. Google Secret Manager
  const projectId = process.env.GCP_PROJECT || admin.instanceId().app.options.projectId;
  if (projectId) {
    try {
      const client = new SecretManagerServiceClient();
      const [version] = await client.accessSecretVersion({
        name: `projects/${projectId}/secrets/${secretName}/versions/latest`,
      });
      const val = version.payload?.data?.toString();
      if (val) return val;
    } catch {
      // Secret Manager not accessible or secret missing, fall back to Firestore
    }
  }

  // 3. Firestore fallback: sys_settings/secrets
  try {
    const doc = await admin.firestore().collection("sys_settings").doc("secrets").get();
    if (doc.exists && doc.data()?.[secretName]) {
      return String(doc.data()![secretName]);
    }
  } catch {
    // Firestore not reachable
  }

  return null;
}

export async function getPaylinkConfig(): Promise<PaylinkConfig> {
  if (cachedConfig) {
    return cachedConfig;
  }

  const publicToken = await fetchSecret("paylink-public-token");
  const hashToken = await fetchSecret("paylink-hash-token");

  if (!publicToken || !hashToken) {
    throw new Error(
      "PayLink configuration missing. Please ensure 'paylink-public-token' and 'paylink-hash-token' are configured in Secret Manager or sys_settings/secrets."
    );
  }

  const baseUrl = process.env.PAYLINK_BASE_URL || "https://pay.getpayin.com";
  const appReturnScheme = process.env.PAYLINK_APP_RETURN_SCHEME || "zspeed://payment-return";

  cachedConfig = {
    publicToken,
    hashToken,
    baseUrl,
    appReturnScheme,
  };

  return cachedConfig;
}
