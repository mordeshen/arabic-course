-- ============================================================
-- Patch: add a letter_trace slide after every letter_identify
-- slide in the reading lesson (lesson 100).
-- Idempotent: re-running deletes old trace slides and re-inserts.
-- Prerequisites:
--   1. migration_letter_trace.sql    (registers the slide_type)
--   2. Lesson 100 exists with letter_identify slides already seeded.
-- Uses pure SQL (no DO block / PL/pgSQL) for maximum portability.
-- ============================================================

begin;

-- 1) Idempotency: remove any previously inserted trace slides
delete from lesson_slides where lesson_id = 100 and type = 'letter_trace';

-- 2) Temporarily negate positions so we can re-assign fresh
--    sequential values without hitting the unique index on
--    (lesson_id, position) where active = true.
update lesson_slides set position = -position where lesson_id = 100;

-- 3) Renumber existing slides with gaps left for upcoming traces.
--    new_pos = (rank in original order) + (# of letter_identify slides strictly before this one).
--    This produces positions like 1, 2, 3, 5, 7, 9, 11, 13, 15, 16 for
--    an input of [intro, rule, ident×6, drag, summary], leaving gaps at 4, 6, 8, 10, 12, 14.
with ordered as (
  select
    ls.id,
    ls.type,
    row_number() over (order by ls.position desc) as ord,
    (
      select count(*)::int
      from lesson_slides x
      where x.lesson_id = 100
        and x.type = 'letter_identify'
        and x.position > ls.position    -- larger (less-negative) = earlier in original order
    ) as identifies_before
  from lesson_slides ls
  where ls.lesson_id = 100
)
update lesson_slides ls
set position = o.ord + o.identifies_before
from ordered o
where ls.id = o.id;

-- 4) Insert a letter_trace slide right after each letter_identify,
--    pulling the letter + name out of examples[0].letters (the one with highlight=true).
insert into lesson_slides (lesson_id, position, type, content)
select
  100,
  ls.position + 1,
  'letter_trace',
  jsonb_build_object(
    'letter',             h.ch,
    'letter_hebrew_name', h.nm,
    'title',              'עכשיו נסו לכתוב: ' || h.ch,
    'intro',              'ציירו את האות בתוך המסגרת. אפשר להתחיל מאיפה שנוח — העיקר להישאר בתוך הקווים.',
    'note',               'רמז: האות מופיעה ברקע בצבע חיוור עם קו מקווקו. העבירו את העט/העכבר מעליה.'
  )
from lesson_slides ls
cross join lateral (
  select
    elem->>'char' as ch,
    elem->>'name' as nm
  from jsonb_array_elements(ls.content->'examples'->0->'letters') as elem
  where coalesce((elem->>'highlight')::boolean, false)
  limit 1
) as h
where ls.lesson_id = 100 and ls.type = 'letter_identify';

commit;

-- ============================================================
-- Verify:
--   select position, type, content->>'letter' as letter
--   from lesson_slides where lesson_id = 100
--   order by position;
-- Expected: each letter_identify immediately followed by a
-- letter_trace with the same letter (positions 3+4, 5+6, ...).
-- ============================================================
