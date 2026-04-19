# מיפוי רכיבי שיעור — הקורס

> תוצר שלב 1 של אדריכלות "Empty Shell + Dynamic Content"
> מנותח על בסיס 18 קבצי lesson_XX.html

---

## סיכום

- **18 שיעורים**, כל אחד עם **9 שקופיות בערך** (s0..s8)
- **19 סוגי רכיבים** ייחודיים זוהו
- **3 רכיבים אוניברסליים** (intro, rule_card, summary) — בכל השיעורים
- **רכיבים מיוחדים** — חלקם מופיעים רק בשיעור אחד

---

## רכיבים אוניברסליים (כל השיעורים)

### 1. `intro` — שקופית פתיחה
מופיע ב: **כל 18 השיעורים** (תמיד הראשון)

**שדות:**
```json
{
  "title": "string",          // "האותיות"
  "subtitle": "string",       // "שיעור 1"
  "arabic_title": "string",   // "أبجد هوّز"
  "description": "string",    // הסבר על השיעור
  "ornament": "string"        // אופציונלי, אלמנט עיצובי
}
```

### 2. `rule_card` — כרטיס כלל/הסבר
מופיע ב: **כל השיעורים, כמה פעמים בכל שיעור**

**שדות:**
```json
{
  "title": "string?",         // אופציונלי
  "html": "string",           // טקסט HTML עם <span class="highlight/teal/rose/gold">
  "examples": [               // אופציונלי
    {"arabic": "...", "hebrew": "..."}
  ]
}
```

### 3. `summary` — סיכום
מופיע ב: **כל השיעורים** (תמיד אחרון, s8)

**שדות:**
```json
{
  "key_points": [
    {"title": "...", "html": "..."}
  ],
  "vocabulary_recap": ["מילים שלמדנו"],
  "next_lesson_teaser": "string?"
}
```

---

## רכיבים נפוצים (מספר שיעורים)

### 4. `vocab_grid` — רשת אוצר מילים
מופיע ב: שיעורים **1, 3, 5, 6** וכו'

**שדות:**
```json
{
  "title": "string?",
  "items": [
    {
      "arabic": "أنا",
      "hebrew": "אני",
      "transliteration": "ana?",
      "click_hint": "לחץ?",
      "category": "string?"
    }
  ]
}
```

### 5. `example_cards` — כרטיסי דוגמה
מופיע ב: **רוב השיעורים (2-17)**

**שדות:**
```json
{
  "title": "string?",
  "items": [
    {
      "arabic_phrase": "بَ + باب",
      "hebrew_translation": "דלת",
      "separator": "= | → | ↔",
      "translation_note": "ב — כמו בעברית"
    }
  ]
}
```

### 6. `collision_arena` — אנימציית התנגשות
מופיע ב: שיעורים **1, 2, 3, 6, 7, 10, 11, 12, 13, 14, 15, 16**

**שדות:**
```json
{
  "left_word": "بيت",
  "operator": "+ | ❤",
  "right_word": "المدير",
  "result": "بيت المدير",
  "result_label": "= בית של המנהל"
}
```

### 7. `memory_game` — משחק זיכרון
מופיע ב: שיעורים **1, 5, 9, 10, 13, 17**

**שדות:**
```json
{
  "pairs": [
    {"arabic": "أنا", "hebrew": "אני"},
    {"arabic": "شكراً", "hebrew": "תודה"}
  ],
  "show_timer": true
}
```

### 8. `quiz_match` — שאלה עם reveal
מופיע ב: **רוב השיעורים**

**שדות:**
```json
{
  "questions": [
    {
      "question": "1. לאיזו קבוצה שייכת האות ט?",
      "answer": "קבוצה 2 — כועסות (ת כועסת)",
      "hint": "string?"
    }
  ],
  "reveal_all_button": true
}
```

### 9. `quiz_multi_choice` / `speed_quiz` — שאלון אופציות
מופיע ב: שיעורים **14, 16, 18**

