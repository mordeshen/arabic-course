-- ============================================================
-- Seed: Lesson 101 — Reading part 2 (האותיות הדומות לעברית + ع)
-- Letters: ش س ع ف و ي ه  (7)
-- Structure: intro, rule_card, 7× letter_identify, drag_game, summary (11 slides)
-- After running, apply patch_all_reading_lessons_add_trace.sql to interleave trace slides.
-- ============================================================

begin;

delete from lesson_slides where lesson_id = 101;
delete from lessons where id = 101;

insert into lessons (id, number, part, title, subtitle, arabic_title, is_free, difficulty, description, active) values
  (101, 101, null, 'קריאה — אותיות מוכרות', 'שיעור קריאה 2', 'القراءة ٢', true, 'beginner',
   '7 אותיות נוספות: ش س ع ف و ي ه. רובן מזכירות אותיות עבריות, אחת ייחודית (ע).', true);

-- Slide 1: intro
insert into lesson_slides (lesson_id, position, type, content) values
(101, 1, 'intro', $${
  "subtitle": "שיעור קריאה 2",
  "title": "עוד אותיות מוכרות",
  "arabic_title": "القراءة ٢",
  "ornament": "✦ ✧ ✦",
  "description": "6 אותיות שדומות לעברית ואחת ייחודית — ע׳ שאין לנו."
}$$::jsonb);

-- Slide 2: rule_card
insert into lesson_slides (lesson_id, position, type, content) values
(101, 2, 'rule_card', $${
  "title": "מה נלמד",
  "html": "בשיעור הזה נכיר <span class=\"highlight\">7 אותיות</span>: ש, ס, פ, ו, י, ה — <span class=\"teal\">כולן קיימות בעברית</span> — וגם ع (עַיְן) — אות <span class=\"rose\">ייחודית לערבית</span> עם צליל גרוני. לכל אות נראה איך היא נכתבת במילה ונכתוב אותה בעצמנו."
}$$::jsonb);

-- Slide 3: ش (shin)
insert into lesson_slides (lesson_id, position, type, content) values
(101, 3, 'letter_identify', $${
  "title": "האות ش — שִין (צליל sh)",
  "intro": "<span class=\"teal\">ש</span> עם <span class=\"highlight\">3 נקודות למעלה</span>. זה הצליל ש של 'שלום'.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ش", "highlight": true, "name": "שִין"}, {"char": "م", "name": "מִים"}, {"char": "س", "name": "סִין"}], "transliteration": "shams", "meaning": "שמש"},
    {"position_label": "אמצע מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "ش", "highlight": true, "name": "שִין"}, {"char": "ي", "name": "יַא"}], "transliteration": "mashi", "meaning": "הולך"},
    {"position_label": "סוף מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "ش", "highlight": true, "name": "שִין"}], "transliteration": "mish", "meaning": "לא (שלילה)"}
  ]
}$$::jsonb);

-- Slide 4: س (sin)
insert into lesson_slides (lesson_id, position, type, content) values
(101, 4, 'letter_identify', $${
  "title": "האות س — סִין (צליל s)",
  "intro": "<span class=\"teal\">ס</span> — אותה צורה כמו ש, רק <span class=\"highlight\">בלי הנקודות</span>.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "س", "highlight": true, "name": "סִין"}, {"char": "ل", "name": "לַאם"}, {"char": "ا", "name": "אַלֵף"}, {"char": "م", "name": "מִים"}], "transliteration": "salam", "meaning": "שלום"},
    {"position_label": "אמצע מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "س", "highlight": true, "name": "סִין"}, {"char": "ا", "name": "אַלֵף"}], "transliteration": "masa", "meaning": "ערב"},
    {"position_label": "סוף מילה", "letters": [{"char": "ك", "name": "כַּאף"}, {"char": "ا", "name": "אַלֵף"}, {"char": "س", "highlight": true, "name": "סִין"}], "transliteration": "kas", "meaning": "כוס"}
  ],
  "note": "<span class=\"rose\">טיפ:</span> ש וס הן משפחה — רק הנקודות שונות. ש = 3 נקודות למעלה, ס = ללא נקודות."
}$$::jsonb);

