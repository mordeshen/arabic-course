# מערכת תשלומים — מדריך העברה לפרוייקטים אחרים

מסמך זה מתאר את כל המעגל של התשלומים במגן ככה שתוכל להעתיק את התבנית לפרוייקטים אחרים. הסטאק: **Next.js + Supabase + Grow (משולם) דרך Make.com + Morning/Green Invoice לחשבוניות**.

---

## 1. ארכיטקטורה — תמונת על

```
┌────────────┐   1. POST /api/checkout (plan_id)
│  Frontend  │──────────────────────────────┐
│ (pricing)  │                              ▼
└─────┬──────┘                       ┌──────────────┐
      │                              │  Next.js API │
      │  5. redirect → Grow URL      │   checkout   │
      │◀─────────────────────────────│              │
      │                              └──────┬───────┘
      ▼                                     │ 2. INSERT pending_purchases
┌────────────┐                              │ 3. POST → Make.com (webhook A)
│   Grow     │                              ▼
│ (תשלום)    │                       ┌──────────────┐
│            │   4. URL חזרה          │   Make.com   │
│            │◀──────────────────────│  Scenario 1  │ → Grow Create Payment Link
└─────┬──────┘                       └──────────────┘
      │ 6. משתמש משלם
      ▼
┌────────────┐  7. notify (תשלום אושר)
│   Grow     │──────────────────────▶┌──────────────┐
└────────────┘                       │   Make.com   │
                                     │  Scenario 2  │
                                     └──────┬───────┘
                                            │ 8. POST + x-make-secret
                                            ▼
                                     ┌──────────────┐
                                     │  Next.js API │
                                     │    webhook   │
                                     │              │
                                     └──────┬───────┘
                                            │ 9. fulfilled=true
                                            │ 10. credit user_subscriptions
                                            │ 11. Morning → invoice → email
                                            ▼
                                     ┌──────────────┐
                                     │   Supabase   │
                                     └──────────────┘
```

**למה Make.com באמצע?** ל-Grow אין SDK רשמי לקריאה ישירה ליצירת link תשלום. Make.com משמש כ-glue: מקבל webhook, קורא ל-Grow, מחזיר URL. אותו דבר בכיוון השני — Grow notify ל-Make, Make מאמת ושולח הלאה.

---

## 2. סכמת DB ב-Supabase

צריך 3 טבלאות עיקריות. SQL להעתקה:

```sql
-- מסלולים (catalog)
create table subscription_plans (
  id            text primary key,             -- 'free', 'one_time', 'monthly', 'premium'
  name          text not null,
  price         integer not null,             -- באגורות (1₪ = 100)
  token_limit   integer,
  daily_token_limit integer,
  period_days   integer,                      -- null = חד-פעמי
  model         text,
  max_tokens    integer,
  features      jsonb default '{}'::jsonb,
  active        boolean default true,
  created_at    timestamptz default now()
);

-- pending purchases — נוצרים ב-checkout, מסומנים fulfilled ב-webhook
create table pending_purchases (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id),
  email       text,
  plan_id     text references subscription_plans(id),
  amount      integer not null,               -- אגורות
  fulfilled   boolean default false,
  gi_doc_id   text,                           -- ID של חשבונית או transaction
  created_at  timestamptz default now()
);

-- מנוי משתמש פעיל
create table user_subscriptions (
  user_id            uuid primary key references auth.users(id),
  plan_id            text references subscription_plans(id) default 'free',
  token_balance      integer default 0,        -- למסלול חד-פעמי
  daily_tokens_used  integer default 0,
  daily_reset_date   date default current_date,
  subscription_start timestamptz,
  subscription_end   timestamptz,
  updated_at         timestamptz default now()
);

-- audit log של תנועות טוקנים/רכישות
create table token_transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id),
  amount      integer not null,
  type        text,                            -- 'purchase' | 'usage' | 'refund'
  description text,
  created_at  timestamptz default now()
);

-- seed
insert into subscription_plans (id, name, price, period_days, daily_token_limit) values
  ('free',     'חינם',    0,     null, 50000),
  ('one_time', 'חד-פעמי', 2900,  null, null),    -- 29₪
  ('monthly',  'חודשי',   4900,  30,   null),    -- 49₪
  ('premium',  'פרימיום', 9900,  30,   null);    -- 99₪
```

