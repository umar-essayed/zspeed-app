const admin = require("firebase-admin");
const path = require("path");

const serviceAccount = require(path.join(__dirname, "../service-account.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "zspeed.firebasestorage.app"
});

const bucket = admin.storage().bucket();

async function setCors() {
  console.log("Setting CORS configuration on bucket: zspeed.firebasestorage.app...");
  await bucket.setCorsConfiguration([
    {
      maxAgeSeconds: 3600,
      method: ["GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS"],
      origin: ["*"],
      responseHeader: ["*"],
    }
  ]);
  console.log("CORS configuration applied successfully!");
}

setCors().catch(console.error);
