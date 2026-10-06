import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

export const onDriverAssigned = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const oldDriverId = before.driverId as string | undefined;
    const newDriverId = after.driverId as string | undefined;

    // Only trigger when driverId is newly assigned (was null/empty → now set)
    if (!newDriverId || oldDriverId === newDriverId) return;

    // Suppress duplicate notification if status was set to driverAssigned by onDeliveryRequestStatusUpdated
    if (after.status === "driverAssigned") return;

    const orderId = event.params.orderId;
    const customerId = after.userId as string;

    // Look up driver name
    const driverDoc = await admin.firestore()
      .collection("driverProfiles").doc(newDriverId).get();
    const driverName = driverDoc.data()?.name as string ?? "A driver";

    const title = "Driver Assigned";
    const body = `${driverName} is assigned to your order #${orderId.substring(0, 8)}`;
    const data = { orderId, screen: "order_tracking" };

    await sendPushToUser(customerId, title, body, data);
    await storeNotification({
      userId: customerId,
      type: "driver_assigned",
      title,
      body,
      data,
    });
  },
);
