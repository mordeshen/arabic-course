# 📁 אינדקס תמונות שלטים — نوّطني Game Assets

## קבצים זמינים (7 שלטים)

| קובץ | שלט ID | ערבית | עברית | אנגלית | כביש | קושי |
|---|---|---|---|---|---|---|
| `sign_03_mizpe_ramon_eilat_...` | sign_03 | متسبي رمون / ايلات | מצפה רמון / אילת | Mizpe Ramon / Eilat | 40 | medium |
| `sign_04_sderot_...` | sign_04 | سديروت | שדרות | Sderot | — | easy |
| `sign_06_jerusalem_...` | sign_06 | اورشليم (القدس) | ירושלים | Jerusalem | — | hard |
| `sign_07_atir_yeda_...` | sign_07 | صناعات متقدمة | עתיר ידע | Atir Yeda | — | hard |
| `sign_08_kafar_kanna_nazareth_...` | sign_08 | كفر كنا / الناصره | כפר כנא / נצרת | Kafar Kanna / Nazareth | 754 | medium |
| `sign_09_tel_aviv_yafo_...` | sign_09 | تل ابيب-يافا | תל אביב-יפו | Tel Aviv-Yafo | 65 | easy |
| `sign_11_kerem_shalom_...` | sign_11 | كيرم شالوم | כרם שלום | Kerem Shalom | 232 | medium |

## שמות קבצים — מבנה

```
sign_{ID}_{english_name}_{arabic_name}_{road}.png
```

- ה-ID תואם ל-`signs[].id` ב-`road_signs_game_data.json`
- השם הערבי בשם הקובץ מאפשר זיהוי מהיר גם בלי לפתוח

## שלטים חסרים (היו בJSON אבל אין תמונה בזיפ)

| שלט ID | מה חסר | פתרון |
|---|---|---|
| sign_01 | כרמיאל (كرميئيل) | צלם או מצא תמונה |
| sign_02 | מרום גולן (مروم جولان) | צלם או מצא תמונה |
| sign_05 | נצרת בודד (الناصره) | קיים בתוך sign_08 כחלק מהשלט |
| sign_10 | פתח תקווה (بيتح تكفا) | צלם או מצא תמונה |
| sign_12 | מרום גולן crop | כפילות של sign_02 |

## שימוש ב-Claude Code

```javascript
// טעינת תמונה לפי sign ID
const signData = gameData.signs.find(s => s.id === 'sign_06');
const imagePath = `./sign_images/${signData.image_file}`;
// או לפי השם החדש:
const imageByName = './sign_images/sign_06_jerusalem_اورشليم_القدس.png';
```

## קבצים נלווים (לא בזיפ, ב-outputs)
- `road_signs_game_data.json` — כל המידע על השלטים, מסכות, תשובות
- `ARABIC_ROAD_GAME_DESIGN.md` — עיצוב המשחק המלא
- `palestinian_arabic_course_kb.json` — בסיס הידע של הקורס