**למה אגורות ולא שקלים?** מונע שגיאות עיגול (float). Grow מקבל בשקלים — מחלקים ב-100 בקריאה.

---

## 3. משתני סביבה

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...        # רק בשרת, לעולם לא בקליינט

# Make.com — webhook A (יצירת לינק תשלום)
MAKE_WEBHOOK_URL=https://hook.eu1.make.com/...
MAKE_WEBHOOK_API_KEY=...              # נשלח ב-x-make-apikey, Make מאמת
MAKE_WEBHOOK_SECRET=...               # נשלח ע"י Make ב-x-make-secret בכיוון ההפוך

# Morning / Green Invoice
GI_API_KEY_ID=...
GI_API_KEY_SECRET=...
GI_SANDBOX=false                      # true לבדיקות

# Site
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
ADMIN_EMAIL=admin@yourdomain.com      # מייל להתראות על כשלים
```

---

## 4. הקבצים — להעתיק כמו שהם

### 4.1 `pages/api/lib/supabase-admin.js`

```js
import { createClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

let adminClient = null;

export function getAdminSupabase() {
  if (adminClient) return adminClient;
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY");
  adminClient = createClient(url, key);
  return adminClient;
}

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
```

### 4.2 `pages/api/plans.js` — public catalog

```js
import { createClient } from "@supabase/supabase-js";

export default async function handler(req, res) {
  if (req.method !== "GET") return res.status(405).end();
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return res.status(500).json({ error: "not configured" });

  const sb = createClient(url, key);
  const { data } = await sb
    .from("subscription_plans")
    .select("id, name, price, token_limit, daily_token_limit, period_days, features")
    .eq("active", true)
    .order("price", { ascending: true });

  res.json(data || []);
}
```

### 4.3 `pages/api/checkout.js` — יצירת לינק תשלום

```js
import { getAdminSupabase, getUserSupabase } from "./lib/supabase-admin";

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).end();

  // 1. Auth
  const userSb = getUserSupabase(req, res);
  if (!userSb) return res.status(401).json({ error: "unauthorized" });
  const { data: { user } } = await userSb.auth.getUser();
  if (!user) return res.status(401).json({ error: "unauthorized" });

  // 2. Validate plan
  const { plan_id: planId } = req.body || {};
  if (!planId) return res.status(400).json({ error: "invalid plan" });

  const admin = getAdminSupabase();
  const { data: plan } = await admin
    .from("subscription_plans")
    .select("price, name")
    .eq("id", planId)
    .single();
  if (!plan) return res.status(400).json({ error: "invalid_plan" });

  const amount = plan.price;          // אגורות
  const amountNIS = amount / 100;     // שקלים — Grow מקבל בשקלים

  // 3. צור pending_purchase
  const { data: pending, error } = await admin
    .from("pending_purchases")
    .insert({ user_id: user.id, email: user.email, plan_id: planId, amount })
    .select()
    .single();
  if (error) return res.status(500).json({ error: "internal" });

  // 4. קרא ל-Make.com → Grow → קבל URL
  const makeUrl = process.env.MAKE_WEBHOOK_URL;
  const makeKey = process.env.MAKE_WEBHOOK_API_KEY;
  if (!makeUrl || !makeKey) return res.status(500).json({ error: "payment not configured" });

  const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL || "").replace(/\/+$/, "");

  try {
    const makeRes = await fetch(makeUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-make-apikey": makeKey },
      body: JSON.stringify({
        fullName: user.user_metadata?.full_name || user.email,
        phone: user.user_metadata?.phone || user.phone || "0500000000",
        email: user.email,
        amount: amountNIS,
        title: `מסלול ${plan.name}`,
        paymentId: pending.id,    // ← קריטי: מועבר ל-Grow ב-custom field, חוזר ב-webhook
        successUrl: `${siteUrl}/?payment=success`,
        failureUrl: `${siteUrl}/?payment=failed`,
      }),
    });

    if (!makeRes.ok) throw new Error(`Make.com failed: ${makeRes.status}`);
    const makeData = await makeRes.json();
    if (!makeData.url) throw new Error("No payment URL returned");

    res.json({ paymentUrl: makeData.url });
  } catch (err) {
    console.error("[checkout]", err.message);
    res.status(500).json({ error: "payment_error", message: "שגיאה ביצירת התשלום" });
  }
}
```

### 4.4 `pages/api/webhook/greeninvoice.js` — fulfillment

ראה את הקובץ המלא ב-`pages/api/webhook/greeninvoice.js`. הנקודות הקריטיות:

1. **אימות secret**: `req.headers["x-make-secret"] === process.env.MAKE_WEBHOOK_SECRET` — אם לא, החזר 401.
2. **חילוץ paymentId** — מ-`payload.paymentId` (זה ה-`pending.id` שלנו שעבר ב-Grow custom).
3. **Idempotency** — `select * from pending_purchases where id = paymentId AND fulfilled = false`. אם לא קיים → החזר `{ ok: true, not_found: true }` עם 200 (כדי ש-Make לא ינסה שוב).
4. **סמן `fulfilled=true`** *לפני* הזיכוי, כדי שגם אם הזיכוי נופל לא נחייב פעמיים.
5. **הוסף לחשבון** — לא להחליף, להוסיף: `currentBalance + amount`.
6. **צור חשבונית ב-Morning** — לא חוסם את ה-response (try/catch).
7. **התראה על כישלון חשבונית** — אם Morning נכשל, שלח מייל admin (לא מחזיר 500 — המשתמש כבר זוכה).
8. **תמיד החזר 200** ל-Make אחרי הזיכוי — אחרת הוא ינסה שוב ויכול ליצור חשבוניות כפולות.

### 4.5 `pages/api/subscription.js` — קריאה למצב + reset יומי

ראה את הקובץ. הלוגיקה:
- אם אין שורה ב-`user_subscriptions` → יוצר אוטומטית `free`.
- אם `daily_reset_date < today` → מאפס `daily_tokens_used`.
- אם `subscription_end < now()` → מוריד ל-`free`.
- מחזיר `remaining` שונה לפי סוג מסלול: `unlimited` (-1) למנויים, `token_balance` לחד-פעמי, `daily_limit - used` ל-free.

### 4.6 כפתור ב-frontend

```js
async function handleUpgrade(planId) {
  if (!user) {
    // הפנה להתחברות (Google OAuth)
    return;
  }
  const r = await fetch("/api/checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ plan_id: planId }),
  });
  const d = await r.json().catch(() => ({}));
  if (d.paymentUrl) {
    window.location.href = d.paymentUrl;
  } else {
    alert("שגיאה ביצירת התשלום");
  }
}
```

---

## 5. הגדרת Make.com — שני התרחישים

### Scenario 1 — יצירת לינק תשלום

```
Trigger: Webhook (POST)
  ↓ מאמת x-make-apikey === MAKE_WEBHOOK_API_KEY (Router/Filter)
  ↓
