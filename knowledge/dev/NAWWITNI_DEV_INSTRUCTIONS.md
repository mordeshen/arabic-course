# 🚗 نوّطني — הוראות פיתוח ל-Claude Code

## סקירה כללית

**נווטני** (نوّطني) הוא משחק ניווט אינטראקטיבי ללימוד קריאת ערבית דרך שלטי כבישים ישראליים. ה-GPS התקלקל — הדרך היחידה הביתה היא לקרוא את השלטים בערבית.

**Stack:** Next.js (App Router) + Tailwind + Supabase + Framer Motion
**Deploy:** Railway (staging) / Vercel (prod)
**שפות UI:** עברית ראשית, ערבית בתוך המשחק

---

## קבצי נתונים (כבר קיימים)

```
data/
├── road_signs_game_data.json      # 12 שלטים אמיתיים + מסכות + קואורדינטות
├── virtual_signs_waze_quiz.json   # 60 שלטים וירטואליים + 6 חידונים
├── palestinian_arabic_course_kb.json  # בסיס ידע — אוצר מילים + תרגילים
└── sign_images/                   # תמונות שלטים (מתוך nawwitni_sign_images.zip)
    ├── sign_03_mizpe_ramon_eilat_...png
    ├── sign_04_sderot_...png
    ├── sign_06_jerusalem_...png
    ├── sign_07_atir_yeda_...png
    ├── sign_08_kafar_kanna_nazareth_...png
    ├── sign_09_tel_aviv_yafo_...png
    └── sign_11_kerem_shalom_...png
```

**אל תשנה את מבנה ה-JSON** — כל ה-IDs, שמות השדות, ומבנה הנתונים כבר תואמים בין הקבצים.

---

## ארכיטקטורה

```
src/
├── app/
│   ├── layout.tsx              # RTL, fonts, global providers
│   ├── page.tsx                # מסך פתיחה
│   ├── play/
│   │   ├── navigation/
│   │   │   ├── page.tsx        # בחירת משימה
│   │   │   └── [missionId]/
│   │   │       └── page.tsx    # מסך צומת (ליבת המשחק)
│   │   ├── speed/page.tsx      # מצב קריאה מהירה
│   │   ├── build/page.tsx      # בנה שלט (drag & drop)
│   │   ├── locate/page.tsx     # GPS שבור (מפה)
│   │   ├── waze-quiz/page.tsx  # חידון ווייז
│   │   └── match/page.tsx      # התאם שמות
│   ├── learn/
│   │   └── page.tsx            # חזרה על מילים שנלמדו
│   └── api/
│       └── scores/route.ts     # שמירת ניקוד ב-Supabase
├── components/
│   ├── game/
│   │   ├── SignDisplay.tsx      # תצוגת שלט אמיתי עם מסכות
│   │   ├── VirtualSign.tsx     # שלט וירטואלי SVG/HTML
│   │   ├── Junction.tsx        # מסך צומת — בחירת כיוון
│   │   ├── FuelGauge.tsx       # מד דלק אנימטיבי
│   │   ├── MissionMap.tsx      # מפת מסלול עם התקדמות
│   │   ├── Timer.tsx           # טיימר למצב מהיר
│   │   ├── LetterDrag.tsx      # drag & drop אותיות ערביות
│   │   ├── MapClick.tsx        # מפת ישראל ללחיצה
│   │   ├── MemoryMatch.tsx     # משחק זיכרון כרטיסים
│   │   ├── WazeInstruction.tsx # הוראת ווייז וירטואלית
│   │   └── ScoreBoard.tsx      # טבלת ניקוד
│   ├── ui/
│   │   ├── ArabicText.tsx      # wrapper לטקסט ערבי עם font נכון
│   │   ├── RevealMask.tsx      # מסכה שנעלמת באנימציה
│   │   ├── GameButton.tsx      # כפתורי פעולה
│   │   └── HintBubble.tsx      # בועת רמז
│   └── layout/
│       ├── GameShell.tsx        # shell משותף — header, fuel, score
│       └── Navigation.tsx       # ניווט בין מצבים
├── hooks/
│   ├── useGameState.ts          # state management ראשי
│   ├── useFuel.ts               # ניהול דלק
│   ├── useScore.ts              # ניקוד ושיאים
│   ├── useWordsLearned.ts       # מילים שנלמדו (localStorage)
│   └── useMission.ts            # לוגיקת משימה — צמתים, התקדמות
├── lib/
│   ├── signs.ts                 # פונקציות טעינה/סינון של שלטים
│   ├── missions.ts              # הגדרת מסלולים
│   ├── scoring.ts               # חישוב ניקוד
│   └── supabase.ts              # client
├── types/
│   └── game.ts                  # TypeScript types לכל ה-JSON
└── styles/
    └── arabic.css               # סגנונות ספציפיים לטקסט ערבי
```

