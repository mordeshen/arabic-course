-- ============================================================
-- Arabic Course — Payments Migration v1.0
-- Run this in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. course_plans — catalog of available plans
-- ============================================================
create table if not exists course_plans (
  id            text primary key,                       -- 'free' | 'part1' | 'part2' | 'part3' | 'full'
  name          text not null,
  price         integer not null,                       -- אגורות (1₪ = 100)
  parts         integer[] not null default '{}',        -- [1], [2], [1,2,3], [] לחינם
  duration_days integer,                                -- null = ללא תוקף (חינם), 180 = חצי שנה
  description   text,
  active        boolean default true,
  sort_order    integer default 0,                      -- לקביעת סדר תצוגה
  created_at    timestamptz default now()
);

-- Seed: המסלולים של הקורס
insert into course_plans (id, name, price, parts, duration_days, description, sort_order) values
  ('free',  'חינם',           0,    '{}'::integer[],   null, 'שיעורים 1-2 — אותיות וברכות', 0),
  ('part1', 'חלק 1',          2900, '{1}'::integer[],  180,  'שיעורים 3-6: היכרות, מספרים, משפחה, ביטויים', 1),
  ('part2', 'חלק 2',          3500, '{2}'::integer[],  180,  'שיעורים 7-12: שלילה, ברכות, פעלים, ציווי, אוכל', 2),
  ('part3', 'חלק 3',          3500, '{3}'::integer[],  180,  'שיעורים 13-18: סמיכות, רבים, שעות, סלנג, בניינים', 3),
  ('full',  'כל הקורס',       5900, '{1,2,3}'::integer[], 180, 'כל הקורס — חיסכון של 46₪!', 4)
on conflict (id) do update set
  name = excluded.name,
  price = excluded.price,
  parts = excluded.parts,
  duration_days = excluded.duration_days,
  description = excluded.description,
  sort_order = excluded.sort_order;

-- ============================================================
-- 2. pending_purchases — created at checkout, marked fulfilled at webhook
-- ============================================================
create table if not exists pending_purchases (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  email       text,
  plan_id     text references course_plans(id),
  amount      integer not null,                         -- אגורות
  fulfilled   boolean default false,
  fulfilled_at timestamptz,
  transaction_id text,                                  -- מ-Grow
  asmachta    text,                                     -- מ-Grow
  created_at  timestamptz default now()
);

create index if not exists idx_pending_user on pending_purchases (user_id);
create index if not exists idx_pending_fulfilled on pending_purchases (fulfilled, created_at);

-- ============================================================
-- 3. user_access — what each user owns
-- ============================================================
-- parts_owned format: [{"part": 1, "expires": "2026-10-07T00:00:00Z", "plan_id": "part1"}, ...]
create table if not exists user_access (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  parts_owned jsonb default '[]'::jsonb not null,
  updated_at  timestamptz default now()
);

-- ============================================================
-- 4. purchase_log — full audit trail
-- ============================================================
create table if not exists purchase_log (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  plan_id     text,
  amount      integer,
  type        text,                                     -- 'purchase' | 'expired' | 'refund' | 'manual_grant'
  description text,
  metadata    jsonb default '{}'::jsonb,
  created_at  timestamptz default now()
);

create index if not exists idx_log_user on purchase_log (user_id, created_at desc);

-- ============================================================
-- 5. RLS Policies — security against malicious B2C
-- ============================================================

-- course_plans: public read (אבל רק active)
alter table course_plans enable row level security;

drop policy if exists "Public read active plans" on course_plans;
create policy "Public read active plans" on course_plans
  for select using (active = true);

-- pending_purchases: רק המשתמש עצמו יכול לראות את שלו, אף אחד לא יכול לכתוב מהקליינט
alter table pending_purchases enable row level security;

drop policy if exists "Users read own pending" on pending_purchases;
create policy "Users read own pending" on pending_purchases
  for select using (auth.uid() = user_id);

-- אין policy ל-INSERT/UPDATE/DELETE — רק service_role יכול (server-side only)

-- user_access: רק המשתמש עצמו יכול לראות, אף אחד לא יכול לכתוב מהקליינט
alter table user_access enable row level security;

drop policy if exists "Users read own access" on user_access;
create policy "Users read own access" on user_access
  for select using (auth.uid() = user_id);

-- אין policy ל-INSERT/UPDATE/DELETE — רק service_role

-- purchase_log: רק המשתמש עצמו יכול לראות
alter table purchase_log enable row level security;

drop policy if exists "Users read own log" on purchase_log;
create policy "Users read own log" on purchase_log
  for select using (auth.uid() = user_id);

-- אין policy לכתיבה — רק service_role

-- ============================================================
-- 6. Helper function — האם משתמש יכול לגשת לשיעור מסוים?
--    מחזיר true/false. מטפל גם בפג תוקף.
-- ============================================================
create or replace function user_has_lesson_access(p_user_id uuid, p_lesson_num integer)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_part integer;
  v_access jsonb;
  v_item jsonb;
begin
  -- שיעורים חינם
  if p_lesson_num <= 2 then
    return true;
  end if;

  -- מיפוי שיעור → חלק
  if p_lesson_num between 3 and 6 then
    v_part := 1;
  elsif p_lesson_num between 7 and 12 then
    v_part := 2;
  elsif p_lesson_num between 13 and 18 then
    v_part := 3;
  else
    return false;  -- שיעור לא ידוע
  end if;

  -- שלוף את parts_owned של המשתמש
  select parts_owned into v_access
  from user_access
  where user_id = p_user_id;

  if v_access is null then
    return false;
  end if;

  -- עבור על הרשימה — האם יש רשומה תקפה לחלק הזה?
  for v_item in select * from jsonb_array_elements(v_access)
  loop
    if (v_item->>'part')::integer = v_part
       and (v_item->>'expires')::timestamptz > now()
    then
      return true;
    end if;
  end loop;

  return false;
end;
$$;

-- ============================================================
-- 7. Helper function — קיבוץ של כל החלקים שהמשתמש קנה ובתוקף
--    משמש את ה-API endpoint /api/me
-- ============================================================
create or replace function get_user_active_parts(p_user_id uuid)
returns table(part integer, expires timestamptz, plan_id text)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    (item->>'part')::integer as part,
    (item->>'expires')::timestamptz as expires,
    (item->>'plan_id')::text as plan_id
  from user_access ua,
       jsonb_array_elements(ua.parts_owned) as item
  where ua.user_id = p_user_id
    and (item->>'expires')::timestamptz > now();
end;
$$;

-- ============================================================
-- Done!
-- ============================================================
