# Auth Starter Kit

Drop-in Supabase auth for a Next.js (Pages Router) project.
Extracted and generalized from [מגן](https://magen.app).

## What you get

- **Google OAuth + Email magic link** — login flows handled by Supabase
- **`useUser()` hook** — access `user`, `profile`, and auth methods anywhere in React
- **Server-side auth in API routes** — cookie-based, RLS-enforced
- **`profiles` table** — auto-created on signup via DB trigger
- **WhatsApp pairing** — link a phone number to an authenticated user via signed token

## Files

```
lib/
  supabase.js              # browser client
  UserContext.js           # React context + useUser() hook
pages/
  _app.js                  # mounts <UserProvider>
  pair.js                  # WhatsApp pairing landing page
  api/
    me.js                  # example protected route
    pair.js                # WhatsApp pairing endpoint (+ generatePairToken helper)
    lib/
      supabase-admin.js    # getUserSupabase() + getAdminSupabase()
sql/
  schema.sql               # profiles, RLS, triggers, whatsapp_pairings
.env.example
```

## Setup (5 minutes)

1. **Install deps**
   ```bash
   npm install @supabase/ssr @supabase/supabase-js
   ```

2. **Copy files** into your Next.js project root (preserving the structure above).

3. **Create a Supabase project**, then run `sql/schema.sql` in the SQL Editor.

4. **Enable Google provider** in Supabase Dashboard → Authentication → Providers → Google.
   Add your OAuth client credentials. (Skip if you only want magic links.)

5. **Set env vars** (`.env.local`):
   ```bash
   NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
   SUPABASE_SERVICE_ROLE_KEY=eyJ...
   PAIR_TOKEN_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
   ```

6. **Run** `npm run dev`. You're done.

## Usage

### Client-side

```jsx
import { useUser } from "../lib/UserContext";

export default function HomePage() {
  const { user, profile, loading, signInWithGoogle, signOut } = useUser();

  if (loading) return <p>Loading...</p>;
  if (!user) return <button onClick={signInWithGoogle}>Sign in with Google</button>;

  return (
    <div>
      <p>Hello, {profile?.name || user.email}</p>
      <button onClick={signOut}>Sign out</button>
    </div>
  );
}
```

### Server-side (API route)

```js
import { getUserSupabase } from "./lib/supabase-admin";

export default async function handler(req, res) {
  const sb = getUserSupabase(req, res);
  if (!sb) return res.status(503).json({ error: "auth not configured" });

  const { data: { user } } = await sb.auth.getUser();
  if (!user) return res.status(401).json({ error: "unauthorized" });

  // RLS enforced — only the user's own rows
  const { data } = await sb.from("profiles").select("*").eq("id", user.id).single();
  return res.json(data);
}
```

### Two server clients — when to use which

| Helper | Auth context | RLS | Use for |
|---|---|---|---|
| `getUserSupabase(req, res)` | The calling user's JWT (cookies) | **Enforced** | Reading/writing the caller's own data |
| `getAdminSupabase()` | Service role key | **Bypassed** | Cross-user reads, server-trusted writes (e.g. webhooks, pairing) |

Both return `null` if env vars are missing — they will not crash the app at boot.

## WhatsApp pairing flow

1. Your bot or backend calls `generatePairToken(phone)` (exported from `pages/api/pair.js`) to mint a 10-minute HMAC-signed token.
2. Bot sends the user a link: `https://yourapp.com/pair?token=<TOKEN>`.
3. User opens the link. If not signed in, they sign in with Google or magic link (the page is RTL-agnostic and uses inline styles — restyle as needed).
4. Pair page POSTs `/api/pair` with the token + the user's JWT.
5. Server verifies the token, checks `whatsapp_pairings`, and links phone → `user_id`.

After pairing, your WhatsApp webhook can look up `user_id` by `phone` to authenticate incoming messages.

## Safety notes

- **Missing env vars do not crash the app.** Helpers return `null`, endpoints return `503`. The boot succeeds, individual routes degrade gracefully.
- **`SUPABASE_SERVICE_ROLE_KEY`** must never reach the browser. Only import `getAdminSupabase` from server-only files (`pages/api/**`).
- **`PAIR_TOKEN_SECRET`** must be a long random string. The default is a placeholder warning — anyone who knows your secret can mint pairings.
- **RLS is your last line of defense.** Always enable RLS on any table containing user data, with `auth.uid() = user_id` policies.
- **Never trust `req.body.user_id`** from clients. Always derive `user.id` from `sb.auth.getUser()`.
