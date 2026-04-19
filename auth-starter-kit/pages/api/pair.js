// WhatsApp pairing endpoint.
//
// Flow:
//   1. Your bot/backend generates a signed pair token via generatePairToken(phone)
//      and sends the user a link: https://yourapp.com/pair?token=<TOKEN>
//   2. User opens the link, signs in (Google or magic link).
//   3. The pair page POSTs here with the token + their JWT (Bearer or cookie).
//   4. We verify the token, look up whatsapp_pairings, and link phone -> user_id.
//
// The token is a self-contained HMAC — no DB lookup needed for verification,
// and it auto-expires after 10 minutes.

import crypto from "crypto";
import { getAdminSupabase, getUserSupabase } from "./lib/supabase-admin";

// IMPORTANT: set PAIR_TOKEN_SECRET in production. We don't throw at boot
// (so a missing env var can't crash the whole app), but the endpoint will
// refuse to operate until it's set.
const SECRET = process.env.PAIR_TOKEN_SECRET || null;
if (!SECRET && process.env.NODE_ENV === "production") {
  console.warn("[pair] PAIR_TOKEN_SECRET is not set — /api/pair will return 503 until configured");
}

// --- Token helpers ---

export function generatePairToken(phone) {
  if (!SECRET) throw new Error("PAIR_TOKEN_SECRET is not configured");
  const payload = JSON.stringify({ phone, exp: Date.now() + 10 * 60 * 1000 });
  const b64 = Buffer.from(payload).toString("base64url");
  const sig = crypto.createHmac("sha256", SECRET).update(b64).digest("base64url");
  return b64 + "." + sig;
}

function verifyPairToken(raw) {
  if (!SECRET) return { error: "server not configured" };
  const dotIdx = raw.indexOf(".");
  if (dotIdx < 0) return { error: "invalid token format" };

  const b64 = raw.slice(0, dotIdx);
  const sig = raw.slice(dotIdx + 1);

  const expected = crypto.createHmac("sha256", SECRET).update(b64).digest("base64url");
  const sigBuf = Buffer.from(sig);
  const expBuf = Buffer.from(expected);
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    return { error: "invalid signature" };
  }

  let data;
  try {
    data = JSON.parse(Buffer.from(b64, "base64url").toString("utf8"));
  } catch {
    return { error: "malformed payload" };
  }

  if (!data.phone || !data.exp) return { error: "missing fields" };
  if (Date.now() > data.exp) return { error: "token expired" };

  return { data };
}

function maskPhone(phone) {
  // "whatsapp:+972501234567" -> "+972***4567"
  const num = phone.replace("whatsapp:", "");
  if (num.length < 7) return num;
  return num.slice(0, 4) + "***" + num.slice(-4);
}

// --- Handler ---

export default async function handler(req, res) {
  if (!SECRET) {
    return res.status(503).json({ error: "pairing not configured (PAIR_TOKEN_SECRET missing)" });
  }

  // GET /api/pair?token=XXX — validate token only (no auth needed)
  if (req.method === "GET") {
    const { token } = req.query;
    if (!token) return res.status(400).json({ valid: false, reason: "missing token" });

    const result = verifyPairToken(token);
    if (result.error) return res.json({ valid: false, reason: result.error });

    return res.json({ valid: true, phone_masked: maskPhone(result.data.phone) });
  }

  // POST /api/pair — pair phone to authenticated user
  if (req.method === "POST") {
    const { token } = req.body || {};
    if (!token) return res.status(400).json({ error: "missing token" });

    const result = verifyPairToken(token);
    if (result.error) return res.status(400).json({ error: result.error });

    const { phone } = result.data;

    // Authenticate user — try Bearer header first (mobile/SPA), then cookies (browser)
    let user = null;

    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith("Bearer ")) {
      const admin = getAdminSupabase();
      if (admin) {
        const { data: { user: tokenUser }, error } = await admin.auth.getUser(authHeader.split(" ")[1]);
        if (!error && tokenUser) user = tokenUser;
      }
    }

    if (!user) {
      const userSupa = getUserSupabase(req, res);
      if (userSupa) {
        const { data: { user: cookieUser }, error } = await userSupa.auth.getUser();
        if (!error && cookieUser) user = cookieUser;
      }
    }

    if (!user) return res.status(401).json({ error: "not authenticated" });

    const admin = getAdminSupabase();
    if (!admin) return res.status(503).json({ error: "server not configured" });

    // Check if phone already paired
    const { data: existing, error: lookupErr } = await admin
      .from("whatsapp_pairings")
      .select("user_id, email")
      .eq("phone", phone)
      .maybeSingle();

    if (lookupErr) {
      console.error("pair lookup error:", lookupErr);
      return res.status(500).json({ error: "database error" });
    }

    // Already paired to same user — idempotent success
    if (existing && existing.user_id === user.id) {
      const profile = user.user_metadata || {};
      return res.json({ ok: true, name: profile.name || profile.full_name || null });
    }

    // Already paired to a different user — reject
    if (existing) {
      return res.status(409).json({
        error: "phone already paired to another account",
        code: "ALREADY_PAIRED",
      });
    }

    // Insert new pairing
    const { error: insertErr } = await admin
      .from("whatsapp_pairings")
      .insert({
        phone,
        user_id: user.id,
        email: user.email,
      });

    if (insertErr) {
      console.error("pair insert error:", insertErr);
      return res.status(500).json({ error: "failed to save pairing" });
    }

    const profile = user.user_metadata || {};
    return res.json({ ok: true, name: profile.name || profile.full_name || null });
  }

  res.setHeader("Allow", "GET, POST");
  return res.status(405).json({ error: "method not allowed" });
}