-- Slide 5: ع (ayn)
insert into lesson_slides (lesson_id, position, type, content) values
(101, 5, 'letter_identify', $${
  "title": "האות ع — עַיְן (צליל ע׳ גרוני)",
  "intro": "<span class=\"rose\">אות ייחודית לערבית</span> — צליל גרוני שמגיע מעמוק בגרון. אין בעברית מודרנית, אבל ב-<b>ערבית מזרחית</b> וב-<b>תימנית</b> הוא קיים. לצורה שלה 4 וריאציות שונות מאוד.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ع", "highlight": true, "name": "עַיְן"}, {"char": "ي", "name": "יַא"}, {"char": "ن", "name": "נוּן"}], "transliteration": "ʿayn", "meaning": "עין"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ش", "name": "שִין"}, {"char": "ع", "highlight": true, "name": "עַיְן"}, {"char": "ر", "name": "רַא"}], "transliteration": "shaʿr", "meaning": "שיער"},
    {"position_label": "סוף מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "ع", "highlight": true, "name": "עַיְן"}], "transliteration": "maʿ", "meaning": "עם"}
  ],
  "note": "<span class=\"teal\">מעַ</span> (עם) — מילה ממש שימושית. למשל: <span class=\"highlight\">אנא מַעַכּ</span> = אני אִתְּךָ."
}$$::jsonb);

-- Slide 6: ف (fa)
insert into lesson_slides (lesson_id, position, type, content) values
(101, 6, 'letter_identify', $${
  "title": "האות ف — פַא (צליל f)",
  "intro": "<span class=\"teal\">פ</span> — <span class=\"highlight\">נקודה אחת למעלה</span>.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ف", "highlight": true, "name": "פַא"}, {"char": "و", "name": "וַאו"}, {"char": "ل", "name": "לַאם"}], "transliteration": "ful", "meaning": "פול (מאכל)"},
    {"position_label": "אמצע מילה", "letters": [{"char": "س", "name": "סִין"}, {"char": "ف", "highlight": true, "name": "פַא"}, {"char": "ر", "name": "רַא"}], "transliteration": "safar", "meaning": "נסיעה"},
    {"position_label": "סוף מילה", "letters": [{"char": "ك", "name": "כַּאף"}, {"char": "ي", "name": "יַא"}, {"char": "ف", "highlight": true, "name": "פַא"}], "transliteration": "kif", "meaning": "איך"}
  ]
}$$::jsonb);

-- Slide 7: و (waw) — non-connector
insert into lesson_slides (lesson_id, position, type, content) values
(101, 7, 'letter_identify', $${
  "title": "האות و — וַאו (צליל w / u)",
  "intro": "<span class=\"teal\">ו</span> — משמשת גם כעיצור (w) וגם כתנועה ארוכה (u). <span class=\"rose\">אות שלא מתחברת</span> לאות הבאה — אז כל 4 הצורות שלה נראות דומות.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "و", "highlight": true, "name": "וַאו"}, {"char": "ل", "name": "לַאם"}, {"char": "د", "name": "דַאל"}], "transliteration": "walad", "meaning": "ילד"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ي", "name": "יַא"}, {"char": "و", "highlight": true, "name": "וַאו"}, {"char": "م", "name": "מִים"}], "transliteration": "yawm", "meaning": "יום"},
    {"position_label": "סוף מילה", "letters": [{"char": "د", "name": "דַאל"}, {"char": "ل", "name": "לַאם"}, {"char": "و", "highlight": true, "name": "וַאו"}], "transliteration": "dalw", "meaning": "דלי"}
  ],
  "note": "<span class=\"rose\">שימו לב:</span> ו לא מתחברת לאות הבאה, לכן נראית זהה בכל מיקום."
}$$::jsonb);

