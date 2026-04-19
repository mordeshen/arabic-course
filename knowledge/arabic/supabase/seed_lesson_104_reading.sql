-- Seed: Lesson 104 — ייחודיות ב + אַלֵף (غ ق ر ز د ا)
begin;
delete from lesson_slides where lesson_id = 104;
delete from lessons where id = 104;

insert into lessons (id, number, part, title, subtitle, arabic_title, is_free, difficulty, description, active) values
  (104, 104, null, 'קריאה — אותיות ייחודיות (חלק ב) ואַלֵף', 'שיעור קריאה 5', 'الحروف الخاصّة ٢', true, 'beginner',
   '6 אותיות אחרונות לכיסוי כל האלפבית: غ ق ر ز د ا.', true);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 1, 'intro', $${
  "subtitle": "שיעור קריאה 5",
  "title": "שש אותיות לסיום",
  "arabic_title": "الحروف الخاصّة ٢",
  "ornament": "✦ ✧ ✦",
  "description": "השיעור האחרון בחלק הקריאה. אחרי זה — כל 28 האותיות שלכם."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 2, 'rule_card', $${
  "title": "מה נלמד",
  "html": "<span class=\"highlight\">6 אותיות</span> שמסיימות את האלפבית הערבי: <span class=\"teal\">غ</span> (ע' גרונית) &nbsp;·&nbsp; <span class=\"teal\">ق</span> (ק/עצירה) &nbsp;·&nbsp; <span class=\"teal\">ر</span> (ר) &nbsp;·&nbsp; <span class=\"teal\">ز</span> (ז) &nbsp;·&nbsp; <span class=\"teal\">د</span> (ד) &nbsp;·&nbsp; <span class=\"teal\">ا</span> (אַלֵף — תנועת a ארוכה).<br><br><span class=\"rose\">4 מתוך 6</span> לא מתחברות לאות הבאה: ر, ز, د, ا."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 3, 'letter_identify', $${
  "title": "האות غ — עַ'יְן (צליל gh)",
  "intro": "<span class=\"teal\">ע'</span> — צליל gh גרוני (כמו R צרפתית). אותה צורה כמו ع, רק עם <span class=\"highlight\">נקודה אחת למעלה</span>.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "غ", "highlight": true, "name": "עַ'יְן"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ب", "name": "בַּא"}, {"char": "ة", "name": "תַּא מַרבּוּטַה"}], "transliteration": "ghaba", "meaning": "יער"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ص", "name": "סַֿאד"}, {"char": "غ", "highlight": true, "name": "עַ'יְן"}, {"char": "ي", "name": "יַא"}, {"char": "ر", "name": "רַא"}], "transliteration": "saghir", "meaning": "קטן"},
    {"position_label": "סוף מילה", "letters": [{"char": "ف", "name": "פַא"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ر", "name": "רַא"}, {"char": "غ", "highlight": true, "name": "עַ'יְן"}], "transliteration": "farigh", "meaning": "ריק"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 4, 'letter_identify', $${
  "title": "האות ق — קַאף (צליל q / עצירה)",
  "intro": "<span class=\"teal\">ק</span> בערבית ספרותית = צליל q עמוק. <span class=\"rose\">בפלסטינית עירונית</span> נהגית כ-<b>עצירה גרונית</b> (כמו a בתחילת \"את\"). <span class=\"highlight\">2 נקודות למעלה</span>.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ق", "highlight": true, "name": "קַאף"}, {"char": "ل", "name": "לַאם"}, {"char": "ب", "name": "בַּא"}], "transliteration": "qalb / ʾalb", "meaning": "לב"},
    {"position_label": "אמצע מילה", "letters": [{"char": "و", "name": "וַאו"}, {"char": "ق", "highlight": true, "name": "קַאף"}, {"char": "ت", "name": "תַּא"}], "transliteration": "waqt", "meaning": "זמן"},
    {"position_label": "סוף מילה", "letters": [{"char": "ف", "name": "פַא"}, {"char": "و", "name": "וַאו"}, {"char": "ق", "highlight": true, "name": "קַאף"}], "transliteration": "fawq", "meaning": "מעל"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 5, 'letter_identify', $${
  "title": "האות ر — רַא (צליל r)",
  "intro": "<span class=\"teal\">ר מתגלגלת</span> — בערבית ה-ר נשמעת קרוב יותר לר איטלקית/ספרדית מאשר לר ישראלית. <span class=\"rose\">לא מתחברת</span> לאות הבאה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ر", "highlight": true, "name": "רַא"}, {"char": "ج", "name": "גִ'ים"}, {"char": "ل", "name": "לַאם"}], "transliteration": "rajul", "meaning": "גבר"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ك", "name": "כַּאף"}, {"char": "ر", "highlight": true, "name": "רַא"}, {"char": "ي", "name": "יַא"}, {"char": "م", "name": "מִים"}], "transliteration": "karim", "meaning": "נדיב"},
    {"position_label": "סוף מילה", "letters": [{"char": "ن", "name": "נוּן"}, {"char": "و", "name": "וַאו"}, {"char": "ر", "highlight": true, "name": "רַא"}], "transliteration": "nur", "meaning": "אור"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 6, 'letter_identify', $${
  "title": "האות ز — זַאי (צליל z)",
  "intro": "<span class=\"teal\">ז</span> פשוטה. אותה צורה כמו ר, רק עם <span class=\"highlight\">נקודה למעלה</span>. <span class=\"rose\">לא מתחברת</span> לאות הבאה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ز", "highlight": true, "name": "זַאי"}, {"char": "ي", "name": "יַא"}, {"char": "ت", "name": "תַּא"}], "transliteration": "zayt", "meaning": "שמן"},
    {"position_label": "אמצע מילה", "letters": [{"char": "أ", "name": "אַלֵף"}, {"char": "ز", "highlight": true, "name": "זַאי"}, {"char": "ر", "name": "רַא"}, {"char": "ق", "name": "קַאף"}], "transliteration": "azraq", "meaning": "כחול"},
    {"position_label": "סוף מילה", "letters": [{"char": "أ", "name": "אַלֵף"}, {"char": "ر", "name": "רַא"}, {"char": "ز", "highlight": true, "name": "זַאי"}], "transliteration": "aruzz", "meaning": "אורז"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 7, 'letter_identify', $${
  "title": "האות د — דַאל (צליל d)",
  "intro": "<span class=\"teal\">ד</span> פשוטה. זוהי האות הרגילה (לא הכועסת ض). <span class=\"rose\">לא מתחברת</span> לאות הבאה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "د", "highlight": true, "name": "דַאל"}, {"char": "ا", "name": "אַלֵף"}, {"char": "ر", "name": "רַא"}], "transliteration": "dar", "meaning": "בית"},
    {"position_label": "אמצע מילה", "letters": [{"char": "م", "name": "מִים"}, {"char": "د", "highlight": true, "name": "דַאל"}, {"char": "ي", "name": "יַא"}, {"char": "ن", "name": "נוּן"}, {"char": "ة", "name": "תַּא מַרבּוּטַה"}], "transliteration": "madina", "meaning": "עיר"},
    {"position_label": "סוף מילה", "letters": [{"char": "و", "name": "וַאו"}, {"char": "ل", "name": "לַאם"}, {"char": "د", "highlight": true, "name": "דַאל"}], "transliteration": "walad", "meaning": "ילד"}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 8, 'letter_identify', $${
  "title": "האות ا — אַלֵף (תנועת a ארוכה)",
  "intro": "<span class=\"teal\">אַלֵף</span> — האות הראשונה באלפבית, אבל הכי מיוחדת: היא מייצגת <span class=\"highlight\">תנועה</span> (a ארוכה), לא עיצור. <span class=\"rose\">לא מתחברת</span> לאות הבאה.",
  "examples": [
    {"position_label": "תחילת מילה", "letters": [{"char": "ا", "highlight": true, "name": "אַלֵף"}, {"char": "س", "name": "סִין"}, {"char": "م", "name": "מִים"}], "transliteration": "ism", "meaning": "שם"},
    {"position_label": "אמצע מילה", "letters": [{"char": "ب", "name": "בַּא"}, {"char": "ا", "highlight": true, "name": "אַלֵף"}, {"char": "ب", "name": "בַּא"}], "transliteration": "bab", "meaning": "דלת"},
    {"position_label": "סוף מילה", "letters": [{"char": "أ", "name": "אַלֵף"}, {"char": "ن", "name": "נוּן"}, {"char": "ا", "highlight": true, "name": "אַלֵף"}], "transliteration": "ana", "meaning": "אני"}
  ],
  "note": "<span class=\"teal\">הערה:</span> אַלֵף בתחילת מילה מופיעה לפעמים עם <b>המזה</b> (أ) — סימן של עצירה. נלמד על זה בשיעור דקדוק."
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 9, 'letter_drag_game', $${
  "title": "מצאו את האות החסרה",
  "instructions": "4 אותיות חסרות יחד — תעזרו לאוצר המילים שלכם.",
  "challenges": [
    {"word_letters": [{"char": "غ", "isolated": "غ", "name": "עַ'יְן"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ة", "isolated": "ة", "name": "תַּא מַרבּוּטַה"}], "target_index": 0, "correct_isolated": "غ", "correct_name": "עַ'יְן", "transliteration": "ghaba", "meaning": "יער", "success_note": "ע' גרונית!", "options": [{"isolated": "غ", "name": "עַ'יְן"}, {"isolated": "ع", "name": "עַיְן"}, {"isolated": "ق", "name": "קַאף"}, {"isolated": "خ", "name": "חַ'א"}]},
    {"word_letters": [{"char": "ق", "isolated": "ق", "name": "קַאף"}, {"char": "ل", "isolated": "ل", "name": "לַאם"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}], "target_index": 0, "correct_isolated": "ق", "correct_name": "קַאף", "transliteration": "qalb", "meaning": "לב", "success_note": "ק פותחת.", "options": [{"isolated": "ق", "name": "קַאף"}, {"isolated": "ف", "name": "פַא"}, {"isolated": "ك", "name": "כַּאף"}, {"isolated": "غ", "name": "עַ'יְן"}]},
    {"word_letters": [{"char": "ن", "isolated": "ن", "name": "נוּן"}, {"char": "و", "isolated": "و", "name": "וַאו"}, {"char": "ر", "isolated": "ر", "name": "רַא"}], "target_index": 2, "correct_isolated": "ر", "correct_name": "רַא", "transliteration": "nur", "meaning": "אור", "success_note": "ר בסוף.", "options": [{"isolated": "ر", "name": "רַא"}, {"isolated": "ز", "name": "זַאי"}, {"isolated": "د", "name": "דַאל"}, {"isolated": "ن", "name": "נוּן"}]},
    {"word_letters": [{"char": "ز", "isolated": "ز", "name": "זַאי"}, {"char": "ي", "isolated": "ي", "name": "יַא"}, {"char": "ت", "isolated": "ت", "name": "תַּא"}], "target_index": 0, "correct_isolated": "ز", "correct_name": "זַאי", "transliteration": "zayt", "meaning": "שמן", "success_note": "ז — נקודה למעלה על ר.", "options": [{"isolated": "ز", "name": "זַאי"}, {"isolated": "ر", "name": "רַא"}, {"isolated": "ذ", "name": "דַ'אל"}, {"isolated": "د", "name": "דַאל"}]},
    {"word_letters": [{"char": "و", "isolated": "و", "name": "וַאו"}, {"char": "ل", "isolated": "ل", "name": "לַאם"}, {"char": "د", "isolated": "د", "name": "דַאל"}], "target_index": 2, "correct_isolated": "د", "correct_name": "דַאל", "transliteration": "walad", "meaning": "ילד", "success_note": "ד פשוטה.", "options": [{"isolated": "د", "name": "דַאל"}, {"isolated": "ض", "name": "דַֿאד"}, {"isolated": "ذ", "name": "דַ'אל"}, {"isolated": "ر", "name": "רַא"}]},
    {"word_letters": [{"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "س", "isolated": "س", "name": "סִין"}, {"char": "م", "isolated": "م", "name": "מִים"}], "target_index": 0, "correct_isolated": "ا", "correct_name": "אַלֵף", "transliteration": "ism", "meaning": "שם", "success_note": "אַלֵף פותחת.", "options": [{"isolated": "ا", "name": "אַלֵף"}, {"isolated": "ل", "name": "לַאם"}, {"isolated": "د", "name": "דַאל"}, {"isolated": "ر", "name": "רַא"}]},
    {"word_letters": [{"char": "ب", "isolated": "ب", "name": "בַּא"}, {"char": "ا", "isolated": "ا", "name": "אַלֵף"}, {"char": "ب", "isolated": "ب", "name": "בַּא"}], "target_index": 1, "correct_isolated": "ا", "correct_name": "אַלֵף", "transliteration": "bab", "meaning": "דלת", "success_note": "אַלֵף באמצע — תנועת a ארוכה.", "options": [{"isolated": "ا", "name": "אַלֵף"}, {"isolated": "و", "name": "וַאו"}, {"isolated": "ي", "name": "יַא"}, {"isolated": "ن", "name": "נוּן"}]}
  ]
}$$::jsonb);

insert into lesson_slides (lesson_id, position, type, content) values
(104, 10, 'summary', $${
  "key_points": [
    {"title": "① 6 אותיות אחרונות", "html": "<span class=\"teal\">غ</span> ע' &nbsp;·&nbsp; <span class=\"teal\">ق</span> ק &nbsp;·&nbsp; <span class=\"teal\">ر</span> ר &nbsp;·&nbsp; <span class=\"teal\">ز</span> ז &nbsp;·&nbsp; <span class=\"teal\">د</span> ד &nbsp;·&nbsp; <span class=\"teal\">ا</span> אַלֵף"},
    {"title": "② 4 מהן לא מתחברות", "html": "<b class=\"highlight\">ر · ز · د · ا</b> לא מתחברות לאות הבאה — תמיד יוצרות \"חיתוך\" במילה."},
    {"title": "③ מסיימים את האלפבית!", "html": "28 אותיות — <span class=\"teal\">כולן שלכם</span>. עכשיו אתם מוכנים לקריאה אמיתית 🎉"}
  ],
  "vocabulary_recap": ["غابة", "قلب", "نور", "زيت", "ولد", "اسم"],
  "next_lesson_teaser": "סיימתם את חלק הקריאה! בהמשך — שיעור 3 של הקורס: כינויי גוף והיכרות. נתחיל לדבר בערבית 🗣️"
}$$::jsonb);

commit;
