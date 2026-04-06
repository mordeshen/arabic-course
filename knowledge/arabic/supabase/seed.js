#!/usr/bin/env node
/**
 * Seed script — Populates Supabase tables from kb_*.json files
 *
 * Usage:
 *   export SUPABASE_URL=https://your-project.supabase.co
 *   export SUPABASE_SERVICE_KEY=your-service-role-key
 *   node seed.js
 *
 * Or with .env file (requires dotenv):
 *   node -r dotenv/config seed.js
 */

import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const KB_DIR = join(__dirname, "..");

// ── Config ──────────────────────────────────────────────────
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error(
    "Missing SUPABASE_URL or SUPABASE_SERVICE_KEY environment variables."
  );
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ── Helpers ─────────────────────────────────────────────────
function loadJSON(filename) {
  const path = join(KB_DIR, filename);
  console.log(`  Reading ${filename}...`);
  return JSON.parse(readFileSync(path, "utf-8"));
}

const BATCH_SIZE = 500;

async function batchInsert(table, rows) {
  let inserted = 0;
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const { error } = await supabase.from(table).insert(batch);
    if (error) {
      console.error(`  Error inserting into ${table} (batch ${i}):`, error.message);
      throw error;
    }
    inserted += batch.length;
  }
  return inserted;
}

async function clearTable(table) {
  const { error } = await supabase.from(table).delete().neq("id", 0);
  if (error) {
    console.error(`  Warning: could not clear ${table}:`, error.message);
  }
}

// ── Seed: vocabulary ────────────────────────────────────────
async function seedVocabulary() {
  console.log("\n📖 Seeding vocabulary...");
  const data = loadJSON("kb_dictionary.json");
  const rows = data.entries.filter((e) => e.hebrew || e.word).map((e) => ({
    hebrew: e.hebrew || e.word,
    arabic: e.arabic || null,
    hebrew_translit: e.hebrew_transliteration || null,
    latin_translit: e.latin_transliteration || null,
    category: e.category || "general",
    source: e.source || null,
  }));

  await clearTable("vocabulary");
  const count = await batchInsert("vocabulary", rows);
  console.log(`  Inserted ${count} vocabulary entries.`);
}

// ── Seed: verb_conjugations ─────────────────────────────────
async function seedConjugations() {
  console.log("\n🔄 Seeding verb_conjugations...");
  const data = loadJSON("kb_conjugations.json");
  const tables = data.verb_tables || {};

  const rows = Object.entries(tables).map(([key, v]) => {
    const past = v.conjugations?.past || {};
    const pres = v.conjugations?.present || {};
    const imp = v.conjugations?.imperative || {};

    return {
      verb_key: key,
      root: v.root,
      base_form: v.base,
      translation: v.translation,
      binyan: v.binyan || null,
      // Past
      past_1sg: past["1sg"] || null,
      past_2sg_m: past["2sg_m"] || null,
      past_2sg_f: past["2sg_f"] || null,
      past_3sg_m: past["3sg_m"] || null,
      past_3sg_f: past["3sg_f"] || null,
      past_1pl: past["1pl"] || null,
      past_2pl: past["2pl"] || null,
      past_3pl: past["3pl"] || null,
      // Present
      pres_1sg: pres["1sg"] || null,
      pres_2sg_m: pres["2sg_m"] || null,
      pres_2sg_f: pres["2sg_f"] || null,
      pres_3sg_m: pres["3sg_m"] || null,
      pres_3sg_f: pres["3sg_f"] || null,
      pres_1pl: pres["1pl"] || null,
      pres_2pl: pres["2pl"] || null,
      pres_3pl: pres["3pl"] || null,
      // Imperative
      imp_sg_m: imp["sg_m"] || null,
      imp_sg_f: imp["sg_f"] || null,
      imp_pl: imp["pl"] || null,
    };
  });

  await clearTable("verb_conjugations");
  const count = await batchInsert("verb_conjugations", rows);
  console.log(`  Inserted ${count} verb conjugation entries.`);

  // Also seed binyan patterns as grammar rules
  if (data.binyan_patterns) {
    console.log("  (binyan_patterns will be seeded with grammar_rules)");
  }
}