-- Slide 8: ي (ya)
insert into lesson_slides (lesson_id, position, type, content) values
(101, 8, 'letter_identify', $${
  "title": "האות ي — יַא (צליל y / i)",
  "intro": "<span class=\"teal\">י</span> — משמשת גם כעיצור (y) וגם כתנועה ארוכה (i). <span class=\"highlight\">שתי נקודות מתחת</span> בצורה העצמאית.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ي", "highlight": true, "name": "יַא"}, {"char": "و", "name": "וַאו"}, {"char": "م", "name": "מִים"}], "transliteration": "yawm", "meaning": "יום"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ب", "name": "בַּא"}, {"char": "ي", "highlight": true, "name": "יַא"}, {"char": "ن", "name": "נוּן"}], "transliteration": "bayn", "meaning": "בין"},
    {"position_label": "סוף מילה", "letters": [{"char": "ف", "name": "פַא"}, {"char": "ي", "highlight": true, "name": "יַא"}], "transliteration": "fi", "meaning": "ב־ / יש"}
  ]
}$$::jsonb);

-- Slide 9: ه (ha)
insert into lesson_slides (lesson_id, position, type, content) values
(101, 9, 'letter_identify', $${
  "title": "האות ه — הַא (צליל h)",
  "intro": "<span class=\"teal\">ה</span> — צליל h נושם. הצורה משתנה די הרבה בין המיקומים, שימו לב.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ه", "highlight": true, "name": "הַא"}, {"char": "ذ", "name": "דַ'אל"}, {"char": "ا", "name": "אַלֵף"}], "transliteration": "hadha", "meaning": "זה"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ف", "name": "פַא"}, {"char": "ه", "highlight": true, "name": "הַא"}, {"char": "م", "name": "מִים"}], "transliteration": "fahm", "meaning": "הבנה"},
    {"position_label": "סוף מילה", "letters": [{"char": "و", "name": "וַאו"}, {"char": "ج", "name": "גִ'ים"}, {"char": "ه", "highlight": true, "name": "הַא"}], "transliteration": "wajh", "meaning": "פנים"}
  ]
}$$::jsonb);

