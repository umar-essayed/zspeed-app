import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";
import { assertUserNotBlocked } from "../middleware/assertUserNotBlocked";

export const onRideCreated = onDocumentCreated(
  { document: "rides/{rideId}", region: "us-central1" },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const ride = snapshot.data();
    const rideId = event.params.rideId;
    const customerId = ride.customerId ?? ride.userId;
    const customerName = ride.customerName ?? "A customer";
    const vehicleType = ride.vehicleType ?? "SEDAN";

    const db = admin.firestore();

    // Check if customer is blocked
    if (customerId) {
      try {
        await assertUserNotBlocked(customerId, db);
      } catch (err) {
        console.warn(`[onRideCreated] Auto-cancelling ride ${rideId} because customer ${customerId} is blocked`);
        await db.collection("rides").doc(rideId).update({
          status: "cancelled",
          cancellationReason: "Account suspended or blacklisted",
          cancelledBy: "system",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }
    }

    // Query active driver profiles to notify them of a new ride request
    const driversSnapshot = await admin.firestore()
      .collection("driverProfiles")
      .where("status", "==", "online")
      .get();

    if (driversSnapshot.empty) return;

    const title = "New Ride Request! 🚗";
    const body = `${customerName} requested a ${vehicleType} ride near you.`;
    const data = { rideId, screen: "driver_ride_request" };

    const promises: Promise<any>[] = [];
    for (const doc of driversSnapshot.docs) {
      const driverId = doc.id;
      const driverVehicleType = (doc.data().vehicleType ?? "").toLowerCase();
      let matches = false;
      if (vehicleType.toLowerCase() === "sedan" && (driverVehicleType === "car" || driverVehicleType === "sedan")) {
        matches = true;
      } else if (vehicleType.toLowerCase() === "moto" && (driverVehicleType === "motorcycle" || driverVehicleType === "moto" || driverVehicleType === "cycle")) {
        matches = true;
      } else if (vehicleType.toLowerCase() === "luxury" && (driverVehicleType === "car" || driverVehicleType === "luxury" || driverVehicleType === "premium")) {
        matches = true;
      }

      if (matches) {
        promises.push(sendPushToUser(driverId, title, body, data));
        promises.push(storeNotification({
          userId: driverId,
          type: "ride_requested",
          title,
          body,
          data,
        }));
      }
    }

    await Promise.all(promises);
  }
);
