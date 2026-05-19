/**
 * SFC Arena OTP Worker
 * Cloudflare Worker — free tier (100K req/day)
 *
 * Endpoints:
 *   POST /sendOtp    { email }        → sends 6-digit code via Resend
 *   POST /verifyOtp  { email, code }  → verifies code, returns Firebase customToken
 *
 * KV namespace "OTP_STORE" stores OTP records with TTL.
 *
 * Secrets required (wrangler secret put <NAME>):
 *   RESEND_API_KEY, SA_EMAIL, SA_PRIVATE_KEY, FIREBASE_PROJECT_ID
 */

const CORS = {
  'Access-Control-Allow-Origin' : '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

const OTP_TTL_SEC   = 10 * 60;   // 10 minutes
const MAX_ATTEMPTS  = 5;

// ─── Entry point ──────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }
    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    const url = new URL(request.url);
    try {
      switch (url.pathname) {
        case '/sendOtp':   return await handleSendOtp(request, env);
        case '/verifyOtp': return await handleVerifyOtp(request, env);
        default:           return json({ error: 'Not found' }, 404);
      }
    } catch (err) {
      console.error(err);
      return json({ error: err.message ?? 'Internal error' }, 500);
    }
  },
};

// ─── /sendOtp ─────────────────────────────────────────────────────────────────

async function handleSendOtp(request, env) {
  const { email } = await request.json();
  if (!email) return json({ error: 'Email required' }, 400);

  const normalised = email.trim().toLowerCase();

  // Look up user in Firebase to get their UID
  const accessToken = await getGoogleAccessToken(env.SA_EMAIL, env.SA_PRIVATE_KEY);
  const uid = await getUidByEmail(normalised, accessToken, env.FIREBASE_PROJECT_ID);

  // Don't reveal whether the email is registered — always return success
  if (!uid) return json({ success: true });

  // Generate OTP and store in KV (overwrite any existing request)
  const code      = String(Math.floor(100000 + Math.random() * 900000));
  const record    = JSON.stringify({ code, uid, attempts: 0 });
  await env.OTP_STORE.put(`otp:${normalised}`, record, { expirationTtl: OTP_TTL_SEC });

  // Send email via Resend
  await sendEmail(env.RESEND_API_KEY, normalised, code);

  return json({ success: true });
}

// ─── /verifyOtp ───────────────────────────────────────────────────────────────

async function handleVerifyOtp(request, env) {
  const { email, code } = await request.json();
  if (!email || !code) return json({ error: 'Email and code required' }, 400);

  const normalised = email.trim().toLowerCase();
  const raw        = await env.OTP_STORE.get(`otp:${normalised}`);

  if (!raw) {
    return json({ error: 'No code was requested. Please go back and try again.' }, 400);
  }

  const record = JSON.parse(raw);

  if (record.attempts >= MAX_ATTEMPTS) {
    await env.OTP_STORE.delete(`otp:${normalised}`);
    return json({ error: 'Too many incorrect attempts. Please request a new code.' }, 400);
  }

  if (code.trim() !== record.code) {
    record.attempts += 1;
    const remaining = OTP_TTL_SEC; // keep original TTL (KV TTL resets on put — use remaining time)
    await env.OTP_STORE.put(`otp:${normalised}`, JSON.stringify(record), {
      expirationTtl: remaining,
    });
    const attemptsLeft = MAX_ATTEMPTS - record.attempts;
    return json({ success: false, attemptsLeft });
  }

  // ── Correct code ────────────────────────────────────────────────────────────
  await env.OTP_STORE.delete(`otp:${normalised}`);

  // Generate a Firebase custom token so Flutter can sign in as this user
  const customToken = await createFirebaseCustomToken(
    record.uid,
    env.SA_EMAIL,
    env.SA_PRIVATE_KEY,
  );

  return json({ success: true, customToken });
}

// ─── Firebase helpers ─────────────────────────────────────────────────────────

async function getUidByEmail(email, accessToken, projectId) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:lookup`,
    {
      method : 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}` },
      body   : JSON.stringify({ email: [email] }),
    },
  );
  const data = await res.json();
  return data.users?.[0]?.localId ?? null;
}

async function createFirebaseCustomToken(uid, saEmail, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  return signJWT({
    iss: saEmail,
    sub: saEmail,
    aud: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    iat: now,
    exp: now + 3600,
    uid,
  }, privateKeyPem);
}

async function getGoogleAccessToken(saEmail, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  const jwt = await signJWT({
    iss  : saEmail,
    sub  : saEmail,
    aud  : 'https://oauth2.googleapis.com/token',
    iat  : now,
    exp  : now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/cloud-platform',
  }, privateKeyPem);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method : 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body   : `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) throw new Error('Failed to get Google access token');
  return data.access_token;
}

// ─── JWT / crypto helpers ─────────────────────────────────────────────────────

async function signJWT(payload, privateKeyPem) {
  const header   = b64u(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const body     = b64u(JSON.stringify(payload));
  const input    = `${header}.${body}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBuffer(privateKeyPem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key,
    new TextEncoder().encode(input));

  return `${input}.${b64uBuf(sig)}`;
}

function pemToBuffer(pem) {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

function b64u(str)    { return b64uBuf(new TextEncoder().encode(str)); }
function b64uBuf(buf) {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

// ─── Email via Resend ─────────────────────────────────────────────────────────

async function sendEmail(apiKey, to, code) {
  const res = await fetch('https://api.resend.com/emails', {
    method : 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
    body   : JSON.stringify({
      from   : 'Hostminton App <onboarding@resend.dev>',
      to     : [to],
      subject: 'Your password reset code',
      html   : `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;
                    background:#0d0d1a;color:#e8e8f0;padding:32px;border-radius:16px;">
          <h2 style="color:#7c6eff;margin-top:0;">Password Reset</h2>
          <p style="color:#a0a0c0;margin-bottom:8px;">
            Use the code below to reset your Hostminton password.<br>
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
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Resend error: ${err}`);
  }
}

// ─── Utility ──────────────────────────────────────────────────────────────────

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}