-- Slide 10: drag_game
insert into lesson_slides (lesson_id, position, type, content) values
(101, 10, 'letter_drag_game', $${
  "title": "מצאו את האות החסרה",
  "instructions": "אחת מהאותיות במילה חסרה. בחרו את הכרטיס המתאים.",
  "challenges": [
    {"word_letters": [{"char": "ش", "isolated": "ش", "name": "שִין"}, {"char": "م", "isolated": "م", "name": "מִים"}, {"char": "س", "isolated": "س", "name": "סִין"}], "target_index": 0, "correct_isolated": "ش", "correct_name": "שִין", "transliteration": "shams", "meaning": "שמש", "success_note": "ש פותחת!", "options": [{"isolated": "ش", "name": "שִין"}, {"isolated": "س", "name": "סִין"}, {"isolated": "ف", "name": "פַא"}, {"isolated": "ه", "name": "הַא"}]},
    {"word_letters": [{"char": "س", "isolated": "س", "name": "סִין"}, {"char": "ل", "isolated": "ل", "name": "לַאם"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "م", "isolated": "م", "name": "מִים"}], "target_index": 0, "correct_isolated": "س", "correct_name": "סִין", "transliteration": "salam", "meaning": "שלום", "success_note": "שלום!", "options": [{"isolated": "س", "name": "סִין"}, {"isolated": "ش", "name": "שִין"}, {"isolated": "ع", "name": "עַיְן"}, {"isolated": "ف", "name": "פַא"}]},
    {"word_letters": [{"char": "ع", "isolated": "ع", "name": "עַיְן"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ن", "isolated": "ن", "name": "נוּן"}], "target_index": 0, "correct_isolated": "ع", "correct_name": "עַיְן", "transliteration": "ʿayn", "meaning": "עין", "success_note": "ע גרונית!", "options": [{"isolated": "ع", "name": "עַיְן"}, {"isolated": "و", "name": "וַאו"}, {"isolated": "ه", "name": "הַא"}, {"isolated": "س", "name": "סִין"}]},
    {"word_letters": [{"char": "ك", "isolated": "ك", "name": "כַּאף"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ف", "isolated": "ف", "name": "פַא"}], "target_index": 2, "correct_isolated": "ف", "correct_name": "פַא", "transliteration": "kif", "meaning": "איך", "success_note": "נקודה אחת למעלה.", "options": [{"isolated": "ف", "name": "פַא"}, {"isolated": "ب", "name": "בַּא"}, {"isolated": "ت", "name": "תַּא"}, {"isolated": "ي", "name": "יַא"}]},
    {"word_letters": [{"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "و", "isolated": "و", "name": "וַאו"}, {"char": "م", "isolated": "م", "name": "מִים"}], "target_index": 1, "correct_isolated": "و", "correct_name": "וַאו", "transliteration": "yawm", "meaning": "יום", "success_note": "ו באמצע!", "options": [{"isolated": "و", "name": "וַאו"}, {"isolated": "ي", "name": "יַא"}, {"isolated": "ه", "name": "הַא"}, {"isolated": "ع", "name": "עַיְן"}]},
    {"word_letters": [{"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ن", "isolated": "ن", "name": "נוּן"}], "target_index": 1, "correct_isolated": "ي", "correct_name": "יַא", "transliteration": "bayn", "meaning": "בין", "success_note": "י באמצע.", "options": [{"isolated": "ي", "name": "יַא"}, {"isolated": "و", "name": "וַאו"}, {"isolated": "ه", "name": "הַא"}, {"isolated": "ن", "name": "נוּן"}]},
    {"word_letters": [{"char": "ه", "isolated": "ه", "name": "הַא"}, {"char": "ذ", "isolated": "ذ", "name": "דַ'אל"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}], "target_index": 0, "correct_isolated": "ه", "correct_name": "הַא", "transliteration": "hadha", "meaning": "זה", "success_note": "ה פותחת.", "options": [{"isolated": "ه", "name": "הַא"}, {"isolated": "ح", "name": "חַא"}, {"isolated": "ع", "name": "עַיְן"}, {"isolated": "ي", "name": "יַא"}]},
    {"word_letters": [{"char": "م", "isolated": "م", "name": "מִים"}, {"char": "ع", "isolated": "ع", "name": "עַיְן"}], "target_index": 1, "correct_isolated": "ع", "correct_name": "עַיְן", "transliteration": "maʿ", "meaning": "עם", "success_note": "ע בסוף.", "options": [{"isolated": "ع", "name": "עַיְן"}, {"isolated": "ه", "name": "הַא"}, {"isolated": "ن", "name": "נוּן"}, {"isolated": "م", "name": "מִים"}]}
  ]
}$$::jsonb);

-- Slide 11: summary
insert into lesson_slides (lesson_id, position, type, content) values
(101, 11, 'summary', $${
  "key_points": [
    {"title": "① האותיות של השיעור", "html": "<span class=\"teal\">ش</span> ש &nbsp;|&nbsp; <span class=\"teal\">س</span> ס &nbsp;|&nbsp; <span class=\"teal\">ع</span> ע׳ &nbsp;|&nbsp; <span class=\"teal\">ف</span> פ &nbsp;|&nbsp; <span class=\"teal\">و</span> ו &nbsp;|&nbsp; <span class=\"teal\">ي</span> י &nbsp;|&nbsp; <span class=\"teal\">ه</span> ה"},
    {"title": "② משפחת ש-ס", "html": "<b class=\"highlight\">ش</b> 3 נקודות למעלה &nbsp;·&nbsp; <b class=\"highlight\">س</b> ללא נקודות. אחרת — זהה."},
    {"title": "③ ע׳ ייחודית", "html": "ع היא הראשונה בקורס שאין מקבילה בעברית מודרנית. <span class=\"rose\">צליל גרוני</span> — עמוק בגרון."}
  ],
  "vocabulary_recap": ["شمس", "سلام", "عين", "كيف", "يوم", "هذا", "مع"],
  "next_lesson_teaser": "בשיעור הבא: 4 האותיות \"הכועסות\" — ص ض ط ظ. צלילים חזקים יותר שמגיעים מעומק הפה. 🔥"
}$$::jsonb);

commit;
