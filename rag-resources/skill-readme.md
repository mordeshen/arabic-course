# 🇵🇸 Palestinian Arabic Skill — ערבית פלסטינית מדוברת

A comprehensive Palestinian Arabic skill for Claude Code, based on **Marwan's Library** (הספרייה של מרואן).

## Quick Install

```bash
# Option 1: Run the installer
chmod +x install.sh && ./install.sh

# Option 2: Manual install
mkdir -p ~/.claude/skills/palestinian-arabic
cp -r . ~/.claude/skills/palestinian-arabic/
```

## What's Inside

| File | Size | Content |
|------|------|---------|
| `SKILL.md` | 4KB | Main instructions for Claude |
| `references/dictionary.md` | 125KB | Full vocabulary: greetings, family, numbers, phone, food, doctor, directions, slang |
| `references/grammar.md` | 271KB | Complete grammar: all verb tenses, binyanim, negation, pronouns, MSA vs spoken |
| `references/transcripts.md` | 273KB | 22 real-world transcripts: songs, interviews, sketches |
| `references/culture.md` | 1KB | Cultural context (expandable) |
| `references/dialects.md` | 1.5KB | Regional dialect overview (expandable) |
| `references/corrections.md` | 0.5KB | Native speaker corrections log |
| `scripts/add_knowledge.py` | 7KB | CLI tool for adding new entries |

**Total: ~680KB of native-speaker-verified content**

## Usage in Claude Code

Just ask Claude anything about Palestinian Arabic:

```
> תרגם לי: "איפה התחנת אוטובוס?"
> איך מטים את הפועל "הלך" בעבר?
> מה ההבדל בין מִש ל-מא בשלילה?
> איך אומרים "יישר כח" בערבית?
```

## Adding Knowledge

```bash
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py word        # Add a word
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py correction  # Log a correction
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py grammar     # Add grammar rule
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py bulk file   # Import from file
python ~/.claude/skills/palestinian-arabic/scripts/add_knowledge.py show        # View stats
```

## Source

Based on **מרואן - הספרייה** — a complete Palestinian Arabic course for Hebrew speakers, created by a native speaker. The course covers beginners through advanced levels with Hebrew transliteration, grammar explanations, and real-world usage examples.

## Transliteration

Uses Marwan's Hebrew-based transliteration system with nikud. See `SKILL.md` for the full mapping table.
