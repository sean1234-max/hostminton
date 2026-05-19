const admin = require('./_firebase');

const db          = admin.firestore();
const MAX_ATTEMPTS = 5;

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
  const code  = (req.body?.code  ?? '').trim();
  if (!email || !code) return res.status(400).json({ error: 'Email and code are required.' });

  const docRef = db.collection('otp_requests').doc(email);
  const doc    = await docRef.get();

  if (!doc.exists) {
    return res.status(400).json({ error: 'No code was requested. Please go back and try again.' });
  }

  const { code: stored, uid, expiresAt, attempts } = doc.data();

  if (Date.now() > expiresAt) {
    await docRef.delete();
    return res.status(400).json({ error: 'Code has expired. Please request a new one.' });
  }

  if (attempts >= MAX_ATTEMPTS) {
    await docRef.delete();
    return res.status(400).json({ error: 'Too many incorrect attempts. Please request a new code.' });
  }

  if (code !== stored) {
    await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
    return res.status(200).json({ success: false, attemptsLeft: MAX_ATTEMPTS - attempts - 1 });
  }

  // Correct — delete OTP and return a Firebase custom token
  await docRef.delete();
  const customToken = await admin.auth().createCustomToken(uid);

  return res.status(200).json({ success: true, customToken });
};