**שדות:**
```json
{
  "title": "מה הרבים?",
  "timer_seconds": 150,
  "questions": [
    {
      "q": "وَلَد (ילד)",
      "correct": "أولاد",
      "options": ["أولاد", "ولدين", "ولدات", "ولود"]
    }
  ]
}
```

---

## רכיבים ספציפיים (שיעור אחד או שניים)

### 10. `letter_chips` — אותיות לחיצות
מופיע ב: **שיעור 1 בלבד**

**שדות:**
```json
{
  "groups": [
    {
      "title": "קבוצה 1 — זהות לעברית",
      "color": "gold",
      "letters": [
        {"letter": "ב", "example": "بَاب [דלת]"}
      ]
    }
  ]
}
```

### 11. `greeting_pair` — צמדי ברכות
מופיע ב: **שיעור 2**

**שדות:**
```json
{
  "items": [
    {
      "label": "ערב טוב",
      "say": "مساء الخير",
      "response": "مساء النور",
      "hebrew": "ערב טוב ↔ ערב אור"
    }
  ]
}
```

### 12. `greeting_grid` — ברכות עם תשובה
מופיע ב: **שיעור 8**

**שדות:**
```json
{
  "items": [
    {
      "say_label": "ברכה",
      "say": "يعطيك العافية",
      "say_meaning": "יישר כוח",
      "response_label": "תשובה",
      "response": "الله يعافيك",
      "response_meaning": "אלוהים יתן לך בריאות"
    }
  ]
}
```

### 13. `dialogue` — דיאלוג
מופיע ב: שיעורים **3, 18**

**שדות:**
```json
{
  "title": "אחמד פוגש את לילה",
  "lines": [
    {
      "speaker": "אחמד",
      "arabic": "صباح الخير!",
      "hebrew": "בוקר טוב!",
      "cloze_word": "string?",
      "cloze_answer": "string?"
    }
  ]
}
```

### 14. `conjugation_table` — טבלת הטיה
מופיע ב: שיעורים **3, 9, 10**

**שדות:**
```json
{
  "title": "כינויי גוף",
  "headers": ["עברית", "ערבית"],
  "rows": [
    {"hebrew": "אני", "arabic": "أنا"},
    {"hebrew": "אתה", "arabic": "إنت"}
  ]
}
```

### 15. `conjugation_interactive` — תרגיל הטיה
מופיע ב: **שיעור 9**

**שדות:**
```json
{
  "questions": [
    {
      "prompt": "הפועל \"לאכול\" בגוף הם:",
      "options": [
        {"text": "بَاكُل", "correct": false},
        {"text": "بِكْلُو", "correct": true}
      ]
    }
  ]
}
```

### 16. `sentence_builder` — בונה משפטים
מופיע ב: **שיעור 6**

**שדות:**
```json
{
  "builders": [
    {
      "prompt": "בנו: \"יאללה, צריך ללכת\"",
      "blocks": ["لازم", "بس", "يلا", "نروح"],
      "correct_order": ["يلا", "لازم", "نروح"]
    }
  ]
}
```

### 17. `number_builder` — בונה מספרים
מופיע ב: **שיעור 4**

**שדות:**
```json
{
  "numbers": [
    {"digit": 0, "arabic": "صفر", "hebrew": "אפס"},
    {"digit": 1, "arabic": "واحد", "hebrew": "אחד"}
  ]
}
```

### 18. `number_grid` — רשת מספרים
מופיע ב: **שיעור 4**

**שדות:**
```json
{
  "items": [
    {"digit": 1, "arabic": "واحد", "hebrew": "אחד"}
  ]
}
```

### 19. `family_grid` — רשת משפחה
מופיע ב: **שיעור 5**

**שדות:**
```json
{
  "items": [
    {"arabic": "أبوي", "hebrew": "אבא שלי"}
  ]
}
```

---

## רכיבים נדירים / Custom

