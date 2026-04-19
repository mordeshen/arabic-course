import { createClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const ANON_KEY = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !ANON_KEY) {
  console.error("[supabase] missing SUPABASE_URL or SUPABASE_ANON_KEY");
}
if (!SERVICE_KEY) {
  console.warn("[supabase] missing SUPABASE_SERVICE_ROLE_KEY — write operations will fail");
}

// ── Admin client (service_role, bypass RLS, server only) ──
let _admin = null;
export function getAdminSupabase() {
  if (_admin) return _admin;
  if (!SUPABASE_URL || !SERVICE_KEY) {
    throw new Error("Supabase admin not configured");
  }
  _admin = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return _admin;
}

// ── User-scoped client (reads cookies, respects RLS) ──
// Used to identify the logged-in user from their session cookie
export function getUserSupabase(req, res) {
  if (!SUPABASE_URL || !ANON_KEY) return null;

  return createServerClient(SUPABASE_URL, ANON_KEY, {
    cookies: {
      getAll() {
        return Object.entries(req.cookies || {}).map(([name, value]) => ({ name, value }));
      },
      setAll(cookies) {
        cookies.forEach(({ name, value, options }) => {
          const parts = [`${name}=${encodeURIComponent(value)}`];
          if (options?.path) parts.push(`Path=${options.path}`);
          if (options?.maxAge != null) parts.push(`Max-Age=${options.maxAge}`);
          if (options?.domain) parts.push(`Domain=${options.domain}`);
          if (options?.sameSite) parts.push(`SameSite=${options.sameSite}`);
          if (options?.httpOnly) parts.push("HttpOnly");
          if (options?.secure) parts.push("Secure");
          const existing = res.getHeader("Set-Cookie") || [];
          res.setHeader("Set-Cookie", [
            ...(Array.isArray(existing) ? existing : [existing]),
            parts.join("; "),
          ]);
        });
      },
    },
  });
}

// ── Helper: get current user from request ──
export async function getCurrentUser(req, res) {
  const sb = getUserSupabase(req, res);
  if (!sb) return null;
  try {
    const { data: { user } } = await sb.auth.getUser();
    return user || null;
  } catch (e) {
    console.error("[getCurrentUser]", e.message);
    return null;
  }
}
