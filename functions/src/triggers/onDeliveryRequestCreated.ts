import { onDocumentCreated } from "firebase-functions/v2/firestore";

import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

export const onDeliveryRequestCreated = onDocumentCreated(
  "deliveryRequests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const driverId = data.driverId as string;
    const orderId = data.orderId as string;
    // We get the vendor name if any
    const vendorName = data.vendorName ?? data.restaurantName ?? "a vendor";

    const title = "New Delivery Request";
    const body = `You have a new request for order #${orderId.substring(0, 8)} from ${vendorName}`;
    const notificationData = { requestId: event.params.requestId, orderId, screen: "delivery_request" };

    await sendPushToUser(driverId, title, body, notificationData);
    await storeNotification({
      userId: driverId,
      type: "new_delivery_request",
      title,
      body,
      data: notificationData,
    });
  }
);
