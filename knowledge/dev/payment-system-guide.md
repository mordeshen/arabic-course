# מערכת תשלומים - מדריך מימוש מלא

> מדריך גנרי וגמיש למימוש מערכת תשלומים מלאה בפרויקטים מבוססי Next.js + Supabase.
> כולל אינטגרציה עם Grow (סליקה), Make.com (אוטומציה) ו-Green Invoice (חשבוניות).

---

## תוכן עניינים

1. [ארכיטקטורה כללית](#ארכיטקטורה-כללית)
2. [סכמת בסיס נתונים (Supabase)](#סכמת-בסיס-נתונים-supabase)
3. [API Endpoints](#api-endpoints)
4. [אינטגרציית Make.com](#אינטגרציית-makecom)
5. [לוגיקת Feature Gating](#לוגיקת-feature-gating)
6. [ניהול טוקנים](#ניהול-טוקנים)
7. [דוגמה למדרגות מחירים](#דוגמה-למדרגות-מחירים)
8. [מדריך צעד אחר צעד לפרויקט חדש](#מדריך-צעד-אחר-צעד-לפרויקט-חדש)
9. [אבטחה ושיקולים](#אבטחה-ושיקולים)

---

## ארכיטקטורה כללית

### תרשים זרימה

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Frontend   │────>│  POST        │────>│  Make.com    │────>│  Grow        │
│  (לחיצה על  │     │  /api/       │     │  Scenario    │     │  (סליקה)     │
│   "רכוש")   │     │  checkout    │     │              │     │              │
└─────────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                      │
                           המשתמש משלם ב-Grow                         │
                                                                      │
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────┴───────┐
│  Supabase   │<────│  POST        │<────│  Make.com    │<────│  Grow        │
│  (עדכון     │     │  /api/       │     │  (קבלת      │     │  (אישור     │
│   מנוי)     │     │  webhook/    │     │   אישור)    │     │   תשלום)    │
└─────────────┘     │  greeninvoice│     └──────┬───────┘     └──────────────┘
                    └──────────────┘            │
                                                │
                                         ┌──────┴───────┐
                                         │ Green Invoice │
                                         │ (חשבונית)    │
                                         └──────────────┘
```

### הזרימה בפשטות

1. **המשתמש לוחץ "רכוש"** - הפרונטאנד שולח בקשה ל-`/api/checkout`
2. **נוצרת רכישה ממתינה** - נשמרת בטבלת `pending_purchases` (לצורך idempotency)
3. **Make.com מקבל את הבקשה** - יוצר לינק תשלום ב-Grow ומחזיר אותו
4. **המשתמש משלם** - דרך דף התשלום של Grow
5. **Grow מודיע ל-Make.com** - שהתשלום הצליח
6. **Make.com מפעיל שני דברים**:
   - שולח webhook לשרת שלנו (עדכון מנוי + טוקנים)
   - יוצר חשבונית ב-Green Invoice
7. **המנוי מתעדכן** - המשתמש מקבל גישה מיידית

---

## סכמת בסיס נתונים (Supabase)

### טבלה 1: `subscription_plans` - קטלוג תוכניות

קטלוג של כל התוכניות הזמינות. זו טבלת reference שבדרך כלל מעדכנים ידנית או דרך ממשק ניהול.

```sql
CREATE TABLE subscription_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,                          -- שם התוכנית, לדוגמה: "מנוי חודשי"
  slug TEXT UNIQUE NOT NULL,                   -- מזהה ייחודי לקוד, לדוגמה: "monthly"
  price DECIMAL(10,2) NOT NULL DEFAULT 0,      -- מחיר בשקלים
  token_limit INTEGER NOT NULL DEFAULT 0,      -- מכסת טוקנים חודשית (0 = ללא הגבלה)
  daily_messages INTEGER NOT NULL DEFAULT 0,   -- מכסת הודעות יומית (0 = ללא הגבלה)
  model TEXT DEFAULT 'gpt-4o-mini',            -- מודל AI שזמין לתוכנית
  features JSONB DEFAULT '[]'::jsonb,          -- רשימת פיצ'רים, לדוגמה: ["chat","search","export"]
  duration_days INTEGER DEFAULT 30,            -- משך התוכנית בימים
  is_active BOOLEAN DEFAULT true,              -- האם התוכנית זמינה לרכישה
  sort_order INTEGER DEFAULT 0,                -- סדר תצוגה בדף המחירים
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- אינדקסים
CREATE INDEX idx_plans_active ON subscription_plans(is_active);
CREATE INDEX idx_plans_slug ON subscription_plans(slug);

-- דוגמת הכנסת נתונים
INSERT INTO subscription_plans (name, slug, price, token_limit, daily_messages, model, features, duration_days, sort_order) VALUES
  ('חינם', 'free', 0, 1000, 5, 'gpt-4o-mini', '["chat"]', 0, 0),
  ('סטארטר', 'starter', 29.90, 10000, 30, 'gpt-4o-mini', '["chat","search"]', 30, 1),
  ('חודשי', 'monthly', 49.90, 50000, 100, 'gpt-4o', '["chat","search","export"]', 30, 2),
  ('פרימיום', 'premium', 99.90, 0, 0, 'gpt-4o', '["chat","search","export","api","priority"]', 30, 3);
```

### טבלה 2: `user_subscriptions` - מנויים פעילים

מנוי אחד פעיל לכל משתמש. זו הטבלה המרכזית שנבדקת בכל בקשה.

```sql
CREATE TABLE user_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'cancelled', 'expired', 'paused')),
  token_balance INTEGER NOT NULL DEFAULT 0,    -- יתרת טוקנים נוכחית
  daily_tokens_used INTEGER NOT NULL DEFAULT 0, -- שימוש יומי (מתאפס כל יום)
  daily_reset_at TIMESTAMPTZ DEFAULT now() + INTERVAL '1 day', -- מתי מתאפס השימוש היומי
  started_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ,                      -- null = לא פג תוקף (חינם)
  cancelled_at TIMESTAMPTZ,                    -- מתי בוטל (null = לא בוטל)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- מנוי פעיל אחד לכל משתמש
CREATE UNIQUE INDEX idx_user_active_sub ON user_subscriptions(user_id)
  WHERE status = 'active';

-- אינדקסים נוספים
CREATE INDEX idx_subs_user ON user_subscriptions(user_id);
CREATE INDEX idx_subs_status ON user_subscriptions(status);
CREATE INDEX idx_subs_expires ON user_subscriptions(expires_at)
  WHERE status = 'active';

-- RLS (Row Level Security) - המשתמש רואה רק את המנוי שלו
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription"
  ON user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- רק service_role יכול לעדכן (דרך ה-API)
CREATE POLICY "Service role can manage subscriptions"
  ON user_subscriptions FOR ALL
  USING (auth.role() = 'service_role');
```

### טבלה 3: `pending_purchases` - רכישות בתהליך

טבלה קריטית ל-idempotency - מונעת כפל חיובים ומאפשרת מעקב אחרי רכישות.

```sql
CREATE TABLE pending_purchases (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  amount DECIMAL(10,2) NOT NULL,               -- הסכום שנשלח לתשלום
  payment_ref TEXT,                             -- מזהה מ-Grow / מערכת הסליקה
  grow_payment_id TEXT,                         -- מזהה עסקה ב-Grow
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'fulfilled', 'failed', 'expired')),
  metadata JSONB DEFAULT '{}'::jsonb,          -- מידע נוסף (IP, user agent וכו')
  fulfilled_at TIMESTAMPTZ,                    -- מתי בוצע בפועל
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- אינדקסים
CREATE INDEX idx_purchases_user ON pending_purchases(user_id);
CREATE INDEX idx_purchases_status ON pending_purchases(status);
CREATE INDEX idx_purchases_ref ON pending_purchases(payment_ref);
CREATE INDEX idx_purchases_grow ON pending_purchases(grow_payment_id);

-- ניקוי רכישות ממתינות ישנות (אופציונלי - מריצים כ-cron)
-- UPDATE pending_purchases SET status = 'expired'
-- WHERE status = 'pending' AND created_at < now() - INTERVAL '24 hours';
```

### טבלה 4: `token_transactions` - יומן שימוש

לוג מלא של כל פעולה על טוקנים - חיוני לדיבאג, ניתוח ותמיכה.

```sql
CREATE TABLE token_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL
    CHECK (type IN ('usage', 'purchase', 'bonus', 'refund', 'daily_reset', 'expiry')),
  amount INTEGER NOT NULL,                     -- חיובי = הוספה, שלילי = שימוש
  balance_after INTEGER NOT NULL,              -- יתרה אחרי הפעולה
  description TEXT,                            -- תיאור קצר, לדוגמה: "שאילת שאלה בצ'אט"
  metadata JSONB DEFAULT '{}'::jsonb,          -- מידע נוסף (model, endpoint, tokens_in, tokens_out)
  created_at TIMESTAMPTZ DEFAULT now()
);

-- אינדקסים
CREATE INDEX idx_transactions_user ON token_transactions(user_id);
CREATE INDEX idx_transactions_type ON token_transactions(type);
CREATE INDEX idx_transactions_created ON token_transactions(created_at);

-- RLS
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON token_transactions FOR SELECT
  USING (auth.uid() = user_id);
```

### פונקציות עזר ב-SQL

```sql
-- פונקציה לניכוי טוקנים (אטומית - מונעת race conditions)
CREATE OR REPLACE FUNCTION deduct_tokens(
  p_user_id UUID,
  p_amount INTEGER,
  p_description TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS TABLE(success BOOLEAN, new_balance INTEGER) AS $$
DECLARE
  v_balance INTEGER;
  v_new_balance INTEGER;
BEGIN
  -- נעילה על השורה למניעת race conditions
  SELECT token_balance INTO v_balance
  FROM user_subscriptions
  WHERE user_id = p_user_id AND status = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 0;
    RETURN;
  END IF;

  -- בדיקה שיש מספיק טוקנים (0 = ללא הגבלה)
  IF v_balance > 0 AND v_balance < p_amount THEN
    RETURN QUERY SELECT false, v_balance;
    RETURN;
  END IF;

  -- ניכוי (אם 0 = ללא הגבלה, לא מנכים)
  IF v_balance = 0 THEN
    v_new_balance := 0;
  ELSE
    v_new_balance := v_balance - p_amount;
  END IF;

  -- עדכון היתרה
  UPDATE user_subscriptions
  SET token_balance = v_new_balance,
      daily_tokens_used = daily_tokens_used + p_amount,
      updated_at = now()
  WHERE user_id = p_user_id AND status = 'active';

  -- רישום בלוג
  INSERT INTO token_transactions (user_id, type, amount, balance_after, description, metadata)
  VALUES (p_user_id, 'usage', -p_amount, v_new_balance, p_description, p_metadata);

  RETURN QUERY SELECT true, v_new_balance;
END;
$$ LANGUAGE plpgsql;

-- פונקציה לאיפוס יומי
CREATE OR REPLACE FUNCTION reset_daily_tokens() RETURNS void AS $$
BEGIN
  UPDATE user_subscriptions
  SET daily_tokens_used = 0,
      daily_reset_at = now() + INTERVAL '1 day',
      updated_at = now()
  WHERE status = 'active'
    AND daily_reset_at <= now();
END;
$$ LANGUAGE plpgsql;

-- פונקציה לסימון מנויים שפג תוקפם
CREATE OR REPLACE FUNCTION expire_subscriptions() RETURNS void AS $$
BEGIN
  UPDATE user_subscriptions
  SET status = 'expired',
      updated_at = now()
  WHERE status = 'active'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
END;
$$ LANGUAGE plpgsql;
```

---

## API Endpoints

### 1. `POST /api/checkout` - יצירת רכישה

יוצר רכישה ממתינה ומחזיר לינק תשלום מ-Grow (דרך Make.com).

```javascript
// /app/api/checkout/route.js (Next.js App Router)

import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth'; // או כל מנגנון auth אחר

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY // service role - לא anon!
);

export async function POST(request) {
  try {
    // 1. אימות המשתמש
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: 'לא מחובר' }, { status: 401 });
    }

    const { planSlug } = await request.json();

    // 2. שליפת התוכנית
    const { data: plan, error: planError } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('slug', planSlug)
      .eq('is_active', true)
      .single();

    if (planError || !plan) {
      return NextResponse.json({ error: 'תוכנית לא נמצאה' }, { status: 404 });
    }

    // 3. בדיקה שאין רכישה ממתינה לאותה תוכנית (idempotency)
    const { data: existingPurchase } = await supabase
      .from('pending_purchases')
      .select('*')
      .eq('user_id', session.user.id)
      .eq('plan_id', plan.id)
      .eq('status', 'pending')
      .gte('created_at', new Date(Date.now() - 30 * 60 * 1000).toISOString()) // 30 דקות אחרונות
      .single();

    if (existingPurchase) {
      // מחזירים את הרכישה הקיימת במקום ליצור חדשה
      // אם יש כבר לינק - מחזירים אותו
      if (existingPurchase.metadata?.payment_url) {
        return NextResponse.json({
          purchaseId: existingPurchase.id,
          paymentUrl: existingPurchase.metadata.payment_url
        });
      }
    }

    // 4. יצירת רכישה ממתינה
    const { data: purchase, error: purchaseError } = await supabase
      .from('pending_purchases')
      .insert({
        user_id: session.user.id,
        plan_id: plan.id,
        amount: plan.price,
        metadata: {
          plan_name: plan.name,
          user_email: session.user.email,
          ip: request.headers.get('x-forwarded-for') || 'unknown'
        }
      })
      .select()
      .single();

    if (purchaseError) {
      console.error('Error creating purchase:', purchaseError);
      return NextResponse.json({ error: 'שגיאה ביצירת רכישה' }, { status: 500 });
    }

    // 5. שליחה ל-Make.com לקבלת לינק תשלום מ-Grow
    const makeResponse = await fetch(process.env.MAKE_WEBHOOK_CHECKOUT_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        purchaseId: purchase.id,
        amount: plan.price,
        description: `${plan.name} - מנוי`,
        customerEmail: session.user.email,
        customerName: session.user.name || '',
        successUrl: `${process.env.NEXT_PUBLIC_APP_URL}/payment/success?purchaseId=${purchase.id}`,
        cancelUrl: `${process.env.NEXT_PUBLIC_APP_URL}/payment/cancel`,
        webhookUrl: `${process.env.NEXT_PUBLIC_APP_URL}/api/webhook/payment`
      })
    });

    const makeData = await makeResponse.json();

    // 6. שמירת לינק התשלום ברכישה
    if (makeData.paymentUrl) {
      await supabase
        .from('pending_purchases')
        .update({
          metadata: { ...purchase.metadata, payment_url: makeData.paymentUrl },
          grow_payment_id: makeData.growPaymentId || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', purchase.id);
    }

    // 7. החזרת לינק התשלום ללקוח
    return NextResponse.json({
      purchaseId: purchase.id,
      paymentUrl: makeData.paymentUrl
    });

  } catch (error) {
    console.error('Checkout error:', error);
    return NextResponse.json({ error: 'שגיאה בתהליך הרכישה' }, { status: 500 });
  }
}
```

### 2. `POST /api/webhook/payment` - קבלת אישור תשלום

נקודת הקצה שמקבלת הודעה מ-Make.com כשהתשלום הצליח.

```javascript
// /app/api/webhook/payment/route.js

import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

export async function POST(request) {
  try {
    // 1. אימות ה-webhook (ראה חלק אבטחה)
    const webhookSecret = request.headers.get('x-webhook-secret');
    if (webhookSecret !== process.env.WEBHOOK_SECRET) {
      console.warn('Invalid webhook secret');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const {
      purchaseId,
      paymentRef,        // מזהה עסקה מ-Grow
      status,            // 'success' | 'failed'
      amount,
      customerEmail,
      invoiceUrl         // לינק לחשבונית מ-Green Invoice (אם כבר נוצרה)
    } = body;

    // 2. שליפת הרכישה הממתינה
    const { data: purchase, error: purchaseError } = await supabase
      .from('pending_purchases')
      .select('*, subscription_plans(*)')
      .eq('id', purchaseId)
      .single();

    if (purchaseError || !purchase) {
      console.error('Purchase not found:', purchaseId);
      return NextResponse.json({ error: 'רכישה לא נמצאה' }, { status: 404 });
    }

    // 3. בדיקת idempotency - אם כבר טופל, מחזירים הצלחה
    if (purchase.status === 'fulfilled') {
      return NextResponse.json({ message: 'כבר טופל', alreadyProcessed: true });
    }

    // 4. טיפול בתשלום שנכשל
    if (status === 'failed') {
      await supabase
        .from('pending_purchases')
        .update({
          status: 'failed',
          payment_ref: paymentRef,
          updated_at: new Date().toISOString()
        })
        .eq('id', purchaseId);

      return NextResponse.json({ message: 'רכישה סומנה ככשלון' });
    }

    // 5. אימות הסכום
    if (parseFloat(amount) !== parseFloat(purchase.amount)) {
      console.error('Amount mismatch:', { expected: purchase.amount, received: amount });
      await supabase
        .from('pending_purchases')
        .update({
          status: 'failed',
          metadata: { ...purchase.metadata, error: 'amount_mismatch' },
          updated_at: new Date().toISOString()
        })
        .eq('id', purchaseId);

      return NextResponse.json({ error: 'סכום לא תואם' }, { status: 400 });
    }

    const plan = purchase.subscription_plans;

    // 6. ביטול מנוי קודם (אם קיים)
    await supabase
      .from('user_subscriptions')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('user_id', purchase.user_id)
      .eq('status', 'active');

    // 7. יצירת מנוי חדש
    const expiresAt = plan.duration_days > 0
      ? new Date(Date.now() + plan.duration_days * 24 * 60 * 60 * 1000).toISOString()
      : null;

    const { data: subscription, error: subError } = await supabase
      .from('user_subscriptions')
      .insert({
        user_id: purchase.user_id,
        plan_id: plan.id,
        status: 'active',
        token_balance: plan.token_limit,
        daily_tokens_used: 0,
        daily_reset_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        expires_at: expiresAt
      })
      .select()
      .single();

    if (subError) {
      console.error('Error creating subscription:', subError);
      return NextResponse.json({ error: 'שגיאה ביצירת מנוי' }, { status: 500 });
    }

    // 8. רישום עסקת טוקנים
    await supabase
      .from('token_transactions')
      .insert({
        user_id: purchase.user_id,
        type: 'purchase',
        amount: plan.token_limit,
        balance_after: plan.token_limit,
        description: `רכישת תוכנית ${plan.name}`,
        metadata: {
          plan_slug: plan.slug,
          purchase_id: purchaseId,
          payment_ref: paymentRef
        }
      });

    // 9. סימון הרכישה כמבוצעת
    await supabase
      .from('pending_purchases')
      .update({
        status: 'fulfilled',
        payment_ref: paymentRef,
        fulfilled_at: new Date().toISOString(),
        metadata: {
          ...purchase.metadata,
          invoice_url: invoiceUrl || null,
          subscription_id: subscription.id
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', purchaseId);

    return NextResponse.json({
      message: 'מנוי הופעל בהצלחה',
      subscriptionId: subscription.id
    });

  } catch (error) {
    console.error('Webhook error:', error);
    return NextResponse.json({ error: 'שגיאה בעיבוד' }, { status: 500 });
  }
}
```

### 3. `GET /api/subscription` - בדיקת מנוי נוכחי

```javascript
// /app/api/subscription/route.js

import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

export async function GET() {
  try {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: 'לא מחובר' }, { status: 401 });
    }

    // שליפת מנוי פעיל עם פרטי התוכנית
    const { data: subscription, error } = await supabase
      .from('user_subscriptions')
      .select(`
        *,
        subscription_plans (
          name, slug, price, token_limit, daily_messages, model, features
        )
      `)
      .eq('user_id', session.user.id)
      .eq('status', 'active')
      .single();

    if (error || !subscription) {
      // אין מנוי - מחזירים את התוכנית החינמית
      const { data: freePlan } = await supabase
        .from('subscription_plans')
        .select('*')
        .eq('slug', 'free')
        .single();

      return NextResponse.json({
        hasSubscription: false,
        plan: freePlan || null,
        tokenBalance: 0,
        dailyTokensUsed: 0
      });
    }

    // בדיקה אם צריך איפוס יומי
    if (new Date(subscription.daily_reset_at) <= new Date()) {
      await supabase
        .from('user_subscriptions')
        .update({
          daily_tokens_used: 0,
          daily_reset_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', subscription.id);

      subscription.daily_tokens_used = 0;
    }

    return NextResponse.json({
      hasSubscription: true,
      plan: subscription.subscription_plans,
      status: subscription.status,
      tokenBalance: subscription.token_balance,
      dailyTokensUsed: subscription.daily_tokens_used,
      dailyMessages: subscription.subscription_plans.daily_messages,
      expiresAt: subscription.expires_at,
      startedAt: subscription.started_at
    });

  } catch (error) {
    console.error('Subscription check error:', error);
    return NextResponse.json({ error: 'שגיאה' }, { status: 500 });
  }
}
```

### 4. `GET /api/plans` - רשימת תוכניות

```javascript
// /app/api/plans/route.js

import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY // כאן אפשר anon key - מידע פומבי
);

export async function GET() {
  try {
    const { data: plans, error } = await supabase
      .from('subscription_plans')
      .select('id, name, slug, price, token_limit, daily_messages, model, features, sort_order')
      .eq('is_active', true)
      .order('sort_order', { ascending: true });

    if (error) {
      return NextResponse.json({ error: 'שגיאה בשליפת תוכניות' }, { status: 500 });
    }

    return NextResponse.json({ plans });

  } catch (error) {
    console.error('Plans error:', error);
    return NextResponse.json({ error: 'שגיאה' }, { status: 500 });
  }
}
```

---

## אינטגרציית Make.com

### סצנריו 1: יצירת לינק תשלום (Checkout)

```
Trigger: Webhook (Custom webhook)
  ↓
Step 1: HTTP Request → Grow API
  - Method: POST
  - URL: https://api.grow.link/v1/payments  (או URL דומה לפי התיעוד של Grow)
  - Body:
    {
      "amount": {{body.amount}},
      "description": {{body.description}},
      "customer_email": {{body.customerEmail}},
      "success_url": {{body.successUrl}},
      "cancel_url": {{body.cancelUrl}},
      "webhook_url": "https://hook.eu2.make.com/YOUR_PAYMENT_COMPLETE_WEBHOOK",
      "metadata": {
        "purchaseId": {{body.purchaseId}}
      }
    }
  ↓
Step 2: Webhook Response
  - Return: { "paymentUrl": {{step1.payment_url}}, "growPaymentId": {{step1.id}} }
```

### סצנריו 2: אישור תשלום (Payment Complete)

```
Trigger: Webhook (מ-Grow - כש-Grow מודיע שהתשלום הצליח)
  ↓
Step 1: HTTP Request → הפרויקט שלנו
  - Method: POST
  - URL: {{YOUR_APP_URL}}/api/webhook/payment
  - Headers: { "x-webhook-secret": "YOUR_SECRET" }
  - Body:
    {
      "purchaseId": {{body.metadata.purchaseId}},
      "paymentRef": {{body.transaction_id}},
      "status": "success",
      "amount": {{body.amount}},
      "customerEmail": {{body.customer_email}}
    }
  ↓
Step 2: HTTP Request → Green Invoice API
  - Method: POST
  - URL: https://api.greeninvoice.co.il/api/v1/documents
  - Headers: { "Authorization": "Bearer YOUR_TOKEN" }
  - Body:
    {
      "type": 320,              // חשבונית מס / קבלה
      "client": {
        "name": {{body.customer_name}},
        "emails": [{{body.customer_email}}]
      },
      "income": [{
        "description": "מנוי - {{body.description}}",
        "quantity": 1,
        "price": {{body.amount}},
        "currency": "ILS",
        "vatType": 1
      }],
      "remarks": "מזהה עסקה: {{body.transaction_id}}"
    }
  ↓
Step 3: (אופציונלי) HTTP Request → עדכון הרכישה עם לינק החשבונית
  - Method: PATCH
  - URL: Supabase REST API - pending_purchases
```

### הגדרות Make.com

**טיפים חשובים:**
- הגדירו **Error Handler** בכל סצנריו - אם שלב נכשל, לשלוח התראה (Slack/Email)
- הגדירו **Retry** על שלבי HTTP - לפחות 3 ניסיונות
- שמרו את כל ה-secrets ב-**Data stores** או **Variables** של Make.com
- הפעילו **Logging** לצורך דיבאג

---

## לוגיקת Feature Gating

### פונקציית בדיקת גישה

```javascript
// /lib/access-control.js

import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// הגדרת מה זמין בחינם
const FREE_FEATURES = ['chat'];
const FREE_DAILY_MESSAGES = 5;
const FREE_TOKEN_LIMIT = 1000;

/**
 * בדיקה האם למשתמש יש גישה לפיצ'ר מסוים
 */
export async function canAccess(userId, feature) {
  const sub = await getUserSubscription(userId);

  // אם אין מנוי - בדיקת גישה חינמית
  if (!sub) {
    return {
      allowed: FREE_FEATURES.includes(feature),
      reason: FREE_FEATURES.includes(feature) ? 'free_access' : 'no_subscription',
      plan: 'free'
    };
  }

  // בדיקה שהפיצ'ר כלול בתוכנית
  const features = sub.subscription_plans.features || [];
  if (!features.includes(feature)) {
    return {
      allowed: false,
      reason: 'feature_not_included',
      plan: sub.subscription_plans.slug,
      availableIn: await getPlansWithFeature(feature)
    };
  }

  // בדיקת מכסת הודעות יומית
  const dailyLimit = sub.subscription_plans.daily_messages;
  if (dailyLimit > 0 && sub.daily_tokens_used >= dailyLimit) {
    return {
      allowed: false,
      reason: 'daily_limit_reached',
      plan: sub.subscription_plans.slug,
      resetAt: sub.daily_reset_at
    };
  }

  // בדיקת טוקנים
  const tokenLimit = sub.subscription_plans.token_limit;
  if (tokenLimit > 0 && sub.token_balance <= 0) {
    return {
      allowed: false,
      reason: 'no_tokens',
      plan: sub.subscription_plans.slug
    };
  }

  return {
    allowed: true,
    reason: 'authorized',
    plan: sub.subscription_plans.slug,
    model: sub.subscription_plans.model,
    tokenBalance: sub.token_balance
  };
}

/**
 * שליפת מנוי פעיל של משתמש
 */
async function getUserSubscription(userId) {
  const { data, error } = await supabase
    .from('user_subscriptions')
    .select(`
      *,
      subscription_plans (*)
    `)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

  if (error) return null;
  return data;
}

/**
 * איזה תוכניות כוללות את הפיצ'ר
 */
async function getPlansWithFeature(feature) {
  const { data } = await supabase
    .from('subscription_plans')
    .select('name, slug, price')
    .eq('is_active', true)
    .contains('features', [feature])
    .order('price');

  return data || [];
}

/**
 * Middleware לשימוש ב-API routes
 */
export function withAccessControl(feature) {
  return async function middleware(request, context) {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: 'לא מחובר' }, { status: 401 });
    }

    const access = await canAccess(session.user.id, feature);
    if (!access.allowed) {
      return NextResponse.json({
        error: 'אין גישה',
        ...access
      }, { status: 403 });
    }

    // מוסיפים את פרטי הגישה ל-request
    request.access = access;
    return null; // null = ממשיכים לטיפול ב-route
  };
}
```

### שימוש ב-Middleware

```javascript
// /app/api/chat/route.js

import { withAccessControl, canAccess } from '@/lib/access-control';
import { deductTokens } from '@/lib/token-management';

export async function POST(request) {
  // בדיקת גישה
  const accessResult = await withAccessControl('chat')(request);
  if (accessResult) return accessResult; // מחזיר 401/403 אם אין גישה

  const { message } = await request.json();
  const access = request.access;

  // שימוש במודל שמתאים לתוכנית
  const response = await callAI({
    model: access.model, // 'gpt-4o-mini' או 'gpt-4o' לפי התוכנית
    message
  });

  // ניכוי טוקנים
  const tokensUsed = response.usage.total_tokens;
  await deductTokens(session.user.id, tokensUsed, 'שאילת שאלה בצ\'אט');

  return NextResponse.json({ response: response.content });
}
```

---

## ניהול טוקנים

### מודול ניהול טוקנים

```javascript
// /lib/token-management.js

import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

/**
 * ניכוי טוקנים מהמנוי של המשתמש
 * משתמש בפונקציית SQL אטומית למניעת race conditions
 */
export async function deductTokens(userId, amount, description = null, metadata = {}) {
  const { data, error } = await supabase
    .rpc('deduct_tokens', {
      p_user_id: userId,
      p_amount: amount,
      p_description: description,
      p_metadata: metadata
    });

  if (error) {
    console.error('Token deduction error:', error);
    throw new Error('שגיאה בניכוי טוקנים');
  }

  const result = data[0];

  if (!result.success) {
    throw new Error('אין מספיק טוקנים');
  }

  return {
    success: true,
    newBalance: result.new_balance,
    deducted: amount
  };
}

/**
 * הוספת טוקנים (רכישה / בונוס / החזר)
 */
export async function addTokens(userId, amount, type = 'purchase', description = null, metadata = {}) {
  // שליפת יתרה נוכחית
  const { data: sub, error: subError } = await supabase
    .from('user_subscriptions')
    .select('id, token_balance')
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

  if (subError || !sub) {
    throw new Error('מנוי לא נמצא');
  }

  const newBalance = sub.token_balance + amount;

  // עדכון היתרה
  const { error: updateError } = await supabase
    .from('user_subscriptions')
    .update({
      token_balance: newBalance,
      updated_at: new Date().toISOString()
    })
    .eq('id', sub.id);

  if (updateError) {
    throw new Error('שגיאה בעדכון טוקנים');
  }

  // רישום בלוג
  await supabase
    .from('token_transactions')
    .insert({
      user_id: userId,
      type,
      amount,
      balance_after: newBalance,
      description,
      metadata
    });

  return { success: true, newBalance };
}

/**
 * שליפת היסטוריית שימוש
 */
export async function getTokenHistory(userId, limit = 50) {
  const { data, error } = await supabase
    .from('token_transactions')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);

  return data || [];
}

