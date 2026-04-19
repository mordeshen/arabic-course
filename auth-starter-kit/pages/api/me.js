// Example protected API route — copy this pattern for any authenticated endpoint.
import { getUserSupabase } from "./lib/supabase-admin";

export default async function handler(req, res) {
  const sb = getUserSupabase(req, res);
  if (!sb) return res.status(503).json({ error: "auth not configured" });

  const { data: { user } } = await sb.auth.getUser();
  if (!user) return res.status(401).json({ error: "unauthorized" });

  // RLS is enforced — this query only returns the current user's profile.
  const { data: profile } = await sb
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  return res.json({ user: { id: user.id, email: user.email }, profile });
}