### `cloze_dialogue` — דיאלוג עם השלמת מילים
מופיע ב: **שיעור 18**
- כמו `dialogue` אבל עם `data-ans` שמוחבא

### `deepen_panel` — פאנל הרחבה
מופיע ב: **שיעור 2**
- כפתור שמרחיב מידע נוסף
- אפשר להוסיף לכל סוג כשדה אופציונלי `deepen: {title, html}`

### `progress_road` — מד התקדמות
מופיע ב: **nawwitni בלבד** (לא בשיעורים רגילים)

---

## הצעת סכמת DB

על בסיס המיפוי:

```sql
-- מטא של שיעור
create table lessons (
  id integer primary key,
  number integer unique not null,         -- 1..18
  part integer,                           -- 1, 2, 3 (לתשלומים)
  title text not null,
  subtitle text,
  arabic_title text,
  description text,
  difficulty text,                        -- beginner | intermediate | advanced
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- שקופיות
create table lesson_slides (
  id uuid primary key default gen_random_uuid(),
  lesson_id integer references lessons(id) on delete cascade,
  position integer not null,              -- סדר ההצגה
  type text not null,                     -- intro | rule_card | vocab_grid | ...
  content jsonb not null default '{}',    -- התוכן הספציפי לסוג
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create unique index on lesson_slides (lesson_id, position) where active = true;
create index on lesson_slides (type);
```

**`content` הוא JSONB גמיש** — לכל `type` יש סכמה משלו (כמתועד למעלה), אבל ברמת ה-DB זה JSONB. אם נרצה אכיפת סכמה, נעשה את זה בשכבת ה-API.

---

## רכיבים שהמערכת תצטרך לתמוך — סיכום סופי

| # | סוג | שכיחות | תלות |
|---|-----|--------|------|
| 1 | `intro` | 18/18 | אוניברסלי |
| 2 | `rule_card` | 18/18 | אוניברסלי |
| 3 | `summary` | 18/18 | אוניברסלי |
| 4 | `example_cards` | 16/18 | נפוץ מאוד |
| 5 | `collision_arena` | 12/18 | נפוץ |
| 6 | `quiz_match` | ~12/18 | נפוץ |
| 7 | `vocab_grid` | ~6/18 | בינוני |
| 8 | `memory_game` | 6/18 | בינוני |
| 9 | `quiz_multi_choice` | 3/18 | בינוני |
| 10 | `dialogue` | 2/18 | מועט |
| 11 | `conjugation_table` | 3/18 | מועט |
| 12 | `letter_chips` | 1/18 | ייחודי לשיעור 1 |
| 13 | `greeting_pair` | 1/18 | ייחודי לשיעור 2 |
| 14 | `greeting_grid` | 1/18 | ייחודי לשיעור 8 |
| 15 | `conjugation_interactive` | 1/18 | ייחודי לשיעור 9 |
| 16 | `sentence_builder` | 1/18 | ייחודי לשיעור 6 |
| 17 | `number_builder` | 1/18 | ייחודי לשיעור 4 |
| 18 | `number_grid` | 1/18 | ייחודי לשיעור 4 |
| 19 | `family_grid` | 1/18 | ייחודי לשיעור 5 |

---

## אסטרטגיית מיגרציה מומלצת

### עדיפות 1 — לבנות קודם (תומך ב-90% מהשיעורים)
- `intro`, `rule_card`, `summary` (אוניברסליים)
- `example_cards`, `collision_arena`, `quiz_match`
- `vocab_grid`, `memory_game`

### עדיפות 2 — לבנות אחרי השיעורים העיקריים
- `quiz_multi_choice`, `dialogue`, `conjugation_table`

### עדיפות 3 — רכיבים ייחודיים (בנייה רק בעת הצורך)
- כשנגיע לשיעור הרלוונטי, נבנה את הרכיב הייחודי

**יתרון:** אחרי בניית קבוצה 1, נוכל כבר להתחיל למגרר ~14 שיעורים. שיעורים 1, 4, 5, 8 יחכו לרכיביהם הייחודיים.
