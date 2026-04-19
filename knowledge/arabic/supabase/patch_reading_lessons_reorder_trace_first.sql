-- ============================================================
-- Patch: reorder reading-lesson slides so letter_trace comes
-- BEFORE each letter_identify, carrying the letter explanation
-- (title + intro) from the identify slide into the trace slide.
--
-- Rationale: pedagogically, a student first wants to SEE the
-- letter, read what it is, and WRITE it. Only then to see how
-- it behaves inside words (initial/medial/final). This patch
-- implements that order across all reading lessons (100..109).
--
-- This supersedes patch_all_reading_lessons_add_trace.sql
-- (which placed trace AFTER identify).
--
-- Idempotent: deletes existing trace slides and re-inserts.
-- Pure SQL (no DO block).
-- ============================================================

begin;

-- 1) Idempotency: remove previously inserted trace slides.
delete from lesson_slides
where lesson_id between 100 and 109 and type = 'letter_trace';

-- 2) Temporarily negate positions for all slides in the affected
--    lessons so we can reassign fresh positive values without
--    hitting the (lesson_id, position) unique index mid-update.
update lesson_slides
set position = -position
where lesson_id between 100 and 109;

-- 3) Renumber per-lesson, leaving a one-slot gap BEFORE every
--    letter_identify for the upcoming trace slide.
--    Formula: new_pos = (ordinal in lesson) + (# of letter_identify
--    slides at-or-before self in original order).
--    Positions are currently negated, so "at or before" in
--    original order = ">=" in negated form.
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
        and x.position >= ls.position   -- at-or-before in original order
    ) as identifies_at_or_before
  from lesson_slides ls
  where ls.lesson_id between 100 and 109
)
update lesson_slides ls
set position = o.ord + o.identifies_at_or_before
from ordered o
where ls.id = o.id;

-- 4) Insert a letter_trace slide immediately BEFORE each letter_identify.
--    Carry over title + intro so the first slide per letter explains it.
insert into lesson_slides (lesson_id, position, type, content)
select
  ls.lesson_id,
  ls.position - 1,
  'letter_trace',
  jsonb_build_object(
    'letter',             h.ch,
    'letter_hebrew_name', h.nm,
    'title',              ls.content->>'title',
    'intro',              ls.content->>'intro',
    'note',               'ציירו את האות בתוך המסגרת. אחרי שתכתבו אותה — נראה איך היא נכנסת לתוך מילים.'
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
--   select lesson_id, position, type,
--          coalesce(content->>'letter', content->>'title') as hint
--   from lesson_slides where lesson_id between 100 and 109
--   order by lesson_id, position;
-- Expected pattern per lesson:
--   intro, rule_card, trace(ب), identify(ب), trace(ت), identify(ت),
--   ..., drag_game, summary.
-- ============================================================
