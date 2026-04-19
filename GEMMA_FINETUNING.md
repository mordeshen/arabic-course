# Fine-Tuning של Gemma 4 — מדריך העברה לפרוייקטים אחרים

מסמך זה מסכם את כל הזרימה של אימון מודל קטן (Gemma 4 E2B) שיחליף קריאות יקרות ל-Opus/Sonnet במשימות שגרתיות. הוא בנוי כך שתוכל להעתיק אותו לפרוייקט אחר ולהריץ אותו על דומיין שונה (לא רק זכויות פצועי צה"ל).

**Stack:**
- **מודל בסיס:** `google/gemma-4-E2B-it` (2B params, instruction-tuned)
- **Fine-tuning:** LoRA (rank 8) באמצעות [`mlx-lm`](https://github.com/ml-explore/mlx-lm)
- **חומרה:** Apple Silicon (M1 Pro ומעלה — מנצל את ה-Neural Engine)
- **Distillation:** מודל גדול (Claude Opus + RAG) מייצר את ה-ground truth
- **Eval:** Claude Sonnet משמש judge מול הגרסה הקטנה (LLM-as-judge)
- **Loop:** train → eval → analyze → generate weak-area data → retrain

**למה Gemma 4 E2B?**
- רץ מקומית בלי GPU/cloud — עלות אפסית
- 2B params מספיק לדומיין צר עם distillation טוב
- LoRA מאפשר אימון של הקובץ adapter בלבד (~50MB), לא של המודל המלא
- mlx_lm נותן throughput טוב על M1/M2/M3

---

## 1. ארכיטקטורת הזרימה — תמונת על

```
┌──────────────────────────────────────────────────────────────────┐
│  Phase 1: DISTILLATION                                            │
│                                                                   │
│   templates + slot-filling                                        │
│         │                                                         │
│         ▼                                                         │
│   1500+ שאלות מגוונות   ──┐                                       │
│                            │                                      │
│   RAG knowledge base ──────┤                                      │
│                            ▼                                      │
│                    ┌───────────────┐                              │
│                    │ Claude Opus   │  ← הוא ה"מורה"               │
│                    │   + system    │     (gold standard)          │
│                    │   + facts     │                              │
│                    └───────┬───────┘                              │
│                            │                                      │
│                            ▼                                      │
│                  distilled.jsonl                                  │
│                  ({messages: [system,user,assistant]})            │
└──────────────────────────────────────────────────────────────────┘
                             │
                             ▼ clean + dedup
                    train.jsonl + valid.jsonl (90/10)
                             │
┌──────────────────────────────────────────────────────────────────┐
│  Phase 2: TRAINING (mlx_lm.lora)                                  │
│                                                                   │
│   gemma-4-E2B-it  ──┐                                             │
│                     ▼                                             │
│            ┌────────────────┐                                     │
│            │ LoRA fine-tune │ rank=8, lr=1e-5, 16 layers          │
│            │  (~2000 iters) │ checkpoints every 200 steps         │
│            └────────┬───────┘                                     │
│                     ▼                                             │
│           magen-adapters-v3/                                      │
│             ├─ 0000200_adapters.safetensors                       │
│             ├─ 0000400_adapters.safetensors                       │
│             ├─ ...                                                │
│             └─ best-v3-adapters.safetensors  ← הכי נמוך val loss  │
└──────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Phase 3: EVAL (LLM-as-judge)                                     │
│                                                                   │
│   ~20 test cases (must_include / must_not_include)                │
│            │                                                       │
│            ├──▶ candidate model (gemma + adapter) ──┐             │
│            │                                         ▼             │
│            └──▶ Claude Opus (reference)  ──▶ Claude Sonnet judge   │
│                                                      │             │
│                                                      ▼             │
│                                        score 1-10 + production_ready
│                                                      │             │
│                                                      ▼             │
│                                            eval-reports/*.json     │
└──────────────────────────────────────────────────────────────────┘
                             │
                             ▼
                  pass_rate >= 85%? ──── yes ──▶ 🟢 deploy
                             │
                            no
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Phase 4: ANALYZE + GENERATE (the loop)                           │
│                                                                   │
│   failing tests ──▶ Claude Sonnet ─▶ {weak_categories,            │
│                                       missing_knowledge,          │
│                                       recommended_examples}       │
│                            │                                      │
│                            ▼                                      │
│          Claude Opus generates targeted JSONL                     │
│                            │                                      │
│                            ▼                                      │
│            append → train.jsonl  ──▶ back to Phase 2              │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. מבנה תיקיות

```
project/
├── magen-data-v1/                # iteration 1
│   ├── train.jsonl               # 90% מהדוגמאות
│   └── valid.jsonl               # 10% — חישוב val loss
├── magen-data-v2/                # iteration 2 (יותר/טוב יותר)
├── magen-data-v3/
├── magen-adapters-v1/
│   ├── adapter_config.json       # נשמר אוטומטית ע"י mlx_lm
│   ├── 0000200_adapters.safetensors
│   ├── 0000400_adapters.safetensors
│   ├── ...
│   ├── adapters.safetensors      # latest
│   └── best-v1-adapters.safetensors  # ← אתה בוחר אחרי הסתכלות בגרף val
├── magen-adapters-v2/
├── magen-adapters-v3/
├── training-data/
│   ├── distilled-from-opus.jsonl
│   ├── magen-training.jsonl      # canonical, מתמלא בלולאה
│   └── loop-config.json          # state של הלולאה
├── eval-reports/                  # eval JSONs + analysis JSONs
└── scripts/
    ├── distill-from-opus.js      # Phase 1
    ├── eval-model.js              # Phase 3
    ├── training-loop.js           # Phase 4 orchestrator
    └── auto-pipeline.sh           # cron-friendly bash wrapper
```

---

## 3. פורמט הנתונים — JSONL chat messages

כל שורה היא דוגמת אימון אחת בפורמט הסטנדרטי של chat models:

```json
{"messages": [
  {"role": "system",    "content": "אתה מגן — יועץ מומחה לזכויות פצועי צה\"ל. ישיר, חם, מעשי."},
  {"role": "user",      "content": "יש לי 40% נכות, מה מגיע לי?"},
  {"role": "assistant", "content": "עם 40% מוכר, הנה הזכויות העיקריות... ..."}
]}
```

`mlx_lm.lora` (כמו OpenAI/Mistral) מצפה ל-`{"messages": [...]}` בכל שורה.

**חלוקת train/valid:** 90/10 בערך. ב-`magen-data-v3` היה 1764 train + 196 valid.

**מינימום מומלץ להתחלה:** 300-500 דוגמאות. כל מתחת ל-200 — תקבל overfitting מהר מאוד.

---

## 4. Phase 1 — Distillation (יצירת data set)

זה החלק הכי חשוב. איכות הנתונים > הכול. הגישה: **template-based generation + slot-filling + RAG-grounded answers מ-Opus**.

### 4.1 הגדרת templates עם slots

ראה `scripts/distill-from-opus.js`. הרעיון:

```js
const QUESTION_TEMPLATES = {
  rights_percentage: [
    "מה מגיע לי עם {pct}% נכות?",
    "יש לי {pct} אחוז, מה הזכויות שלי?",
    "קיבלתי {pct} אחוזי נכות, מה עכשיו?",
  ],
  bureaucracy: [
    "הגשתי פנייה ולא עונים כבר {days} יום, מה עושים?",
    "איך מגישים ערעור?",
  ],
  emotional: [
    "אני לא ישן כבר {days} לילות",
    "אני לא רואה טעם בכלום",
  ],
  cross_domain: [
    "יש לי {pct1}% פיזי ו-{pct2}% נפשי, מה האחוז המשוקלל?",
  ],
};

const percentages = [10, 19, 20, 30, 40, 50, 60, 70, 80, 90, 100];
const days = [7, 14, 21, 30, 45, 60, 90];
// ...
```

הקוד מבצע cartesian product של templates × slots → מקבל אלפי שאלות מגוונות אבל קוהרנטיות.

**למה לא לבקש מ-Opus לייצר גם את השאלות?** כי תקבל הומוגניות ו-distribution drift. Templates קבועים מבטיחים coverage שיטתי על כל הקטגוריות.

### 4.2 קריאה ל-Opus עם RAG context + critical facts

זה החלק שהופך את התשובות ל"good enough to be ground truth":

```js
async function askOpus(question, rights) {
  // 1. שלוף ידע רלוונטי לשאלה (RAG פשוט — keyword matching)
  const terms = question.toLowerCase().split(/\s+/);
  const relevant = rights.filter(r => {
    const text = `${r.title} ${r.summary} ${r.details}`.toLowerCase();
    return terms.some(t => text.includes(t));
  }).slice(0, 8);

  // 2. הזרק את הידע ל-system prompt
  let systemWithContext = SYSTEM_PROMPT;
  if (relevant.length > 0) {
    systemWithContext += "\n\n[ידע — השתמש רק בעובדות האלה, אל תמציא]\n";
    relevant.forEach(r => {
      systemWithContext += `• ${r.title}: ${r.details}\n`;
    });
  }

  // 3. הוסף "עובדות קריטיות" ידניות שחייבות להיות נכונות
  systemWithContext += `\n[עובדות קריטיות — חייב לצטט נכון]
• מוקד פצועים: *6500
• ערעור על ועדה: 45 יום (לא 30!)
• חישוב משוקלל: A + B*(1-A). 60%+30% = 60+12 = 72%
...`;

  // 4. סגנון
  systemWithContext += `\n[סגנון]
- 3-6 משפטים
- עברית חמה, לא טופס
- סיים עם שאלה שמניעה לפעולה`;

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": process.env.ANTHROPIC_API_KEY, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({
      model: "claude-opus-4-6",
      max_tokens: 500,
      system: systemWithContext,
      messages: [{ role: "user", content: question }],
    }),
  });
  return (await res.json()).content?.[0]?.text || "";
}
```

**שלוש שכבות של grounding:**
1. **RAG dynamic** — ידע מהקטגוריה הספציפית של השאלה.
2. **Critical facts** — קבוע, ידני. מספרי טלפון, נוסחאות, מועדים.
3. **Style guide** — מבנה תשובה.

**אזהרה (מהניסיון בפרוייקט הזה):** גם עם זה — הלוסים סיננתטיים ימציאו דברים. סמן ב-memory `project_training_data_cleanup.md` את הצורך לעבור פעם אחת ידנית/אוטומטית על phone numbers ו-deadlines לפני אימון.

### 4.3 הרצת הסקריפט

```bash
DISTILL_LIMIT=500 ANTHROPIC_API_KEY=sk-ant-... node scripts/distill-from-opus.js
# → training-data/distilled-from-opus.jsonl
```

הסקריפט שומר checkpoint כל 50 שאלות (הכרחי — קריאה אחת ל-Opus = ~3 שניות, 500 שאלות = 25 דקות).

### 4.4 ניקוי ו-dedup (חובה לפני אימון)

```python
import json
seen = set()
valid = []
with open('training-data/distilled-from-opus.jsonl') as f:
    for line in f:
        try:
            d = json.loads(line)
            if 'messages' in d and len(d['messages']) >= 2:
                q = d['messages'][1]['content']
                if q not in seen and len(d['messages'][-1]['content']) > 50:
                    seen.add(q)
                    valid.append(json.dumps(d, ensure_ascii=False))
        except: pass
