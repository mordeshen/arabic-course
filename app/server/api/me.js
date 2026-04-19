// ──────────────────────────────────────────────────────────────
// GET /api/me
// Returns current user + profile + active course parts.
// Used by the client to know who is logged in and what they own.
// ──────────────────────────────────────────────────────────────

import { Router } from "express";
import { getUserSupabase, getAdminSupabase } from "../lib/supabase.js";

const router = Router();

router.get("/", async (req, res) => {
  const sb = getUserSupabase(req, res);
  if (!sb) return res.status(503).json({ error: "auth_not_configured" });

  const { data: { user }, error: userErr } = await sb.auth.getUser();
  if (userErr || !user) {
    return res.status(401).json({ error: "unauthorized" });
  }

  // Profile (RLS enforced — only the user's own row)
  const { data: profile } = await sb
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  // Active parts — go through admin client because the helper function is
  // SECURITY DEFINER and we want consistent behavior with the access middleware
  let activeParts = [];
  try {
    const admin = getAdminSupabase();
    const { data, error } = await admin.rpc("get_user_active_parts", {
      p_user_id: user.id,
    });
    if (!error && Array.isArray(data)) {
      activeParts = data;
    }
  } catch (e) {
    console.error("[/api/me] get_user_active_parts:", e.message);
  }

  res.json({
    user: { id: user.id, email: user.email },
    profile: profile || null,
    active_parts: activeParts,
  });
});

export default router;
