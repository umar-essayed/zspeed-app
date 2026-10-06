import * as admin from "firebase-admin";
import * as crypto from "crypto";

interface CartItem {
  itemId: string;
  quantity: number;
  unitPrice: number;
  currency?: string;
}

interface CartValidationResult {
  ok: true;
  cartSnapshotHash: string;
}

interface CartDiffItem {
  itemId: string;
  reason: string;
  oldValue: string;
  newValue: string;
}

interface CartValidationFailure {
  ok: false;
  diff: CartDiffItem[];
}

export async function revalidateCartForPayment(
  orderId: string,
  db: admin.firestore.Firestore
): Promise<CartValidationResult | CartValidationFailure> {
  const orderDoc = await db.collection("orders").doc(orderId).get();
  if (!orderDoc.exists) {
    return {
      ok: false,
      diff: [{ itemId: orderId, reason: "order_not_found", oldValue: "", newValue: "" }],
    };
  }

  const orderData = orderDoc.data()!;
  const cartItems = orderData.items as CartItem[] || [];
  const diff: CartDiffItem[] = [];

  for (const item of cartItems) {
    const itemDoc = await db
      .collection("vendors")
      .doc(orderData.vendorId || orderData.restaurantId)
      .collection("items")
      .doc(item.itemId)
      .get();

    if (!itemDoc.exists) {
      diff.push({
        itemId: item.itemId,
        reason: "item_no_longer_available",
        oldValue: String(item.unitPrice),
        newValue: "unavailable",
      });
      continue;
    }

    const currentItemData = itemDoc.data()!;
    const currentPrice = currentItemData.price;

    if (currentPrice !== item.unitPrice) {
      diff.push({
        itemId: item.itemId,
        reason: "price_changed",
        oldValue: String(item.unitPrice),
        newValue: String(currentPrice),
      });
    }

    const isAvailable = currentItemData.isAvailable !== false;
    if (!isAvailable) {
      diff.push({
        itemId: item.itemId,
        reason: "item_unavailable",
        oldValue: String(item.quantity),
        newValue: "0",
      });
    }
  }

  if (diff.length > 0) {
    return { ok: false, diff };
  }

  const normalized = cartItems
    .map((item) => `${item.itemId}:${item.quantity}:${item.unitPrice}`)
    .sort()
    .join("|");

  const cartSnapshotHash = crypto.createHash("sha256").update(normalized).digest("hex");

  return { ok: true, cartSnapshotHash };
}
