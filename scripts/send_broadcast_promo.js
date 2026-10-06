/**
 * Standalone Broadcast Script for Sending Notifications with Promo Code to Customers
 * 
 * Usage:
 *   node scripts/send_broadcast_promo.js --code="PROMO20" --title="Special Discount! 🎉" --body="Use code PROMO20 for 20% off your next order!"
 * 
 * Or run directly with default/interactive values:
 *   node scripts/send_broadcast_promo.js
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

// 1. Locate and initialize Firebase Service Account
const serviceAccountPath = path.join(__dirname, "../zspeed-firebase-adminsdk-fbsvc-d363073c4d.json");

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`❌ Service account key not found at: ${serviceAccountPath}`);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

// 2. Helper to parse command line arguments
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

async function main() {
  const args = parseArgs();

  // Command-line parameters with fallback defaults
  const promoCode = (args.code || "SAVE20").trim().toUpperCase();
  const title = args.title || `Special Offer! Promo Code: ${promoCode} 🎁`;
  const body = args.body || `Use promo code ${promoCode} to get a special discount on your next order! Open the app to claim now.`;
  const dryRun = args.dryRun === "true";

  console.log("\n=======================================================");
  console.log("   🚀 Z_Speed Broadcast Promo Notification Script");
  console.log("=======================================================");
  console.log(`📌 Target Audience : CUSTOMERS ONLY (type === 'customer')`);
  console.log(`🎟️  Promo Code     : ${promoCode}`);
  console.log(`📣 Title          : ${title}`);
  console.log(`📝 Body           : ${body}`);
  if (dryRun) {
    console.log(`⚠️  DRY RUN MODE    : Enabled (No notifications or DB writes will occur)`);
  }
  console.log("=======================================================\n");

  console.log("🔍 Querying customer accounts from Firestore...");

  // Query customers only
  const usersSnap = await db.collection("users").get();
  
  const customerDocs = [];
  usersSnap.forEach((doc) => {
    const data = doc.data();
    // Include if type is explicitly customer or default customer
    if (!data.type || data.type === "customer") {
      customerDocs.push({ id: doc.id, data });
    }
  });

  console.log(`✔ Found ${customerDocs.length} customer user(s).\n`);

  if (customerDocs.length === 0) {
    console.log("⚠️ No customer users found. Exiting.");
    process.exit(0);
  }

  let totalPushSent = 0;
  let totalPushFailed = 0;
  let totalNotificationsStored = 0;

  const fcmTokenMap = new Map(); // token -> userId
  const customersToNotifyInApp = [];

  customerDocs.forEach((c) => {
    const tokens = c.data.fcmTokens || [];
    if (Array.isArray(tokens)) {
      tokens.forEach((token) => {
        if (token && typeof token === "string") {
          fcmTokenMap.set(token, c.id);
        }
      });
    }
    customersToNotifyInApp.push(c.id);
  });

  console.log(`📲 Total valid FCM Token(s) collected: ${fcmTokenMap.size}`);

  if (dryRun) {
    console.log("\n[DRY RUN] Would send push notifications to:", Array.from(fcmTokenMap.keys()));
    console.log("[DRY RUN] Would create in-app notifications for:", customersToNotifyInApp);
    console.log("\n✅ Dry run completed successfully.");
    process.exit(0);
  }

  // 3. Send FCM Push Notifications in Chunks of 500 tokens
  const allTokens = Array.from(fcmTokenMap.keys());
  const tokenChunks = [];
  for (let i = 0; i < allTokens.length; i += 500) {
    tokenChunks.push(allTokens.slice(i, i + 500));
  }

  console.log(`\n📡 Sending Push Notifications in ${tokenChunks.length} batch(es)...`);

  for (let i = 0; i < tokenChunks.length; i++) {
    const tokensBatch = tokenChunks[i];
    const message = {
      tokens: tokensBatch,
      notification: {
        title: title,
        body: body,
      },
      data: {
        promoCode: promoCode,
        screen: "promo_code",
        type: "general",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "order_updates",
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await messaging.sendEachForMulticast(message);
      totalPushSent += response.successCount;
      totalPushFailed += response.failureCount;
      console.log(`   Batch ${i + 1}/${tokenChunks.length}: Sent ${response.successCount} successfully, ${response.failureCount} failed.`);
    } catch (err) {
      console.error(`❌ Batch ${i + 1} send failed:`, err.message);
    }
  }

  // 4. Store In-App Notifications in Firestore (Batched by 500 writes)
  console.log(`\n💾 Storing in-app notification records in Firestore...`);
  
  const userChunks = [];
  for (let i = 0; i < customersToNotifyInApp.length; i += 500) {
    userChunks.push(customersToNotifyInApp.slice(i, i + 500));
  }

  for (let i = 0; i < userChunks.length; i++) {
    const userBatch = userChunks[i];
    const writeBatch = db.batch();

    userBatch.forEach((userId) => {
      const ref = db.collection("notifications").doc();
      writeBatch.set(ref, {
        userId: userId,
        type: "general",
        title: title,
        body: body,
        data: {
          promoCode: promoCode,
          screen: "promo_code",
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await writeBatch.commit();
    totalNotificationsStored += userBatch.length;
    console.log(`   Firestore Batch ${i + 1}/${userChunks.length}: Stored ${userBatch.length} notification documents.`);
  }

  console.log("\n=======================================================");
  console.log("🎉 BROADCAST COMPLETE!");
  console.log("=======================================================");
  console.log(`👥 Customers Targeted    : ${customersToNotifyInApp.length}`);
  console.log(`📩 Push Messages Delivered: ${totalPushSent}`);
  console.log(`⚠️ Push Messages Failed   : ${totalPushFailed}`);
  console.log(`💾 In-App Records Stored : ${totalNotificationsStored}`);
  console.log("=======================================================\n");

  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Fatal Error executing broadcast script:", err);
  process.exit(1);
});
