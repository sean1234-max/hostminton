// Shared Firebase Admin initialisation (runs once per serverless instance)
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId : process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.SA_EMAIL,
      // Vercel stores secrets as strings; replace literal \n with real newlines
      privateKey : process.env.SA_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
}

module.exports = admin;
