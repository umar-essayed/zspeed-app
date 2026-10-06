import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { PaylinkService } from "../services/paylink/paylinkService";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";

export const paylinkSaveCard = onCall(
  { timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const db = admin.firestore();
    await assertUserNotBlocked(uid, db);

    const {
      firstName,
      lastName,
      cardNumber,
      cardExpiryMonth,
      cardExpiryYear,
      cardCvv,
      setAsDefault,
    } = request.data || {};

    if (!firstName || !lastName || !cardNumber || !cardExpiryMonth || !cardExpiryYear) {
      throw new HttpsError("invalid-argument", "Missing required card details.");
    }

    // Tokenize card securely server-side
    const tokenResult = await PaylinkService.tokenizeCard({
      userId: uid,
      firstName: String(firstName).trim(),
      lastName: String(lastName).trim(),
      cardNumber: String(cardNumber).replace(/\s+/g, ""),
      cardExpiryMonth: String(cardExpiryMonth).padStart(2, "0"),
      cardExpiryYear: String(cardExpiryYear),
      cardCvv: cardCvv ? String(cardCvv) : undefined,
    });

    const savedCardsRef = db.collection("users").doc(uid).collection("savedCards");

    // If setting as default, clear previous defaults
    if (setAsDefault) {
      const existingCards = await savedCardsRef.where("isDefault", "==", true).get();
      const batch = db.batch();
      existingCards.docs.forEach((doc) => {
        batch.update(doc.ref, { isDefault: false });
      });
      await batch.commit();
    }

    // Create new card document (NO PAN, NO CVV stored!)
    const cardDocRef = savedCardsRef.doc();
    await cardDocRef.set({
      id: cardDocRef.id,
      cardToken: tokenResult.token,
      brand: tokenResult.brand,
      last4: tokenResult.last4,
      expMonth: tokenResult.expMonth,
      expYear: tokenResult.expYear,
      holderName: `${firstName} ${lastName}`.trim(),
      isDefault: Boolean(setAsDefault),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      cardId: cardDocRef.id,
      brand: tokenResult.brand,
      last4: tokenResult.last4,
      expMonth: tokenResult.expMonth,
      expYear: tokenResult.expYear,
    };
  }
);

export const paylinkDeleteCard = onCall(
  { timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const { cardId } = request.data || {};
    if (!cardId) {
      throw new HttpsError("invalid-argument", "cardId is required.");
    }

    const db = admin.firestore();
    const cardRef = db.collection("users").doc(uid).collection("savedCards").doc(cardId);
    const cardDoc = await cardRef.get();

    if (!cardDoc.exists) {
      throw new HttpsError("not-found", "Card not found.");
    }

    const cardData = cardDoc.data()!;
    if (cardData.cardToken) {
      await PaylinkService.revokeToken(cardData.cardToken, uid);
    }

    await cardRef.delete();

    return {
      success: true,
    };
  }
);
