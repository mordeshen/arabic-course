-- Seed: Lesson 102 — האותיות הכועסות (ص ض ط ظ)
begin;
delete from lesson_slides where lesson_id = 102;
delete from lessons where id = 102;

insert into lessons (id, number, part, title, subtitle, arabic_title, is_free, difficulty, description, active) values
  (102, 102, null, 'קריאה — האותיות הכועסות', 'שיעור קריאה 3', 'الحروف المفخّمة', true, 'beginner',
   '4 אותיות עם צליל חזק/עמוק (emphatic): ص ض ط ظ.', true);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 1, 'intro', $${
  "subtitle": "שיעור קריאה 3",
  "title": "האותיות הכועסות",
  "arabic_title": "الحروف المفخّمة",
  "ornament": "✦ ✧ ✦",
  "description": "4 אותיות שיש להן בת-דמות רגילה בעברית — אבל כאן הן נהגות חזק וכבד יותר."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 2, 'rule_card', $${
  "title": "מה זה 'כועסות'?",
  "html": "<span class=\"highlight\">4 אותיות</span> בערבית שנשמעות כמו <span class=\"teal\">ס/ד/ט/ז</span> — אבל הגויות עם יותר עוצמה, לשון מורמת וקול עמוק יותר. חושבים עליהן כ״גרסאות כועסות״ של האותיות הרגילות:<br><br><b>ص</b> = ס כועסת &nbsp;·&nbsp; <b>ض</b> = ד כועסת &nbsp;·&nbsp; <b>ط</b> = ט כועסת &nbsp;·&nbsp; <b>ظ</b> = ז כועסת."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 3, 'letter_identify', $${
  "title": "האות ص — סַֿאד (ס כועסת)",
  "intro": "<span class=\"teal\">ס חזקה ועמוקה</span>. הלשון צמודה לשיניים, הקול מגיע מלמטה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ص", "highlight": true, "name": "סַֿאד"}, {"char": "ب", "name": "בַּא"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ح", "name": "חַא"}], "transliteration": "sabah", "meaning": "בוקר"},
    {"position_label": "אמצע מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "ص", "highlight": true, "name": "סַֿאד"}, {"char": "ر", "name": "רַא"}], "transliteration": "misr", "meaning": "מצרים"},
    {"position_label": "סוף מילה", "letters": [{"char": "ف", "name": "פַא"}, {"char": "ص", "highlight": true, "name": "סַֿאד"}], "transliteration": "fass", "meaning": "שן (שום) / חתיכה"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 4, 'letter_identify', $${
  "title": "האות ض — דַֿאד (ד כועסת)",
  "intro": "<span class=\"teal\">ד חזקה</span>. הצורה דומה ל-ص אבל עם <span class=\"highlight\">נקודה למעלה</span>.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ض", "highlight": true, "name": "דַֿאד"}, {"char": "ي", "name": "יַא"}, {"char": "ف", "name": "פַא"}], "transliteration": "dayf", "meaning": "אורח"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ف", "name": "פַא"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ض", "highlight": true, "name": "דַֿאד"}, {"char": "ي", "name": "יַא"}], "transliteration": "faadi", "meaning": "פנוי"},
    {"position_label": "סוף מילה", "letters": [{"char": "ا", "name": "אַלֵף"}, {"char": "ب", "name": "בַּא"}, {"char": "ي", "name": "יַא"}, {"char": "ض", "highlight": true, "name": "דַֿאד"}], "transliteration": "abyad", "meaning": "לבן"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 5, 'letter_identify', $${
  "title": "האות ط — טַא (ט כועסת)",
  "intro": "<span class=\"teal\">ט חזקה</span>. צורה מאוד מוכרת — קו אנכי עם עיגול בבסיס.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ط", "highlight": true, "name": "טַא"}, {"char": "ي", "name": "יַא"}, {"char": "ب", "name": "בַּא"}], "transliteration": "tayyib", "meaning": "טוב"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ق", "name": "קַאף"}, {"char": "ط", "highlight": true, "name": "טַא"}, {"char": "ع", "name": "עַיְן"}], "transliteration": "qataʿ", "meaning": "חתך"},
    {"position_label": "סוף מילה", "letters": [{"char": "خ", "name": "חַ'א"}, {"char": "ط", "highlight": true, "name": "טַא"}], "transliteration": "khatt", "meaning": "קו / כתב"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 6, 'letter_identify', $${
  "title": "האות ظ — זַֿא (ז כועסת)",
  "intro": "<span class=\"teal\">ז חזקה</span>. צורה כמו ط אבל עם <span class=\"highlight\">נקודה למעלה</span>. אות נדירה יחסית.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ظ", "highlight": true, "name": "זַֿא"}, {"char": "ه", "name": "הַא"}, {"char": "ر", "name": "רַא"}], "transliteration": "zuhr", "meaning": "צוהריים"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ن", "name": "נוּן"}, {"char": "ظ", "highlight": true, "name": "זַֿא"}, {"char": "ي", "name": "יַא"}, {"char": "ف", "name": "פַא"}], "transliteration": "nazif", "meaning": "נקי"},
    {"position_label": "סוף מילה", "letters": [{"char": "ح", "name": "חַא"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ف", "name": "פַא"}, {"char": "ظ", "highlight": true, "name": "זַֿא"}], "transliteration": "hafiz", "meaning": "זוכר / שומר"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 7, 'letter_drag_game', $${
  "title": "מצאו את האות הכועסת",
  "instructions": "האותיות הכועסות דומות מאוד לאחיותיהן הרגילות. הבחינו בפרטים!",
  "challenges": [
    {"word_letters": [{"char": "ص", "isolated": "ص", "name": "סַֿאד"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "ح", "isolated": "ح", "name": "חַא"}], "target_index": 0, "correct_isolated": "ص", "correct_name": "סַֿאד", "transliteration": "sabah", "meaning": "בוקר", "success_note": "ס כועסת פותחת.", "options": [{"isolated": "ص", "name": "סַֿאד"}, {"isolated": "س", "name": "סִין"}, {"isolated": "ض", "name": "דַֿאד"}, {"isolated": "ش", "name": "שִין"}]},
    {"word_letters": [{"char": "ض", "isolated": "ض", "name": "דַֿאד"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ف", "isolated": "ف", "name": "פַא"}], "target_index": 0, "correct_isolated": "ض", "correct_name": "דַֿאד", "transliteration": "dayf", "meaning": "אורח", "success_note": "ד כועסת.", "options": [{"isolated": "ض", "name": "דַֿאד"}, {"isolated": "ص", "name": "סַֿאד"}, {"isolated": "د", "name": "דַאל"}, {"isolated": "ظ", "name": "זַֿא"}]},
    {"word_letters": [{"char": "ط", "isolated": "ط", "name": "טַא"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}], "target_index": 0, "correct_isolated": "ط", "correct_name": "טַא", "transliteration": "tayyib", "meaning": "טוב", "success_note": "ט כועסת!", "options": [{"isolated": "ط", "name": "טַא"}, {"isolated": "ظ", "name": "זַֿא"}, {"isolated": "ت", "name": "תַּא"}, {"isolated": "ب", "name": "בַּא"}]},
    {"word_letters": [{"char": "م", "isolated": "م", "name": "מִים"}, {"char": "ص", "isolated": "ص", "name": "סַֿאד"}, {"char": "ر", "isolated": "ر", "name": "רַא"}], "target_index": 1, "correct_isolated": "ص", "correct_name": "סַֿאד", "transliteration": "misr", "meaning": "מצרים", "success_note": "ס חזקה באמצע.", "options": [{"isolated": "ص", "name": "סַֿאד"}, {"isolated": "س", "name": "סִין"}, {"isolated": "ش", "name": "שִין"}, {"isolated": "ض", "name": "דַֿאד"}]},
    {"word_letters": [{"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ض", "isolated": "ض", "name": "דַֿאד"}], "target_index": 3, "correct_isolated": "ض", "correct_name": "דַֿאד", "transliteration": "abyad", "meaning": "לבן", "success_note": "ד כועסת בסוף.", "options": [{"isolated": "ض", "name": "דַֿאד"}, {"isolated": "د", "name": "דַאל"}, {"isolated": "ص", "name": "סַֿאד"}, {"isolated": "ظ", "name": "זַֿא"}]},
    {"word_letters": [{"char": "ظ", "isolated": "ظ", "name": "זַֿא"}, {"char": "ه", "isolated": "ه", "name": "הַא"}, {"char": "ر", "isolated": "ر", "name": "רַא"}], "target_index": 0, "correct_isolated": "ظ", "correct_name": "זַֿא", "transliteration": "zuhr", "meaning": "צוהריים", "success_note": "ז כועסת!", "options": [{"isolated": "ظ", "name": "זַֿא"}, {"isolated": "ط", "name": "טַא"}, {"isolated": "ض", "name": "דַֿאד"}, {"isolated": "ص", "name": "סַֿאד"}]}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(102, 8, 'summary', $${
  "key_points": [
    {"title": "① ארבע הכועסות", "html": "<span class=\"teal\">ص</span> ס כועסת &nbsp;·&nbsp; <span class=\"teal\">ض</span> ד כועסת &nbsp;·&nbsp; <span class=\"teal\">ط</span> ט כועסת &nbsp;·&nbsp; <span class=\"teal\">ظ</span> ז כועסת"},
    {"title": "② שימו לב לנקודות", "html": "<b class=\"highlight\">ص/ض</b> — אותה צורה, ض עם נקודה למעלה. <br><b class=\"highlight\">ط/ظ</b> — אותה צורה, ظ עם נקודה למעלה."},
    {"title": "③ איך להגות?", "html": "לשון מורמת, הקול עמוק. <span class=\"rose\">שימו לב לתנועה שליד</span> — היא נעשית יותר גרונית ליד הכועסות."}
  ],
  "vocabulary_recap": ["صباح", "ضيف", "طيب", "ظهر", "أبيض"],
  "next_lesson_teaser": "בשיעור הבא: 5 אותיות ייחודיות נוספות — ث ج ح خ ذ. חלקן בלי מקבילה בעברית. 🌟"
}$$::jsonb);

commit;
