import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

/**
 * Fires when a menu item is updated.
 * Notifies the market/pharmacy owner when stock drops below warningLimit.
 */
export const onMenuItemUpdated = onDocumentUpdated(
  "vendors/{vendorId}/menuSections/{sectionId}/items/{itemId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const stockAfter: number | null = after.stock ?? null;
    const warningLimit: number | null = after.warningLimit ?? null;

    // Only act when stock is defined, warningLimit is set, and stock < warningLimit
    if (stockAfter === null || warningLimit === null) return;
    if (stockAfter >= warningLimit) return;

    // Only notify when stock just crossed the threshold (not on every update below it)
    const stockBefore: number | null = before.stock ?? null;
    if (stockBefore !== null && stockBefore < warningLimit) return;

    const vendorId = event.params.vendorId;
    const itemName: string = after.name ?? "Unknown item";

    // Look up the vendor owner
    const vendorDoc = await getFirestore()
      .collection("vendors")
      .doc(vendorId)
      .get();

    if (!vendorDoc.exists) {
      logger.error(`Vendor ${vendorId} not found for low-stock alert`);
      return;
    }

    const ownerId: string | undefined = vendorDoc.data()?.ownerId;
    if (!ownerId) {
      logger.error(`Vendor ${vendorId} has no ownerId`);
      return;
    }

    const title = "⚠️ Low Stock Alert";
    const body = `"${itemName}" is running low — only ${stockAfter} left (limit: ${warningLimit})`;
    const data = { vendorId, screen: "vendor_menu" };

    await sendPushToUser(ownerId, title, body, data);

    await storeNotification({
      userId: ownerId,
      type: "low_stock",
      title,
      body,
      data,
    });

    logger.info(`Low-stock alert sent to ${ownerId} for item "${itemName}" (stock: ${stockAfter})`);
  }
);
