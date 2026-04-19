-- ============================================================
-- Add new slide type: letter_trace
-- Run this in Supabase SQL Editor (idempotent — uses on conflict)
-- ============================================================

insert into slide_types (type, description, schema_doc) values
  ('letter_trace',
   'תרגול כתיבת אות בתוך מסגרת מקווקוות (canvas). בודק כיסוי ודיוק.',
   '{letter, letter_hebrew_name?, sound?, title?, intro?, note?}')
on conflict (type) do update set
  description = excluded.description,
  schema_doc  = excluded.schema_doc;