---

## עיצוב

### כיוון אסתטי: "לילה במדבר + ניאון"
תחושה של נהיגה בלילה במדבר הנגב — חושך עם שלטים זוהרים.

### צבעים
```css
:root {
  --bg-primary: #0a0e1a;        /* שמיים כהים */
  --bg-secondary: #111827;      /* אספלט */
  --bg-road: #1a1f35;           /* כביש בלילה */
  --sign-green: #006B3F;        /* שלט כביש ירוק */
  --sign-blue: #1565C0;         /* שלט עירוני */
  --sign-brown: #5D4037;        /* שלט תיירות */
  --sign-white: #F5F5F5;        /* טקסט שלט */
  --waze-blue: #33CCFF;         /* אקסנט ווייז */
  --fuel-yellow: #FFA500;       /* דלק */
  --fuel-danger: #E53935;       /* דלק נמוך */
  --success: #66BB6A;           /* תשובה נכונה */
  --error: #EF5350;             /* תשובה שגויה */
  --text-primary: #E8E8E8;      /* טקסט ראשי */
  --text-muted: #9CA3AF;        /* טקסט משני */
  --neon-glow: 0 0 20px rgba(51, 204, 255, 0.3); /* זוהר ניאון */
  --road-line: #FFC107;         /* קו כביש צהוב */
}
```

### פונטים
```css
/* ערבית — חובה Noto Sans Arabic, גדול וברור */
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;600;700&display=swap');

/* עברית */
@import url('https://fonts.googleapis.com/css2?family=Heebo:wght@300;400;500;700;900&display=swap');

/* מספרי כביש — Mono */
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@700&display=swap');

.arabic-text {
  font-family: 'Noto Sans Arabic', sans-serif;
  font-size: 1.75rem;        /* מינימום! */
  line-height: 1.6;
  direction: rtl;
  letter-spacing: 0.02em;
}

.arabic-text--sign {
  font-size: 2.5rem;          /* על שלטים — גדול */
  font-weight: 700;
}

.arabic-text--waze {
  font-size: 1.5rem;
  font-weight: 600;
}
```

### Layout
- **כל האפליקציה RTL** — `dir="rtl"` על html
- **מובייל-first** — רוב המשתמשים יהיו בטלפון
- max-width על שלטים: `min(90vw, 500px)`
- שלטים ממורכזים, כפתורים גדולים (נגישות)

### אנימציות
```
prefers-reduced-motion: reduce — כבד את זה תמיד!
```

**אנימציות מרכזיות (Framer Motion):**

| אלמנט | אנימציה | Duration | Easing |
|---|---|---|---|
| מסכה מתגלה | opacity 1→0 + scale 1→1.02 | 0.6s | ease-out |
| מעבר צומת | slide-in מימין | 0.4s | spring(0.7) |
| דלק יורד | shake + color change | 0.5s | ease-in-out |
| תשובה נכונה | pulse ירוק + ✓ | 0.4s | spring |
| תשובה שגויה | shake אדום + ✗ | 0.3s | ease-out |
| הגעה ליעד | scale up + confetti | 0.8s | spring(0.5) |
| שלט ווייז נכנס | fade-in + slide-up | 0.3s | ease-out |
| טיימר — אזהרה | pulse אדום כש<3 שניות | 0.5s | loop |
| כרטיס מתהפך (match) | rotateY 0→180 | 0.4s | ease-in-out |