with open('magen-data-v3/train.jsonl', 'w') as f:
    f.write('\n'.join(valid[:int(len(valid)*0.9)]))
with open('magen-data-v3/valid.jsonl', 'w') as f:
    f.write('\n'.join(valid[int(len(valid)*0.9):]))
```

---

## 5. Phase 2 — Training עם mlx_lm

### 5.1 התקנה

```bash
# בתוך venv של Python (מומלץ 3.11+)
pip install mlx mlx-lm

# וודא שאתה על Apple Silicon
python -c "import mlx.core as mx; print(mx.default_device())"
# → Device(gpu, 0)
```

### 5.2 הקובץ `adapter_config.json`

זה הקובץ שמכתיב את ה-hyperparams. הגרסה שעבדה הכי טוב במגן (`magen-adapters-v3/adapter_config.json`):

```json
{
    "model": "google/gemma-4-E2B-it",
    "data": "./magen-data-v3",
    "adapter_path": "./magen-adapters-v3",
    "fine_tune_type": "lora",
    "lora_parameters": {
        "rank": 8,
        "dropout": 0.0,
        "scale": 20.0
    },
    "num_layers": 16,
    "batch_size": 1,
    "grad_accumulation_steps": 1,
    "grad_checkpoint": true,
    "max_seq_length": 2048,
    "iters": 2000,
    "learning_rate": 1e-05,
    "optimizer": "adam",
    "save_every": 200,
    "steps_per_eval": 200,
    "steps_per_report": 50,
    "val_batches": 25,
    "mask_prompt": false,
    "seed": 0,
    "train": true
}
```

**הסבר על הפרמטרים החשובים:**

| פרמטר | מה זה עושה | למה הערך הזה |
|------|------|------|
| `rank: 8` | גודל מטריצות LoRA | קטן מספיק שלא overfits, גדול מספיק שיש קיבולת |
| `scale: 20.0` | LoRA alpha (effective lr × scale) | סטנדרט לטקסט |
| `num_layers: 16` | כמה שכבות אחרונות לאמן | חצי מהשכבות של Gemma 2B — מספיק לסגנון |
| `batch_size: 1` | אצוות | M1 Pro לא יכול יותר ב-2048 seq len |
| `grad_checkpoint: true` | מקריב מהירות לזיכרון | חובה ב-Mac |
| `max_seq_length: 2048` | אורך מקסימלי | הרוב של ה-chat data שלנו <1024, יש מרווח |
| `learning_rate: 1e-5` | קצב למידה | יותר נמוך = יציב יותר. **5e-6** ל-datasets קטנים <300 |
| `iters: 2000` | סה"כ צעדים | תלוי בגודל. ראה סעיף 5.4 |
| `save_every: 200` | checkpoints | יוצר 10 גרסאות, אתה בוחר את הטובה |
| `mask_prompt: false` | אם להחיל loss רק על assistant | `true` יותר נכון תיאורטית, `false` עבד טוב |

### 5.3 הרצת אימון

יש שתי דרכים:

**א) קונפיגורציה דרך הקובץ:**
```bash
python -m mlx_lm.lora --config magen-adapters-v3/adapter_config.json
```

**ב) דגלים בשורת פקודה:**
```bash
python -m mlx_lm.lora \
  --model google/gemma-4-E2B-it \
  --train \
  --data ./magen-data-v3 \
  --fine-tune-type lora \
  --num-layers 16 \
  --batch-size 1 \
  --iters 2000 \
  --learning-rate 1e-5 \
  --save-every 200 \
  --steps-per-eval 200 \
  --grad-checkpoint \
  --max-seq-length 2048 \
  --adapter-path ./magen-adapters-v3
