const admin = require("firebase-admin");
const path = require("path");

// Load service account key
const serviceAccount = require(path.join(__dirname, "../service-account.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Recursive document deletion helper
async function deleteDocAndSubcollections(docRef) {
  // List all subcollections recursively
  const collections = await docRef.listCollections();
  for (const col of collections) {
    const docsSnapshot = await col.get();
    for (const doc of docsSnapshot.docs) {
      await deleteDocAndSubcollections(col.doc(doc.id));
    }
  }
  
  // Delete the document itself
  await docRef.delete();
  console.log(`Deleted document: ${docRef.path}`);
}

async function runCleanup() {
  const docRefs = await db.collection("restaurants").listDocuments();
  console.log(`Found ${docRefs.length} restaurant document references to clean up.`);
  
  for (const docRef of docRefs) {
    await deleteDocAndSubcollections(docRef);
  }



  console.log("\nCleanup completed successfully!");
  process.exit(0);
}

runCleanup().catch((err) => {
  console.error("Cleanup failed:", err);
  process.exit(1);
});
