import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { sendPushToUsers } from "../notifications/send";
import { storeNotificationForUsers } from "../notifications/store";

export const onNewApplication = onDocumentCreated(
  "applications/{appId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const app = snapshot.data();
    const applicationType = app.applicationType as string ?? "unknown";
    const applicantName = app.fullName as string ?? "Someone";
    // For vendor applications, use the specific vendorType (restaurant/supermarket/pharmacy)
    // rather than the generic applicationType ("restaurant" for all vendors).
    const vendorType: string = (applicationType === "vendor" || applicationType === "restaurant") ?
      ((app.formData?.vendorType as string) ?? "restaurant") :
      applicationType;

    // Find all admin users
    const adminsSnap = await admin.firestore()
      .collection("users")
      .where("type", "==", "admin")
      .get();

    const adminIds = adminsSnap.docs.map((doc) => doc.id);
    if (adminIds.length === 0) return;

    const title = "New Application";
    const body = `${applicantName} applied as ${vendorType}`;
    const data = { applicationId: event.params.appId, screen: "admin_applications" };

    await sendPushToUsers(adminIds, title, body, data);
    await storeNotificationForUsers(adminIds, "new_application", title, body, data);
  },
);
