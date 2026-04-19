-- ============================================================
-- Arabic Course — Seed for Lesson 1 (האותיות)
-- 1:1 reproduction of app/lessons/lesson_01.html (after the U+0651
-- shadda → Hebrew dagesh fix), plus a new letter_forms_table slide
-- that teaches the Arabic alphabet contextual forms.
-- ============================================================
-- Run order:
--   1. migration_lessons.sql (already done)
--   2. migration_letter_forms_table.sql (registers the new type)
--   3. THIS file (seeds 14 slides for lesson 1)
-- Idempotent: deletes any existing slides for lesson 1 first.
-- Uses $$...$$ dollar-quoting + ::jsonb to keep Hebrew text clean.
-- ============================================================

begin;

delete from lesson_slides where lesson_id = 1;

-- ── Slide 1: intro (was s0) ──────────────────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 1, 'intro', $${
  "title": "האותיות",
  "subtitle": "שיעור 1",
  "arabic_title": "ברוך הבא לערבית",
  "ornament": "✦ ✧ ✦",
  "description": "המטרה: להכיר את האותיות בערבית ואת הצלילים שלהן. נלמד שהרבה אותיות דומות לעברית, חלקן \"כועסות\", וחלקן ייחודיות לגמרי."
}$$::jsonb);

-- ── Slide 2: rule_card — שלוש קבוצות אותיות (from s1) ────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 2, 'rule_card', $${
  "title": "שלוש קבוצות אותיות",
  "html": "האותיות בערבית מדוברת (פלסטינית) מתחלקות לשלוש קבוצות:<br><br><span class=\"highlight\">קבוצה 1 — זהות לעברית:</span> אותיות שנשמעות בדיוק כמו בעברית. אם אתם יודעים עברית, כבר מכירים אותן!<br><br><span class=\"rose\">קבוצה 2 — \"כועסות\":</span> אותיות שנשמעות כמו אותיות רגילות, אבל נהגות בצורה \"כבדה\" יותר — הלשון נדחסת למטה, הפה נפתח רחב. כאילו האות כועסת.<br><br><span class=\"teal\">קבוצה 3 — ייחודיות:</span> צלילים שלא קיימים בעברית כלל. צריך ללמוד אותם מאפס."
}$$::jsonb);

-- ── Slide 3: collision_arena — עברית + ערבית = משפחה אחת ─────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 3, 'collision_arena', $${
  "left_word": "עברית",
  "operator": "❤",
  "right_word": "ערבית",
  "result": "משפחה אחת!",
  "result_label": "= שפות שמיות אחיות"
}$$::jsonb);

-- ── Slide 4: rule_card — מילים דומות (from s1) ───────────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 4, 'rule_card', $${
  "title": "מילים דומות בעברית ובערבית",
  "html": "<span class=\"highlight\">מילים דומות:</span><br><br>שָׁלוֹם ↔ סַלַאם &nbsp;|&nbsp; בַּיִת ↔ בֵּית &nbsp;|&nbsp; כֶּלֶב ↔ כַּלְבּ &nbsp;|&nbsp; סֵפֶר ↔ סִפְר<br><br><span class=\"teal\">עברית וערבית הן שפות שמיות אחיות — הרבה מילים חולקות שורש משותף!</span>"
}$$::jsonb);