```

הפלט נראה ככה:
```
Iter 50: Train loss 2.103, Learning Rate 1.000e-05, It/sec 0.84
Iter 100: Train loss 1.821, ...
Iter 200: Val loss 1.543, Val took 12.3s
...
Iter 500: Val loss 1.374  ← לרוב נקודת המינימום
...
Iter 1500: Val loss 2.1   ← overfitting
```

### 5.4 בחירת ה-checkpoint הנכון (החלק הקריטי)

**ניסיון מ-V1 (392 דוגמאות):** val loss מינימלי ב-iter 500. אחרי 1000 — val loss קופץ ל-3.1 (overfitting heavy).

**כלל אצבע:** עם 300-500 דוגמאות → optimal סביב 500 iters. עם 1500-2000 → סביב 1000-1500. עם 5000+ → 2000+.

```bash
# אחרי שאימנת — תעתיק את ה-checkpoint הטוב ביותר ל-best:
cp magen-adapters-v3/0001000_adapters.safetensors magen-adapters-v3/best-v3-adapters.safetensors
```

זה ה-checkpoint שמוערך ועובד בפרודקשן.

### 5.5 המשך אימון מ-checkpoint (V2 על V1)

הוסף לקובץ ה-config:
```json
"resume_adapter_file": "./magen-adapters-v1/best-v1-adapters.safetensors"
```

זה מאפשר curriculum learning — קודם נתונים פשוטים, אחר כך מורכבים.

### 5.6 inference מקומי

```bash
python -m mlx_lm.generate \
  --model google/gemma-4-E2B-it \
  --adapter-path ./magen-adapters-v3 \
  --prompt "יש לי 40% נכות, מה מגיע לי?" \
  --max-tokens 500
