import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

// ── SMTP secrets (set via `firebase functions:secrets:set`) ──────────────
const smtpUser = defineSecret("SMTP_USER");
const smtpPass = defineSecret("SMTP_PASS");

/**
 * Send a 6-digit OTP to the given email address.
 * Stores the code in Firestore `emailVerifications/{normalizedEmail}`.
 * Sends the email directly via SMTP (Nodemailer).
 */
export const sendEmailOTP = onCall(
  { secrets: [smtpUser, smtpPass] },
  async (request) => {
    const email = (request.data?.email as string ?? "").trim().toLowerCase();
    if (!email || !/^[^@]+@[^@]+\.[^@]+$/.test(email)) {
      throw new HttpsError("invalid-argument", "A valid email is required.");
    }

    console.log(`[sendEmailOTP] Sending OTP to ${email}`);

    // If skipExistingCheck is not set, check if email is already registered.
    const skipExistingCheck = request.data?.skipExistingCheck === true;

    if (!skipExistingCheck) {
      let existingUser = null;
      try {
        existingUser = await admin.auth().getUserByEmail(email);
      } catch (err: any) {
        // auth/user-not-found is expected when email is available
        if (err?.code !== "auth/user-not-found") {
          console.error("[sendEmailOTP] getUserByEmail error:", err);
        }
      }

      if (existingUser) {
        console.log(`[sendEmailOTP] Email ${email} already exists in Auth.`);
        throw new HttpsError(
          "already-exists",
          "This email is already registered. Please login instead.",
        );
      }
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
    );

    try {
      await admin.firestore()
        .collection("emailVerifications")
        .doc(email)
        .set({ code, expiresAt, verified: false });
    } catch (err) {
      console.error("[sendEmailOTP] Firestore error:", err);
      throw new HttpsError("failed-precondition", "Failed to save verification code.");
    }

    // Determine SMTP user & password from secrets or environment
    let user = smtpUser.value();
    let pass = smtpPass.value();

    if (!user || !pass) {
      user = process.env.SMTP_USER || "";
      pass = process.env.SMTP_PASS || "";
    }

    if (!user || !pass) {
      console.error("[sendEmailOTP] SMTP credentials missing in secrets.");
      throw new HttpsError(
        "failed-precondition",
        "SMTP email credentials (SMTP_USER/SMTP_PASS) are not configured on the server."
      );
    }

    // Send email directly via SMTP
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || "mail.zspeedapp.com",
        port: Number(process.env.SMTP_PORT) || 465,
        secure: process.env.SMTP_SECURE !== "false",
        auth: { user, pass },
      });

      const htmlBody = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #FF6B35;">Email Verification</h2>
          <p>Your verification code is:</p>
          <div style="text-align: center; margin: 20px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #333;">${code}</span>
          </div>
          <p>This code expires in 10 minutes.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #757575; font-size: 12px;">If you did not request this code, please ignore this email.</p>
        </div>
      `;

      await transporter.sendMail({
        from: `"Z-Speed" <${user}>`,
        to: email,
        subject: "Z Speed - Email Verification Code",
        html: htmlBody,
      });

      console.log(`[sendEmailOTP] OTP sent successfully to ${email}`);
      return { success: true };
    } catch (err: any) {
      console.error("[sendEmailOTP] SMTP send error:", err);
      throw new HttpsError(
        "failed-precondition",
        `Failed to send email: ${err?.message || err}`
      );
    }
  });

/**
 * Verify the 6-digit OTP the user entered.
 */
export const verifyEmailOTP = onCall(async (request) => {
  const email = (request.data?.email as string ?? "").trim().toLowerCase();
  const code = (request.data?.code as string ?? "").trim();

  if (!email || !code) {
    throw new HttpsError(
      "invalid-argument",
      "Email and code are required.",
    );
  }

  console.log(`[verifyEmailOTP] Verifying code for ${email}`);

  const docRef = admin.firestore()
    .collection("emailVerifications")
    .doc(email);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError(
      "not-found",
      "No verification code found. Please request a new one.",
    );
  }

  const data = doc.data()!;
  const expiresAt = (data.expiresAt as admin.firestore.Timestamp).toDate();

  if (new Date() > expiresAt) {
    throw new HttpsError("deadline-exceeded", "Code has expired.");
  }

  if (data.code !== code) {
    throw new HttpsError("permission-denied", "Invalid code.");
  }

  await docRef.update({ verified: true });

  console.log(`[verifyEmailOTP] Successfully verified ${email}`);
  return { success: true, verified: true };
});
