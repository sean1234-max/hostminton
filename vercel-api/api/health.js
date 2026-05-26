module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  const vars = {
    hasFirebaseProjectId : !!process.env.FIREBASE_PROJECT_ID,
    hasSaEmail           : !!process.env.SA_EMAIL,
    hasSaPrivateKey      : !!process.env.SA_PRIVATE_KEY,
    hasResendApiKey      : !!process.env.RESEND_API_KEY,
  };
  res.status(200).json({ ok: true, env: vars });
};