---

## קומפוננטות מרכזיות — הנחיות

### `SignDisplay.tsx` — שלט אמיתי עם מסכות

```typescript
interface SignDisplayProps {
  sign: RealSign;                    // מ-road_signs_game_data.json
  locationIndex: number;             // איזה יישוב בשלט (שלטים כפולים)
  revealHebrew: boolean;
  revealEnglish: boolean;
  onReveal?: () => void;
}
```

**לוגיקה:**
1. טען תמונת שלט מ-`/sign_images/`
2. הנח מסכות CSS absolute מעל העברית והאנגלית
3. קואורדינטות מגיעות מה-JSON באחוזים (`x_pct`, `y_pct`, `w_pct`, `h_pct`)
4. מסכה = div עם `backdrop-filter: blur(8px)` + רקע כהה + סימן ❓
5. כשהתשובה נכונה → מסכה נעלמת ב-fade-out

```tsx
// דוגמת שימוש בקואורדינטות:
<div style={{
  position: 'absolute',
  left: `${mask.x_pct}%`,
  top: `${mask.y_pct}%`,
  width: `${mask.w_pct}%`,
  height: `${mask.h_pct}%`,
}}>
```

### `VirtualSign.tsx` — שלט וירטואלי SVG

```typescript
interface VirtualSignProps {
  sign: VirtualSign;                 // מ-virtual_signs_waze_quiz.json
  style: SignStyle;                  // highway_green / city_blue / brown_tourist / waze_minimal
  showRoadNumber?: boolean;
  showArrow?: 'left' | 'right' | 'straight';
  size?: 'small' | 'medium' | 'large';
}
```

**עיצוב שלט וירטואלי:**
- SVG עם צורת שלט כביש ישראלי (מלבן עם חץ בצד)
- צבעים מ-`sign_styles` ב-JSON
- טקסט ערבי בלבד (Noto Sans Arabic, bold)
- מספר כביש בריבוע קטן למעלה
- אופציונלי: חץ כיוון, מרחק בק"מ

```
┌──────────────────┐
│  [754]           │
│                  │
│    كفر كنا    ←  │
│                  │
└──────────────────┘
```

**סגנון ווייז:**
```
╭─────────────────────────╮
│  📍 اتجه يمين بعد ٥٠٠ م  │
│     ← الناصره            │
╰─────────────────────────╯
```

רקע לבן, פינות מעוגלות, אייקון מיקום בכחול, טקסט אפור כהה.

### `Junction.tsx` — מסך צומת

זה הליבה של מצב הניווט.

```typescript
interface JunctionProps {
  mission: Mission;
  junctionIndex: number;
  fuel: number;
  onChoice: (direction: 'left' | 'right' | 'straight') => void;
  onHint: () => void;
}
```

**מבנה מסך:**
```
┌─────────────────────────────┐
│ ⛽⛽⛽🪫  |  📍 ???  |  🎯 يعד  │  ← header קבוע
├─────────────────────────────┤
│                             │
│   [שלט שמאלי]  [שלט ימני]  │  ← שלטים (real או virtual)
│                             │
│   ← شمال    |    جنوب →    │  ← כיוונים בערבית
│                             │
├─────────────────────────────┤
│  [⬅️]    [⬆️]    [➡️]      │  ← כפתורי בחירה
│         [💡 رمز]            │  ← כפתור רמז
└─────────────────────────────┘
```

**פרט חשוב:** בשלטי צומת עם 2 יעדים (כמו מצפה רמון/אילת) — כל יעד בצד אחר של המסך עם חץ כיוון.

### `FuelGauge.tsx` — מד דלק

**לא בר פרוגרס משעמם!** עיצוב כמו מד דלק אמיתי:
- אייקון משאבה ⛽
- 5-7 "טיפות" דלק שנכבות אחת אחת
- כשנשאר 1-2: אנימציית pulse באדום + "⚠️ البنزين خلص!" (הדלק נגמר)
- אנימציית shake כשמפסידים דלק
- צבע: צהוב→כתום→אדום לפי הכמות

