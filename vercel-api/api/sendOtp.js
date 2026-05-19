const admin  = require('./_firebase');
const { Resend } = require('resend');

const db     = admin.firestore();
const resend = new Resend(process.env.RESEND_API_KEY);

const OTP_TTL_MS   = 10 * 60 * 1000; // 10 minutes

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin',  '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

module.exports = async (req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST')   return res.status(405).json({ error: 'Method not allowed' });

  const email = (req.body?.email ?? '').trim().toLowerCase();
  if (!email) return res.status(400).json({ error: 'Email is required.' });

  // Look up user — silently succeed if email not found (don't leak existence)
  let uid;
  try {
    const user = await admin.auth().getUserByEmail(email);
    uid = user.uid;
  } catch (_) {
    return res.status(200).json({ success: true });
  }

  const code      = String(Math.floor(100000 + Math.random() * 900000));
  const expiresAt = Date.now() + OTP_TTL_MS;

  await db.collection('otp_requests').doc(email).set({
    code, uid, expiresAt, attempts: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await resend.emails.send({
    from   : 'Hostminton App <onboarding@resend.dev>',
    to     : [email],
    subject: 'Your password reset code',
    html   : `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;
                  background:#0d0d1a;color:#e8e8f0;padding:32px;border-radius:16px;">
        <h2 style="color:#7c6eff;margin-top:0;">Password Reset</h2>
        <p style="color:#a0a0c0;">
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
      </div>`,
  });

  return res.status(200).json({ success: true });
};
