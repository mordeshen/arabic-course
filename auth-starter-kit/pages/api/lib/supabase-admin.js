import { createClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

let adminClient = null;

/**
 * Privileged client — uses service role key, bypasses RLS.
 * Use only on the server, only when you need to read/write across users.
 *
 * Returns null if env vars are missing — callers should handle this and
 * return a 503, instead of letting the whole app crash at boot.
 */
export function getAdminSupabase() {
  if (adminClient) return adminClient;
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    console.warn("[supabase-admin] missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return null;
  }
  adminClient = createClient(url, key);
  return adminClient;
}

/**
 * Per-request client — reads the user's session from cookies.
 * Use this in API routes to identify the calling user. RLS is enforced.
 *
 * Usage:
 *   const sb = getUserSupabase(req, res);
 *   const { data: { user } } = await sb.auth.getUser();
 *   if (!user) return res.status(401).json({ error: "unauthorized" });
 */
export function getUserSupabase(req, res) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) return null;

  return createServerClient(url, anonKey, {
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
          res.setHeader("Set-Cookie", [
            ...(res.getHeader("Set-Cookie") || []),
            parts.join("; "),
          ]);
        });
      },
    },
  });
}

/**
 * Convenience: returns the authenticated user, or null.
 * Use this when you don't also need the per-request client itself.
 */
export async function getRequestUser(req, res) {
  const sb = getUserSupabase(req, res);
  if (!sb) return null;
  const { data: { user } } = await sb.auth.getUser();
  return user || null;
}