/**
 * סיכום שימוש חודשי
 */
export async function getMonthlyUsage(userId) {
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const { data, error } = await supabase
    .from('token_transactions')
    .select('amount, type')
    .eq('user_id', userId)
    .eq('type', 'usage')
    .gte('created_at', startOfMonth.toISOString());

  const totalUsed = (data || []).reduce((sum, t) => sum + Math.abs(t.amount), 0);

  return { totalUsed, transactionCount: data?.length || 0 };
}
```

### איפוס יומי (Cron Job)

ב-Supabase אפשר להגדיר cron job באמצעות `pg_cron`:

```sql
-- הפעלת pg_cron (ב-Supabase Dashboard → SQL Editor)
SELECT cron.schedule(
  'reset-daily-tokens',          -- שם ה-job
  '0 0 * * *',                   -- כל יום בחצות
  $$ SELECT reset_daily_tokens() $$
);

-- סימון מנויים שפג תוקפם
SELECT cron.schedule(
  'expire-subscriptions',
  '*/15 * * * *',                -- כל 15 דקות
  $$ SELECT expire_subscriptions() $$
);
```

לחלופין, אפשר להריץ את זה כ-Edge Function של Supabase שמופעלת דרך cron.

---

## דוגמה למדרגות מחירים

### תצוגה בפרונטאנד

| | חינם | סטארטר | חודשי | פרימיום |
|---|---|---|---|---|
| **מחיר** | 0 ש"ח | 29.90 ש"ח/חודש | 49.90 ש"ח/חודש | 99.90 ש"ח/חודש |
| **טוקנים** | 1,000 | 10,000 | 50,000 | ללא הגבלה |
| **הודעות ביום** | 5 | 30 | 100 | ללא הגבלה |
| **מודל AI** | GPT-4o Mini | GPT-4o Mini | GPT-4o | GPT-4o |
| **צ'אט** | V | V | V | V |
| **חיפוש** | X | V | V | V |
| **ייצוא** | X | X | V | V |
| **גישת API** | X | X | X | V |
| **עדיפות** | X | X | X | V |

### קומפוננטת מחירים (React)

```jsx
// /components/PricingTable.jsx

