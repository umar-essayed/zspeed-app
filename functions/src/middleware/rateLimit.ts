import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Rate Limit Middleware (Phase 8.10)
 *
 * Generic rate limiter using Firestore with TTL for automatic cleanup.
 *
 * Features:
 * - Per-user, per-action limits
 * - Sliding window with configurable duration
 * - Automatic cleanup via Firestore TTL on expiresAt field
 * - No external dependencies (Redis-free)
 *
 * Usage:
 * ```typescript
 * await checkRateLimit({
 *   action: 'order_creation',
 *   userId: request.auth.uid,
 *   maxAttempts: 5,
 *   windowSeconds: 3600,  // 1 hour
 * });
 * ```
 */

export interface RateLimitConfig {
  action: string;
  userId: string;
  maxAttempts: number;
  windowSeconds: number;
}

export async function checkRateLimit(config: RateLimitConfig): Promise<void> {
  const { action, userId, maxAttempts, windowSeconds } = config;
  if (!userId) return;

  try {
    const docId = `${userId}_${action}`;
    const ref = admin.firestore().collection("rateLimits").doc(docId);

    const now = admin.firestore.Timestamp.now();
    const windowStart = new admin.firestore.Timestamp(
      now.seconds - windowSeconds, 0
    );

    const doc = await ref.get();

    if (doc.exists) {
      const data = doc.data()!;
      const attempts = (data.attempts as number) || 0;
      const windowStarted = data.windowStartedAt as admin.firestore.Timestamp;

      if (windowStarted && windowStarted > windowStart) {
        // Within current window
        if (attempts >= maxAttempts) {
          console.warn(`[RateLimit] Exceeded for user ${userId} on action ${action} (${attempts}/${maxAttempts})`);
          throw new HttpsError(
            "resource-exhausted",
            `Rate limit exceeded for ${action}. Please wait a moment and try again.`
          );
        }
        await ref.update({
          attempts: admin.firestore.FieldValue.increment(1),
        });
      } else {
        // Window expired — reset
        await ref.set({
          attempts: 1,
          windowStartedAt: now,
          expiresAt: new admin.firestore.Timestamp(
            now.seconds + windowSeconds * 2, 0
          ),
        });
      }
    } else {
      // First attempt
      await ref.set({
        attempts: 1,
        windowStartedAt: now,
        expiresAt: new admin.firestore.Timestamp(
          now.seconds + windowSeconds * 2, 0
        ),
      });
    }
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error(`[RateLimit Error] Failed checking rate limit for ${userId}:`, error);
  }
}
