import { dispatchNextDriver } from "../services/dispatchService";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

export const onDeliveryRequestExpired = onDocumentUpdated("deliveryRequests/{requestId}", async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();

  // We only care if the status transitioned from 'pending' to 'expired'
  if (beforeData?.status === "pending" && afterData?.status === "expired") {
    console.log(`[onDeliveryRequestExpired] Delivery request ${event.params.requestId} expired. Rebouncing order ${afterData.orderId}`);
    try {
      await dispatchNextDriver(afterData.orderId);
    } catch (error) {
      console.error("[onDeliveryRequestExpired] Error rebounding the delivery request:", error);
    }
  }
});
