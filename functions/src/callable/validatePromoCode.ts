import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { checkRateLimit } from "../middleware/rateLimit";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";

/**
 * Cloud Function: validatePromoCode (Callable)
 *
 * Phase 8.9: Server-side promo code validation
 *
 * Input:
 * - promoCode: string
 * - customerId: string
 * - restaurantId: string
 * - orderTotal: number
 *
 * Returns:
 * {
 *   valid: boolean,
 *   discountType?: 'percentage' | 'fixed',
 *   discountValue?: number,
 *   calculatedDiscount?: number,
 *   message?: string
 * }
 *
 * Validation Rules:
 * 1. Code exists and is active
 * 2. Within validity period (startDate - endDate)
 * 3. Total usage limit not exceeded
 * 4. Per-user usage limit not exceeded
 * 5. Minimum order amount met
 * 6. Restaurant restrictions (if any)
 */
export const validatePromoCode = onCall(
  async (request) => {
    const customerId = request.auth?.uid;
    if (!customerId) {
      throw new HttpsError("unauthenticated", "User must be logged in");
    }

    const db = admin.firestore();
    await assertUserNotBlocked(customerId, db);

    const { promoCode, vendorId, orderTotal, clientDeliveryFee } = request.data;

    // Validate inputs
    if (!promoCode || typeof promoCode !== "string") {
      throw new HttpsError("invalid-argument", "Promo code is required");
    }
    if (!vendorId || typeof vendorId !== "string") {
      throw new HttpsError("invalid-argument", "Vendor ID is required");
    }
    if (typeof orderTotal !== "number" || orderTotal <= 0) {
      throw new HttpsError("invalid-argument", "Invalid order total");
    }

    // Phase 8.10: Rate limiting - max 100 promo validations per minute per user
    try {
      if (customerId) {
        await checkRateLimit({
          action: "promo_validation",
          userId: customerId,
          maxAttempts: 100,
          windowSeconds: 60,
        });
      }
    } catch (e: any) {
      logger.warn(`[validatePromoCode] Rate limit warning for ${customerId}:`, e?.message || e);
    }

    logger.info(`Validating promo code: ${promoCode} for customer: ${customerId}`);

    try {
    // 1. Fetch promo code document
      const promoRef = admin.firestore().collection("promoCodes").doc(promoCode.toUpperCase());
      const promoSnap = await promoRef.get();

      if (!promoSnap.exists) {
        return {
          valid: false,
          message: "Invalid promo code",
        };
      }

      const promo = promoSnap.data()!;

      // 2. Check if active
      if (promo.isActive !== true) {
        return {
          valid: false,
          message: "This promo code is no longer active",
        };
      }

      // 3. Check validity period
      const now = admin.firestore.Timestamp.now();
      const expiresAt = (promo.expiresAt ?? promo.endDate) as admin.firestore.Timestamp | undefined;
      const startDate = promo.startDate as admin.firestore.Timestamp | undefined;

      if (startDate && now < startDate) {
        return {
          valid: false,
          message: "This promo code is not yet valid",
        };
      }

      if (expiresAt && now > expiresAt) {
        return {
          valid: false,
          message: "This promo code has expired",
        };
      }

      // 4. Check total usage limit
      const maxUses = (promo.maxUsageCount ?? promo.maxUses) as number | undefined;
      const currentUses = (promo.usageCount ?? promo.currentUses) as number ?? 0;

      if (maxUses !== undefined && maxUses > 0 && currentUses >= maxUses) {
        return {
          valid: false,
          message: "This promo code has reached its usage limit",
        };
      }

      // 5. Check per-user usage limit
      const maxUsesPerUser = (promo.maxUsagePerUser ?? promo.maxUsesPerUser) as number | undefined;
      if (maxUsesPerUser !== undefined && maxUsesPerUser > 0) {
        const userUsageSnap = await admin.firestore()
          .collection("users")
          .doc(customerId)
          .collection("usedPromoCodes")
          .doc(promoSnap.id)
          .get();

        const userCount = (userUsageSnap.data()?.count as number) || 0;
        if (userCount >= maxUsesPerUser) {
          return {
            valid: false,
            message: "You have already used this promo code the maximum number of times",
          };
        }
      }

      // 6. Check minimum order amount
      const minOrderAmount = (promo.minOrderAmount) as number ?? 0;
      if (orderTotal < minOrderAmount) {
        return {
          valid: false,
          message: `Minimum order amount is ${minOrderAmount} EGP`,
        };
      }

      // 7. Check vendor restrictions
      const promoVendorId = promo.vendorId as string | undefined;
      const applicableVendors = promo.applicableVendors as string[] | undefined;
      if (promoVendorId && promoVendorId !== vendorId) {
        return {
          valid: false,
          message: "This promo code is not valid for this vendor",
        };
      }
      if (applicableVendors && applicableVendors.length > 0 && !applicableVendors.includes(vendorId)) {
        return {
          valid: false,
          message: "This promo code is not valid for this vendor",
        };
      }

      // 8. Calculate discount
      const discountType = (promo.type ?? promo.discountType) as string || "percentage";
      const discountValue = (promo.discountValue as number) || 0;
      const maxDiscountAmount = (promo.maxDiscountAmount as number) ?? null;

      let calculatedDiscount = 0;

      if (discountType === "percentage") {
        calculatedDiscount = (orderTotal * discountValue) / 100;
        if (maxDiscountAmount !== null && calculatedDiscount > maxDiscountAmount) {
          calculatedDiscount = maxDiscountAmount;
        }
      } else if (discountType === "freeDelivery") {
        let actualDeliveryFee = 49.0;
        try {
          const restDoc = await admin.firestore().collection("vendors").doc(vendorId).get();
          if (restDoc.exists) {
            const deliveryFeeMode = restDoc.data()?.deliveryFeeMode ?? "fixed";
            const vendorDeliveryFee = (restDoc.data()?.deliveryFee as number) ?? null;
            const minFee = (typeof vendorDeliveryFee === "number" && vendorDeliveryFee > 0.0) ? vendorDeliveryFee : 49.0;

            if (deliveryFeeMode === "fixed") {
              actualDeliveryFee = minFee;
            } else if (typeof clientDeliveryFee === "number") {
              actualDeliveryFee = clientDeliveryFee;
            } else {
              actualDeliveryFee = minFee;
            }
          }
        } catch (_) {
          if (typeof clientDeliveryFee === "number") {
            actualDeliveryFee = clientDeliveryFee;
          }
        }
        calculatedDiscount = actualDeliveryFee;
      } else {
        // fixed discount
        calculatedDiscount = discountValue;
      }

      // Ensure discount doesn't exceed order total
      calculatedDiscount = Math.min(calculatedDiscount, orderTotal);

      logger.info(
        `Promo code ${promoCode} validated successfully. Discount: ${calculatedDiscount} EGP`,
      );

      return {
        valid: true,
        discountType,
        discountValue,
        calculatedDiscount,
        message: `Discount of ${calculatedDiscount.toFixed(2)} EGP applied!`,
      };
    } catch (error) {
      logger.error("Error validating promo code:", error);
      throw new HttpsError("internal", "Failed to validate promo code");
    }
  });
