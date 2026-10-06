import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { sendPushToUser } from "../notifications/send";
import { storeNotification } from "../notifications/store";

/**
 * Triggered when an application document is updated.
 * Sends push notification + email on status change.
 */
export const onApplicationStatusChanged = onDocumentUpdated(
  "applications/{appId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const oldStatus = before.status as string;
    const newStatus = after.status as string;

    // Only react to status changes
    if (oldStatus === newStatus) return;

    const userId = after.userId as string;
    if (!userId) return;

    const applicationType =
      (after.applicationType as string) ?? "unknown";
    const formData =
      (after.formData as Record<string, unknown>) ?? {};
    const businessInfo =
      (formData.businessInfo as Record<string, string>) ?? {};
    const personalInfo =
      (formData.personalInfo as Record<string, string>) ?? {};
    const contactInfo =
      (formData.contactInfo as Record<string, string>) ?? {};

    const applicantName =
      (applicationType === "vendor" || applicationType === "restaurant") ?
        (businessInfo.restaurantName ?? "Vendor") :
        (personalInfo.name ?? "Applicant");

    if (newStatus === "approved") {
      const title = "Application Approved!";
      const body =
        `Congratulations ${applicantName}! ` +
        `Your ${applicationType} application has been ` +
        "approved. You can now start using Z Speed.";
      const data = {
        applicationId: event.params.appId,
        screen: "application_status",
      };

      await storeNotification({
        userId, type: "application_approved",
        title, body, data,
      });

      await sendPushToUser(userId, title, body, data);

      const email =
        (applicationType === "vendor" || applicationType === "restaurant") ?
          (contactInfo.ownerEmail ?? "") :
          (personalInfo.email ?? "");

      if (email) {
        await sendApprovalEmail(
          userId, email, applicantName, applicationType,
        );
      }
    } else if (newStatus === "rejected") {
      const rejectionReason =
        (after.rejectionReason as string) ??
          "No reason provided";
      const title = "Application Update";
      const body =
        `Your ${applicationType} application needs ` +
        `attention. Reason: ${rejectionReason}`;
      const data = {
        applicationId: event.params.appId,
        screen: "application_status",
      };

      await storeNotification({
        userId, type: "application_rejected",
        title, body, data,
      });

      await sendPushToUser(userId, title, body, data);

      const email =
        (applicationType === "vendor" || applicationType === "restaurant") ?
          (contactInfo.ownerEmail ?? "") :
          (personalInfo.email ?? "");

      if (email) {
        await sendRejectionEmail(
          userId, email, applicantName,
          applicationType, rejectionReason,
        );
      }
    }
  },
);

// Queue an approval email via Firestore "mail" collection.
async function sendApprovalEmail(
  userId: string,
  email: string,
  name: string,
  type: string,
): Promise<void> {
  try {
    const html = [
      "<div style=\"font-family: Arial, sans-serif;",
      " max-width: 600px; margin: 0 auto;\">",
      "<h2 style=\"color: #2E7D32;\">",
      `Congratulations, ${name}!</h2>`,
      `<p>Your <strong>${type}</strong> application`,
      " on Z Speed has been",
      " <span style=\"color: #2E7D32;",
      " font-weight: bold;\">approved</span>.</p>",
      "<p>You can now log in and start using",
      " the platform.</p>",
      "<hr style=\"border: none; border-top:",
      " 1px solid #eee; margin: 20px 0;\">",
      "<p style=\"color: #757575;",
      " font-size: 12px;\">",
      "Automated email from Z Speed.</p>",
      "</div>",
    ].join("");
    await admin.firestore().collection("mail").add({
      to: email,
      message: {
        subject: "Z Speed - Application Approved!",
        html,
      },
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("Failed to queue approval email:", err);
  }
}

// Queue a rejection email via Firestore "mail" collection.
async function sendRejectionEmail(
  userId: string,
  email: string,
  name: string,
  type: string,
  reason: string,
): Promise<void> {
  try {
    const html = [
      "<div style=\"font-family: Arial, sans-serif;",
      " max-width: 600px; margin: 0 auto;\">",
      "<h2 style=\"color: #C62828;\">",
      "Application Update</h2>",
      `<p>Dear ${name},</p>`,
      `<p>Your <strong>${type}</strong> application`,
      " on Z Speed has been",
      " <span style=\"color: #C62828;",
      " font-weight: bold;\">rejected</span>.</p>",
      `<p><strong>Reason:</strong> ${reason}</p>`,
      "<p>Please review the feedback and resubmit",
      " your application if applicable.</p>",
      "<hr style=\"border: none; border-top:",
      " 1px solid #eee; margin: 20px 0;\">",
      "<p style=\"color: #757575;",
      " font-size: 12px;\">",
      "Automated email from Z Speed.</p>",
      "</div>",
    ].join("");
    await admin.firestore().collection("mail").add({
      to: email,
      message: {
        subject: "Z Speed - Application Update",
        html,
      },
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("Failed to queue rejection email:", err);
  }
}
