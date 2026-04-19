-- ============================================================
-- Seed: Lesson 100 — Reading Arabic (לקרוא ערבית)
-- 10 slides: intro, approach, 6x letter_identify (ب ت ك ل م ن),
--            drag-game (10 challenges), summary.
-- After running, apply patch_reading_lesson_add_trace.sql to
-- interleave letter_trace slides after each letter_identify.
-- Prerequisites:
--   1. migration_lessons.sql            (base schema)
--   2. migration_letter_forms_table.sql (letter_identify type)
-- Idempotent: re-runs delete old content first.
-- ============================================================

begin;

-- Clean slate
delete from lesson_slides where lesson_id = 100;
delete from lessons where id = 100;

-- Lesson row
insert into lessons (id, number, part, title, subtitle, arabic_title, is_free, difficulty, description, active) values
  (100, 100, null, 'לקרוא ערבית', 'שיעור הקריאה', 'اقرأ', true, 'beginner',
   'לומדים 6 אותיות ראשונות בצורתן הכתובה, מזהים אותן במילים ומתרגלים לכתוב.', true);

-- ── Slide 1: intro ──────────────────────────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 1, 'intro', $${
  "subtitle": "שיעור הקריאה",
  "title": "לקרוא ערבית",
  "arabic_title": "اقرأ",
  "ornament": "✦ ✧ ✦",
  "description": "לאט לאט, אות אחרי אות — נלמד לזהות ולכתוב את האותיות הראשונות במילים אמיתיות."
}$$::jsonb);

-- ── Slide 2: rule_card — approach ───────────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 2, 'rule_card', $${
  "title": "איך נלמד",
  "html": "בשיעור הזה נכיר <span class=\"highlight\">6 אותיות</span> ראשונות. לכל אות נראה איך היא נראית בצורות שונות — <span class=\"teal\">בתחילת, באמצע ובסוף</span> המילה.<br><br>אחרי כל אות נתרגל לכתוב אותה בעצמנו במסגרת מקווקוות — כמו במחברת. בסוף — משחק זיהוי של כל האותיות יחד.<br><br><span class=\"rose\">האותיות מופרדות כאן לטובת הלימוד</span> — בכתיבה רגילה הן מחוברות."
}$$::jsonb);

-- ── Slide 3: letter_identify — ب (בַּא) ──────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 3, 'letter_identify', $${
  "title": "האות ب — בַּא (צליל b)",
  "intro": "האות <span class=\"teal\">ب</span> היא ב׳. תמיד יש לה <span class=\"highlight\">נקודה אחת מתחת</span> — גם כשהצורה משתנה לפי מיקומה במילה.",
  "examples": [
    {
      "position_label": "תחילת מילה",
      "letters": [
        {"char": "ب", "highlight": true, "name": "בַּא"},
        {"char": "ي", "name": "יַא"},
        {"char": "ت", "name": "תַּא"}
      ],
      "transliteration": "bayt",
      "meaning": "בית"
    },
    {
      "position_label": "אמצע מילה",
      "letters": [
        {"char": "ل", "name": "לַאם"},
        {"char": "ب", "highlight": true, "name": "בַּא"},
        {"char": "ن", "name": "נוּן"}
      ],
      "transliteration": "laban",
      "meaning": "יוגורט/לבן"
    },
    {
      "position_label": "סוף מילה",
      "letters": [
        {"char": "ك", "name": "כַּאף"},
        {"char": "ت", "name": "תַּא"},
        {"char": "ا", "name": "אַלֵף"},
        {"char": "ب", "highlight": true, "name": "בַּא"}
      ],
      "transliteration": "kitab",
      "meaning": "ספר"
    }
  ],
  "note": "<span class=\"teal\">הנקודה מתחת</span> היא הסימן הקבוע של ב׳ — גם כשהצורה משתנה, הנקודה תמיד שם."
}$$::jsonb);

