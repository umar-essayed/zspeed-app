import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

export const onRideStatusChanged = onDocumentUpdated(
  { document: "rides/{rideId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const oldStatus = before.status;
    const newStatus = after.status;

    if (oldStatus === newStatus) return;

    const rideId = event.params.rideId;
    const customerId = after.customerId;
    const driverName = after.driverName ?? "Driver";

    let title = "";
    let body = "";

    if (newStatus === "accepted") {
      title = "Ride Request Accepted!";
      body = `${driverName} has accepted your ride request and is heading your way.`;
    } else if (newStatus === "arrived") {
      title = "Driver Arrived!";
      body = `${driverName} has arrived at your pickup location.`;
    } else if (newStatus === "started") {
      title = "Ride Started!";
      body = `Your trip with ${driverName} is in progress. Have a safe ride!`;
    } else if (newStatus === "completed") {
      title = "Ride Completed!";
      body = "Thank you for riding with Z-SPEED. Your trip has finished successfully.";
    } else if (newStatus === "cancelled") {
      title = "Ride Cancelled";
      body = `Your ride request was cancelled. Reason: ${after.cancellationReason ?? "None"}`;
    } else {
      return; // No notification for other statuses
    }

    const data = { rideId, screen: "active_ride" };

    await sendPushToUser(customerId, title, body, data);
    await storeNotification({
      userId: customerId,
      type: `ride_${newStatus}`,
      title,
      body,
      data,
    });
  }
);
