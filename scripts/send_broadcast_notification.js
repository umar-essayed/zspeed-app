/**
 * Standalone Super Admin Broadcast Script with Full Configs & Location Filtering
 * 
 * Usage:
 *   node scripts/send_broadcast_notification.js \
 *     --target="customer" \
 *     --area="Cairo" \
 *     --title="Special Flash Discount! 🎉" \
 *     --body="Enjoy 20% off all orders in Cairo!" \
 *     --titleAr="خصم حصري لفترة محدودة! 🎉" \
 *     --bodyAr="استمتع بخصم 20% على جميع الطلبات في القاهرة!" \
 *     --screen="promo_code" \
 *     --code="CAIRO20" \
 *     --sendPush=true \
 *     --storeInApp=true
 * 
 * Or dry run:
 *   node scripts/send_broadcast_notification.js --dryRun=true
 */

const path = require("path");
const fs = require("fs");

let admin;
try {
  admin = require("firebase-admin");
} catch (_) {
  try {
    admin = require(path.join(__dirname, "../functions/node_modules/firebase-admin"));
  } catch (err) {
    console.error("❌ Error: firebase-admin module not found.");
    console.error("Please run: cd functions && npm install");
    process.exit(1);
  }
}

const serviceAccountPath = path.join(__dirname, "../zspeed-firebase-adminsdk-fbsvc-d363073c4d.json");

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`❌ Service account key not found at: ${serviceAccountPath}`);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const messaging = admin.messaging();

function parseArgs() {
  const args = process.argv.slice(2);
  const parsed = {};

  args.forEach((arg) => {
    if (arg.startsWith("--")) {
      const [key, ...valueParts] = arg.substring(2).split("=");
      parsed[key] = valueParts.join("=");
    }
  });

  return parsed;
}