// ── Seed: grammar_rules ─────────────────────────────────────
async function seedGrammarRules() {
  console.log("\n📐 Seeding grammar_rules...");
  const core = loadJSON("kb_core.json");
  const conj = loadJSON("kb_conjugations.json");
  const rows = [];

  // -- Phonology rules --
  const phon = core.phonology || {};

  if (phon.sun_letters) {
    rows.push({
      rule_key: "sun_letters",
      domain: "phonology",
      title: "אותיות שמש",
      description: phon.sun_letters.description,
      content: phon.sun_letters,
      lesson_num: 2,
      difficulty: "beginner",
      tags: ["שמש", "אל הידיעה", "הגייה", "phonology"],
    });
  }

  if (phon.moon_letters) {
    rows.push({
      rule_key: "moon_letters",
      domain: "phonology",
      title: "אותיות ירח",
      description: phon.moon_letters.description,
      content: phon.moon_letters,
      lesson_num: 2,
      difficulty: "beginner",
      tags: ["ירח", "אל הידיעה", "הגייה", "phonology"],
    });
  }

  if (phon.definite_article) {
    rows.push({
      rule_key: "definite_article",
      domain: "phonology",
      title: "אל הידיעה",
      description: "כללי אל הידיעה — מתי ה-ל נבלעת ומתי ה-א נעלמת",
      content: phon.definite_article,
      lesson_num: 2,
      difficulty: "beginner",
      tags: ["אל הידיעה", "יידוע", "phonology"],
    });
  }

  if (phon.vowel_changes_in_dialect) {
    rows.push({
      rule_key: "vowel_changes",
      domain: "phonology",
      title: "שינויי תנועות בפלסטינית",
      description: phon.vowel_changes_in_dialect.description,
      content: phon.vowel_changes_in_dialect,
      difficulty: "intermediate",
      tags: ["תנועות", "דיאלקט", "הגייה", "phonology"],
    });
  }

  // -- Morphology rules --
  const morph = core.morphology || {};

  if (morph.attached_pronouns) {
    rows.push({
      rule_key: "attached_pronouns",
      domain: "morphology",
      title: "כינויי שייכות חבורים",
      description: morph.attached_pronouns.description || "כינויי גוף שמתחברים לשמות ולפעלים",
      content: morph.attached_pronouns,
      lesson_num: 3,
      difficulty: "beginner",
      tags: ["כינויים", "שייכות", "morphology"],
    });
  }

  if (morph.verb_patterns) {
    rows.push({
      rule_key: "verb_patterns_overview",
      domain: "morphology",
      title: "משקלי פעלים — סקירה",
      description: morph.verb_patterns.description || "בניינים ומשקלים בערבית מדוברת",
      content: morph.verb_patterns,
      lesson_num: 9,
      difficulty: "intermediate",
      tags: ["בניינים", "פעלים", "morphology"],
    });
  }

  if (morph.verb_conjugation_template) {
    rows.push({
      rule_key: "verb_conjugation_template",
      domain: "morphology",
      title: "תבנית הטיית פועל",
      description: "תחיליות, סיומות ואותיות איתן",
      content: morph.verb_conjugation_template,
      lesson_num: 9,
      difficulty: "beginner",
      tags: ["הטיה", "פעלים", "morphology"],
    });
  }

  // -- Grammar essentials --
  const gram = core.grammar_essentials || {};

  if (gram.negation) {
    rows.push({
      rule_key: "negation",
      domain: "grammar",
      title: "שלילה במדוברת",
      description: "דרכי שלילה — מא, מש, מא...ש",
      content: gram.negation,
      lesson_num: 7,
      difficulty: "beginner",
      tags: ["שלילה", "מא", "מש", "grammar"],
    });
  }

  if (gram.questions) {
    rows.push({
      rule_key: "questions",
      domain: "grammar",
      title: "שאלות",
      description: "מילות שאלה ודרכי שאילה בפלסטינית",
      content: gram.questions,
      lesson_num: 3,
      difficulty: "beginner",
      tags: ["שאלות", "מילות שאלה", "grammar"],
    });
  }

  if (gram.prepositions) {
    rows.push({
      rule_key: "prepositions",
      domain: "grammar",
      title: "מיליות יחס",
      description: "מיליות יחס נפוצות בערבית מדוברת",
      content: gram.prepositions,
      lesson_num: 6,
      difficulty: "beginner",
      tags: ["מיליות", "יחס", "grammar"],
    });
  }

  if (gram.demonstratives) {
    rows.push({
      rule_key: "demonstratives",
      domain: "grammar",
      title: "כינויי רמז",
      description: "האד, האדי, הדול — כינויי רמז במדוברת",
      content: gram.demonstratives,
      lesson_num: 6,
      difficulty: "beginner",
      tags: ["כינויי רמז", "grammar"],
    });
  }

  // -- Binyan patterns from conjugations file --
  if (conj.binyan_patterns) {
    const patterns = conj.binyan_patterns;
    if (Array.isArray(patterns)) {
      patterns.forEach((p, i) => {
        rows.push({
          rule_key: `binyan_${p.number || i + 1}`,
          domain: "morphology",
          title: `בניין ${p.number || i + 1} — ${p.name || ""}`,
          description: p.description || p.meaning || "",
          content: p,
          lesson_num: 17,
          difficulty: "advanced",
          tags: ["בניינים", `בניין_${p.number || i + 1}`, "morphology"],
        });
      });
    } else if (typeof patterns === "object") {
      Object.entries(patterns).forEach(([key, p]) => {
        rows.push({
          rule_key: `binyan_${key}`,
          domain: "morphology",
          title: `בניין ${key}`,
          description: typeof p === "string" ? p : p.description || p.meaning || "",
          content: typeof p === "string" ? { pattern: p } : p,
          lesson_num: 17,
          difficulty: "advanced",
          tags: ["בניינים", `בניין_${key}`, "morphology"],
        });
      });
    }
  }

  await clearTable("grammar_rules");
  const count = await batchInsert("grammar_rules", rows);
  console.log(`  Inserted ${count} grammar rules.`);
}