-- ── Slide 4: letter_identify — ت (תַּא) ──────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 4, 'letter_identify', $${
  "title": "האות ت — תַּא (צליל t)",
  "intro": "האות <span class=\"teal\">ت</span> היא ת׳. דומה מאוד ל-ب, רק עם <span class=\"highlight\">שתי נקודות מלמעלה</span> במקום אחת מלמטה.",
  "examples": [
    {
      "position_label": "תחילת מילה",
      "letters": [
        {"char": "ت", "highlight": true, "name": "תַּא"},
        {"char": "ف", "name": "פַא"},
        {"char": "ا", "name": "אַלֵף"},
        {"char": "ح", "name": "חַא"}
      ],
      "transliteration": "tuffaḥ",
      "meaning": "תפוח"
    },
    {
      "position_label": "אמצע מילה",
      "letters": [
        {"char": "ك", "name": "כַּאף"},
        {"char": "ت", "highlight": true, "name": "תַּא"},
        {"char": "ا", "name": "אַלֵף"},
        {"char": "ب", "name": "בַּא"}
      ],
      "transliteration": "kitab",
      "meaning": "ספר"
    },
    {
      "position_label": "סוף מילה",
      "letters": [
        {"char": "ب", "name": "בַּא"},
        {"char": "ن", "name": "נוּן"},
        {"char": "ت", "highlight": true, "name": "תַּא"}
      ],
      "transliteration": "bint",
      "meaning": "בת/ילדה"
    }
  ],
  "note": "<span class=\"rose\">זכרו:</span> ب = נקודה אחת <b>למטה</b>. ت = שתי נקודות <b>למעלה</b>. אלה אותיות אחיות שמתבלבלות בקלות."
}$$::jsonb);

-- ── Slide 5: letter_identify — ك (כַּאף) ────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 5, 'letter_identify', $${
  "title": "האות ك — כַּאף (צליל k)",
  "intro": "האות <span class=\"teal\">ك</span> היא כ׳/ק׳ קשה. הצורה משתנה ממש בין תחילה/אמצע (צרה, פתוחה) לסוף/עצמאית (גדולה וזקופה).",
  "examples": [
    {
      "position_label": "תחילת מילה",
      "letters": [
        {"char": "ك", "highlight": true, "name": "כַּאף"},
        {"char": "ل", "name": "לַאם"},
        {"char": "ب", "name": "בַּא"}
      ],
      "transliteration": "kalb",
      "meaning": "כלב"
    },
    {
      "position_label": "אמצע מילה",
      "letters": [
        {"char": "ش", "name": "שִין"},
        {"char": "ك", "highlight": true, "name": "כַּאף"},
        {"char": "ر", "name": "רַא"},
        {"char": "ا", "name": "אַלֵף"}
      ],
      "transliteration": "shukran",
      "meaning": "תודה"
    },
    {
      "position_label": "סוף מילה",
      "letters": [
        {"char": "ش", "name": "שִין"},
        {"char": "ب", "name": "בַּא"},
        {"char": "ا", "name": "אַלֵף"},
        {"char": "ك", "highlight": true, "name": "כַּאף"}
      ],
      "transliteration": "shubbak",
      "meaning": "חלון"
    }
  ]
}$$::jsonb);

-- ── Slide 6: letter_identify — ل (לַאם) ────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 6, 'letter_identify', $${
  "title": "האות ل — לַאם (צליל l)",
  "intro": "האות <span class=\"teal\">ل</span> היא ל׳. הצורה הלטינית מזכירה את L. באמצע המילה היא מצטמצמת לקו אנכי.",
  "examples": [
    {
      "position_label": "תחילת מילה",
      "letters": [
        {"char": "ل", "highlight": true, "name": "לַאם"},
        {"char": "و", "name": "וַאו"},
        {"char": "ن", "name": "נוּן"}
      ],
      "transliteration": "lawn",
      "meaning": "צבע"
    },
    {
      "position_label": "אמצע מילה",
      "letters": [
        {"char": "ك", "name": "כַּאף"},
        {"char": "ل", "highlight": true, "name": "לַאם"},
        {"char": "ب", "name": "בַּא"}
      ],
      "transliteration": "kalb",
      "meaning": "כלב"
    },
    {
      "position_label": "סוף מילה",
      "letters": [
        {"char": "ج", "name": "גִ'ים"},
        {"char": "م", "name": "מִים"},
        {"char": "ل", "highlight": true, "name": "לַאם"}
      ],
      "transliteration": "jamal",
      "meaning": "גמל"
    }
  ]
}$$::jsonb);