function calculateHaversineDistance(lat1, lon1, lat2, lon2) {
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

async function main() {
  const args = parseArgs();

  const targetAudience = (args.target || "all").toLowerCase();
  const targetUserId = args.userId ? args.userId.trim().toLowerCase() : null;
  const targetArea = args.area ? args.area.trim().toLowerCase() : null;
  const lat = args.lat ? parseFloat(args.lat) : undefined;
  const lng = args.lng ? parseFloat(args.lng) : undefined;
  const radiusKm = args.radiusKm ? parseFloat(args.radiusKm) : undefined;

  const promoCode = args.code ? args.code.trim().toUpperCase() : "";
  const title = args.title || (promoCode ? `Special Offer! Promo Code: ${promoCode} 🎁` : "App Announcement 📢");
  const body = args.body || (promoCode ? `Use promo code ${promoCode} to get a special discount!` : "Check out the latest updates in Z_Speed!");
  const titleAr = args.titleAr || title;
  const bodyAr = args.bodyAr || body;
  const imageUrl = args.image || "";

  const screen = args.screen || (promoCode ? "promo_code" : "none");
  const entityId = args.entityId || "";
  const sendPush = args.sendPush !== "false";
  const storeInApp = args.storeInApp !== "false";
  const priority = args.priority || "high";
  const soundSetting = args.sound || "default";
  const dryRun = args.dryRun === "true";

  console.log("\n=======================================================");
  console.log("   🚀 Z_Speed Broadcast Notification Tool (Super Admin)");
  console.log("=======================================================");
  console.log(`🎯 Target Audience : ${targetAudience.toUpperCase()}`);
  if (targetArea) console.log(`📍 Target Area     : ${targetArea}`);
  if (radiusKm && lat !== undefined && lng !== undefined) {
    console.log(`🌐 Geo Radius      : ${radiusKm} km around (${lat}, ${lng})`);
  }
  console.log(`📣 Title (EN)      : ${title}`);
  console.log(`📝 Body (EN)       : ${body}`);
  if (titleAr !== title) console.log(`📣 Title (AR)      : ${titleAr}`);
  if (bodyAr !== body) console.log(`📝 Body (AR)       : ${bodyAr}`);
  if (promoCode) console.log(`🎟️  Promo Code     : ${promoCode}`);
  if (screen !== "none") console.log(`📱 Target Screen   : ${screen}`);
  console.log(`📲 FCM Push        : ${sendPush}`);
  console.log(`💾 In-App Store    : ${storeInApp}`);
  if (dryRun) console.log(`⚠️  DRY RUN MODE    : ENABLED (No network/DB changes)`);
  console.log("=======================================================\n");

  console.log("🔍 Fetching target users from Firestore...");
  const usersSnap = await db.collection("users").get();
  const targetUsers = [];

  usersSnap.forEach((doc) => {
    const uData = doc.data();
    const userType = (uData.type || "customer").toLowerCase();

    // Audience filter
    if (targetAudience === "specific_user") {
      if (!targetUserId) return;
      const matchesId = doc.id.toLowerCase() === targetUserId;
      const matchesUid = (uData.uid || "").toLowerCase() === targetUserId;
      const matchesEmail = (uData.email || "").toLowerCase() === targetUserId;
      const matchesPhone = (uData.phone || uData.phoneNumber || "")
        .replace(/\s+/g, "")
        .toLowerCase()
        .includes(targetUserId.replace(/\s+/g, ""));

      if (!matchesId && !matchesUid && !matchesEmail && !matchesPhone) {
        return;
      }
    } else if (targetAudience !== "all" && userType !== targetAudience) {
      return;
    }

    // Area filter
    if (targetArea) {
      const userAddr = (uData.address || "").toLowerCase();
      const savedAddrStr = Array.isArray(uData.savedAddresses)
        ? uData.savedAddresses.map((sa) => `${sa.address || ""} ${sa.label || ""}`).join(" ").toLowerCase()
        : "";

      if (!userAddr.includes(targetArea) && !savedAddrStr.includes(targetArea)) {
        return;
      }
    }

    // Geo radius filter
    if (lat !== undefined && lng !== undefined && radiusKm !== undefined && radiusKm > 0) {
      let geoMatch = false;

      if (typeof uData.latitude === "number" && typeof uData.longitude === "number") {
        if (calculateHaversineDistance(lat, lng, uData.latitude, uData.longitude) <= radiusKm) {
          geoMatch = true;
        }
      }

      if (!geoMatch && Array.isArray(uData.savedAddresses)) {
        for (const sa of uData.savedAddresses) {
          if (typeof sa.latitude === "number" && typeof sa.longitude === "number") {
            if (calculateHaversineDistance(lat, lng, sa.latitude, sa.longitude) <= radiusKm) {
              geoMatch = true;
              break;
            }
          }
        }
      }

      if (!geoMatch) return;
    }

    targetUsers.push({ id: doc.id, data: uData });
  });

  console.log(`✔ Found ${targetUsers.length} user(s) matching broadcast query.\n`);

  if (targetUsers.length === 0) {
    console.log("⚠️ No matching users found. Exiting.");
    process.exit(0);
  }

  const fcmTokenMap = new Map();
  const userIds = targetUsers.map((u) => u.id);

  targetUsers.forEach((u) => {
    const tokens = u.data.fcmTokens || [];
    if (Array.isArray(tokens)) {
      tokens.forEach((token) => {
        if (token && typeof token === "string") {
          fcmTokenMap.set(token, u.id);
        }
      });
    }
  });

  console.log(`📲 Valid FCM Tokens collected: ${fcmTokenMap.size}`);

  if (dryRun) {
    console.log("\n[DRY RUN SUMMARY]");
    console.log(`Would send FCM push to ${fcmTokenMap.size} device tokens.`);
    console.log(`Would save in-app notification for ${userIds.length} users.`);
    console.log("✅ Dry run completed successfully.\n");
    process.exit(0);
  }

  let totalPushSent = 0;
  let totalPushFailed = 0;
  let totalInAppStored = 0;

  const payloadData = {
    type: "broadcast",
    screen: screen,
    ...(promoCode ? { promoCode } : {}),
    ...(entityId ? { targetEntityId: entityId } : {}),
  };

  // 1. Send FCM Push
  if (sendPush && fcmTokenMap.size > 0) {
    const allTokens = Array.from(fcmTokenMap.keys());
    const tokenChunks = [];
    for (let i = 0; i < allTokens.length; i += 500) {
      tokenChunks.push(allTokens.slice(i, i + 500));
    }

    console.log(`📡 Delivering Push Notifications in ${tokenChunks.length} batch(es)...`);

    for (let i = 0; i < tokenChunks.length; i++) {
      const chunk = tokenChunks[i];
      const message = {
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
            channelId: soundSetting === "alert" ? "driver_ride_requests" : "order_updates",
            sound: soundSetting === "alert" ? "driver_alert" : "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: soundSetting === "alert" ? "driver_alert.caf" : "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const resp = await messaging.sendEachForMulticast(message);
        totalPushSent += resp.successCount;
        totalPushFailed += resp.failureCount;
        console.log(`   Batch ${i + 1}/${tokenChunks.length}: ${resp.successCount} sent, ${resp.failureCount} failed.`);
      } catch (err) {
        console.error(`❌ Batch ${i + 1} push failed:`, err.message);
      }
    }
  }

  // 2. Store In-App Notifications
  if (storeInApp && userIds.length > 0) {
    console.log(`\n💾 Writing In-App inbox documents in Firestore...`);
    const userChunks = [];
    for (let i = 0; i < userIds.length; i += 500) {
      userChunks.push(userIds.slice(i, i + 500));
    }

    for (let i = 0; i < userChunks.length; i++) {
      const uBatch = userChunks[i];
      const batch = db.batch();

      uBatch.forEach((uid) => {
        const ref = db.collection("notifications").doc();
        batch.set(ref, {
          userId: uid,
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

      await batch.commit();
      totalInAppStored += uBatch.length;
      console.log(`   Firestore Batch ${i + 1}/${userChunks.length}: Stored ${uBatch.length} notifications.`);
    }
  }

  console.log("\n=======================================================");
  console.log("🎉 BROADCAST COMPLETE!");
  console.log("=======================================================");
  console.log(`👥 Target Users          : ${targetUsers.length}`);
  console.log(`📩 Push Sent             : ${totalPushSent}`);
  console.log(`⚠️ Push Failed           : ${totalPushFailed}`);
  console.log(`💾 In-App Records Saved  : ${totalInAppStored}`);
  console.log("=======================================================\n");

  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Fatal Error:", err);
  process.exit(1);
});