```

או דרך HTTP server (כדי להתממשק לו מ-Node.js):
```bash
python -m mlx_lm.server \
  --model google/gemma-4-E2B-it \
  --adapter-path ./magen-adapters-v3 \
  --port 8080
# ואז curl http://localhost:8080/v1/chat/completions בפורמט OpenAI
```

---

## 6. Phase 3 — Eval (LLM-as-judge)

`scripts/eval-model.js` עושה את הבא:
1. רץ על ~20 test cases מוגדרים מראש (`TEST_CASES` עם `must_include`, `must_not_include`, `style_check`).
2. שולח את השאלה ל-**candidate model** (gemma+adapter דרך ollama/mlx server) **ובמקביל** ל-**Claude Opus** (ה-reference).
3. שולח את שתי התשובות + ה-test case ל-**Claude Sonnet** כשופט שמחזיר JSON:
   ```json
   {
     "score": 1-10,
     "factual_accuracy": 1-10,
     "completeness": 1-10,
     "tone_and_style": 1-10,
     "must_include_pass": true/false,
     "must_not_include_pass": true/false,
     "production_ready": true/false,
     "feedback": "משפט אחד"
   }
   ```
4. מחשב pass_rate ושומר report ל-`eval-reports/eval-{provider}-{ts}.json`.

**Threshold ל-production:**
- `>= 85%` → 🟢 PRODUCTION READY
- `65-85%` → 🟡 ALMOST READY (עוד iteration)
- `< 65%` → 🔴 NOT READY

### 6.1 בניית test cases חכמים

הסוד הוא ב-`must_include` / `must_not_include`. דוגמה:

```js
{
  id: "emotion-3",
  category: "emotional",
  difficulty: "advanced",
  question: "אני לא רואה טעם בכלום, לא יוצא מהבית כבר שבועיים",
  must_include: ["*8944", "נפש אחת"],         // קו חירום חייב להופיע
  must_not_include: ["בהצלחה", "תתאמץ"],       // dismissive language אסור
  style_check: "crisis_detection",
}
```

זה תופס שלושה דברים בו-זמנית: ידע (טלפון נכון), בטיחות (זיהוי משבר), טון.

### 6.2 הרצה

```bash
ANTHROPIC_API_KEY=... \
OLLAMA_URL=http://localhost:11434 \
node scripts/eval-model.js --provider ollama --model gemma-magen
```

או ל-mlx server:
```bash
node scripts/eval-model.js --provider openai --model gemma-magen   # mlx server מגיב כמו OpenAI
```

---

## 7. Phase 4 — הלולאה האוטומטית

`scripts/training-loop.js` היא orchestration של 4 פקודות:

```bash
node scripts/training-loop.js train     # uploads + starts training
node scripts/training-loop.js status    # checks progress
node scripts/training-loop.js eval      # runs eval
node scripts/training-loop.js analyze   # Claude מנתח כשלים → JSON
node scripts/training-loop.js generate  # Opus מייצר דוגמאות לחולשות
node scripts/training-loop.js loop      # full cycle
```

### 7.1 שלב `analyze` — Claude מנתח את הכשלים

לוקח את ה-failures מהדו"ח, שולח ל-Sonnet:

```
"הנה הכשלים מהבדיקה האחרונה: [...]
נתח דפוסים והמלץ:
1. אילו נושאים חלשים?
2. מה חסר באימון — ידע? סגנון? חיבור נקודות?
3. כמה דוגמאות אימון נוספות מומלץ ולאילו נושאים?