-- ── Slide 5: letter_chips (from s2) — 1:1 to legacy ──────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 5, 'letter_chips', $${
  "groups": [
    {
      "title": "קבוצה 1 — זהות לעברית",
      "color": "gold",
      "letters": [
        {"letter": "בּ", "example": "בּאבּ [דלת]"},
        {"letter": "ת",  "example": "שַנְתֵה [תיק]"},
        {"letter": "ד",  "example": "חַ'אלֵד"},
        {"letter": "ר",  "example": "כמו ר בעברית (ברור) | מַררַה [פעם]"},
        {"letter": "ז",  "example": "מֻמְתאז [מצוין]"},
        {"letter": "ש",  "example": "שַמְס [שמש]"},
        {"letter": "ס",  "example": "שַמְס [שמש]"},
        {"letter": "ע",  "example": "יַעְני [כלומר]"},
        {"letter": "פ",  "example": "פַיְרוּז"},
        {"letter": "כּ", "example": "כַּלְבּ [כלב]"},
        {"letter": "ל",  "example": "מַלאן [מלא]"},
        {"letter": "מ",  "example": "מַלאן [מלא]"},
        {"letter": "נ",  "example": "מַלאן [מלא]"},
        {"letter": "ה",  "example": "מַפְהוּם [מובן]"},
        {"letter": "ו",  "example": "וַלַד [ילד]"},
        {"letter": "י",  "example": "יַללא [קדימה]"},
        {"letter": "ח",  "example": "נקייה — שילוב ח׳ וה׳ | חַבּיבּי [אהובי]"}
      ],
      "note": "💡 שימו לב: בערבית אין פּ דגושה (P) — רק פ רפויה (F), כמו במילה \"רפוי\""
    },
    {
      "title": "קבוצה 2 — \"כועסות\"",
      "color": "rose",
      "letters": [
        {"letter": "ט",  "example": "ת כועסת | בַּטְּאטְּא [תפו\"א]"},
        {"letter": "דֿ", "example": "ד כועסת | דַֿחְכֵּה [צחוק]"},
        {"letter": "סֿ", "example": "ס כועסת | סַֿףּ [כיתה]"},
        {"letter": "זֿ", "example": "ז כועסת | מַזְֿבּוּטְּ [נכון]"}
      ]
    },
    {
      "title": "קבוצה 3 — ייחודיות",
      "color": "teal",
      "letters": [
        {"letter": "ת'", "example": "th כמו think | מַתַ'ל [פתגם]"},
        {"letter": "ד'", "example": "th כמו that | האד'י [זו, זאת]"},
        {"letter": "ג'", "example": "j/zh | גַ'ו [אווירה]"},
        {"letter": "ח'", "example": "kh כמו בעברית | ח'אלֵד"},
        {"letter": "ע'", "example": "gh גרונית | ע'אבּה [יער]"},
        {"letter": "ק",  "example": "עצירה גרונית | קַלְבּי [הלב שלי]"}
      ]
    }
  ]
}$$::jsonb);