### `LetterDrag.tsx` — בנה שלט (Drag & Drop)

מצב "بنه شلط" — השחקן מקבל שם בעברית ובונה אותו באותיות ערביות.

```typescript
interface LetterDragProps {
  targetArabic: string;           // "الناصره"
  hebrewName: string;             // "נצרת"
  distractorLetters: string[];    // אותיות מסיחות
  onComplete: (correct: boolean) => void;
}
```

**לוגיקה:**
1. פרק את `targetArabic` לאותיות בודדות
2. הוסף `distractorLetters` (2-4 אותיות שלא שייכות)
3. ערבב את כל האותיות
4. השחקן גורר אותיות לתיבות ריקות
5. אות נכונה = נצבעת בירוק ונשארת
6. אות שגויה = shake + חוזרת למאגר
7. **רמז:** הצג את האות הבאה הנכונה (עולה דלק)

**עיצוב אותיות:**
- כל אות בריבוע 60x60px
- font-size: 2rem, Noto Sans Arabic bold
- רקע לבן, border כהה, border-radius: 8px
- גרירה: scale(1.1) + shadow + cursor grab
- תיבות יעד: border dashed, רקע שקוף

### `MapClick.tsx` — מפת ישראל

מפה סכמטית (SVG) של ישראל עם אזורים ללחיצה.

**לא Google Maps!** SVG מצויר עם:
- קווי מתאר של ישראל
- נקודות עיקריות מסומנות (אחרי תשובה נכונה)
- לחיצה → מרחק מהמיקום האמיתי → ניקוד

```
⭐⭐⭐ = < 10 ק"מ
⭐⭐  = < 30 ק"מ  
⭐   = < 50 ק"מ
```

**נוסחת מרחק:** Haversine formula בין lat/lng של הלחיצה ל-lat/lng מה-JSON.

### `MemoryMatch.tsx` — התאם שמות

משחק זיכרון קלאסי — 16 כרטיסים (8 זוגות).

- כרטיס ערבי = רקע ירוק, טקסט לבן
- כרטיס עברי = רקע כחול, טקסט לבן
- גב כרטיס = סימן שאלה + דפוס גיאומטרי
- התאמה נכונה = שני הכרטיסים נשארים גלויים + pulse ירוק
- **דגש:** להשתמש בזוגות מ-`special_learning_category` — שמות שונים (חברון↔الخليل)

---

## State Management

### `useGameState.ts`
```typescript
interface GameState {
  mode: 'navigation' | 'speed' | 'build' | 'locate' | 'waze_quiz' | 'match';
  currentMission: number | null;
  currentJunction: number;
  fuel: number;
  maxFuel: number;
  stars: number;
  mistakes: number;
  hintsUsed: number;
  wordsLearned: LearnedWord[];
  totalScore: number;
  completedMissions: string[];
  streakCount: number;            // רצף תשובות נכונות
}

interface LearnedWord {
  arabic: string;
  hebrew: string;
  transliteration: string;
  learnedAt: string;              // ISO date
  source: 'sign' | 'waze' | 'quiz';
  timesCorrect: number;
  timesWrong: number;
}
```

**שמירה:** `localStorage` לפרוגרס מקומי + Supabase לשיאים ולידרבורד.

### ניקוד
```typescript
const SCORING = {
  correct_first_try: 10,
  correct_second_try: 5,
  hint_penalty: -2,
  speed_bonus_under_3s: 5,
  speed_bonus_under_5s: 3,
  no_mistakes_mission_bonus: 15,
  streak_bonus_per_5: 10,        // כל 5 נכונות ברצף
  dual_name_bonus: 5,            // זיהוי שם ששונה (חברון↔الخليل)
};
```

---

## מסלולי ניווט — missions.ts

כל mission הוא מערך של צמתים. כל צומת מפנה לשלט (אמיתי או וירטואלי) ומגדיר בחירה נכונה.