Grow: Create Payment Link
  - sum:          {{amount}}
  - description:  {{title}}
  - pageCode:     <Grow page code שלך>
  - userId:       <Grow user id שלך>
  - cField1:      {{paymentId}}   ← קריטי, חוזר אלינו ב-Scenario 2
  - successUrl:   {{successUrl}}
  - cancelUrl:    {{failureUrl}}
  - clientName:   {{fullName}}
  - clientEmail:  {{email}}
  - phone:        {{phone}}
  ↓
Webhook Response:
  { "url": "{{Grow.linkUrl}}", "id": "{{Grow.id}}" }
```

### Scenario 2 — אישור תשלום

```
Trigger: Grow Webhook — "Payment Approved"
  ↓
HTTP: Make a request
  - URL:    https://yourdomain.com/api/webhook/greeninvoice
  - Method: POST
  - Headers: x-make-secret = {{MAKE_WEBHOOK_SECRET}}
  - Body (JSON):
    {
      "paymentId":     "{{Grow.cField1}}",
      "transactionId": "{{Grow.transactionId}}",
      "asmachta":      "{{Grow.asmachta}}",
      "fullName":      "{{Grow.clientName}}"
    }
```

---

## 6. בדיקת קצה-לקצה

יש סקריפט מוכן ב-`scripts/test-payment-e2e.js`. הוא בודק:

1. `GET /api/plans` מחזיר מסלולים
2. `POST /api/checkout` ללא auth → 401
3. `POST /api/webhook/greeninvoice` עם paymentId פיקטיבי → `{ ok: true, not_found: true }`
4. `POST /api/webhook/greeninvoice` עם secret שגוי → 401
5. `GET /api/subscription` ללא auth → 401

```bash
node scripts/test-payment-e2e.js http://localhost:3000
node scripts/test-payment-e2e.js https://yourdomain.com
```

לבדיקת תשלום אמיתי — צור מסלול `test` ב-`subscription_plans` עם `price=50` (0.50₪) ו-`active=false` (כדי שלא יופיע בקטלוג הציבורי), ותכניס כפתור בדיקה רק לאדמין.

---

## 7. עקרונות חשובים — אסור לפספס

1. **Idempotency על webhook** — Make יכול לשלוח אותה הודעה פעמיים. בלי `WHERE fulfilled = false` תחייב פעמיים.
2. **לעולם לא לשמור סכום כסף ב-float** — אגורות (integer) בלבד.
3. **אימות secret על webhook** — אחרת כל אחד יכול לשלוח POST ולקבל מנוי חינם.
4. **`paymentId` חייב לעבור hand-to-hand** — שלנו → Make → Grow `cField1` → Make → אלינו. אחרת אין דרך לדעת איזה pending לסגור.
5. **חשבונית = non-blocking** — אם Morning נופל אסור שזה יבטל את הזיכוי. המשתמש שילם, חייבים לזכות.
6. **התראה על כשל חשבונית** — אחרת תגלה שלא הוצאת חשבוניות רק בסוף החודש.
7. **`fulfilled=true` לפני הזיכוי** — אם הזיכוי נופל, עדיף לא לזכות מאשר לזכות פעמיים. תקן ידנית.
8. **service_role key רק בשרת** — לעולם לא ב-`NEXT_PUBLIC_*`.
9. **Reset יומי lazy** — לא צריך cron, פשוט בודקים `daily_reset_date` בכל קריאה ל-`/api/subscription`.
10. **`subscription_end` lazy expiry** — אותה שיטה.

---

## 8. רשימת קבצים להעתקה

```
pages/api/lib/supabase-admin.js
pages/api/plans.js
pages/api/checkout.js
pages/api/subscription.js
pages/api/webhook/greeninvoice.js
scripts/test-payment-e2e.js
```

ועוד — להריץ את ה-SQL מסעיף 2 על Supabase חדש, להגדיר את משתני הסביבה מסעיף 3, ולבנות את שני ה-Make scenarios מסעיף 5.

---

## 9. החלפות אפשריות

- **Grow → Tranzila / CardCom / PayPlus** — כל הזרימה זהה, רק התרחישים ב-Make משתנים. ה-API שלנו לא יודע איזה ספק תשלומים יש.
- **Make.com → n8n / Zapier** — אותו דבר. זה רק glue.
- **Morning → Hashavshevet / iCount** — שינוי רק ב-`createInvoice()` ב-webhook.
- **Supabase → Postgres ישיר** — להחליף את `getAdminSupabase()` ב-pg client. הסכמה זהה.

הארכיטקטורה (`pending_purchases` + `webhook` + `idempotency` + `lazy expiry`) — נשארת זהה לכל ספק.
