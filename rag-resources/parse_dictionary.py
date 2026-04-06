#!/usr/bin/env python3
"""Parse dictionary_raw.txt into structured JSON."""

import json
import re
import sys
import logging

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
log = logging.getLogger(__name__)

# Annotations to strip from Hebrew meaning lines
ANNOTATIONS = [
    'לערך זה יש תמונה',
    'לערך זה יש סרטון או אודיו',
    'ערך זה נבדק ונמצא תקין',
    'טרם נבדק',
    'ערך בבדיקה',
]

NOISE_EXACT = {
    'menu', 'logo', 'מילון ערבית מדוברת',
    'קבוצות מילים לפי נושאים', 'הצג רשימת נושאים',
    'התחברו למילון',
}

# Expected category counts from the document
EXPECTED_COUNTS = {
    'אוכל': 311,
    'בבית': 255,
    'בגדים': 86,
    'ביטויים': 117,
    'בעלי חיים 1 - יונקים': 84,
    'בעלי חיים 2 - עופות': 41,
    'בעלי חיים 3 - כל השאר': 103,
    'ברכות': 102,
    'בשימוש בעברית': 63,
    'גוף האדם': 146,
    'דקדוק': 73,
    'דתות וחגים': 215,
    'זמן': 182,
    'חומרים': 53,
    'חינוך': 92,
    'טכנולוגיה ומחשבים': 100,
    'ירקות': 37,
    'כלי עבודה': 30,
    'כלכלה': 181,
    'מדע': 78,
    'מוסיקה': 55,
    'מזג אוויר': 79,
    'מספרים': 68,
    'מקומות 1 - מדינות': 48,
    'מקומות 2 - ערים': 28,
    'מקומות 3 - כל השאר': 240,
    'מקצועות': 219,
    'משפחה': 109,
    'ספורט': 117,
    'פוליטיקה': 191,
    'פירות': 58,
}


def has_arabic(s):
    return bool(re.search(r'[\u0600-\u06FF]', s))


def has_hebrew(s):
    return bool(re.search(r'[\u0590-\u05FF]', s))


def has_latin(s):
    return bool(re.search(r'[a-zA-Z]', s))


def count_hebrew(s):
    return len(re.findall(r'[\u0590-\u05FF]', s))


def count_arabic(s):
    return len(re.findall(r'[\u0600-\u06FF]', s))


def is_primarily_arabic(s):
    """Line is primarily Arabic text (more Arabic than Hebrew chars)."""
    return count_arabic(s) > count_hebrew(s) and has_arabic(s)


def is_primarily_hebrew(s):
    """Line is primarily Hebrew text."""
    return count_hebrew(s) > count_arabic(s) and has_hebrew(s)


def contains_annotation(s):
    """Check if line contains any of the known annotations."""
    return any(ann in s for ann in ANNOTATIONS)


def is_noise(line):
    if not line:
        return True
    if line in NOISE_EXACT:
        return True
    # Combined noise strings
    if 'התחברו למילון' in line and 'מילון ערבית מדוברת' in line:
        return True
    # 4-digit timestamp
    if re.fullmatch(r'\d{4}', line):
        return True
    # Clock line in Arabic transliteration - broader pattern
    # These start with אִ(ל)סֵ and contain דַקִיקַה
    if 'אִ(ל)סֵ' in line:
        return True
    # "N מילים" pattern
    if re.fullmatch(r'\d+\s+מילים', line):
        return True
    return False


def clean_hebrew(s):
    for ann in ANNOTATIONS:
        s = s.replace(ann, '')
    return s.strip()


def is_category_line(line, next_line):
    """Check if line is a category name (next line is 'N מילים')."""
    if next_line and re.fullmatch(r'\d+\s+מילים', next_line.strip()):
        return True
    return False


