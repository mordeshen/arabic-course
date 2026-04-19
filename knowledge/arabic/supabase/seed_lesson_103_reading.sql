-- Seed: Lesson 103 — ייחודיות א (ث ج ح خ ذ)
begin;
delete from lesson_slides where lesson_id = 103;
delete from lessons where id = 103;

insert into lessons (id, number, part, title, subtitle, arabic_title, is_free, difficulty, description, active) values
  (103, 103, null, 'קריאה — אותיות ייחודיות (חלק א)', 'שיעור קריאה 4', 'الحروف الخاصّة ١', true, 'beginner',
   '5 אותיות עם צלילים ייחודיים לערבית: ث ج ح خ ذ.', true);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 1, 'intro', $${
  "subtitle": "שיעור קריאה 4",
  "title": "חמש אותיות ייחודיות",
  "arabic_title": "الحروف الخاصّة ١",
  "ornament": "✦ ✧ ✦",
  "description": "אותיות עם צלילים שקשה למצוא בעברית מודרנית — אבל הן חלק מההגייה הפלסטינית היומיומית."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 2, 'rule_card', $${
  "title": "מה נלמד",
  "html": "<span class=\"highlight\">5 אותיות</span> שהצליל שלהן דורש התרגלות: <span class=\"teal\">ث</span> (ת' כמו think) &nbsp;·&nbsp; <span class=\"teal\">ج</span> (ג׳/ז׳) &nbsp;·&nbsp; <span class=\"teal\">ح</span> (ח נקייה) &nbsp;·&nbsp; <span class=\"teal\">خ</span> (ח' גרונית) &nbsp;·&nbsp; <span class=\"teal\">ذ</span> (ד' כמו that)."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 3, 'letter_identify', $${
  "title": "האות ث — תַ'א (צליל th)",
  "intro": "<span class=\"teal\">ת'</span> כמו ב-<i>think</i> באנגלית. הלשון יוצאת קלות בין השיניים. <span class=\"highlight\">שלוש נקודות למעלה</span>.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ث", "highlight": true, "name": "תַ'א"}, {"char": "ل", "name": "לַאם"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ث", "name": "תַ'א"}, {"char": "ة", "name": "תַּא מַרבּוּטַה"}], "transliteration": "thalatha", "meaning": "שלוש"},
    {"position_label": "אמצע מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "ث", "highlight": true, "name": "תַ'א"}, {"char": "ل", "name": "לַאם"}], "transliteration": "mithl", "meaning": "כמו"},
    {"position_label": "סוף מילה", "letters": [{"char": "ح", "name": "חַא"}, {"char": "د", "name": "דַאל"}, {"char": "ي", "name": "יַא"}, {"char": "ث", "highlight": true, "name": "תַ'א"}], "transliteration": "hadith", "meaning": "שיחה / חדש"}
  ],
  "note": "<span class=\"rose\">ت (1 נק׳ למטה) · ب (1 למטה) · ث (3 למעלה)</span> — שמרו על הנקודות."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 4, 'letter_identify', $${
  "title": "האות ج — גִ'ים (צליל j / zh)",
  "intro": "<span class=\"teal\">ג׳</span> כמו ב-<i>ג׳ונגל</i>, או <span class=\"teal\">ז׳</span> בלבנונית/סורית. פלסטינית משתמשת בשניהם לפי האזור.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ج", "highlight": true, "name": "גִ'ים"}, {"char": "و", "name": "וַאו"}], "transliteration": "jaw", "meaning": "אווירה"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ر", "name": "רַא"}, {"char": "ج", "highlight": true, "name": "גִ'ים"}, {"char": "ل", "name": "לַאם"}], "transliteration": "rajul", "meaning": "גבר"},
    {"position_label": "סוף מילה", "letters": [{"char": "ز", "name": "זַאי"}, {"char": "و", "name": "וַאו"}, {"char": "ج", "highlight": true, "name": "גִ'ים"}], "transliteration": "zawj", "meaning": "בעל / זוג"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 5, 'letter_identify', $${
  "title": "האות ح — חַא (ח נקייה)",
  "intro": "<span class=\"teal\">ח נקייה, לא גרונית</span> — כמו ח׳ תימנית. מגיעה מעומק הגרון אבל בלי שריקה. חלק מהמילים הכי אהובות בערבית פותחות איתה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ح", "highlight": true, "name": "חַא"}, {"char": "ب", "name": "בַּא"}, {"char": "ي", "name": "יַא"}, {"char": "ب", "name": "בַּא"}, {"char": "ي", "name": "יַא"}], "transliteration": "ḥabibi", "meaning": "אהובי"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ر", "name": "רַא"}, {"char": "ح", "highlight": true, "name": "חַא"}, {"char": "م", "name": "מִים"}, {"char": "ة", "name": "תַּא מַרבּוּטַה"}], "transliteration": "raḥma", "meaning": "חמלה"},
    {"position_label": "סוף מילה", "letters": [{"char": "ص", "name": "סַֿאד"}, {"char": "ب", "name": "בַּא"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ح", "highlight": true, "name": "חַא"}], "transliteration": "sabaḥ", "meaning": "בוקר"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 6, 'letter_identify', $${
  "title": "האות خ — חַ'א (צליל kh גרוני)",
  "intro": "<span class=\"teal\">ח' גרונית</span> כמו ב-<i>אחרי</i>, או בגרמנית <i>Bach</i>. <span class=\"highlight\">נקודה אחת למעלה</span> על אותה צורה של ح.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "خ", "highlight": true, "name": "חַ'א"}, {"char": "ي", "name": "יַא"}, {"char": "ر", "name": "רַא"}], "transliteration": "khayr", "meaning": "טוב / טובה"},
    {"position_label": "אמצע מילה", "letters": [{"char": "د", "name": "דַאל"}, {"char": "خ", "highlight": true, "name": "חַ'א"}, {"char": "ل", "name": "לַאם"}], "transliteration": "dakhal", "meaning": "נכנס"},
    {"position_label": "סוף מילה", "letters": [{"char": "ط", "name": "טַא"}, {"char": "ب", "name": "בַּא"}, {"char": "خ", "highlight": true, "name": "חַ'א"}], "transliteration": "tabakh", "meaning": "בישל"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 7, 'letter_identify', $${
  "title": "האות ذ — דַ'אל (צליל th כמו that)",
  "intro": "<span class=\"teal\">ד'</span> כמו <i>th</i> ב-<i>that</i>. לשון בין השיניים. <span class=\"rose\">לא מתחברת</span> לאות הבאה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ذ", "highlight": true, "name": "דַ'אל"}, {"char": "ه", "name": "הַא"}, {"char": "ب", "name": "בַּא"}], "transliteration": "dhahab", "meaning": "זהב / הלך"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ه", "name": "הַא"}, {"char": "ذ", "highlight": true, "name": "דַ'אל"}, {"char": "ا", "name": "אַלֵף"}], "transliteration": "hadha", "meaning": "זה"},
    {"position_label": "סוף מילה", "letters": [{"char": "أ", "name": "אַלֵף"}, {"char": "س", "name": "סִין"}, {"char": "ت", "name": "תַּא"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ذ", "highlight": true, "name": "דַ'אל"}], "transliteration": "ustadh", "meaning": "מורה / אדון"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 8, 'letter_drag_game', $${
  "title": "מצאו את האות הייחודית",
  "instructions": "שימו לב לנקודות ולצורה — אחיות קרובות מתבלבלות בקלות.",
  "challenges": [
    {"word_letters": [{"char": "ث", "isolated": "ث", "name": "תַ'א"}, {"char": "ل", "isolated": "ل", "name": "לַאם"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "ث", "isolated": "ث", "name": "תַ'א"}, {"char": "ة", "isolated": "ة", "name": "תַּא מַרבּוּטַה"}], "target_index": 0, "correct_isolated": "ث", "correct_name": "תַ'א", "transliteration": "thalatha", "meaning": "שלוש", "success_note": "ת' — 3 נקודות למעלה.", "options": [{"isolated": "ث", "name": "תַ'א"}, {"isolated": "ت", "name": "תַּא"}, {"isolated": "ب", "name": "בַּא"}, {"isolated": "ن", "name": "נוּן"}]},
    {"word_letters": [{"char": "ج", "isolated": "ج", "name": "גִ'ים"}, {"char": "و", "isolated": "و", "name": "וַאו"}], "target_index": 0, "correct_isolated": "ج", "correct_name": "גִ'ים", "transliteration": "jaw", "meaning": "אווירה", "success_note": "ג׳ פותחת.", "options": [{"isolated": "ج", "name": "גִ'ים"}, {"isolated": "ح", "name": "חַא"}, {"isolated": "خ", "name": "חַ'א"}, {"isolated": "ذ", "name": "דַ'אל"}]},
    {"word_letters": [{"char": "ح", "isolated": "ح", "name": "חַא"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ي", "isolated": "ي", "name": "יַא"}], "target_index": 0, "correct_isolated": "ح", "correct_name": "חַא", "transliteration": "ḥabibi", "meaning": "אהובי", "success_note": "ח נקייה — בלי נקודות!", "options": [{"isolated": "ح", "name": "חַא"}, {"isolated": "ج", "name": "גִ'ים"}, {"isolated": "خ", "name": "חַ'א"}, {"isolated": "ه", "name": "הַא"}]},
    {"word_letters": [{"char": "خ", "isolated": "خ", "name": "חַ'א"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ر", "isolated": "ر", "name": "רַא"}], "target_index": 0, "correct_isolated": "خ", "correct_name": "חַ'א", "transliteration": "khayr", "meaning": "טוב", "success_note": "ח' — נקודה למעלה.", "options": [{"isolated": "خ", "name": "חַ'א"}, {"isolated": "ح", "name": "חַא"}, {"isolated": "ج", "name": "גִ'ים"}, {"isolated": "ذ", "name": "דַ'אל"}]},
    {"word_letters": [{"char": "ه", "isolated": "ه", "name": "הַא"}, {"char": "ذ", "isolated": "ذ", "name": "דַ'אל"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}], "target_index": 1, "correct_isolated": "ذ", "correct_name": "דַ'אל", "transliteration": "hadha", "meaning": "זה", "success_note": "ד' באמצע — לא מתחברת לאות הבאה.", "options": [{"isolated": "ذ", "name": "דַ'אל"}, {"isolated": "د", "name": "דַאל"}, {"isolated": "ث", "name": "תַ'א"}, {"isolated": "ز", "name": "זַאי"}]},
    {"word_letters": [{"char": "م", "isolated": "م", "name": "מִים"}, {"char": "ث", "isolated": "ث", "name": "תַ'א"}, {"char": "ل", "isolated": "ل", "name": "לַאם"}], "target_index": 1, "correct_isolated": "ث", "correct_name": "תַ'א", "transliteration": "mithl", "meaning": "כמו", "success_note": "ת' באמצע.", "options": [{"isolated": "ث", "name": "תַ'א"}, {"isolated": "ت", "name": "תַּא"}, {"isolated": "ش", "name": "שִין"}, {"isolated": "س", "name": "סִין"}]}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(103, 9, 'summary', $${
  "key_points": [
    {"title": "① 5 ייחודיות", "html": "<span class=\"teal\">ث</span> ת' &nbsp;·&nbsp; <span class=\"teal\">ج</span> ג׳/ז׳ &nbsp;·&nbsp; <span class=\"teal\">ح</span> ח נקייה &nbsp;·&nbsp; <span class=\"teal\">خ</span> ח' גרונית &nbsp;·&nbsp; <span class=\"teal\">ذ</span> ד'"},
    {"title": "② משפחת ح ج خ", "html": "<b class=\"highlight\">3 אחיות עם אותה צורת עיגול</b>: ج נקודה למטה · ح ללא נקודה · خ נקודה למעלה."},
    {"title": "③ ת' וד' — בין השיניים", "html": "ث ו-ذ הן \"צלילי בין-שיניים\" — דורשים לתרגל. כדי לא להתבלבל: <b>ث = th</b> של <i>think</i>, <b>ذ = th</b> של <i>that</i>."}
  ],
  "vocabulary_recap": ["ثلاثة", "جو", "حبيبي", "خير", "هذا"],
  "next_lesson_teaser": "שיעור אחרון של קריאה: 6 אותיות אחרונות — غ ق ر ز د ا. אחרי זה תכירו את כל 28 האותיות. 🎯"
}$$::jsonb);

commit;