-- ── Slide 6: letter_forms_table (NEW) ────────────────────────
-- 28 letters × 4 forms (isolated/initial/medial/final) + Hebrew name + sound + example
insert into lesson_slides (lesson_id, position, type, content) values
(1, 6, 'letter_forms_table', $${
  "title": "צורות האותיות",
  "intro_html": "כל אות בערבית יכולה להיכתב ב-<span class=\"highlight\">4 צורות</span> שונות, תלוי איפה היא נמצאת במילה: לבד, בתחילת המילה, באמצע, או בסוף.<br><span class=\"teal\">6 אותיות לא מתחברות לאות הבאה</span> — הן \"קוטעות\" את המילה לשני חלקים.",
  "rows": [
    {"hebrew_name": "אַלֵף",  "sound": "a",          "isolated": "ا", "initial": "ا",  "medial": "ـا",  "final": "ـا",  "example_arabic": "أَنَا",     "example_hebrew": "אַנא — אני",      "non_connector": true},
    {"hebrew_name": "בַּא",   "sound": "b",          "isolated": "ب", "initial": "بـ", "medial": "ـبـ", "final": "ـب", "example_arabic": "بَاب",      "example_hebrew": "בּאבּ — דלת"},
    {"hebrew_name": "תַּא",   "sound": "t",          "isolated": "ت", "initial": "تـ", "medial": "ـتـ", "final": "ـت", "example_arabic": "شَنْتَة",   "example_hebrew": "שַנְתֵה — תיק"},
    {"hebrew_name": "תַ'א",   "sound": "th (think)", "isolated": "ث", "initial": "ثـ", "medial": "ـثـ", "final": "ـث", "example_arabic": "مَتَل",     "example_hebrew": "מַתַ'ל — פתגם"},
    {"hebrew_name": "גִ'ים",  "sound": "j / zh",     "isolated": "ج", "initial": "جـ", "medial": "ـجـ", "final": "ـج", "example_arabic": "جَو",       "example_hebrew": "גַ'ו — אווירה"},
    {"hebrew_name": "חַא",    "sound": "ḥ נקייה",     "isolated": "ح", "initial": "حـ", "medial": "ـحـ", "final": "ـح", "example_arabic": "حَبِيبِي",  "example_hebrew": "חַבּיבּי — אהובי"},
    {"hebrew_name": "חַ'א",   "sound": "kh",         "isolated": "خ", "initial": "خـ", "medial": "ـخـ", "final": "ـخ", "example_arabic": "خَالِد",    "example_hebrew": "חַ'אלֵד — שם"},
    {"hebrew_name": "דַאל",   "sound": "d",          "isolated": "د", "initial": "د",  "medial": "ـد",  "final": "ـد",  "example_arabic": "دَار",      "example_hebrew": "דאר — בית", "non_connector": true},
    {"hebrew_name": "דַ'אל",  "sound": "th (that)",  "isolated": "ذ", "initial": "ذ",  "medial": "ـذ",  "final": "ـذ",  "example_arabic": "هَاذِي",    "example_hebrew": "האד'י — זאת", "non_connector": true},
    {"hebrew_name": "רַא",    "sound": "r",          "isolated": "ر", "initial": "ر",  "medial": "ـر",  "final": "ـر",  "example_arabic": "مَرَّة",    "example_hebrew": "מַררַה — פעם", "non_connector": true},
    {"hebrew_name": "זַאי",   "sound": "z",          "isolated": "ز", "initial": "ز",  "medial": "ـز",  "final": "ـز",  "example_arabic": "مُمْتَاز",  "example_hebrew": "מֻמְתאז — מצוין", "non_connector": true},
    {"hebrew_name": "סִין",   "sound": "s",          "isolated": "س", "initial": "سـ", "medial": "ـسـ", "final": "ـس", "example_arabic": "شَمْس",     "example_hebrew": "שַמְס — שמש"},
    {"hebrew_name": "שִין",   "sound": "sh",         "isolated": "ش", "initial": "شـ", "medial": "ـشـ", "final": "ـش", "example_arabic": "شُكْرَاً",   "example_hebrew": "שֻכְּרַן — תודה"},
    {"hebrew_name": "סַֿאד",  "sound": "ṣ כועסת",     "isolated": "ص", "initial": "صـ", "medial": "ـصـ", "final": "ـص", "example_arabic": "صَفّ",      "example_hebrew": "סַֿףּ — כיתה"},
    {"hebrew_name": "דַֿאד",  "sound": "ḍ כועסת",     "isolated": "ض", "initial": "ضـ", "medial": "ـضـ", "final": "ـض", "example_arabic": "ضَيْف",     "example_hebrew": "דַֿיְף — אורח"},
    {"hebrew_name": "טַא",    "sound": "ṭ כועסת",     "isolated": "ط", "initial": "طـ", "medial": "ـطـ", "final": "ـط", "example_arabic": "بَطَّاطَا", "example_hebrew": "בַּטְּאטְּא — תפו\"א"},
    {"hebrew_name": "זַֿא",   "sound": "ẓ כועסת",     "isolated": "ظ", "initial": "ظـ", "medial": "ـظـ", "final": "ـظ", "example_arabic": "ظَهْر",     "example_hebrew": "זַֿהְר — צוהריים"},
    {"hebrew_name": "עַיְן",  "sound": "ʿ גרונית",   "isolated": "ع", "initial": "عـ", "medial": "ـعـ", "final": "ـع", "example_arabic": "يَعْنِي",   "example_hebrew": "יַעְני — כלומר"},
    {"hebrew_name": "עַ'יְן", "sound": "gh גרונית",  "isolated": "غ", "initial": "غـ", "medial": "ـغـ", "final": "ـغ", "example_arabic": "غَابَة",    "example_hebrew": "ע'אבּה — יער"},
    {"hebrew_name": "פַא",    "sound": "f",          "isolated": "ف", "initial": "فـ", "medial": "ـفـ", "final": "ـف", "example_arabic": "فَيْرُوز",  "example_hebrew": "פַיְרוּז — שם"},
    {"hebrew_name": "קַאף",   "sound": "q / עצירה",  "isolated": "ق", "initial": "قـ", "medial": "ـقـ", "final": "ـق", "example_arabic": "قَلْبِي",   "example_hebrew": "קַלְבּי — הלב שלי"},
    {"hebrew_name": "כַּאף",  "sound": "k",          "isolated": "ك", "initial": "كـ", "medial": "ـكـ", "final": "ـك", "example_arabic": "كَلْب",     "example_hebrew": "כַּלְבּ — כלב"},
    {"hebrew_name": "לַאם",   "sound": "l",          "isolated": "ل", "initial": "لـ", "medial": "ـلـ", "final": "ـل", "example_arabic": "مَلْآن",    "example_hebrew": "מַלאן — מלא"},
    {"hebrew_name": "מִים",   "sound": "m",          "isolated": "م", "initial": "مـ", "medial": "ـمـ", "final": "ـم", "example_arabic": "مَرْحَبَا",  "example_hebrew": "מַרְחַבּא — שלום"},
    {"hebrew_name": "נוּן",   "sound": "n",          "isolated": "ن", "initial": "نـ", "medial": "ـنـ", "final": "ـن", "example_arabic": "نُور",      "example_hebrew": "נוּר — אור"},
    {"hebrew_name": "הַא",    "sound": "h",          "isolated": "ه", "initial": "هـ", "medial": "ـهـ", "final": "ـه", "example_arabic": "مَفْهُوم",  "example_hebrew": "מַפְהוּם — מובן"},
    {"hebrew_name": "וַאו",   "sound": "w / u",      "isolated": "و", "initial": "و",  "medial": "ـو",  "final": "ـو",  "example_arabic": "وَلَد",     "example_hebrew": "וַלַד — ילד", "non_connector": true},
    {"hebrew_name": "יַא",    "sound": "y / i",      "isolated": "ي", "initial": "يـ", "medial": "ـيـ", "final": "ـي", "example_arabic": "يَلَّا",    "example_hebrew": "יַללא — קדימה"}
  ],
  "note": "🔸 ה-✕ באותיות עם <span class=\"rose\">צבע אדום</span> מסמן שהן <span class=\"highlight\">לא מתחברות</span> לאות הבאה אחריהן — הן תמיד \"חותכות\" את המילה. 6 כאלה: ا ، د ، ذ ، ر ، ز ، و"
}$$::jsonb);

