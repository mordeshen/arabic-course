-- ============================================================
-- Patch: add a letter_trace slide after every letter_identify
-- slide across ALL reading lessons (lesson_id in 100..109).
-- Idempotent: re-running deletes old trace slides and re-inserts.
-- Pure SQL (no DO block). Replaces patch_reading_lesson_add_trace.sql.
-- ============================================================

begin;

-- Helper: which lessons to touch
-- Reading lessons are 100..109 by convention.

-- 1) Idempotency: remove previously inserted trace slides
delete from lesson_slides
where lesson_id between 100 and 109 and type = 'letter_trace';

-- 2) Temporarily negate positions for all slides in the affected lessons,
--    so we can re-assign fresh positive values without hitting the unique index.
update lesson_slides
set position = -position
where lesson_id between 100 and 109;

-- 3) Renumber slides per-lesson, leaving gaps for the upcoming traces.
--    For each slide: new_pos = (ordinal in its lesson) + (# of letter_identify slides strictly before it in that lesson).
with ordered as (
  select
    ls.id,
    ls.lesson_id,
    ls.type,
    row_number() over (partition by ls.lesson_id order by ls.position desc) as ord,
    (
      select count(*)::int
      from lesson_slides x
      where x.lesson_id = ls.lesson_id
        and x.type = 'letter_identify'
        and x.position > ls.position    -- "larger negative" = "earlier in original order"
    ) as identifies_before
  from lesson_slides ls
  where ls.lesson_id between 100 and 109
)
update lesson_slides ls
set position = o.ord + o.identifies_before
from ordered o
where ls.id = o.id;

-- 4) Insert a letter_trace slide right after each letter_identify.
insert into lesson_slides (lesson_id, position, type, content)
select
  ls.lesson_id,
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
where ls.lesson_id between 100 and 109
  and ls.type = 'letter_identify';

commit;

-- ============================================================
-- Verify:
--   select lesson_id, position, type, content->>'letter' as letter
--   from lesson_slides where lesson_id between 100 and 109
--   order by lesson_id, position;
-- ============================================================
