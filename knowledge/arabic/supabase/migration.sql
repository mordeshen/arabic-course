-- Palestinian Arabic Course — Supabase Schema
-- Run this in Supabase SQL Editor to create all tables
-- Version: 1.0

-- Enable trigram extension for fuzzy search (must run before indexes)
create extension if not exists pg_trgm;

-- ============================================================
-- 1. VOCABULARY — 3700+ word entries from kb_dictionary.json
-- ============================================================
create table if not exists vocabulary (
  id            bigint generated always as identity primary key,
  hebrew        text not null,                    -- Hebrew meaning (e.g. "אוכל")
  arabic        text,                             -- Arabic script (e.g. "أَكْل")
  hebrew_translit text,                           -- Hebrew transliteration (e.g. "אַכְּל")
  latin_translit  text,                           -- Latin transliteration (e.g. "2a-kel")
  category      text not null default 'general',  -- Topic category (אוכל, משפחה, etc.)
  source        text,                             -- Source layer: thematic / essential / dictionary_pages
  lesson_num    smallint,                         -- Lesson number (1-18) if tied to a lesson
  difficulty    text check (difficulty in ('beginner','intermediate','advanced')),
  notes         text,                             -- Extra context or usage notes
  created_at    timestamptz default now()
);

-- Indexes for common queries
create index if not exists idx_vocabulary_category on vocabulary (category);
create index if not exists idx_vocabulary_lesson on vocabulary (lesson_num);
create index if not exists idx_vocabulary_hebrew on vocabulary using gin (hebrew gin_trgm_ops);
create index if not exists idx_vocabulary_arabic on vocabulary using gin (arabic gin_trgm_ops);
create index if not exists idx_vocabulary_translit on vocabulary using gin (hebrew_translit gin_trgm_ops);

-- ============================================================
-- 2. VERB_CONJUGATIONS — Full conjugation tables per verb
-- ============================================================
create table if not exists verb_conjugations (
  id            bigint generated always as identity primary key,
  verb_key      text not null unique,             -- Unique key (e.g. "טלע_go_out")
  root          text not null,                    -- Arabic root (e.g. "ط-ل-ع")
  base_form     text not null,                    -- Base/dictionary form (e.g. "טלע")
  translation   text not null,                    -- English translation (e.g. "go out")
  binyan        smallint,                         -- Binyan number (1-10)
  -- Past tense conjugations
  past_1sg      text,   -- אני
  past_2sg_m    text,   -- אתה
  past_2sg_f    text,   -- את
  past_3sg_m    text,   -- הוא
  past_3sg_f    text,   -- היא
  past_1pl      text,   -- אנחנו
  past_2pl      text,   -- אתם
  past_3pl      text,   -- הם
  -- Present tense conjugations
  pres_1sg      text,
  pres_2sg_m    text,
  pres_2sg_f    text,
  pres_3sg_m    text,
  pres_3sg_f    text,
  pres_1pl      text,
  pres_2pl      text,
  pres_3pl      text,
  -- Imperative
  imp_sg_m      text,
  imp_sg_f      text,
  imp_pl        text,
  -- Meta
  notes         text,
  created_at    timestamptz default now()
);

create index if not exists idx_verb_root on verb_conjugations (root);
create index if not exists idx_verb_base on verb_conjugations (base_form);
create index if not exists idx_verb_binyan on verb_conjugations (binyan);

-- ============================================================
-- 3. GRAMMAR_RULES — Phonology, morphology, grammar essentials
-- ============================================================
create table if not exists grammar_rules (
  id            bigint generated always as identity primary key,
  rule_key      text not null unique,             -- Unique key (e.g. "sun_letters", "negation")
  domain        text not null,                    -- phonology / morphology / grammar
  title         text not null,                    -- Human-readable title
  description   text,                             -- Explanation in Hebrew
  content       jsonb not null default '{}',      -- Structured rule data (examples, letters, forms, etc.)
  lesson_num    smallint,                         -- Linked lesson (1-18)
  difficulty    text check (difficulty in ('beginner','intermediate','advanced')),
  tags          text[] default '{}',              -- Searchable tags
  created_at    timestamptz default now()
);

create index if not exists idx_grammar_domain on grammar_rules (domain);
create index if not exists idx_grammar_lesson on grammar_rules (lesson_num);
create index if not exists idx_grammar_tags on grammar_rules using gin (tags);

-- ============================================================
-- 4. PHRASES — Common phrases, greetings, dialogue patterns
-- ============================================================
create table if not exists phrases (
  id            bigint generated always as identity primary key,
  phrase_ar     text not null,                    -- Phrase in Hebrew transliteration
  phrase_he     text not null,                    -- Hebrew translation
  category      text not null default 'general',  -- greetings / responses / questions / etc.
  register      text check (register in ('colloquial','formal','universal')),
  response      text,                             -- Expected response phrase
  notes         text,                             -- Usage context
  lesson_num    smallint,                         -- Linked lesson (1-18)
  tags          text[] default '{}',
  created_at    timestamptz default now()
);

create index if not exists idx_phrases_category on phrases (category);
create index if not exists idx_phrases_lesson on phrases (lesson_num);
create index if not exists idx_phrases_tags on phrases using gin (tags);

-- ============================================================
-- RLS Policies (public read, authenticated write)
-- ============================================================
alter table vocabulary enable row level security;
alter table verb_conjugations enable row level security;
alter table grammar_rules enable row level security;
alter table phrases enable row level security;

-- Public read access
create policy "Public read vocabulary" on vocabulary for select using (true);
create policy "Public read verb_conjugations" on verb_conjugations for select using (true);
create policy "Public read grammar_rules" on grammar_rules for select using (true);
create policy "Public read phrases" on phrases for select using (true);

-- Authenticated write access
create policy "Auth write vocabulary" on vocabulary for all using (auth.role() = 'authenticated');
create policy "Auth write verb_conjugations" on verb_conjugations for all using (auth.role() = 'authenticated');
create policy "Auth write grammar_rules" on grammar_rules for all using (auth.role() = 'authenticated');
create policy "Auth write phrases" on phrases for all using (auth.role() = 'authenticated');