// ── Seed: phrases ───────────────────────────────────────────
async function seedPhrases() {
  console.log("\n💬 Seeding phrases...");
  const data = loadJSON("kb_phrases.json");

  const rows = [];

  // Common phrases
  for (const p of data.common_phrases || []) {
    rows.push({
      phrase_ar: p.phrase_ar,
      phrase_he: p.phrase_he,
      category: p.category || "general",
      register: p.register || null,
      response: p.response || null,
      notes: p.notes || null,
      tags: p.tags || [],
    });
  }

  // Reading exercises (as phrases with category)
  for (const ex of data.reading_exercises || []) {
    if (ex.phrase_ar || ex.text_ar) {
      rows.push({
        phrase_ar: ex.phrase_ar || ex.text_ar || "",
        phrase_he: ex.phrase_he || ex.text_he || ex.translation || "",
        category: "reading_exercise",
        register: ex.register || "colloquial",
        notes: ex.notes || ex.source || null,
        tags: ["reading", "exercise"],
      });
    }
  }

  // Dialect comparisons (as reference phrases)
  for (const d of data.dialect_comparison || []) {
    if (d.palestinian) {
      rows.push({
        phrase_ar: d.palestinian,
        phrase_he: d.meaning || d.hebrew || "",
        category: "dialect_comparison",
        register: "colloquial",
        notes: d.formal ? `MSA: ${d.formal}` : null,
        tags: ["dialect", "comparison"],
      });
    }
  }

  await clearTable("phrases");
  const count = await batchInsert("phrases", rows);
  console.log(`  Inserted ${count} phrase entries.`);
}

// ── Main ────────────────────────────────────────────────────
async function main() {
  console.log("🌱 Palestinian Arabic KB — Supabase Seed");
  console.log(`   URL: ${SUPABASE_URL}`);
  console.log(`   KB dir: ${KB_DIR}`);

  try {
    await seedVocabulary();
    await seedConjugations();
    await seedGrammarRules();
    await seedPhrases();

    console.log("\n✅ Seed complete!");
  } catch (err) {
    console.error("\n❌ Seed failed:", err.message);
    process.exit(1);
  }
}

main();