-- ── Slide 7: vocab_grid — 5 מילים ראשונות (from s3) ──────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 7, 'vocab_grid', $${
  "title": "5 המילים הראשונות",
  "items": [
    {"arabic": "אַנא",      "hebrew": "אני"},
    {"arabic": "שֻכְּרַן",   "hebrew": "תודה"},
    {"arabic": "מַרְחַבּא",  "hebrew": "שלום/היי"},
    {"arabic": "אַיְוַה",    "hebrew": "כן"},
    {"arabic": "לַאְ",      "hebrew": "לא"}
  ]
}$$::jsonb);

-- ── Slide 8: rule_card — טיפ (from s3) ───────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 8, 'rule_card', $${
  "title": "טיפ",
  "html": "שימו לב — <span class=\"teal\">אַנא</span> (אני) מתחילה באות <span class=\"highlight\">א</span> שהיא אות עיצורית.<br><br><span class=\"teal\">שֻכְּרַן</span> (תודה) מכילה את האות <span class=\"highlight\">ש</span> — זהה לעברית!<br><br><span class=\"rose\">מַרְחַבּא</span> (שלום) היא הברכה הכי נפוצה — אפשר להשתמש בה תמיד."
}$$::jsonb);

-- ── Slide 9: example_cards — מילים לכל קבוצה (from s4) ──────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 9, 'example_cards', $${
  "title": "מילים לכל קבוצה",
  "items": [
    {"arabic_phrase": "קבוצה 1 | בּאבּ",     "separator": "=", "hebrew_translation": "דלת",  "translation_note": "בּ — כמו בעברית"},
    {"arabic_phrase": "קבוצה 1 | חַבּיבּי",   "separator": "=", "hebrew_translation": "אהובי", "translation_note": "ח — ח׳ נקייה, כמו הגייה תימנית. הח׳ של חביבי!"},
    {"arabic_phrase": "קבוצה 2 | סַֿףּ",      "separator": "=", "hebrew_translation": "כיתה", "translation_note": "סֿ — ס כועסת"},
    {"arabic_phrase": "קבוצה 2 | דַֿחְכֵּה",  "separator": "=", "hebrew_translation": "צחוק", "translation_note": "דֿ — ד כועסת"},
    {"arabic_phrase": "קבוצה 3 | גַ'ו",       "separator": "=", "hebrew_translation": "אווירה", "translation_note": "ג׳ — כמו ז׳ בז׳רגון, ז׳אנר"},
    {"arabic_phrase": "קבוצה 3 | ע'אבּה",     "separator": "=", "hebrew_translation": "יער",    "translation_note": "ע' — צליל gh גרוני"}
  ]
}$$::jsonb);