def is_hebrew_meaning(line):
    """Detect if a line is a Hebrew meaning line.
    It should contain Hebrew text and may contain annotations.
    It should be primarily Hebrew (even if it has some Arabic in parenthetical notes).
    """
    if not has_hebrew(line):
        return False
    # If it contains annotations, it's definitely a meaning line
    if contains_annotation(line):
        return True
    # If it has no Arabic, it's Hebrew meaning
    if not has_arabic(line):
        return True
    # If it has both, check if Hebrew dominates
    if is_primarily_hebrew(line):
        return True
    return False


def parse(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = [l.rstrip('\n') for l in f.readlines()]

    entries = []
    current_category = None
    seen_categories = set()  # track which categories we've already seen (for page reload dedup)
    is_repeat_page = False
    seen_in_repeat = {}  # dedup entries only during repeat page loads
    skipped = []
    i = 0

    def peek(offset):
        idx = i + offset
        return lines[idx].strip() if idx < len(lines) else ''

    while i < len(lines):
        line = lines[i].strip()

        # Skip noise
        if is_noise(line):
            i += 1
            continue

        # Check for category header
        next_line = lines[i + 1].strip() if i + 1 < len(lines) else ''
        if is_category_line(line, next_line):
            if line in seen_categories:
                is_repeat_page = True
            else:
                is_repeat_page = False
                seen_categories.add(line)
            current_category = line
            i += 2  # skip category name + "N מילים"
            continue

        # Try to parse entries
        if is_hebrew_meaning(line):
            hebrew = clean_hebrew(line)
            line2 = peek(1)
            line3 = peek(2)
            line4 = peek(3)

            # Standard 4-line: hebrew, arabic, hebrew-translit, latin-translit
            if has_arabic(line2) and not has_latin(line2) and has_hebrew(line3) and has_latin(line4) and not has_arabic(line4):
                arabic = line2
                hebrew_translit = line3
                latin_translit = line4

                entry = {
                    'hebrew': hebrew,
                    'arabic': arabic,
                    'hebrew_transliteration': hebrew_translit,
                    'latin_transliteration': latin_translit,
                    'category': current_category,
                }
                key = (current_category, arabic, hebrew, hebrew_translit, latin_translit)
                if is_repeat_page:
                    if key not in seen_in_repeat:
                        seen_in_repeat[key] = True
                        entries.append(entry)
                else:
                    seen_in_repeat[key] = True
                    entries.append(entry)
                i += 4
                continue

            # Swapped: hebrew, hebrew-translit, arabic, latin-translit
            if has_hebrew(line2) and not has_arabic(line2) and has_arabic(line3) and has_latin(line4) and not has_arabic(line4):
                hebrew_translit = line2
                arabic = line3
                latin_translit = line4

                entry = {
                    'hebrew': hebrew,
                    'arabic': arabic,
                    'hebrew_transliteration': hebrew_translit,
                    'latin_transliteration': latin_translit,
                    'category': current_category,
                }
                key = (current_category, arabic, hebrew, hebrew_translit, latin_translit)
                if is_repeat_page:
                    if key not in seen_in_repeat:
                        seen_in_repeat[key] = True
                        entries.append(entry)
                else:
                    seen_in_repeat[key] = True
                    entries.append(entry)
                i += 4
                continue

            # 3-line entry (missing Arabic): hebrew, hebrew-translit, latin-translit
            if has_hebrew(line2) and not has_arabic(line2) and has_latin(line3) and not has_arabic(line3):
                hebrew_translit = line2
                latin_translit = line3
                arabic = ''  # missing

                entry = {
                    'hebrew': hebrew,
                    'arabic': arabic,
                    'hebrew_transliteration': hebrew_translit,
                    'latin_transliteration': latin_translit,
                    'category': current_category,
                }
                key = (current_category, '', hebrew, hebrew_translit, latin_translit)
                if is_repeat_page:
                    if key not in seen_in_repeat:
                        seen_in_repeat[key] = True
                        entries.append(entry)
                else:
                    seen_in_repeat[key] = True
                    entries.append(entry)
                    log.warning(f"  Entry missing Arabic line at line {i+1}: {hebrew}")
                i += 3
                continue

        # If we get here, the line didn't match any pattern
        if line and not is_noise(line):
            skipped.append((i + 1, line))
        i += 1

    return entries, skipped


def validate(entries):
    errors = []

    # Count by category
    cat_counts = {}
    for e in entries:
        cat = e['category']
        cat_counts[cat] = cat_counts.get(cat, 0) + 1

    # Compare with expected
    for cat, expected in EXPECTED_COUNTS.items():
        actual = cat_counts.get(cat, 0)
        if actual != expected:
            errors.append(f"Category '{cat}': expected {expected}, got {actual}")

    # Check for unexpected categories
    for cat in cat_counts:
        if cat not in EXPECTED_COUNTS and cat is not None:
            errors.append(f"Unexpected category: '{cat}' with {cat_counts[cat]} entries")

    # All fields non-empty (except arabic which may be missing in some entries)
    for i, e in enumerate(entries):
        for field in ['hebrew', 'hebrew_transliteration', 'latin_transliteration']:
            if not e[field]:
                errors.append(f"Entry {i}: empty field '{field}'")

    # Arabic field has Arabic chars (warn if missing)
    missing_arabic = 0
    for i, e in enumerate(entries):
        if not e['arabic']:
            missing_arabic += 1
        elif not has_arabic(e['arabic']):
            errors.append(f"Entry {i}: 'arabic' has no Arabic chars: {e['arabic']}")

    if missing_arabic:
        log.warning(f"  {missing_arabic} entries missing Arabic script")

    # Latin field has Latin chars
    for i, e in enumerate(entries):
        if not has_latin(e['latin_transliteration']):
            errors.append(f"Entry {i}: 'latin_transliteration' has no Latin: {e['latin_transliteration']}")

    # No annotations left in Hebrew
    for i, e in enumerate(entries):
        for ann in ANNOTATIONS:
            if ann in e['hebrew']:
                errors.append(f"Entry {i}: annotation found in hebrew: {ann}")

    # No noise entries
    for i, e in enumerate(entries):
        if e['hebrew'] in NOISE_EXACT or re.fullmatch(r'\d{4}', e['hebrew']):
            errors.append(f"Entry {i}: noise in hebrew: {e['hebrew']}")

    return errors, cat_counts


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Parse dictionary_raw.txt to JSON')
    parser.add_argument('input', help='Input file path')
    parser.add_argument('-o', '--output', default='arabic_dictionary.json', help='Output JSON file')
    args = parser.parse_args()

    entries, skipped = parse(args.input)

    if skipped:
        log.warning(f"Skipped {len(skipped)} unrecognized lines:")
        for line_num, text in skipped:
            log.warning(f"  Line {line_num}: {text}")

    errors, cat_counts = validate(entries)

    # Build output
    output = {
        'metadata': {
            'title': 'מילון ערבית מדוברת',
            'title_arabic': 'قاموس عربي محكي',
            'description': 'Spoken Arabic Dictionary - Hebrew to Spoken Arabic (Levantine dialect)',
            'total_entries': len(entries),
            'categories': {cat: cat_counts.get(cat, 0) for cat in EXPECTED_COUNTS},
        },
        'entries': entries,
    }

    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    log.info(f"Total entries: {len(entries)}")
    log.info(f"Categories: {len(cat_counts)}")
    for cat, count in sorted(cat_counts.items(), key=lambda x: x[0]):
        expected = EXPECTED_COUNTS.get(cat, '?')
        status = '✓' if count == expected else f'✗ (expected {expected})'
        log.info(f"  {cat}: {count} {status}")

    if errors:
        log.warning(f"\nValidation issues ({len(errors)}):")
        for err in errors:
            log.warning(f"  {err}")
    else:
        log.info("\nAll validations passed!")

    log.info(f"\nOutput written to {args.output}")


if __name__ == '__main__':
    main()