```typescript
interface Mission {
  id: string;
  title_hebrew: string;
  title_arabic: string;
  start: string;                   // שם יישוב התחלה
  end: string;                     // שם יישוב יעד
  difficulty: 'easy' | 'medium' | 'hard' | 'expert';
  fuel: number;                    // דלק התחלתי
  junctions: Junction[];
}

interface Junction {
  signs: JunctionSign[];           // 1-2 שלטים בצומת
  correctDirection: 'left' | 'right' | 'straight';
  wrongDestination: string;        // "נסעת ל-X במקום ל-Y!"
  distanceWasted: number;          // ק"מ שהתבזבזו בטעות
}

interface JunctionSign {
  signId: string;                  // מפנה ל-road_signs_game_data או virtual_signs
  signSource: 'real' | 'virtual';
  direction: 'left' | 'right' | 'straight';
}
```

**4 משימות מוגדרות:**

```typescript
const MISSIONS: Mission[] = [
  {
    id: "mission_sea",
    title_hebrew: "הדרך לים",
    title_arabic: "الطريق للبحر",
    start: "الناصره",
    end: "تل ابيب-يافا",
    difficulty: "easy",
    fuel: 5,
    junctions: [
      {
        signs: [
          { signId: "sign_08", signSource: "real", direction: "left" },    // כפר כנא
          { signId: "vs_009", signSource: "virtual", direction: "right" }  // טבריה
        ],
        correctDirection: "left",   // לכיוון כפר כנא→תל אביב
        wrongDestination: "טבריה",
        distanceWasted: 35
      },
      {
        signs: [
          { signId: "sign_09", signSource: "real", direction: "right" }    // תל אביב
        ],
        correctDirection: "right",
        wrongDestination: "חיפה",
        distanceWasted: 20
      },
      {
        signs: [
          { signId: "sign_06", signSource: "real", direction: "left" },    // ירושלים
          { signId: "vs_004", signSource: "virtual", direction: "right" }  // יפו
        ],
        correctDirection: "right",
        wrongDestination: "ירושלים",
        distanceWasted: 60
      }
    ]
  },
  // ... עוד 3 משימות כמפורט ב-ARABIC_ROAD_GAME_DESIGN.md
];
```

---

## Supabase Schema

```sql
-- טבלת שחקנים
create table players (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  created_at timestamptz default now()
);

-- טבלת ניקוד
create table scores (
  id uuid primary key default gen_random_uuid(),
  player_id uuid references players(id),
  mode text not null,              -- 'navigation' | 'speed' | 'build' | etc
  mission_id text,                 -- null for non-navigation modes
  score integer not null,
  stars integer default 0,
  fuel_remaining integer,
  mistakes integer default 0,
  hints_used integer default 0,
  duration_seconds integer,
  created_at timestamptz default now()
);

-- טבלת מילים שנלמדו (אופציונלי — server-side backup)
create table words_learned (
  id uuid primary key default gen_random_uuid(),
  player_id uuid references players(id),
  arabic text not null,
  hebrew text not null,
  times_correct integer default 0,
  times_wrong integer default 0,
  last_seen timestamptz default now(),
  unique(player_id, arabic)
);

-- RLS policies
alter table scores enable row level security;
create policy "Anyone can read scores" on scores for select using (true);
create policy "Authenticated users can insert own scores" on scores for insert
  with check (auth.uid() = player_id);
```

**סכמה:** `nawwitni` (הפרד מסכמות אחרות על אותו Supabase instance)

---

## סדר עבודה מומלץ

### שלב 1 — שלד + שלט בודד
1. Init Next.js project + Tailwind + Framer Motion
2. Layout RTL + fonts (Heebo + Noto Sans Arabic)
3. `SignDisplay` component עם מסכות
4. מסך בודד: הצג שלט אחד, קלוט תשובה, גלה מסכה
5. **בדוק:** מסכות מיושרות נכון על כל תמונה

### שלב 2 — מצב מהיר (speed)
1. `VirtualSign` component — SVG
2. `Timer` component
3. `SpeedRound` page — 10 שלטים ברצף
4. ניקוד + סיכום מילים