-- ── Slide 7: letter_identify — م (מִים) ────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 7, 'letter_identify', $${
  "title": "האות م — מִים (צליל m)",
  "intro": "האות <span class=\"teal\">م</span> היא מ׳. יש לה <span class=\"highlight\">ראש עגול</span> וזנב שמשתנה לפי המיקום — בסוף המילה הזנב יורד וארוך.",
  "examples": [
    {
      "position_label": "תחילת מילה",
      "letters": [
        {"char": "م", "highlight": true, "name": "מִים"},
        {"char": "ا", "name": "אַלֵף"},
        {"char": "ي", "name": "יַא"}
      ],
      "transliteration": "may",
      "meaning": "מים"
    },
    {
      "position_label": "אמצע מילה",
      "letters": [
        {"char": "ج", "name": "גִ'ים"},
        {"char": "م", "highlight": true, "name": "מִים"},
        {"char": "ل", "name": "לַאם"}
      ],
      "transliteration": "jamal",
      "meaning": "גמל"
    },
    {
      "position_label": "סוף מילה",
      "letters": [
        {"char": "ي", "name": "יַא"},
        {"char": "و", "name": "וַאו"},
        {"char": "م", "highlight": true, "name": "מִים"}
      ],
      "transliteration": "yawm",
      "meaning": "יום"
    }
  ]
}$$::jsonb);

-- ── Slide 8: letter_identify — ن (נוּן) ────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 8, 'letter_identify', $${
  "title": "האות ن — נוּן (צליל n)",
  "intro": "האות <span class=\"teal\">ن</span> היא נ׳. צורת סירה עם <span class=\"highlight\">נקודה אחת מלמעלה</span>. שימו לב לדמיון המשפחתי עם ب ו-ت — רק הנקודות משתנות.",
  "examples": [
    {
      "position_label": "תחילת מילה",
      "letters": [
        {"char": "ن", "highlight": true, "name": "נוּן"},
        {"char": "و", "name": "וַאו"},
        {"char": "ر", "name": "רַא"}
      ],
      "transliteration": "nur",
      "meaning": "אור"
    },
    {
      "position_label": "אמצע מילה",
      "letters": [
        {"char": "ب", "name": "בַּא"},
        {"char": "ن", "highlight": true, "name": "נוּן"},
        {"char": "ت", "name": "תַּא"}
      ],
      "transliteration": "bint",
      "meaning": "בת/ילדה"
    },
    {
      "position_label": "סוף מילה",
      "letters": [
        {"char": "ا", "name": "אַלֵף"},
        {"char": "ب", "name": "בַּא"},
        {"char": "ن", "highlight": true, "name": "נוּן"}
      ],
      "transliteration": "ibn",
      "meaning": "בן"
    }
  ],
  "note": "⚠ משפחת ب-ת-נ: אותה צורת סירה, ההבדל רק בנקודות — <b class=\"highlight\">ب</b> אחת למטה · <b class=\"highlight\">ت</b> שתיים למעלה · <b class=\"highlight\">ن</b> אחת למעלה."
}$$::jsonb);

