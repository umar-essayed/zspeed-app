import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Validates that a user is not banned, suspended, or listed in the blacklists collection.
 * Throws an HttpsError("permission-denied") if the user is blocked.
 * 
 * @param uid The Firebase Auth UID of the user.
 * @param db The Firestore database instance.
 * @returns The user's Firestore document data if found, or null.
 */
export async function assertUserNotBlocked(
  uid: string,
  db: admin.firestore.Firestore
): Promise<admin.firestore.DocumentData | null> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  // 1. Check user document status
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.exists ? userDoc.data() : null;

  if (userData) {
    const status = (userData.status || "").toString().toLowerCase();
    if (status === "banned" || status === "suspended") {
      console.warn(`[Blocked Access Rejected] uid=${uid} has status=${status}`);
      throw new HttpsError(
        "permission-denied",
        "Your account has been suspended or banned. Please contact support."
      );
    }
  }

  // 2. Direct UID Blacklist Document Check
  const uidBlacklistRef = db.collection("blacklists").doc(`uid_${uid}`);
  const uidBlacklistSnap = await uidBlacklistRef.get();
  if (uidBlacklistSnap.exists) {
    console.warn(`[Blacklist Rejected] uid=${uid} found in blacklists collection`);
    throw new HttpsError(
      "permission-denied",
      "Your account has been blocked from placing orders."
    );
  }

  // 3. Phone / Email Blacklist Checks if available on user record
  if (userData) {
    const phone = (userData.phone || userData.phoneNumber || "").toString().trim();
    if (phone) {
      // Check raw phone
      const phoneRawId = `phone_${phone.replace(/[^a-zA-Z0-9_]/g, "_")}`;
      const phoneRawSnap = await db.collection("blacklists").doc(phoneRawId).get();
      if (phoneRawSnap.exists) {
        console.warn(`[Blacklist Rejected] phone=${phone} found in blacklists`);
        throw new HttpsError(
          "permission-denied",
          "Your phone number has been blocked."
        );
      }

      // Check normalized Egyptian phone
      let normalizedPhone = phone.replace(/\s+/g, "").replace(/-/g, "");
      if (normalizedPhone.startsWith("0020")) {
        normalizedPhone = "+20" + normalizedPhone.substring(4);
      } else if (normalizedPhone.startsWith("20") && !normalizedPhone.startsWith("+20")) {
        normalizedPhone = "+20" + normalizedPhone.substring(2);
      } else if (normalizedPhone.startsWith("01")) {
        normalizedPhone = "+20" + normalizedPhone.substring(1);
      }
      const phoneNormId = `phone_${normalizedPhone.replace(/[^a-zA-Z0-9_]/g, "_")}`;
      const phoneNormSnap = await db.collection("blacklists").doc(phoneNormId).get();
      if (phoneNormSnap.exists) {
        console.warn(`[Blacklist Rejected] normalized phone=${normalizedPhone} found in blacklists`);
        throw new HttpsError(
          "permission-denied",
          "Your phone number has been blocked."
        );
      }
    }

    const email = (userData.email || "").toString().trim().toLowerCase();
    if (email) {
      const emailDocId = `email_${email.replace(/[^a-zA-Z0-9_]/g, "_")}`;
      const emailBlacklistSnap = await db.collection("blacklists").doc(emailDocId).get();
      if (emailBlacklistSnap.exists) {
        console.warn(`[Blacklist Rejected] email=${email} found in blacklists`);
        throw new HttpsError(
          "permission-denied",
          "Your email address has been blocked."
        );
      }
    }
  }

  return userData ?? null;
}