-- ── Slide 10: quiz_match #1 — התאימו אות לקבוצה (from s5) ────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 10, 'quiz_match', $${
  "title": "התאימו אות לקבוצה",
  "reveal_all_button": true,
  "questions": [
    {"question": "1. לאיזו קבוצה שייכת האות ט?",   "answer": "קבוצה 2 — כועסות (ת כועסת)", "hint": "אות כועסת"},
    {"question": "2. לאיזו קבוצה שייכת האות ג'?",  "answer": "קבוצה 3 — ייחודיות (j/zh)",   "hint": "צליל שלא קיים בעברית"},
    {"question": "3. לאיזו קבוצה שייכת האות ש?",   "answer": "קבוצה 1 — זהה לעברית",        "hint": "שַמְס = שמש"},
    {"question": "4. מה זה בעברית? שֻכְּרַן",      "answer": "תודה",                         "hint": "מילה משיעור 1"},
    {"question": "5. מה זה בעברית? מַרְחַבּא",     "answer": "שלום/היי",                    "hint": "הברכה הכי נפוצה"},
    {"question": "6. לאיזו קבוצה שייכת האות סֿ?",  "answer": "קבוצה 2 — כועסות (ס כועסת)", "hint": "סַֿףּ = כיתה"}
  ]
}$$::jsonb);

-- ── Slide 11: quiz_match #2 — התאימו מילה למשמעות (from s6) ──
insert into lesson_slides (lesson_id, position, type, content) values
(1, 11, 'quiz_match', $${
  "title": "התאימו מילה למשמעות",
  "reveal_all_button": true,
  "questions": [
    {"question": "1. איך אומרים \"אני\" בערבית?",  "answer": "אַנא"},
    {"question": "2. איך אומרים \"כן\" בערבית?",   "answer": "אַיְוַה"},
    {"question": "3. איך אומרים \"לא\" בערבית?",   "answer": "לַאְ"},
    {"question": "4. מה הצליל של ת'?",            "answer": "th כמו think"},
    {"question": "5. מה מיוחד באות ק בערבית מדוברת?", "answer": "נהגית כא עיצורית (עצירה גרונית)", "hint": "קַלְבּי = אַלְבּי"}
  ]
}$$::jsonb);