-- ── Slide 9: letter_drag_game — 10 challenges ───────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 9, 'letter_drag_game', $${
  "title": "מצאו את האות החסרה",
  "instructions": "בכל מילה חסרה אות אחת. לחצו על הכרטיס שלדעתכם מתאים.",
  "challenges": [
    {
      "word_letters": [
        {"char": "ب", "isolated": "ب", "name": "בַּא"},
        {"char": "ا", "isolated": "ا", "name": "אַלֵף"},
        {"char": "ب", "isolated": "ب", "name": "בַּא"}
      ],
      "target_index": 2,
      "correct_isolated": "ب",
      "correct_name": "בַּא",
      "transliteration": "bab",
      "meaning": "דלת",
      "success_note": "ב׳ בסוף המילה — אותה נקודה, רק עם זנב בצד.",
      "options": [
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ت", "name": "תַּא"},
        {"isolated": "ك", "name": "כַּאף"},
        {"isolated": "ل", "name": "לַאם"}
      ]
    },
    {
      "word_letters": [
        {"char": "ب", "isolated": "ب", "name": "בַּא"},
        {"char": "ن", "isolated": "ن", "name": "נוּן"},
        {"char": "ت", "isolated": "ت", "name": "תַּא"}
      ],
      "target_index": 1,
      "correct_isolated": "ن",
      "correct_name": "נוּן",
      "transliteration": "bint",
      "meaning": "בת/ילדה",
      "success_note": "נ׳ באמצע — נקודה אחת למעלה.",
      "options": [
        {"isolated": "ن", "name": "נוּן"},
        {"isolated": "م", "name": "מִים"},
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ت", "name": "תַּא"}
      ]
    },
    {
      "word_letters": [
        {"char": "ك", "isolated": "ك", "name": "כַּאף"},
        {"char": "ت", "isolated": "ت", "name": "תַּא"},
        {"char": "ا", "isolated": "ا", "name": "אַלֵף"},
        {"char": "ب", "isolated": "ب", "name": "בַּא"}
      ],
      "target_index": 0,
      "correct_isolated": "ك",
      "correct_name": "כַּאף",
      "transliteration": "kitab",
      "meaning": "ספר",
      "success_note": "כַּאף פותחת את המילה.",
      "options": [
        {"isolated": "ك", "name": "כַּאף"},
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ل", "name": "לַאם"},
        {"isolated": "ن", "name": "נוּן"}
      ]
    },
    {
      "word_letters": [
        {"char": "ك", "isolated": "ك", "name": "כַּאף"},
        {"char": "ل", "isolated": "ل", "name": "לַאם"},
        {"char": "ب", "isolated": "ب", "name": "בַּא"}
      ],
      "target_index": 1,
      "correct_isolated": "ل",
      "correct_name": "לַאם",
      "transliteration": "kalb",
      "meaning": "כלב",
      "success_note": "לַאם באמצע — רק קו אנכי פשוט.",
      "options": [
        {"isolated": "ل", "name": "לַאם"},
        {"isolated": "م", "name": "מִים"},
        {"isolated": "ن", "name": "נוּן"},
        {"isolated": "ت", "name": "תַּא"}
      ]
    },
    {
      "word_letters": [
        {"char": "ل", "isolated": "ل", "name": "לַאם"},
        {"char": "و", "isolated": "و", "name": "וַאו"},
        {"char": "ن", "isolated": "ن", "name": "נוּן"}
      ],
      "target_index": 0,
      "correct_isolated": "ل",
      "correct_name": "לַאם",
      "transliteration": "lawn",
      "meaning": "צבע",
      "success_note": "לַאם פותחת — הקו האנכי הגבוה.",
      "options": [
        {"isolated": "ل", "name": "לַאם"},
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ك", "name": "כַּאף"},
        {"isolated": "م", "name": "מִים"}
      ]
    },
    {
      "word_letters": [
        {"char": "ج", "isolated": "ج", "name": "גִ'ים"},
        {"char": "م", "isolated": "م", "name": "מִים"},
        {"char": "ل", "isolated": "ل", "name": "לַאם"}
      ],
      "target_index": 1,
      "correct_isolated": "م",
      "correct_name": "מִים",
      "transliteration": "jamal",
      "meaning": "גמל",
      "success_note": "מִים באמצע — העיגול הקטן עם זנב.",
      "options": [
        {"isolated": "م", "name": "מִים"},
        {"isolated": "ن", "name": "נוּן"},
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ل", "name": "לַאם"}
      ]
    },
    {
      "word_letters": [
        {"char": "ي", "isolated": "ي", "name": "יַא"},
        {"char": "و", "isolated": "و", "name": "וַאו"},
        {"char": "م", "isolated": "م", "name": "מִים"}
      ],
      "target_index": 2,
      "correct_isolated": "م",
      "correct_name": "מִים",
      "transliteration": "yawm",
      "meaning": "יום",
      "success_note": "מִים בסוף — הזנב נמשך למטה.",
      "options": [
        {"isolated": "م", "name": "מִים"},
        {"isolated": "ن", "name": "נוּן"},
        {"isolated": "ت", "name": "תַּא"},
        {"isolated": "ب", "name": "בַּא"}
      ]
    },
    {
      "word_letters": [
        {"char": "ن", "isolated": "ن", "name": "נוּן"},
        {"char": "و", "isolated": "و", "name": "וַאו"},
        {"char": "ر", "isolated": "ر", "name": "רַא"}
      ],
      "target_index": 0,
      "correct_isolated": "ن",
      "correct_name": "נוּן",
      "transliteration": "nur",
      "meaning": "אור",
      "success_note": "נ׳ פותחת — סירה עם נקודה אחת למעלה.",
      "options": [
        {"isolated": "ن", "name": "נוּן"},
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ت", "name": "תַּא"},
        {"isolated": "ل", "name": "לַאם"}
      ]
    },
    {
      "word_letters": [
        {"char": "ش", "isolated": "ش", "name": "שִין"},
        {"char": "ب", "isolated": "ب", "name": "בַּא"},
        {"char": "ا", "isolated": "ا", "name": "אַלֵף"},
        {"char": "ك", "isolated": "ك", "name": "כַּאף"}
      ],
      "target_index": 3,
      "correct_isolated": "ك",
      "correct_name": "כַּאף",
      "transliteration": "shubbak",
      "meaning": "חלון",
      "success_note": "כַּאף בסוף — הצורה הגדולה והפתוחה.",
      "options": [
        {"isolated": "ك", "name": "כַּאף"},
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ل", "name": "לַאם"},
        {"isolated": "ن", "name": "נוּן"}
      ]
    },
    {
      "word_letters": [
        {"char": "ل", "isolated": "ل", "name": "לַאם"},
        {"char": "ب", "isolated": "ب", "name": "בַּא"},
        {"char": "ن", "isolated": "ن", "name": "נוּן"}
      ],
      "target_index": 1,
      "correct_isolated": "ب",
      "correct_name": "בַּא",
      "transliteration": "laban",
      "meaning": "יוגורט/לבן",
      "success_note": "ב׳ — עם הנקודה למטה.",
      "options": [
        {"isolated": "ب", "name": "בַּא"},
        {"isolated": "ت", "name": "תַּא"},
        {"isolated": "ن", "name": "נוּן"},
        {"isolated": "م", "name": "מִים"}
      ]
    }
  ]
}$$::jsonb);

