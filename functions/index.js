const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions }   = require('firebase-functions/v2');
const admin      = require('firebase-admin');
const nodemailer = require('nodemailer');
const crypto     = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// Deploy region — change if you prefer another region
setGlobalOptions({ region: 'asia-southeast1' });

// ─── Email transporter (set via Firebase secret / env) ──────────────────────
// After deploying, run:
//   firebase functions:secrets:set GMAIL_USER
//   firebase functions:secrets:set GMAIL_PASS
// Then re-deploy.
function makeTransporter(gmailUser, gmailPass) {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user: gmailUser, pass: gmailPass },
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function generate6Digit() {
  // Cryptographically random 6-digit string
  return String(crypto.randomInt(100000, 999999));
}

const OTP_TTL_MS    = 10 * 60 * 1000; // 10 minutes
const TOKEN_TTL_MS  = 15 * 60 * 1000; // 15 minutes
const MAX_ATTEMPTS  = 5;

// ─── sendOtp ─────────────────────────────────────────────────────────────────
// Called from: ForgotPasswordScreen after user submits email.
// Generates a 6-digit code, saves it to Firestore, sends it via Gmail.

exports.sendOtp = onCall(
  { secrets: ['GMAIL_USER', 'GMAIL_PASS'] },
  async (request) => {
    const email = (request.data.email ?? '').trim().toLowerCase();
    if (!email) throw new HttpsError('invalid-argument', 'Email is required.');

    // Check the user exists in Firebase Auth (don't reveal via error message)
    let uid;
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      uid = userRecord.uid;
    } catch (_) {
      // Return success anyway so we don't leak whether the email is registered
      return { success: true };
    }

    const code      = generate6Digit();
    const expiresAt = Date.now() + OTP_TTL_MS;

    // Overwrite any existing OTP for this email
    await db.collection('otp_requests').doc(email).set({
      code,
      expiresAt,
      attempts : 0,
      uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send email
    const transporter = makeTransporter(
      process.env.GMAIL_USER,
      process.env.GMAIL_PASS,
    );

    await transporter.sendMail({
      from   : `"Hostminton App" <${process.env.GMAIL_USER}>`,
      to     : email,
      subject: 'Your password reset code',
      html   : `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;
                    background:#0d0d1a;color:#e8e8f0;padding:32px;border-radius:16px;">
          <h2 style="color:#7c6eff;margin-top:0;">Password Reset</h2>
          <p style="color:#a0a0c0;margin-bottom:8px;">
            Use the code below to reset your Hostminton password.
            It expires in <strong>10 minutes</strong>.
          </p>
          <div style="background:#1a1a2e;border-radius:12px;padding:24px;
                      text-align:center;margin:24px 0;">
            <span style="font-size:42px;font-weight:700;letter-spacing:12px;
                         color:#7c6eff;">${code}</span>
          </div>
          <p style="color:#606080;font-size:12px;">
            If you didn't request this, you can safely ignore this email.
          </p>
        </div>
      `,
    });

    return { success: true };
  }
);

// ─── verifyOtp ───────────────────────────────────────────────────────────────
// Called from: OtpScreen when the user submits their 6 digits.
// Returns { success: true, resetToken } on correct code.

exports.verifyOtp = onCall(async (request) => {
  const email = (request.data.email ?? '').trim().toLowerCase();
  const code  = (request.data.code  ?? '').trim();

  if (!email || !code) {
    throw new HttpsError('invalid-argument', 'Email and code are required.');
  }

  const docRef = db.collection('otp_requests').doc(email);
  const doc    = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError('not-found', 'No code was requested for this email. Please start over.');
  }

  const { code: stored, expiresAt, attempts } = doc.data();

  if (Date.now() > expiresAt) {
    await docRef.delete();
    throw new HttpsError('deadline-exceeded', 'Code has expired. Please request a new one.');
  }

  if (attempts >= MAX_ATTEMPTS) {
    throw new HttpsError('resource-exhausted', 'Too many incorrect attempts. Please request a new code.');
  }

  if (code !== stored) {
    await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
    return { success: false, attemptsLeft: MAX_ATTEMPTS - attempts - 1 };
  }

  // ── Correct code ────────────────────────────────────────────────────────
  const resetToken  = crypto.randomBytes(32).toString('hex');
  const tokenExpiry = Date.now() + TOKEN_TTL_MS;

  await Promise.all([
    docRef.delete(),
    db.collection('password_reset_tokens').doc(resetToken).set({
      email,
      uid      : doc.data().uid,
      expiresAt: tokenExpiry,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }),
  ]);

  return { success: true, resetToken };
});

// ─── resetPasswordWithToken ──────────────────────────────────────────────────
// Called from: ResetPasswordScreen after the user types their new password.
// Uses the Admin SDK to update the password server-side (no re-auth needed).

exports.resetPasswordWithToken = onCall(async (request) => {
  const { resetToken, newPassword } = request.data;

  if (!resetToken || !newPassword) {
    throw new HttpsError('invalid-argument', 'Reset token and new password are required.');
  }

  if (newPassword.length < 8) {
    throw new HttpsError('invalid-argument', 'Password must be at least 8 characters.');
  }

  const tokenRef = db.collection('password_reset_tokens').doc(resetToken);
  const tokenDoc = await tokenRef.get();

  if (!tokenDoc.exists) {
    throw new HttpsError('not-found', 'Invalid or expired reset session. Please start over.');
  }

  const { email, uid, expiresAt } = tokenDoc.data();

  if (Date.now() > expiresAt) {
    await tokenRef.delete();
    throw new HttpsError('deadline-exceeded', 'Reset session expired. Please start over.');
  }

  // Update password via Admin SDK
  await admin.auth().updateUser(uid, { password: newPassword });

  // Update Firestore lastPasswordChange
  await db.collection('users').doc(uid).update({
    lastPasswordChange: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Delete the used token
  await tokenRef.delete();

  return { success: true, email };
});
