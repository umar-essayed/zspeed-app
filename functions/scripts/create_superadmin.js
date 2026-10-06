/**
 * One-time script to create a super admin user in Firebase Auth + Firestore.
 * Uses REST APIs - no service account needed.
 *
 * Usage:  node scripts/create_superadmin.js
 * Run from:  d:\Flutter Projects\Z_Speed_app\functions
 */

const https = require("https");

const API_KEY = "AIzaSyDAbVV19Xn03TcxPTB0PIYU9JYlKvWT2bg";
const PROJECT_ID = "zspeed";
const ADMIN_EMAIL = "superadmin@gmail.com";
const ADMIN_PASSWORD = "Test1234@";
const ADMIN_NAME = "Super Admin";

function request(url, options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function main() {
  // Step 1: Create or sign in Firebase Auth user
  console.log(`\nCreating auth user: ${ADMIN_EMAIL} ...`);
  const signUpUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
  const signUpResp = await request(
    signUpUrl,
    { method: "POST", headers: { "Content-Type": "application/json" } },
    { email: ADMIN_EMAIL, password: ADMIN_PASSWORD, returnSecureToken: true }
  );

  let uid, idToken;
  if (signUpResp.status === 200) {
    uid = signUpResp.data.localId;
    idToken = signUpResp.data.idToken;
    console.log(`✔ Auth user created: ${uid}`);
  } else if (
    signUpResp.data?.error?.message === "EMAIL_EXISTS"
  ) {
    console.log("⚠ Email already exists. Signing in to get UID...");
    const signInUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const signInResp = await request(
      signInUrl,
      { method: "POST", headers: { "Content-Type": "application/json" } },
      { email: ADMIN_EMAIL, password: ADMIN_PASSWORD, returnSecureToken: true }
    );
    if (signInResp.status === 200) {
      uid = signInResp.data.localId;
      idToken = signInResp.data.idToken;
      console.log(`  Found existing user: ${uid}`);
    } else {
      console.error("Error signing in:", JSON.stringify(signInResp.data));
      process.exit(1);
    }
  } else {
    console.error("Error creating user:", JSON.stringify(signUpResp.data));
    process.exit(1);
  }

  // Step 2: Update display name
  console.log("Setting display name...");
  const updateUrl = `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${API_KEY}`;
  await request(
    updateUrl,
    { method: "POST", headers: { "Content-Type": "application/json" } },
    { idToken, displayName: ADMIN_NAME }
  );
  console.log("✔ Display name set");

  // Step 3: Write Firestore document via REST (uses idToken - no admin SDK needed)
  console.log("Creating Firestore user document...");
  const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
  const now = new Date().toISOString();

  const firestoreDoc = {
    fields: {
      id: { stringValue: uid },
      name: { stringValue: ADMIN_NAME },
      email: { stringValue: ADMIN_EMAIL },
      type: { stringValue: "superAdmin" },
      status: { stringValue: "active" },
      walletBalance: { doubleValue: 0.0 },
      loyaltyPoints: { integerValue: "0" },
      fcmTokens: { arrayValue: { values: [] } },
      notificationPreferences: {
        mapValue: {
          fields: {
            orderUpdates: { booleanValue: true },
            newOrders: { booleanValue: true },
            deliveryRequests: { booleanValue: true },
            promotional: { booleanValue: true },
            applicationUpdates: { booleanValue: true },
          },
        },
      },
      createdAt: { timestampValue: now },
      updatedAt: { timestampValue: now },
    },
  };

  const firestoreResp = await request(
    firestoreUrl,
    {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
    },
    firestoreDoc
  );

  if (firestoreResp.status === 200) {
    console.log(`✔ Firestore document created: users/${uid}`);
  } else {
    console.error(
      "Error creating Firestore doc:",
      JSON.stringify(firestoreResp.data)
    );
    console.log("\n⚠ Auth user was created but Firestore write failed.");
    console.log(
      "  You may need to adjust Firestore security rules to allow admin writes,"
    );
    console.log("  or create the document manually in Firebase Console.");
    console.log(`\n  UID: ${uid}`);
    process.exit(1);
  }

  console.log("\n═══════════════════════════════════════════");
  console.log("   Super Admin account created successfully!");
  console.log("═══════════════════════════════════════════");
  console.log(`   Email:    ${ADMIN_EMAIL}`);
  console.log(`   Password: ${ADMIN_PASSWORD}`);
  console.log(`   UID:      ${uid}`);
  console.log(`   Role:     admin`);
  console.log("═══════════════════════════════════════════\n");
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