'use client';

import { useState, useEffect } from 'react';

export default function PricingTable() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(false);
  const [currentPlan, setCurrentPlan] = useState(null);

  useEffect(() => {
    fetch('/api/plans').then(r => r.json()).then(d => setPlans(d.plans));
    fetch('/api/subscription').then(r => r.json()).then(d => setCurrentPlan(d.plan?.slug));
  }, []);

  async function handleCheckout(planSlug) {
    setLoading(true);
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ planSlug })
      });
      const data = await res.json();

      if (data.paymentUrl) {
        window.location.href = data.paymentUrl; // מעבר לדף תשלום של Grow
      }
    } catch (err) {
      alert('שגיאה בתהליך הרכישה');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-6 p-6" dir="rtl">
      {plans.map(plan => (
        <div key={plan.id} className="border rounded-lg p-6 text-center">
          <h3 className="text-xl font-bold">{plan.name}</h3>
          <p className="text-3xl font-bold my-4">
            {plan.price === 0 ? 'חינם' : `${plan.price} ש"ח`}
            {plan.price > 0 && <span className="text-sm">/חודש</span>}
          </p>
          <ul className="text-right space-y-2 mb-6">
            <li>טוקנים: {plan.token_limit === 0 ? 'ללא הגבלה' : plan.token_limit.toLocaleString()}</li>
            <li>הודעות ביום: {plan.daily_messages === 0 ? 'ללא הגבלה' : plan.daily_messages}</li>
            <li>מודל: {plan.model}</li>
          </ul>
          <button
            onClick={() => handleCheckout(plan.slug)}
            disabled={loading || currentPlan === plan.slug}
            className="w-full py-2 px-4 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
          >
            {currentPlan === plan.slug ? 'התוכנית הנוכחית' : plan.price === 0 ? 'התחל בחינם' : 'רכוש עכשיו'}
          </button>
        </div>
      ))}
    </div>
  );
}
```

---

## מדריך צעד אחר צעד לפרויקט חדש

### שלב 1: הגדרת Supabase

1. צרו פרויקט חדש ב-[supabase.com](https://supabase.com)
2. העתיקו את כל ה-SQL מהסעיף "סכמת בסיס נתונים" למעלה ל-SQL Editor
3. הריצו את ה-SQL ליצירת הטבלאות, הפונקציות וה-RLS
4. שמרו את ה-URL ואת ה-keys:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`

