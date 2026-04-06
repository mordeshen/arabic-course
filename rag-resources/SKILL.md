---
name: palestinian-arabic
description: >
  Palestinian Arabic (العامية الفلسطينية) translation, writing, and comprehension skill.
  Use this skill whenever the user asks to translate to/from Palestinian Arabic, write messages
  in Palestinian dialect, understand Arabic slang or expressions, communicate with Arabic speakers,
  or needs help with any Palestinian/Levantine Arabic content. Also trigger when the user mentions
  ערבית, פלסטינית, عامية, or asks to write/read/understand Arabic text in a colloquial context.
  Contains a comprehensive 400KB+ knowledge base from Marwan's Library — a complete Palestinian
  Arabic course verified by a native speaker. Trigger for: translation, Arabic learning, dialect
  questions, greetings, slang, verb conjugation, Arabic grammar, Levantine Arabic, שאמי.
---

# Palestinian Arabic Skill (ערבית פלסטינית)

## Source

**מרואן - הספרייה** (Marwan's Library) — a complete Palestinian Arabic course by a native speaker.
All content verified ✓.

## Reference Files

Load these based on query type. **Do not load all files at once** — read only what's needed:

| When the query is about... | Read this file |
|---|---|
| Vocabulary, phrases, expressions, specific words | `references/dictionary.md` |
| Verb conjugation, tenses, grammar rules, sentence structure | `references/grammar.md` |
| Understanding real spoken Arabic, song lyrics, interviews | `references/transcripts.md` |
| Cultural norms, formality, greetings protocol | `references/culture.md` |
| Regional dialect differences (Jerusalem vs Hebron vs Galilee) | `references/dialects.md` |
| Past mistakes and corrections | `references/corrections.md` |

### File sizes (for context management)
- `dictionary.md` — 125KB (beginners lessons 1-9, level 2, advanced topics)
- `grammar.md` — 271KB (all tenses, binyanim, negation, pronouns, MSA vs spoken)
- `transcripts.md` — 273KB (22 real-world transcripts with translations)
- `culture.md` — 1KB (expandable)
- `dialects.md` — 1.5KB (expandable)
- `corrections.md` — 0.5KB (log of native speaker corrections)

**Tip:** For large files, use Grep to search for the relevant section rather than reading the entire file.

## Marwan's Transliteration System

The course uses Hebrew-letter transliteration with nikud. Key mappings:

| Hebrew | Arabic | Sound | Example |
|--------|--------|-------|---------|
| בּ | ب | b | בּאבּ (door) |
| כּ | ك | k | כַּלְבּ (dog) |
| ג' | ج | j/z | גַ'ו (atmosphere) |
| ח' | خ | kh | ח'אלֵד |
| ר' | غ | gh | ר'אבֵּה (forest) |
| ט | ط | emphatic t | בַּטֿאטֿא (potato) |
| דֿ | ض | emphatic d | דַֿחְכֵּה (laughter) |
| סֿ | ص | emphatic s | סַֿףّ (class) |
| זֿ | ظ | emphatic z | מַזְֿבּוּטֿ (correct) |
| ת' | ث | th (think) | מַתַ'ל (proverb) |
| ד' | ذ | th (that) | האד'י (this f.) |
| ק | ق | glottal stop* | קַלְבּי → אַלְבּי (my heart) |
| {text} | — | feminine form | עִנְדַכּ {עִנְדֵכּ} |
| (א) | — | swallowed alef | (א)ס-סַלאם |

*ק is pronounced as glottal stop (hamza) in most Palestinian dialects; hard Q in Hebron.

## Usage Rules

1. **Default to spoken Palestinian** (מדוברת), not MSA (ספרותית), unless asked
2. **Always provide**: transliteration in Hebrew letters + Hebrew meaning
3. **Gender**: show both forms using {feminine} notation
4. **Greetings**: always provide the greeting AND the expected response
5. **Register**: note formality level when relevant (casual/respectful/formal)
6. **Uncertainty**: if something isn't in the references, say so — don't guess

## Response Format

```
[Transliteration] — [Arabic script optional]
[Hebrew translation]
{Feminine form if different}
[Context: when/how to use]
```

Example:
```
יַעְטֿיכּ (א)לְעאפְיֵה — يعطيك العافية
ברכה לאדם שעובד (יישר כח)
{יַעְטֿיכּי (א)לְעאפְיֵה}
תשובה: אַללַה יְעאפיכּ {יְעאפיכּי}
```

## Adding Knowledge

Use the helper script to add new entries:
```bash
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py word        # Add word
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py correction  # Log correction
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py grammar     # Add grammar rule
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py bulk file   # Bulk import
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py show        # Stats
```
