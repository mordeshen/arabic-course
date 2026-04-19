-- ============================================================
-- Add new slide type: letter_forms_table
-- Run this in Supabase SQL Editor (idempotent — uses on conflict)
-- ============================================================

insert into slide_types (type, description, schema_doc) values
  ('letter_forms_table',
   'טבלת אותיות עם 4 צורות (עצמאית, תחילה, אמצע, סוף) + שם, צליל ודוגמה',
   '{title?, intro_html?, rows: [{hebrew_name, sound, isolated, initial, medial, final, example_arabic, example_hebrew, non_connector?}], note?}'),
  ('letter_identify',
   'זיהוי אותיות בתוך מילים — מדגיש את האות הנלמדת בצבע זהב',
   '{title?, intro?, examples: [{position_label, letters: [{char, highlight?, name?}], transliteration, meaning}], note?}'),
  ('letter_drag_game',
   'משחק זיהוי אותיות — לוחצים על הכרטיס שמתאים לאות החסרה עם פידבק חכם',
   '{title?, instructions?, challenges: [{word_letters, target_index, correct_isolated, correct_name, transliteration, meaning, success_note, options: [{isolated, name}]}]}')
on conflict (type) do update set
  description = excluded.description,
  schema_doc  = excluded.schema_doc;
