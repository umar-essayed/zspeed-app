import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

interface BroadcastRequest {
  targetAudience?: "all" | "customer" | "driver" | "vendor" | "admin" | "specific_user";
  targetUserId?: string;
  targetArea?: string;
  centerLat?: number;
  centerLng?: number;
  radiusKm?: number;

  // Content & Localization
  title?: string;
  body?: string;
  titleAr?: string;
  bodyAr?: string;
  titleEn?: string;
  bodyEn?: string;
  imageUrl?: string;

  // Navigation & Payload
  targetScreen?: string;
  promoCode?: string;
  targetEntityId?: string;
  customData?: Record<string, string>;

  // Delivery & Sound Configs
  sendPush?: boolean;
  storeInApp?: boolean;
  priority?: "high" | "normal";
  sound?: "default" | "alert" | "silent";
}

function calculateHaversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export const sendBroadcastNotification = onCall(
  { timeoutSeconds: 300, memory: "512MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const db = admin.firestore();

    // Verify caller has Super Admin role
    const callerDoc = await db.collection("users").doc(uid).get();
    if (!callerDoc.exists) {
      throw new HttpsError("permission-denied", "Caller profile not found.");
    }

    const callerData = callerDoc.data() || {};
    const role = callerData.type || callerData.role;
    if (role !== "super_admin" && role !== "superAdmin") {
      logger.warn(`[sendBroadcastNotification] Unauthorized attempt by uid=${uid} (role=${role})`);
      throw new HttpsError(
        "permission-denied",
        "Only Super Admin can issue broadcast notifications."
      );
    }

    const data: BroadcastRequest = request.data || {};
    const targetAudience = data.targetAudience || "all";
    const title = data.title || data.titleEn || "Notification";
    const body = data.body || data.bodyEn || "";
    const titleAr = data.titleAr || title;
    const bodyAr = data.bodyAr || body;
    const imageUrl = data.imageUrl || "";

    const targetScreen = data.targetScreen || "none";
    const promoCode = data.promoCode || "";
    const targetEntityId = data.targetEntityId || "";
    const sendPush = data.sendPush !== false;
    const storeInApp = data.storeInApp !== false;
    const priority = data.priority || "high";
    const soundSetting = data.sound || "default";

    logger.info(`[sendBroadcastNotification] Triggered by Super Admin uid=${uid} for audience=${targetAudience}`);

    // Query Users
    const usersSnap = await db.collection("users").get();
    const targetUsers: Array<{ id: string; data: any }> = [];

    const targetAreaNormalized = data.targetArea
      ? data.targetArea.trim().toLowerCase()
      : null;

    usersSnap.forEach((doc) => {
      const uData = doc.data();
      const userType = uData.type || "customer";

      // 1. Audience Filter
      if (targetAudience === "specific_user") {
        const targetUserIdClean = (data.targetUserId || "").trim().toLowerCase();
        if (!targetUserIdClean) {
          return;
        }
        const matchesId = doc.id.toLowerCase() === targetUserIdClean;
        const matchesUid = (uData.uid || "").toLowerCase() === targetUserIdClean;
        const matchesEmail = (uData.email || "").toLowerCase() === targetUserIdClean;
        const matchesPhone = (uData.phone || uData.phoneNumber || "")
          .replace(/\s+/g, "")
          .toLowerCase()
          .includes(targetUserIdClean.replace(/\s+/g, ""));

        if (!matchesId && !matchesUid && !matchesEmail && !matchesPhone) {
          return;
        }
      } else if (targetAudience !== "all" && userType !== targetAudience) {
        return;
      }

      // 2. Location Area Filter
      if (targetAreaNormalized) {
        const userAddress = (uData.address || "").toLowerCase();
        const savedAddressesStr = Array.isArray(uData.savedAddresses)
          ? uData.savedAddresses
              .map((sa: any) => `${sa.address || ""} ${sa.label || ""}`)
              .join(" ")
              .toLowerCase()
          : "";

        const matchesArea =
          userAddress.includes(targetAreaNormalized) ||
          savedAddressesStr.includes(targetAreaNormalized);

        if (!matchesArea) {
          return;
        }
      }

      // 3. Geo Radius Filter
      if (
        data.centerLat !== undefined &&
        data.centerLng !== undefined &&
        data.radiusKm !== undefined &&
        data.radiusKm > 0
      ) {
        let matchedGeo = false;

        if (
          typeof uData.latitude === "number" &&
          typeof uData.longitude === "number"
        ) {
          const dist = calculateHaversineDistance(
            data.centerLat,
            data.centerLng,
            uData.latitude,
            uData.longitude
          );
          if (dist <= data.radiusKm) {
            matchedGeo = true;
          }
        }

        if (!matchedGeo && Array.isArray(uData.savedAddresses)) {
          for (const sa of uData.savedAddresses) {
            if (
              typeof sa.latitude === "number" &&
              typeof sa.longitude === "number"
            ) {
              const dist = calculateHaversineDistance(
                data.centerLat,
                data.centerLng,
                sa.latitude,
                sa.longitude
              );
              if (dist <= data.radiusKm) {
                matchedGeo = true;
                break;
              }
            }
          }
        }

        if (!matchedGeo) {
          return;
        }
      }

      targetUsers.push({ id: doc.id, data: uData });
    });

    logger.info(`[sendBroadcastNotification] Targeted ${targetUsers.length} user(s) matching criteria.`);

    if (targetUsers.length === 0) {
      return {
        success: true,
        targetedUsersCount: 0,
        pushSentCount: 0,
        pushFailedCount: 0,
        inAppStoredCount: 0,
        message: "No users matched the selected criteria.",
      };
    }

    let pushSentCount = 0;
    let pushFailedCount = 0;
    let inAppStoredCount = 0;

    // Payload data map
    const payloadData: Record<string, string> = {
      type: "broadcast",
      screen: targetScreen,
      ...(promoCode ? { promoCode } : {}),
      ...(targetEntityId ? { targetEntityId } : {}),
      ...(data.customData || {}),
    };

    // Determine Notification Sound & Channel
    let soundFile = "default";
    let channelId = "order_updates";
    if (soundSetting === "alert") {
      soundFile = "driver_alert";
      channelId = "driver_ride_requests";
    } else if (soundSetting === "silent") {
      soundFile = "";
    }

    // FCM Push Delivery
    if (sendPush) {
      const fcmTokens: string[] = [];
      targetUsers.forEach((u) => {
        const tokens = u.data.fcmTokens;
        if (Array.isArray(tokens)) {
          tokens.forEach((t) => {
            if (typeof t === "string" && t.trim().length > 0) {
              fcmTokens.push(t);
            }
          });
        }
      });

      if (fcmTokens.length > 0) {
        const tokenChunks: string[][] = [];
        for (let i = 0; i < fcmTokens.length; i += 500) {
          tokenChunks.push(fcmTokens.slice(i, i + 500));
        }

        for (const chunk of tokenChunks) {
          const message: admin.messaging.MulticastMessage = {
            tokens: chunk,
            notification: {
              title: title,
              body: body,
              ...(imageUrl ? { imageUrl } : {}),
            },
            data: payloadData,
            android: {
              priority: priority === "high" ? "high" : "normal",
              notification: {
                channelId: channelId,
                ...(soundFile ? { sound: soundFile } : {}),
                ...(imageUrl ? { imageUrl } : {}),
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
            apns: {
              payload: {
                aps: {
                  ...(soundFile ? { sound: soundFile } : {}),
                  badge: 1,
                },
              },
              fcmOptions: {
                ...(imageUrl ? { imageUrl } : {}),
              },
            },
          };

          try {
            const resp = await admin.messaging().sendEachForMulticast(message);
            pushSentCount += resp.successCount;
            pushFailedCount += resp.failureCount;
          } catch (err: any) {
            logger.error(`[sendBroadcastNotification] FCM Batch failure: ${err?.message}`);
          }
        }
      }
    }

    // In-App Inbox Persistence
    if (storeInApp) {
      const userChunks: Array<Array<{ id: string; data: any }>> = [];
      for (let i = 0; i < targetUsers.length; i += 500) {
        userChunks.push(targetUsers.slice(i, i + 500));
      }

      for (const batchUsers of userChunks) {
        const writeBatch = db.batch();
        batchUsers.forEach((u) => {
          const docRef = db.collection("notifications").doc();
          writeBatch.set(docRef, {
            userId: u.id,
            type: "general",
            title: title,
            body: body,
            titleAr: titleAr,
            bodyAr: bodyAr,
            imageUrl: imageUrl,
            data: payloadData,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        await writeBatch.commit();
        inAppStoredCount += batchUsers.length;
      }
    }

    return {
      success: true,
      targetedUsersCount: targetUsers.length,
      pushSentCount,
      pushFailedCount,
      inAppStoredCount,
    };
  }
);
