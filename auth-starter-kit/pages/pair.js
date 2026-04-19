// Pair page — user lands here from a WhatsApp link with ?token=XXX
// Handles: validate token -> sign in (if needed) -> POST /api/pair -> show result
import { useState, useEffect } from "react";
import Head from "next/head";
import { useRouter } from "next/router";
import { useUser } from "../lib/UserContext";
import { supabase, isSupabaseConfigured } from "../lib/supabase";

function parseToken(tokenStr) {
  try {
    const dotIdx = tokenStr.indexOf(".");
    const b64 = dotIdx > 0 ? tokenStr.slice(0, dotIdx) : tokenStr;
    const base64 = b64.replace(/-/g, "+").replace(/_/g, "/");
    const json = atob(base64);
    const data = JSON.parse(json);
    if (!data.phone || !data.exp) return null;
    if (Date.now() > data.exp) return { expired: true };
    return data;
  } catch {
    return null;
  }
}

export default function PairPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useUser();
  const [status, setStatus] = useState("loading"); // loading | login | pairing | success | already | error
  const [error, setError] = useState("");
  const [email, setEmail] = useState("");
  const [magicLinkSent, setMagicLinkSent] = useState(false);
  const [sending, setSending] = useState(false);

  const token = router.query.token;

  async function doPairing() {
    setStatus("pairing");
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const headers = { "Content-Type": "application/json" };
      if (session?.access_token) {
        headers["Authorization"] = `Bearer ${session.access_token}`;
      }

      const res = await fetch("/api/pair", {
        method: "POST",
        headers,
        body: JSON.stringify({ token }),
        credentials: "include",
      });
      const data = await res.json();
      if (!res.ok) {
        if (data.code === "ALREADY_PAIRED") {
          setStatus("already");
        } else {
          setError(data.error || "Pairing failed");
          setStatus("error");
        }
        return;
      }
      setStatus("success");
    } catch {
      setError("Network error");
      setStatus("error");
    }
  }

  useEffect(() => {
    if (!router.isReady) return;
    if (!token) { setError("Missing token"); setStatus("error"); return; }

    const parsed = parseToken(token);
    if (!parsed) { setError("Invalid link"); setStatus("error"); return; }
    if (parsed.expired) { setError("Link expired — request a new one from WhatsApp."); setStatus("error"); return; }

    if (authLoading) return;

    if (user) {
      doPairing();
    } else {
      setStatus("login");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [router.isReady, token, user, authLoading]);

  async function handleMagicLink(e) {
    e.preventDefault();
    if (!email.trim() || !isSupabaseConfigured) return;
    setSending(true);
    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: {
        emailRedirectTo: `${window.location.origin}/pair?token=${token}`,
      },
    });
    setSending(false);
    if (error) {
      setError(error.message);
      setStatus("error");
    } else {
      setMagicLinkSent(true);
    }
  }

  async function handleGoogle() {
    if (!isSupabaseConfigured) return;
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/pair?token=${token}` },
    });
  }

  return (
    <>
      <Head><title>Connect WhatsApp</title></Head>
      <main style={{ maxWidth: 420, margin: "4rem auto", padding: "1.5rem", fontFamily: "system-ui, sans-serif" }}>
        {(status === "loading" || status === "pairing") && <p>{status === "pairing" ? "Linking your account..." : "Loading..."}</p>}

        {status === "error" && (
          <div>
            <h2>Error</h2>
            <p>{error}</p>
          </div>
        )}

        {status === "already" && (
          <div>
            <h2>Already linked</h2>
            <p>This WhatsApp number is already connected to your account.</p>
          </div>
        )}

        {status === "success" && (
          <div>
            <h2>Connected</h2>
            <p>Your WhatsApp is now linked. You can return to the chat.</p>
          </div>
        )}

        {status === "login" && !magicLinkSent && (
          <div>
            <h2>Sign in to link WhatsApp</h2>
            <button onClick={handleGoogle} style={{ width: "100%", padding: "0.75rem", marginBottom: "1rem" }}>
              Continue with Google
            </button>
            <form onSubmit={handleMagicLink}>
              <label>Or enter your email:</label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{ width: "100%", padding: "0.5rem", margin: "0.5rem 0" }}
              />
              <button type="submit" disabled={sending} style={{ width: "100%", padding: "0.75rem" }}>
                {sending ? "Sending..." : "Send magic link"}
              </button>
            </form>
          </div>
        )}

        {status === "login" && magicLinkSent && (
          <div>
            <h2>Check your email</h2>
            <p>We sent a sign-in link to <strong>{email}</strong>. Click it to continue.</p>
          </div>
        )}
      </main>
    </>
  );
}