-- ── Slide 12: rule_card — 🎵 השיר (from s6) ──────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 12, 'rule_card', $${
  "title": "🎵 זהו את המילה הערבית!",
  "html": "<div style=\"text-align:center\"><span class=\"highlight\">שׁוּכְּרַן</span> על כל מה שבראת<br><span style=\"font-size:12px;opacity:0.7\">(תודה → שׁוּכְּרַן)</span><br><br><span class=\"highlight\">אַיְוַה אַיְוַה אַיְוַה</span> נבנה לנו קן<br><span style=\"font-size:12px;opacity:0.7\">(כן → אַיְוַה)</span><br><br><span class=\"highlight\">סַבָּאח אַלְחֵ׳יר</span> אדון שוקו<br><span style=\"font-size:12px;opacity:0.7\">(בוקר טוב → סַבָּאח אַלְחֵ׳יר)</span><br><br><span class=\"highlight\">אַנָא</span> ואתה נשנה את העולם<br><span style=\"font-size:12px;opacity:0.7\">(אני → אַנָא)</span></div>"
}$$::jsonb);

-- ── Slide 13: memory_game (from sGAME) ───────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 13, 'memory_game', $${
  "show_timer": true,
  "pairs": [
    {"arabic": "אַנא",     "hebrew": "אני"},
    {"arabic": "שֻכְּרַן",  "hebrew": "תודה"},
    {"arabic": "מַרְחַבּא", "hebrew": "שלום"},
    {"arabic": "אַיְוַה",   "hebrew": "כן"},
    {"arabic": "לַאְ",     "hebrew": "לא"},
    {"arabic": "בּאבּ",    "hebrew": "דלת"}
  ]
}$$::jsonb);

-- ── Slide 14: summary (from s8) ──────────────────────────────
insert into lesson_slides (lesson_id, position, type, content) values
(1, 14, 'summary', $${
  "key_points": [
    {
      "title": "① שלוש קבוצות אותיות",
      "html": "<span class=\"teal\">זהות לעברית</span> (16 אותיות) &nbsp;|&nbsp; <span class=\"rose\">כועסות</span> (4 אותיות) &nbsp;|&nbsp; <span class=\"teal\">ייחודיות</span> (6 אותיות)"
    },
    {
      "title": "② 5 מילים ראשונות",
      "html": "<span class=\"teal\">אַנא</span> (אני) &nbsp;|&nbsp; <span class=\"teal\">שֻכְּרַן</span> (תודה) &nbsp;|&nbsp; <span class=\"teal\">מַרְחַבּא</span> (שלום) &nbsp;|&nbsp; <span class=\"teal\">אַיְוַה</span> (כן) &nbsp;|&nbsp; <span class=\"teal\">לַאְ</span> (לא)"
    },
    {
      "title": "🗣️ טעימה מלהגים",
      "html": "בלהגים שונים, צלילים משתנים. למשל, במשולש הערבי אומרים צ׳ במקום כּ — וזה גורם לחיוכים!<br><br><span class=\"teal\">הבדלי להגים נפוצים:</span><br>• כּ → צ׳ (משולש) — \"כּלב\" → \"צ׳לב\"<br>• ק → א (עירוני) — \"קלב\" → \"אלב\"<br>• ג׳ → ז׳ (לבנוני) — הגייה צרפתית יותר<br><br><span style=\"opacity:0.7\">נלמד עוד על להגים בהמשך הקורס!</span>"
    }
  ],
  "vocabulary_recap": ["אַנא", "שֻכְּרַן", "מַרְחַבּא", "אַיְוַה", "לַאְ"],
  "next_lesson_teaser": "בשיעור הבא: שלום! — הברכות הבסיסיות. נלמד לפתוח ולסגור שיחה, ונכיר את אותיות השמש ואל הידיעה. אַלְף מַבְּרוּכּ! 🎉"
}$$::jsonb);

commit;

-- ============================================================
-- Done. Verify with:
--   select position, type from lesson_slides where lesson_id = 1 order by position;
--   select get_lesson(1);
-- Expected: 14 slides, types in this order:
--   intro, rule_card, collision_arena, rule_card, letter_chips,
--   letter_forms_table, vocab_grid, rule_card, example_cards,
--   quiz_match, quiz_match, rule_card, memory_game, summary
-- ============================================================