### שלב 2: הגדרת Make.com

1. צרו חשבון ב-[make.com](https://make.com)
2. צרו **סצנריו ראשון** - Checkout:
   - Trigger: **Webhooks → Custom Webhook** (שמרו את ה-URL)
   - Module: **HTTP → Make a request** (לקריאה ל-Grow API)
   - Module: **Webhooks → Webhook Response** (להחזרת הלינק)
3. צרו **סצנריו שני** - Payment Complete:
   - Trigger: **Webhooks → Custom Webhook** (זה מה ש-Grow יקרא)
   - Module: **HTTP → Make a request** (קריאה ל-API שלנו)
   - Module: **HTTP → Make a request** (יצירת חשבונית ב-Green Invoice)
4. שמרו את ה-URLs:
   - `MAKE_WEBHOOK_CHECKOUT_URL` - URL של הסצנריו הראשון

### שלב 3: הגדרת חשבון Grow

1. פתחו חשבון ב-[grow.link](https://grow.link) (או ספק סליקה ישראלי אחר)
2. הגדירו **webhook URL** שמצביע על הסצנריו השני ב-Make.com
3. שמרו את ה-API Key:
   - `GROW_API_KEY`

### שלב 4: מימוש API Endpoints

1. צרו את הקבצים הבאים בפרויקט Next.js:
   ```
   /app/api/checkout/route.js
   /app/api/webhook/payment/route.js
   /app/api/subscription/route.js
   /app/api/plans/route.js
   ```
2. העתיקו את הקוד מהסעיף "API Endpoints" למעלה
3. צרו את מודולי העזר:
   ```
   /lib/access-control.js
   /lib/token-management.js
   ```

### שלב 5: אינטגרציית Green Invoice

1. פתחו חשבון ב-[greeninvoice.co.il](https://www.greeninvoice.co.il)
2. הנפיקו API Key ב-Settings → API
3. הוסיפו את ה-Key לסצנריו השני ב-Make.com
4. הגדירו:
   - `GREEN_INVOICE_API_KEY`
   - `GREEN_INVOICE_API_SECRET`

### שלב 6: פרונטאנד

1. צרו דף מחירים עם קומפוננטת `PricingTable`
2. צרו דפי redirect:
   ```
   /app/payment/success/page.jsx  - דף הצלחה אחרי תשלום
   /app/payment/cancel/page.jsx   - דף ביטול
   ```
3. הוסיפו תצוגת מנוי נוכחי בפרופיל המשתמש
4. הוסיפו תצוגת שימוש טוקנים (progress bar)

### שלב 7: בדיקת הזרימה המלאה

1. **בדיקת checkout**: לחיצה על "רכוש" → בדיקה שנוצרת רשומת pending_purchases → בדיקה שחוזר לינק תשלום
2. **בדיקת תשלום**: שלמו עם כרטיס בדיקה ב-Grow → בדיקה שה-webhook מגיע → בדיקה שהמנוי נוצר
3. **בדיקת טוקנים**: השתמשו בפיצ'ר → בדיקה שטוקנים ירדו → בדיקה שנוצרה רשומה ב-token_transactions
4. **בדיקת חשבונית**: בדיקה שנוצרה חשבונית ב-Green Invoice
5. **בדיקת idempotency**: שלחו את אותו webhook פעמיים → בדיקה שהמנוי לא נכפל
6. **בדיקת תפוגה**: שנו expires_at לעבר → בדיקה שהמנוי מסומן כ-expired

---

## אבטחה ושיקולים

### 1. אימות Webhook

**לעולם אל תסמכו על webhook ללא אימות!**

```javascript
// שיטה 1: Shared Secret (פשוט)
function verifyWebhook(request) {
  const secret = request.headers.get('x-webhook-secret');
  return secret === process.env.WEBHOOK_SECRET;
}

// שיטה 2: HMAC Signature (מאובטח יותר)
import crypto from 'crypto';

function verifyWebhookHMAC(request, body) {
  const signature = request.headers.get('x-signature');
  const expected = crypto
    .createHmac('sha256', process.env.WEBHOOK_SIGNING_SECRET)
    .update(JSON.stringify(body))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature || ''),
    Buffer.from(expected)
  );
}

// שיטה 3: IP Whitelist (שכבה נוספת)
const ALLOWED_IPS = [
  '54.75.248.0/24',  // Make.com IPs - לבדוק בתיעוד שלהם
];

function isAllowedIP(request) {
  const ip = request.headers.get('x-forwarded-for')?.split(',')[0];
  return ALLOWED_IPS.some(range => isInRange(ip, range));
}
```

### 2. Idempotency - מניעת כפל חיובים

הלוגיקה כבר מובנית בקוד למעלה, אבל הנה הכללים:

```javascript
// עקרונות מפתח:
// 1. לפני יצירת checkout - בדיקה שאין pending purchase פעיל
// 2. ב-webhook - בדיקה שהרכישה לא כבר fulfilled
// 3. שימוש ב-UNIQUE INDEX למנוי פעיל אחד לכל משתמש
// 4. שימוש ב-payment_ref ייחודי מ-Grow

// בדיקה ב-webhook:
if (purchase.status === 'fulfilled') {
  // כבר טופל! מחזירים 200 בלי לעשות שום דבר
  return NextResponse.json({ message: 'already processed' });
}
```

### 3. Race Conditions בטוקנים

```javascript
// בעיה: שני בקשות מקבילות יכולות לקרוא את אותה יתרה
// ולנכות פחות ממה שצריך

// פתרון: שימוש בפונקציית SQL עם FOR UPDATE (כבר ממומש למעלה)
// הפונקציה deduct_tokens נועלת את השורה לפני הקריאה

// פתרון חלופי: אם לא רוצים SQL function
const { error } = await supabase.rpc('deduct_tokens', {
  p_user_id: userId,
  p_amount: tokensUsed
});

// פתרון פשוט יותר (פחות מאובטח אבל עובד לרוב):
// UPDATE user_subscriptions
// SET token_balance = token_balance - $1
// WHERE user_id = $2 AND token_balance >= $1
// RETURNING token_balance
// אם 0 שורות עודכנו = אין מספיק טוקנים
```

### 4. הגנה על Environment Variables

```env
# .env.local (לעולם לא לעלות ל-Git!)

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Make.com
MAKE_WEBHOOK_CHECKOUT_URL=https://hook.eu2.make.com/xxxxx

# Grow
GROW_API_KEY=gw_xxxxx

# Green Invoice
GREEN_INVOICE_API_KEY=xxxxx
GREEN_INVOICE_API_SECRET=xxxxx

# Webhook Security
WEBHOOK_SECRET=random-strong-secret-here
WEBHOOK_SIGNING_SECRET=another-random-secret

# App
NEXT_PUBLIC_APP_URL=https://your-domain.com
```

### 5. שיקולים נוספים

- **Rate Limiting**: הגבילו את מספר הקריאות ל-API (במיוחד checkout)
- **Logging**: רשמו כל webhook שמגיע, גם אם נכשל
- **Monitoring**: הגדירו התראות על:
  - webhook שנכשלים
  - רכישות pending שלא מתמלאות תוך שעה
  - מנויים שפג תוקפם ולא חודשו
- **Backup**: גבו את טבלת pending_purchases ו-token_transactions
- **GDPR**: אפשרו למשתמשים לייצא ולמחוק את הנתונים שלהם

---

## סיכום

מערכת התשלומים בנויה מ-4 שכבות עיקריות:

1. **סליקה (Grow)** - מטפלת בכרטיסי אשראי ותשלומים
2. **אוטומציה (Make.com)** - מתזמרת את הזרימה בין כל השירותים
3. **בסיס נתונים (Supabase)** - שומרת מנויים, טוקנים ולוגים
4. **חשבוניות (Green Invoice)** - מנפיקה חשבוניות מס

היתרונות של הארכיטקטורה הזו:
- **גמישות**: קל להחליף כל שכבה (למשל Grow ב-PayPlus, או Supabase ב-Firebase)
- **סקיילביליטי**: כל שכבה עצמאית ויכולה לגדול בנפרד
- **אמינות**: idempotency מובנה, לוגים מלאים, טיפול בשגיאות
- **פשטות**: Make.com חוסך כתיבת קוד רב לתזמור
