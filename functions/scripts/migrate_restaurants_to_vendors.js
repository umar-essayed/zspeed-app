const admin = require("firebase-admin");
const path = require("path");

// Load service account key
const serviceAccount = require(path.join(__dirname, "../service-account.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Recursive document copying helper
async function copyDocAndSubcollections(srcRef, destRef, dataTransformer = (data) => data) {
  const snapshot = await srcRef.get();
  if (!snapshot.exists) return;

  // Transform document data if a transformer is provided
  const transformedData = dataTransformer(snapshot.data());
  
  await destRef.set(transformedData);
  console.log(`Copied doc: ${srcRef.path} -> ${destRef.path}`);

  // List all subcollections recursively
  const collections = await srcRef.listCollections();
  for (const col of collections) {
    const destColRef = destRef.collection(col.id);
    const docsSnapshot = await col.get();
    for (const doc of docsSnapshot.docs) {
      const srcDocRef = col.doc(doc.id);
      const destDocRef = destColRef.doc(doc.id);
      await copyDocAndSubcollections(srcDocRef, destDocRef, dataTransformer);
    }
  }
}

// Transform fields containing "restaurantId" to "vendorId"
function transformFieldNames(data) {
  if (!data) return data;
  const result = { ...data };
  
  // If restaurantId is present, map it to vendorId and delete restaurantId
  if ("restaurantId" in result) {
    result.vendorId = result.restaurantId;
    delete result.restaurantId;
  }
  
  // If type is "restaurant", map it to "vendor"
  if (result.type === "restaurant") {
    result.type = "vendor";
  }

  // If role is "restaurant", map to "vendor"
  if (result.role === "restaurant") {
    result.role = "vendor";
  }

  return result;
}

async function runMigration() {
  console.log("Starting Firestore migration: restaurant -> vendor...");

  // 1. Copy restaurants -> vendors
  console.log("\n--- Phase 1: Copying restaurants to vendors (including subcollections) ---");
  const restaurantsSnap = await db.collection("restaurants").get();
  console.log(`Found ${restaurantsSnap.docs.length} restaurant documents.`);
  for (const doc of restaurantsSnap.docs) {
    const srcRef = db.collection("restaurants").doc(doc.id);
    const destRef = db.collection("vendors").doc(doc.id);
    await copyDocAndSubcollections(srcRef, destRef, transformFieldNames);
  }

  // 2. Update users type: "restaurant" -> "vendor"
  console.log("\n--- Phase 2: Updating users collection ---");
  const usersSnap = await db.collection("users").get();
  let updatedUsersCount = 0;
  for (const doc of usersSnap.docs) {
    const userData = doc.data();
    let needsUpdate = false;
    const updates = {};

    if (userData.type === "restaurant") {
      updates.type = "vendor";
      needsUpdate = true;
    }
    if (userData.role === "restaurant" || (userData.type === "restaurant" && userData.role === "customer")) {
      // Also fix role mapping if applicable
      updates.role = "vendor";
      needsUpdate = true;
    }

    if (needsUpdate) {
      await db.collection("users").doc(doc.id).update(updates);
      console.log(`Updated user ${doc.id} (${userData.email}): type=${updates.type || userData.type}, role=${updates.role || userData.role}`);
      updatedUsersCount++;
    }
  }
  console.log(`Updated ${updatedUsersCount} user documents.`);

  // 3. Update orders: rename restaurantId -> vendorId
  console.log("\n--- Phase 3: Updating orders collection ---");
  const ordersSnap = await db.collection("orders").get();
  let updatedOrdersCount = 0;
  for (const doc of ordersSnap.docs) {
    const orderData = doc.data();
    if ("restaurantId" in orderData) {
      await db.collection("orders").doc(doc.id).update({
        vendorId: orderData.restaurantId,
        restaurantId: admin.firestore.FieldValue.delete()
      });
      console.log(`Updated order ${doc.id}: restaurantId -> vendorId (${orderData.restaurantId})`);
      updatedOrdersCount++;
    }
  }
  console.log(`Updated ${updatedOrdersCount} order documents.`);

  // 4. Update carts items: rename restaurantId -> vendorId
  console.log("\n--- Phase 4: Updating carts collection ---");
  const cartsSnap = await db.collection("carts").get();
  let updatedCartsCount = 0;
  for (const doc of cartsSnap.docs) {
    // Each cart can have subcollection "items"
    const itemsSnap = await db.collection("carts").doc(doc.id).collection("items").get();
    for (const itemDoc of itemsSnap.docs) {
      const itemData = itemDoc.data();
      if ("restaurantId" in itemData) {
        await db.collection("carts").doc(doc.id).collection("items").doc(itemDoc.id).update({
          vendorId: itemData.restaurantId,
          restaurantId: admin.firestore.FieldValue.delete()
        });
        console.log(`Updated cart item ${itemDoc.id} in cart ${doc.id}: restaurantId -> vendorId`);
        updatedCartsCount++;
      }
    }
  }
  console.log(`Updated ${updatedCartsCount} cart items.`);

  console.log("\nMigration completed successfully!");
  process.exit(0);
}

runMigration().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