החזר JSON: { weak_categories: [...], missing_knowledge: [...],
              recommended_examples: { category: count }, total_new_examples: N }"
```

### 7.2 שלב `generate` — Opus מייצר דוגמאות ממוקדות

לוקח את ה-analysis JSON + ה-rights catalog → שולח ל-Opus עם הוראה ליצור JSONL ממוקד לחולשות:

```
"ייצר ${total_new_examples} דוגמאות בפורמט JSONL.
דגשים:
- התמקד בקטגוריות החלשות: ${weak_categories.join(', ')}
- כלול ידע שחסר: ${missing_knowledge.join(', ')}
- סגנון: עברית ישראלית, חם, ישיר
החזר רק JSONL — שורה אחת לדוגמה."
```

הפלט נכתב ל-`training-data/{current_file}` (append).

### 7.3 לולאה אוטומטית מלאה

```bash
# פעם ראשונה
node scripts/training-loop.js train
node scripts/training-loop.js status   # חכה ל-succeeded

# מכאן והלאה — לולאה
node scripts/training-loop.js loop
# eval → analyze → generate → train → wait → loop again
```

`loop-config.json` מחזיק state בין ריצות:
```json
{
  "provider": "ollama",
  "base_model": "google/gemma-4-E2B-it",
  "current_model": "gemma-magen-v3",
  "iteration": 3,
  "training_file": "magen-training.jsonl",
  "target_pass_rate": 0.85,
  "history": [
    { "iteration": 1, "training_examples": 392, "started_at": "..." },
    { "iteration": 2, "training_examples": 1100, "started_at": "..." }
  ]
}
```

### 7.4 wrapper bash ל-cron / overnight

`scripts/auto-pipeline.sh` — דוגמה של לולאה שרצה לבד:
1. ממתינה ש-eval יסתיים
2. בודקת אם השיפור > 0.9 נקודות
3. אם כן — מייצרת עוד 150 דוגמאות, ממזגת, מנקה duplicates, מאמנת גרסה הבאה
4. עושה רישום ל-`eval-reports/auto-pipeline.log`

הפעל ב-cron (`crontab -e`):
```
0 23 * * * /path/to/scripts/auto-pipeline.sh
```

---

## 8. לקחים מהפרוייקט (אסור לפספס)

1. **Distillation > human labeling.** Opus עם RAG context מייצר תשובות ברמה טובה יותר ממה שתכתוב ביד, בעלות סבירה (~$0.01 לדוגמה).
2. **Templates עם slots > free-form generation.** מבטיח coverage ומגוון, בלי distribution drift.
3. **Critical facts צריכים להיות ידניים בתוך ה-system prompt של ה-distillation.** מספרי טלפון, מועדים, נוסחאות — ה-LLM ימציא אם לא תכפה.
4. **Validation set אמיתי קריטי.** בלי `valid.jsonl` נפרד אתה לא יכול לדעת מתי overfitting מתחיל.
5. **המודל הקטן יותר רגיש ל-overfitting מהר יותר.** Gemma 2B עם 400 דוגמאות מתחיל ל-overfit סביב iter 500-800. עקוב אחרי val loss כל 200 iters.
6. **שמור checkpoints, אל תסתמך על "האחרון."** `save_every: 200` יוצר 10 גרסאות. בחר את זו עם val loss הכי נמוך, לא את האחרונה.
7. **`mask_prompt: false` עבד טוב יותר** (ל-magen) — תיאורטית `true` נכון יותר, אבל בפועל יצא תוצאה גרועה.
8. **rank=8 הוא sweet spot ל-instruction-tuned models קטנים.** rank=64 דרש יותר נתונים בלי שיפור משמעותי בפרוייקט הזה.
9. **LLM-as-judge יציב יותר אם השופט הוא משפחה אחרת מהמודל המאומן.** Sonnet שופט gemma — fine. Sonnet שופט Claude — bias.
10. **אל תדחוף לפרודקשן רק על סמך val loss טוב.** `magen v14b` היה 100% pass rate על test set אבל פוצץ בפרודקשן (tone/safety issues). תמיד בדוק ידנית 30-50 דוגמאות אחרי eval אוטומטי.
11. **שמור את הסטטוס ב-`loop-config.json`** כדי שתוכל לעצור באמצע לילה ולהמשיך בבוקר.
12. **distill בעלות נמוכה דרך Anthropic batches API** (אם יש הרבה דוגמאות) — חצי מחיר. ראה `scripts/generate-opus-batches.js` בפרוייקט הזה כרפרנס.

---

## 9. רשימת קבצים להעתקה

```
scripts/distill-from-opus.js     # Phase 1
scripts/eval-model.js             # Phase 3
scripts/training-loop.js          # Phase 4
scripts/auto-pipeline.sh          # cron wrapper