### שלב 3 — מצב ניווט (הליבה)
1. `Junction` component
2. `FuelGauge` component
3. `MissionMap` — מפת מסלול
4. `useMission` hook — ניהול צמתים
5. mission אחד שלם (easy) מתחילה עד סוף
6. **בדוק:** דלק, טעויות, רמזים, הגעה

### שלב 4 — חידונים
1. חידון ווייז (multiple choice)
2. התאם שמות (memory match)
3. בנה שלט (drag & drop)
4. GPS שבור (map click)

### שלב 5 — polish + Supabase
1. Supabase auth (anonymous)
2. שמירת ניקוד
3. לידרבורד
4. אנימציות finales
5. PWA config (משחק מטלפון)
6. מסך "מילים שלמדתי" עם חזרות

---

## כללי פיתוח

### חובה
- **RTL everywhere** — `dir="rtl"` על `<html>`, כל ה-layout מימין לשמאל
- **ערבית גדולה** — font-size מינימום 1.5rem, על שלטים 2rem+
- **prefers-reduced-motion** — כל אנימציה עם fallback
- **מובייל first** — 90% מהשימוש יהיה מטלפון
- **כפתורים גדולים** — min 48x48px touch target
- **Noto Sans Arabic** — לא להחליף! זה הפונט היחיד שמציג נכון את כל האותיות
- **test/prod separation** — סביבות נפרדות, env vars

### אל תעשה
- ❌ אל תשנה מבנה JSON — הקבצים כבר תואמים
- ❌ אל תוסיף Google Maps API — המפה היא SVG סכמטי
- ❌ אל תשתמש ב-Inter/Roboto/Arial — Heebo לעברית, Noto Sans Arabic לערבית
- ❌ אל תבנה backend כבד — localStorage + Supabase מספיק
- ❌ אל תשכח שיש שלטים עם 2-3 יישובים (sign_03, sign_08, sign_10) — כל location צריך מסכות נפרדות
- ❌ אל תפריד CSS לקבצים — Tailwind + CSS-in-JS inline
- ❌ אל תשים confetti על כל דבר — רק הגעה ליעד

### Supabase specifics (מהנסיון שלנו)
- `getSession()` צריך timeout + localStorage fallback על Railway
- סכמה נפרדת: `nawwitni`
- בדוק RLS policies לפני deploy

---

## טקסטי UX בערבית (copy-paste ready)

```typescript
const UX_TEXTS = {
  start: "يالله ننطلق!",           // יאללה נצא לדרך
  correct: "برافو عليك!",          // כל הכבוד
  wrong: "غلط! ارجع",              // טעות, תחזור
  hint: "بدك مساعده؟",             // צריך עזרה?
  no_fuel: "خلص البنزين!",         // נגמר הדלק
  arrived: "وصلت! اهلا وسهلا",    // הגעת! ברוכים הבאים
  new_record: "رقم قياسي جديد!",    // שיא חדש
  try_again: "جرب مره ثانيه",      // נסה שוב
  next_mission: "المهمه الجايه",    // המשימה הבאה
  words_learned: "كلمات تعلمتها",   // מילים שלמדת
  loading: "عم بحمّل...",          // טוען...
  choose_direction: "وين بدك تروح؟", // לאן אתה רוצה לנסוע?
  km_wasted: "ضيّعت {n} كم!",      // בזבזת n ק"מ
};
```

---

## בדיקות שמומלץ לעשות ידנית

1. **מסכות מיושרות** — פתח כל 7 תמונות שלט, וודא שהמסכה מכסה בדיוק את העברית/אנגלית
2. **RTL לא שבור** — כפתורים, חצים, שלטים — הכל בכיוון הנכון
3. **טקסט ערבי קריא** — על מסך קטן (375px) האותיות עדיין ברורות
4. **דלק עובד** — 0 דלק = game over, לא crash
5. **שלטים כפולים** — sign_03 (מצפה רמון + אילת) ו-sign_08 (כפר כנא + נצרת) מציגים 2 מסכות נפרדות
6. **תשובות מקובלות** — "ירושלים", "jerusalem", "אל-קודס", "القدس" — כולן מתקבלות
7. **מעבר בין מצבים** — ניווט→מהיר→חידון בלי לאבד state
