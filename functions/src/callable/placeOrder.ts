import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";

export const placeOrder = onCall(
  { timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    try {
      const {
        vendorId: rawVendorId,
        restaurantId,
        items,
        deliveryAddress,
        deliveryLat,
        deliveryLng,
        paymentMethod,
        notes,
        promoCodeId,
        promoCode,
        deliveryFee: clientDeliveryFee,
      } = request.data || {};
      const uid = request.auth?.uid;

      if (!uid) {
        throw new HttpsError("unauthenticated", "User must be logged in.");
      }

      const db = admin.firestore();

      // Enforcement: Ensure user is active and not banned, suspended, or blacklisted
      const userData = await assertUserNotBlocked(uid, db);

      // Role check (Fix C-6)
      const role = request.auth?.token?.role;
      console.log(`[placeOrder Debug] uid=${uid}, token.role=${role}`);
      if (typeof role === "string" && role.toLowerCase() !== "customer") {
        console.log(`[placeOrder Rejected] token.role is ${role}`);
        throw new HttpsError("permission-denied", "Only customers can place orders.");
      }
      if (userData) {
        const userType = userData.type;
        if (typeof userType === "string" && userType.toLowerCase() !== "customer") {
          console.log(`[placeOrder Rejected] userType in Firestore is ${userType}`);
          throw new HttpsError("permission-denied", "Only customers can place orders.");
        }
      }

      const vendorId = rawVendorId || restaurantId;

      if (!vendorId || !items || !Array.isArray(items)) {
        throw new HttpsError("invalid-argument", "Missing required order fields or items.");
      }

      // Payment method validation (Fix L-5)
      if (!paymentMethod || !["cash", "card", "wallet"].includes(paymentMethod)) {
        throw new HttpsError("invalid-argument", "Invalid or missing payment method.");
      }

      // ── 1. Re-validate item prices from the database ──────────────────
      let calculatedSubtotal = 0;
      const serverItems: any[] = [];

      // Cache collectionGroup items safely (fallback lookup across sections)
      let groupDocs: any[] = [];
      try {
        let groupSnap = await db
          .collectionGroup("items")
          .where("restaurantId", "==", vendorId)
          .get();
        if (groupSnap.empty) {
          groupSnap = await db
            .collectionGroup("items")
            .where("vendorId", "==", vendorId)
            .get();
        }
        groupDocs = groupSnap.docs;
      } catch (e) {
        console.warn(`[placeOrder] collectionGroup query skipped/failed:`, e);
      }

      const groupItemsMap = new Map<string, { price: number; variants?: any[] }>();
      groupDocs.forEach((doc) => {
        const data = doc.data();
        const p = data.price;
        if (typeof p === "number") {
          groupItemsMap.set(doc.id, {
            price: p,
            variants: data.variants,
          });
        }
      });

      for (const item of items) {
        const itemId = item.menuItemId || item.id;
        const sectionId: string | undefined = item.sectionId;
        let price: number | null = null;

        // Tier 1: Exact menuSections subcollection path
        if (sectionId) {
          const exactDoc = await db
            .collection("vendors")
            .doc(vendorId)
            .collection("menuSections")
            .doc(sectionId)
            .collection("items")
            .doc(itemId)
            .get();
          if (exactDoc.exists) {
            const docData = exactDoc.data();
            if (docData) {
              if ((item.variantId || item.selectedVariantName) && Array.isArray(docData.variants)) {
                const variant = docData.variants.find((v: any) =>
                  (item.variantId && v.id === item.variantId) ||
                  (item.variantId && v.firebaseId === item.variantId) ||
                  (item.selectedVariantName && v.name === item.selectedVariantName) ||
                  (item.selectedVariantNameAr && v.nameAr === item.selectedVariantNameAr)
                );
                if (variant && typeof variant.price === "number") {
                  price = variant.price;
                }
              }
              if (price === null) {
                price = (docData.price as number) ?? null;
              }
            }
          }
        }

        // Tier 2: Direct items subcollection path under vendor
        if (price === null) {
          const directDoc = await db
            .collection("vendors")
            .doc(vendorId)
            .collection("items")
            .doc(itemId)
            .get();
          if (directDoc.exists) {
            const docData = directDoc.data();
            if (docData) {
              if ((item.variantId || item.selectedVariantName) && Array.isArray(docData.variants)) {
                const variant = docData.variants.find((v: any) =>
                  (item.variantId && v.id === item.variantId) ||
                  (item.variantId && v.firebaseId === item.variantId) ||
                  (item.selectedVariantName && v.name === item.selectedVariantName) ||
                  (item.selectedVariantNameAr && v.nameAr === item.selectedVariantNameAr)
                );
                if (variant && typeof variant.price === "number") {
                  price = variant.price;
                }
              }
              if (price === null) {
                price = (docData.price as number) ?? null;
              }
            }
          }
        }

        // Tier 3: Collection group map match by itemId
        if (price === null) {
          const cached = groupItemsMap.get(itemId);
          if (cached) {
            if ((item.variantId || item.selectedVariantName) && Array.isArray(cached.variants)) {
              const variant = cached.variants.find((v: any) =>
                (item.variantId && v.id === item.variantId) ||
                (item.variantId && v.firebaseId === item.variantId) ||
                (item.selectedVariantName && v.name === item.selectedVariantName) ||
                (item.selectedVariantNameAr && v.nameAr === item.selectedVariantNameAr)
              );
              if (variant && typeof variant.price === "number") {
                price = variant.price;
              }
            }
            if (price === null) {
              price = cached.price;
            }
          }
        }

        // Tier 4: Client payload unitPrice fallback if valid non-negative number
        if (price === null && typeof item.unitPrice === "number" && item.unitPrice >= 0) {
          price = item.unitPrice;
        }

        if (price === null) {
          throw new HttpsError(
            "failed-precondition",
            `Item ${itemId} not found in vendor ${vendorId}.`,
          );
        }

        const quantity = item.quantity || 1;
        const addonsTotal = item.addonsTotal || 0;
        const itemTotal = (price * quantity) + addonsTotal;
        calculatedSubtotal += itemTotal;

        serverItems.push({ ...item, unitPrice: price, itemTotal });
      }

      // ── 2. Fetch platform settings & vendor delivery fee ─────────
      let platformCommission = 0;
      try {
        const settingsDoc = await db
          .collection("sys_settings")
          .doc("app_settings")
          .get();

        if (settingsDoc.exists) {
          platformCommission =
            (settingsDoc.data()?.platformCommission as number) || 0;
        }
      } catch (_) {
        // Default to 0 commission if settings unavailable
      }

      let deliveryFee = 49.0;
      const vendorDoc = await db.collection("vendors").doc(vendorId).get();
      if (vendorDoc.exists) {
        const vData = vendorDoc.data();
        if (vData?.isBusy === true) {
          throw new HttpsError("failed-precondition", "Vendor is currently busy and not accepting orders.");
        }
        if (vData?.isOpen === false) {
          throw new HttpsError("failed-precondition", "Vendor is currently closed.");
        }

        const deliveryFeeMode = vData?.deliveryFeeMode ?? "fixed";
        const vendorDeliveryFee = (vData?.deliveryFee as number) ?? null;
        const minFee = (typeof vendorDeliveryFee === "number" && vendorDeliveryFee > 0.0) ? vendorDeliveryFee : 49.0;

        if (Array.isArray(vData?.deliveryFeeAreas) && vData.deliveryFeeAreas.length > 0 && typeof clientDeliveryFee === "number") {
          deliveryFee = clientDeliveryFee;
        } else if (deliveryFeeMode === "fixed") {
          deliveryFee = minFee;
        } else if (typeof clientDeliveryFee === "number") {
          deliveryFee = clientDeliveryFee;
        } else {
          deliveryFee = minFee;
        }
      } else if (typeof clientDeliveryFee === "number") {
        deliveryFee = clientDeliveryFee;
      }

      // ── 3. Atomic Order Placement & Promo Validation (Fix C-2, M-1) ───
      const orderRef = db.collection("orders").doc();
      let calculatedTotal = 0;

      await db.runTransaction(async (tx) => {
        let discount = 0;
        let appliedPromoCode: string | null = null;
        let discountType: string | null = null;

        if (promoCodeId && typeof promoCodeId === "string") {
          const promoRef = db.collection("promoCodes").doc(promoCodeId);
          const promoDoc = await tx.get(promoRef);

          if (promoDoc.exists) {
            const promo = promoDoc.data()!;
            const now = new Date();

            const isActive = promo.isActive !== false;
            const expiresAt = promo.expiresAt?.toDate?.() ?? null;
            const isExpired = expiresAt ? now > expiresAt : false;
            const maxUsage = (promo.maxUsageCount as number) || 0;
            const usageCount = (promo.usageCount as number) || 0;
            const reachedMax = maxUsage > 0 && usageCount >= maxUsage;
            const minOrderAmount = (promo.minOrderAmount as number) || 0;
            const promoVendorId = (promo.vendorId ?? promo.restaurantId) as string | null;

            const wrongVendor =
              promoVendorId != null && promoVendorId !== vendorId;

            const maxPerUser = (promo.maxUsagePerUser as number) || 1;
            const userUsageRef = db
              .collection("users")
              .doc(uid)
              .collection("usedPromoCodes")
              .doc(promoCodeId);
            const userUsageDoc = await tx.get(userUsageRef);
            const userUsageCount = (userUsageDoc.data()?.count as number) || 0;
            const userLimitReached = userUsageCount >= maxPerUser;

            if (
              isActive &&
              !isExpired &&
              !reachedMax &&
              !userLimitReached &&
              !wrongVendor &&
              calculatedSubtotal >= minOrderAmount
            ) {
              const type = (promo.type as string) || "percentage";
              const discountValue = (promo.discountValue as number) || 0;

              if (type === "percentage") {
                discount =
                  calculatedSubtotal * (Math.min(Math.max(discountValue, 0), 100) / 100);
              } else if (type === "fixed") {
                discount = Math.min(discountValue, calculatedSubtotal);
              } else if (type === "freeDelivery") {
                discount = deliveryFee;
              }

              appliedPromoCode = (promo.code as string) || promoCode || null;
              discountType = type;

              tx.update(promoRef, {
                usageCount: admin.firestore.FieldValue.increment(1),
              });
              tx.set(
                userUsageRef,
                {
                  count: admin.firestore.FieldValue.increment(1),
                  lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true }
              );
            }
          }
        }

        const serviceFee = 0.0;
        calculatedTotal = calculatedSubtotal + deliveryFee + serviceFee - discount;

        const orderItemsSummary = serverItems.map((item: any) => {
          let optSummary = item.optionsSummary || "";
          if (!optSummary) {
            const parts: string[] = [];
            if (item.selectedVariantName) {
              parts.push(item.selectedVariantName);
            }
            if (Array.isArray(item.selectedAddons)) {
              item.selectedAddons.forEach((addon: any) => {
                if (addon && addon.optionName) {
                  parts.push(addon.optionName);
                }
              });
            }
            optSummary = parts.join(", ");
          }

          return {
            id: item.id || item.menuItemId,
            menuItemId: item.menuItemId,
            name: item.menuItemName || item.name || "Item",
            nameAr: item.menuItemNameAr || item.nameAr || null,
            quantity: item.quantity,
            price: item.unitPrice,
            totalPrice: item.itemTotal,
            optionsSummary: optSummary || null,
          };
        });

        const customerName = (userData?.name || userData?.displayName || userData?.fullName || userData?.userName || "").toString().trim();
        const customerPhone = (userData?.phone || userData?.phoneNumber || userData?.mobile || userData?.phone_number || "").toString().trim();

        const orderData: Record<string, any> = {
          id: orderRef.id,
          customerId: uid,
          ...(customerName && { customerName }),
          ...(customerPhone && { customerPhone }),
          vendorId,
          restaurantId: vendorId,
          status: paymentMethod === "card" ? "pending_payment" : "pending",
          paymentState: "unpaid",
          paymentStatus: "pending",
          paymentMethod,
          subtotal: calculatedSubtotal,
          tax: 0,
          deliveryFee,
          serviceFee,
          discount,
          ...(appliedPromoCode && { appliedPromoCode }),
          ...(discountType && { discountType }),
          total: calculatedTotal,
          items: orderItemsSummary,
          deliveryAddress,
          deliveryLat: deliveryLat || 0.0,
          deliveryLng: deliveryLng || 0.0,
          customerNote: notes || "",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        tx.set(orderRef, orderData);

        serverItems.forEach((item: any) => {
          const itemRef = orderRef.collection("items").doc();
          tx.set(itemRef, {
            ...item,
            id: itemRef.id,
          });
        });
      });

      return {
        success: true,
        orderId: orderRef.id,
        total: calculatedTotal,
      };
    } catch (err: any) {
      console.error("[placeOrder Error]", err);
      if (err instanceof HttpsError) {
        throw err;
      }
      throw new HttpsError(
        "internal",
        err?.message || "Failed to place order on server. Please try again."
      );
    }
  }
);
