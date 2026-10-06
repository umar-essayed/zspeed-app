import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

export const onTransportCreated = onDocumentCreated(
  "transports/{transportId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const driverId = data.driverId as string | undefined;
    if (!driverId) {
      logger.warn(`[onTransportCreated] No driverId for transport ${event.params.transportId}`);
      return;
    }

    const customerName = data.customerName ?? "A passenger";
    const vehicleType = data.vehicleType ?? "sedan";

    const title = "New Ride Request 🚖";
    const body = `${customerName} requested a ride (${vehicleType.toUpperCase()})`;
    const notificationData = {
      transportId: event.params.transportId,
      screen: "ride_request",
      type: "ride_request",
    };

    await sendPushToUser(driverId, title, body, notificationData);
    await storeNotification({
      userId: driverId,
      type: "ride_request",
      title,
      body,
      data: notificationData,
    });

    logger.info(`[onTransportCreated] Push and stored notification sent to driver ${driverId} for transport ${event.params.transportId}`);
  }
);
