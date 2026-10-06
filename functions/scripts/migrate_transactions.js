const admin = require("firebase-admin");
const path = require("path");

// Load service account key
const serviceAccount = require(path.join(__dirname, "../service-account.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function runSupplementaryMigration() {
  console.log("Starting supplementary Firestore migrations...");

  // 1. Migrate restaurantWalletTransactions -> vendorWalletTransactions
  console.log("\n--- Phase 1: Migrating restaurantWalletTransactions to vendorWalletTransactions ---");
  const txsSnap = await db.collection("restaurantWalletTransactions").get();
  console.log(`Found ${txsSnap.docs.length} transaction documents.`);
  let copiedCount = 0;
  for (const doc of txsSnap.docs) {
    const data = doc.data();
    const newData = { ...data };
    if ("restaurantId" in newData) {
      newData.vendorId = newData.restaurantId;
      delete newData.restaurantId;
    }
    await db.collection("vendorWalletTransactions").doc(doc.id).set(newData);
    copiedCount++;
  }
  console.log(`Successfully migrated ${copiedCount} transaction documents.`);

  // 2. Update applications collection (applicationType: restaurant -> vendor)
  console.log("\n--- Phase 2: Updating applications collection ---");
  const appsSnap = await db.collection("applications").get();
  let updatedAppsCount = 0;
  for (const doc of appsSnap.docs) {
    const data = doc.data();
    if (data.applicationType === "restaurant") {
      await db.collection("applications").doc(doc.id).update({
        applicationType: "vendor"
      });
      console.log(`Updated application ${doc.id} applicationType -> vendor`);
      updatedAppsCount++;
    }
  }
  console.log(`Updated ${updatedAppsCount} applications.`);

  // 3. Update promoCodes: rename restaurantId -> vendorId, applicableRestaurants -> applicableVendors
  console.log("\n--- Phase 3: Updating promoCodes collection ---");
  const promosSnap = await db.collection("promoCodes").get();
  let updatedPromosCount = 0;
  for (const doc of promosSnap.docs) {
    const data = doc.data();
    const updates = {};
    let needsUpdate = false;

    if ("restaurantId" in data) {
      updates.vendorId = data.restaurantId;
      updates.restaurantId = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }
    if ("applicableRestaurants" in data) {
      updates.applicableVendors = data.applicableRestaurants;
      updates.applicableRestaurants = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }

    if (needsUpdate) {
      await db.collection("promoCodes").doc(doc.id).update(updates);
      console.log(`Updated promo code ${doc.id}`);
      updatedPromosCount++;
    }
  }
  console.log(`Updated ${updatedPromosCount} promo codes.`);

  // 4. Update deliveryRequests: rename restaurantId -> vendorId, restaurantName -> vendorName, restaurantLat -> vendorLat, restaurantLng -> vendorLng
  console.log("\n--- Phase 4: Updating deliveryRequests collection ---");
  const delSnap = await db.collection("deliveryRequests").get();
  let updatedDelCount = 0;
  for (const doc of delSnap.docs) {
    const data = doc.data();
    const updates = {};
    let needsUpdate = false;

    if ("restaurantId" in data) {
      updates.vendorId = data.restaurantId;
      updates.restaurantId = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }
    if ("restaurantName" in data) {
      updates.vendorName = data.restaurantName;
      updates.restaurantName = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }
    if ("restaurantLat" in data) {
      updates.vendorLat = data.restaurantLat;
      updates.restaurantLat = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }
    if ("restaurantLng" in data) {
      updates.vendorLng = data.restaurantLng;
      updates.restaurantLng = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }

    if (needsUpdate) {
      await db.collection("deliveryRequests").doc(doc.id).update(updates);
      console.log(`Updated delivery request ${doc.id}`);
      updatedDelCount++;
    }
  }
  console.log(`Updated ${updatedDelCount} delivery requests.`);

  // 5. Update chats: rename restaurantId -> vendorId
  console.log("\n--- Phase 5: Updating chats collection ---");
  const chatsSnap = await db.collection("chats").get();
  let updatedChatsCount = 0;
  for (const doc of chatsSnap.docs) {
    const data = doc.data();
    if ("restaurantId" in data) {
      await db.collection("chats").doc(doc.id).update({
        vendorId: data.restaurantId,
        restaurantId: admin.firestore.FieldValue.delete()
      });
      console.log(`Updated chat ${doc.id}: restaurantId -> vendorId`);
      updatedChatsCount++;
    }
  }
  console.log(`Updated ${updatedChatsCount} chats.`);

  // 6. Update prescription_requests: rename restaurantId -> vendorId
  console.log("\n--- Phase 6: Updating prescription_requests collection ---");
  const prescSnap = await db.collection("prescription_requests").get();
  let updatedPrescCount = 0;
  for (const doc of prescSnap.docs) {
    const data = doc.data();
    if ("restaurantId" in data) {
      await db.collection("prescription_requests").doc(doc.id).update({
        vendorId: data.restaurantId,
        restaurantId: admin.firestore.FieldValue.delete()
      });
      console.log(`Updated prescription request ${doc.id}: restaurantId -> vendorId`);
      updatedPrescCount++;
    }
  }
  console.log(`Updated ${updatedPrescCount} prescription requests.`);

  console.log("\nSupplementary migrations completed successfully!");
  process.exit(0);
}

runSupplementaryMigration().catch((err) => {
  console.error("Supplementary migration failed:", err);
  process.exit(1);
});
