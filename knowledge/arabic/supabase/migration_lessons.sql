-- ============================================================
-- Arabic Course — Lessons Schema v1.0
-- Run this in Supabase SQL Editor
-- Empty Shell + Dynamic Content architecture
-- ============================================================

-- ============================================================
-- 1. lessons — מטא של שיעור
-- ============================================================
create table if not exists lessons (
  id            integer primary key,           -- 1..18 (תואם למספר השיעור)
  number        integer unique not null,       -- 1..18
  part          integer,                       -- 1, 2, 3 (לתשלומים) | null עבור חינם
  title         text not null,
  subtitle      text,                          -- "שיעור 1" וכו'
  arabic_title  text,
  description   text,
  difficulty    text check (difficulty in ('beginner','intermediate','advanced')),
  is_free       boolean default false,         -- שיעורים 1-2 = true
  active        boolean default true,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index if not exists idx_lessons_part on lessons (part);
create index if not exists idx_lessons_active on lessons (active) where active = true;

-- ============================================================
-- 2. lesson_slides — שקופיות לשיעור
-- ============================================================
create table if not exists lesson_slides (
  id          uuid primary key default gen_random_uuid(),
  lesson_id   integer not null references lessons(id) on delete cascade,
  position    integer not null,                -- סדר הצגה (1, 2, 3, ...)
  type        text not null,                   -- intro | rule_card | vocab_grid | example_cards | ...
  content     jsonb not null default '{}',     -- התוכן הספציפי לסוג (גמיש)
  active      boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- כל שיעור יכול להחזיק שקופית אחת בכל מיקום (כל עוד היא active)
create unique index if not exists idx_slides_position on lesson_slides (lesson_id, position) where active = true;
create index if not exists idx_slides_lesson on lesson_slides (lesson_id, position);
create index if not exists idx_slides_type on lesson_slides (type);

-- ============================================================
-- 3. רשימה של סוגי slides תקפים (constraint רך — להגנה מטעויות הקלדה)
-- ============================================================
create table if not exists slide_types (
  type        text primary key,
  description text,
  schema_doc  text                              -- תיעוד של השדות שמצופים ב-content
);

insert into slide_types (type, description, schema_doc) values
  ('intro',                  'שקופית פתיחה — כותרת ותיאור',                      '{title, subtitle, arabic_title, description, ornament}'),
  ('rule_card',              'כרטיס הסבר/כלל',                                     '{title?, html, examples?[]}'),
  ('summary',                'סיכום שיעור',                                         '{key_points[], vocabulary_recap?[], next_lesson_teaser?}'),
  ('vocab_grid',             'רשת אוצר מילים',                                      '{title?, items: [{arabic, hebrew, transliteration?, click_hint?}]}'),
  ('example_cards',          'כרטיסי דוגמה (לחיצים)',                              '{title?, items: [{arabic_phrase, hebrew_translation, separator, translation_note?}]}'),
  ('collision_arena',        'אנימציית התנגשות מילים',                              '{left_word, operator, right_word, result, result_label}'),
  ('memory_game',            'משחק זיכרון',                                         '{pairs: [{arabic, hebrew}], show_timer?}'),
  ('quiz_match',             'שאלה עם reveal answer',                              '{questions: [{question, answer, hint?}], reveal_all_button?}'),
  ('quiz_multi_choice',      'שאלון רב-ברירה (יכול עם טיימר)',                     '{title?, timer_seconds?, questions: [{q, correct, options[]}]}'),
  ('letter_chips',           'אותיות לחיצות עם דוגמאות (שיעור 1)',                  '{groups: [{title, color, letters: [{letter, example}]}]}'),
  ('greeting_pair',          'צמדי ברכות עם תשובה (שיעור 2)',                       '{items: [{label, say, response, hebrew}]}'),
  ('greeting_grid',          'רשת ברכות עם say/response (שיעור 8)',                 '{items: [{say_label, say, say_meaning, response_label, response, response_meaning}]}'),
  ('dialogue',               'דיאלוג בין דוברים',                                   '{title?, lines: [{speaker, arabic, hebrew, cloze_word?, cloze_answer?}]}'),
  ('conjugation_table',      'טבלת הטיה/כינויים',                                  '{title?, headers: [], rows: [{}]}'),
  ('conjugation_interactive','תרגיל הטיה אינטראקטיבי',                              '{questions: [{prompt, options: [{text, correct}]}]}'),
  ('sentence_builder',       'בונה משפטים (גרירה)',                                '{builders: [{prompt, blocks[], correct_order[]}]}'),
  ('number_builder',         'בונה מספרים (שיעור 4)',                              '{numbers: [{digit, arabic, hebrew}]}'),
  ('number_grid',            'רשת מספרים סטטית (שיעור 4)',                          '{items: [{digit, arabic, hebrew}]}'),
  ('family_grid',            'רשת מילים על המשפחה (שיעור 5)',                       '{items: [{arabic, hebrew}]}')
on conflict (type) do update set
  description = excluded.description,
  schema_doc  = excluded.schema_doc;

-- foreign key רך מ-lesson_slides.type ל-slide_types.type
-- (הערה: לא enforced FK כי אנחנו רוצים לאפשר הוספת types חדשים בקלות,
--  אבל נשאיר את הטבלה כתיעוד מרכזי. אם נרצה אכיפה, נוסיף constraint בעתיד.)

-- ============================================================
-- 4. RLS — public read, אין כתיבה מהקליינט
-- ============================================================
alter table lessons enable row level security;
alter table lesson_slides enable row level security;
alter table slide_types enable row level security;

drop policy if exists "Public read active lessons" on lessons;
create policy "Public read active lessons" on lessons
  for select using (active = true);

drop policy if exists "Public read active slides" on lesson_slides;
create policy "Public read active slides" on lesson_slides
  for select using (
    active = true
    and exists (
      select 1 from lessons l where l.id = lesson_slides.lesson_id and l.active = true
    )
  );

drop policy if exists "Public read slide types" on slide_types;
create policy "Public read slide types" on slide_types
  for select using (true);

-- כתיבה: רק service_role (אין policies = רק service_role יכול)

-- ============================================================
-- 5. trigger לעדכון updated_at אוטומטית
-- ============================================================
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_lessons_updated_at on lessons;
create trigger trg_lessons_updated_at
  before update on lessons
  for each row execute function set_updated_at();

drop trigger if exists trg_slides_updated_at on lesson_slides;
create trigger trg_slides_updated_at
  before update on lesson_slides
  for each row execute function set_updated_at();

-- ============================================================
-- 6. פונקציה: get_lesson(lesson_num) — מחזיר שיעור עם כל השקופיות
-- ============================================================
create or replace function get_lesson(p_lesson_num integer)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result json;
begin
  select json_build_object(
    'lesson', row_to_json(l),
    'slides', coalesce(
      (
        select json_agg(row_to_json(s) order by s.position)
        from lesson_slides s
        where s.lesson_id = l.id and s.active = true
      ),
      '[]'::json
    )
  )
  into v_result
  from lessons l
  where l.number = p_lesson_num
    and l.active = true;

  return v_result;
end;
$$;

-- מתן הרשאת קריאה לאנונימי לפונקציה
grant execute on function get_lesson(integer) to anon, authenticated;

-- ============================================================
-- 7. Seed: 18 שיעורים עם title, part, ו-is_free
-- ============================================================
insert into lessons (id, number, part, title, subtitle, is_free, difficulty, description) values
  (1,  1,  null, 'האותיות',                    'שיעור 1',  true,  'beginner',     'הכרת אותיות הא"ב הערבי וההבדלים מעברית'),
  (2,  2,  null, 'אותיות שמש ואל הידיעה',     'שיעור 2',  true,  'beginner',     'איך מגדירים בערבית: ה־ והכלל של אותיות שמש וירח'),
  (3,  3,  1,    'כינויי גוף והיכרות',         'שיעור 3',  false, 'beginner',     'אני, אתה, היא — והשאלות הראשונות בערבית'),
  (4,  4,  1,    'מספרים',                     'שיעור 4',  false, 'beginner',     'ספירה מ-0 עד 10 + שאלות על גיל ומחיר'),
  (5,  5,  1,    'המשפחה',                     'שיעור 5',  false, 'beginner',     'אבא, אמא, אח ואחות — והמבנה ענדי/מעי'),
  (6,  6,  1,    'ביטויים שימושיים',           'שיעור 6',  false, 'beginner',     'בדדי, לאזם, ממכן ועוד — הביטויים שמייצרים משפט שלם'),
  (7,  7,  2,    'שלילה',                      'שיעור 7',  false, 'intermediate', 'מא, מש, מא...ש — איך אומרים "לא" בערבית מדוברת'),
  (8,  8,  2,    'ברכות מתקדמות',              'שיעור 8',  false, 'intermediate', 'ברכות לאירועים ולמצבים — והתשובות הקבועות'),
  (9,  9,  2,    'הפועל בהווה',                'שיעור 9',  false, 'intermediate', 'הקידומות בַּ/בִּ/מְנִ — איך מטים פועל בהווה-עתיד'),
  (10, 10, 2,    'הפועל בעבר',                 'שיעור 10', false, 'intermediate', 'סיומות הגוף בעבר וההבדלים בין הגופים'),
  (11, 11, 2,    'ציווי וכיוונים',              'שיעור 11', false, 'intermediate', 'איך נותנים הוראות, ומיליות כיוון בערבית'),
  (12, 12, 2,    'במסעדה ובחיי היום-יום',      'שיעור 12', false, 'intermediate', 'אוצר מילים לאוכל, שתייה, חולי ובריאות'),
  (13, 13, 3,    'סמיכות ותא מרבוטה',          'שיעור 13', false, 'advanced',     'איך מחברים שני שמות עצם — והכלל של ת מרבוטה'),
  (14, 14, 3,    'ריבוי',                       'שיעור 14', false, 'advanced',     'ריבוי שלם וריבוי שבור — תבניות ודוגמאות'),
  (15, 15, 3,    'שעות ומספרים מתקדמים',       'שיעור 15', false, 'advanced',     'איך אומרים את השעה ומספרים מעל 20'),
  (16, 16, 3,    'סלנג ופתגמים',                'שיעור 16', false, 'advanced',     'ביטויים תרבותיים, סלנג רחוב, ופתגמים עממיים'),
  (17, 17, 3,    'בניינים',                     'שיעור 17', false, 'advanced',     'מערכת הבניינים בערבית — תבניות ומשמעויות'),
  (18, 18, 3,    'סיכום ותרגול שיחה',           'שיעור 18', false, 'advanced',     'תרגול דיאלוגים, חזרה על כל הקורס')
on conflict (id) do update set
  title       = excluded.title,
  subtitle    = excluded.subtitle,
  part        = excluded.part,
  is_free     = excluded.is_free,
  difficulty  = excluded.difficulty,
  description = excluded.description;

-- ============================================================
-- Done!
-- ============================================================
-- בדיקה מהירה:
-- select * from lessons order by number;
-- select * from slide_types order by type;
-- select get_lesson(1);  -- לבדיקה אחרי שתכניס שקופיות
