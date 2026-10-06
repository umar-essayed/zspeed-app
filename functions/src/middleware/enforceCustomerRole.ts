import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

interface AuthInfo {
  uid: string;
  token: {
    role?: string;
    [key: string]: unknown;
  };
}

export async function assertCustomerOwnsOrder(
  auth: AuthInfo | null,
  orderId: string,
  db: admin.firestore.Firestore
): Promise<admin.firestore.DocumentData> {
  if (!auth) {
    throw new HttpsError("unauthenticated", "User is not authenticated");
  }

  const role = auth.token?.role;
  if (role && role.toLowerCase() !== "customer") {
    throw new HttpsError(
      "permission-denied",
      "Only customers can perform this action"
    );
  }
  const userDoc = await db.collection("users").doc(auth.uid).get();
  if (userDoc.exists) {
    const userType = userDoc.data()?.type;
    if (userType && userType.toLowerCase() !== "customer") {
      throw new HttpsError(
        "permission-denied",
        "Only customers can perform this action"
      );
    }
  }

  const orderDoc = await db.collection("orders").doc(orderId).get();

  if (!orderDoc.exists) {
    throw new HttpsError("not-found", "Order not found");
  }

  const orderData = orderDoc.data()!;
  if (orderData.customerId !== auth.uid) {
    throw new HttpsError(
      "permission-denied",
      "You do not have permission to access this order"
    );
  }

  return orderData;
}