-- ── Slide 10: summary ───────────────────────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(100, 10, 'summary', $${
  "key_points": [
    {
      "title": "① 6 אותיות שלמדנו",
      "html": "<span class=\"teal\">ب</span> ב׳ &nbsp;|&nbsp; <span class=\"teal\">ت</span> ת׳ &nbsp;|&nbsp; <span class=\"teal\">ك</span> כ׳ &nbsp;|&nbsp; <span class=\"teal\">ل</span> ל׳ &nbsp;|&nbsp; <span class=\"teal\">م</span> מ׳ &nbsp;|&nbsp; <span class=\"teal\">ن</span> נ׳"
    },
    {
      "title": "② משפחת הנקודות",
      "html": "ב, ת, נ חולקות את אותה צורת \"סירה\". ההבדל רק בנקודות:<br><br><b class=\"highlight\">ب</b> נקודה אחת למטה &nbsp;·&nbsp; <b class=\"highlight\">ت</b> שתי נקודות למעלה &nbsp;·&nbsp; <b class=\"highlight\">ن</b> נקודה אחת למעלה"
    },
    {
      "title": "③ הצורה משתנה — הסימן נשאר",
      "html": "כל אות נראית קצת שונה <span class=\"teal\">בתחילה, באמצע ובסוף</span> המילה. אבל ה\"סימן המזהה\" (נקודות, עיגול, זנב) תמיד נשאר במקומו."
    }
  ],
  "vocabulary_recap": ["بيت", "كتاب", "كلب", "بنت", "جمل", "يوم"],
  "next_lesson_teaser": "בשיעור הבא נכיר עוד אותיות — ש, ס, ע, פ, ו, י, ה. לאט לאט, האלף-בית הערבי כולו יהיה שלכם. 🌙"
}$$::jsonb);

commit;

-- ============================================================
-- Verify:
--   select position, type from lesson_slides where lesson_id = 100 order by position;
-- Expected: 10 slides in order: intro, rule_card, letter_identify x6,
--           letter_drag_game, summary.
-- Next step: run patch_reading_lesson_add_trace.sql to add letter_trace slides.
-- ============================================================