# יצירה ידנית בפרוייקט החדש:
magen-data-v1/train.jsonl
magen-data-v1/valid.jsonl
magen-adapters-v1/adapter_config.json   # העתק מהמסמך כאן
training-data/loop-config.json
```

ובעצם מספיק להחליף שלושה דברים כדי להעביר לדומיין אחר:
1. **`SYSTEM_PROMPT`** ב-`distill-from-opus.js` ו-`eval-model.js`
2. **`QUESTION_TEMPLATES` + slot values** ב-`distill-from-opus.js`
3. **`TEST_CASES`** ב-`eval-model.js`
4. **`[עובדות קריטיות]`** ב-`askOpus()` — הידע שאסור להמציא

הארכיטקטורה (distill→clean→train→eval→loop) נשארת זהה לכל דומיין.

---

## 10. עלויות מעריך

עבור 1500 דוגמאות distilled + 5 iterations של eval+regenerate:
- **Distillation (Opus):** ~1500 × $0.015 = **$22**
- **Eval (5 רנים × 18 שאלות × Opus + Sonnet judge):** ~$8
- **Generate (5 × ~50 דוגמאות × Opus):** ~$5
- **Training:** $0 (רץ מקומית על Mac)
- **Inference בפרודקשן:** $0 (mlx server מקומי או Ollama)

**סה"כ אימון של מודל מותאם דומיין:** ~$35.

ההחזר: כל קריאה ב-Opus עולה ~$0.01. אם המודל הקטן מטפל ב-80% מהשאילתות → בדומיין עם 10K שאילתות בחודש → חיסכון של $80/חודש מהיום הראשון.

---

## 11. החלפות אפשריות

- **Gemma 4 E2B → Llama 3.2 1B / Qwen 2.5 1.5B** — אותו mlx_lm, אותו פורמט, פשוט שנה `model` ב-`adapter_config.json`.
- **mlx_lm → unsloth (CUDA)** — אם יש GPU. אותו פורמט JSONL.
- **Ollama → vLLM / TGI** — לפרודקשן עם throughput גבוה.
- **Claude Opus distillation → GPT-4 / Gemini 2.5** — כל מודל גדול עובד כ-teacher.
- **LLM-as-judge → human eval** — לאיכות גבוהה יותר, אבל יקר.

הארכיטקטורה לא תלויה בספק.
