# Phase 1 Report — Schema & Normalization Foundation

**QIP (Question Intelligence Platform) · Roadmap Parts 1, 2, 15 (foundation)**
_Prepared: 2026-07-20 · Protocol: `QUESTION_PLATFORM_WORKFLOW.md`_

## Verdict: 🟢 GO

The unified normalized question schema (roadmap Part 2), a deterministic normalization +
ingestion pipeline with source attribution (Part 1), and a full backfill of all **1534** existing
questions are complete, tested, lint/typecheck/build-clean, and ready for Phase 2 to build the
categorization/quality/dedup intelligence on top.

---

## Completed work

### 1. Unified schema — `NormalizedQuestion` (Part 2)

Added to `@ea/content-schema` a backward-compatible `NormalizedQuestion` derived from the existing
authored `Question` via a shared `QuestionBase` object (`Question` was refactored into
`QuestionBase.refine(answerInRange)` so the same base can be `.extend`ed — **no behavior change**;
all pre-existing `Question` parse/validate paths are byte-identical). `NormalizedQuestion` carries
every field the roadmap's Part 2 unified schema requires:

| Part 2 field       | Source in `NormalizedQuestion`                                        |
| ------------------ | -------------------------------------------------------------------- |
| Question / Choices / Correct Answer / Explanation / Difficulty | `stem` / `options` / `answerIndex` / `explanation` / `difficulty` (from base) |
| Category / Subcategory | `category` (from subject) / `subcategory` (from topic)           |
| Learning Outcome   | `learningOutcome` (= `objective`)                                    |
| Related Lesson / Signs / Vehicle Parts | `relatedLesson` / `relatedSigns[]` / `relatedVehicleParts[]` (derived) |
| Estimated Time     | `estimatedSeconds` (difficulty-based heuristic)                      |
| Common Mistakes    | `commonMistakes` (= `whyWrong`)                                      |
| Tags / Image / Video | `tags` (base) / `image?` / `video?`                                |
| Source Metadata    | `source` (`QuestionSource`: origin/collection/attribution/license/method) |
| Quality Score      | `qualityScore?` (reserved — populated in Phase 2)                    |
| Review Status / Version | `review` (base) / `version`                                     |

Plus `fingerprint` — a deterministic content hash reserved for dedup (Phase 2/6).

### 2. Normalization pipeline (`apps/web/lib/qip/normalize.ts`)

- `@ea/content-schema.baseNormalize()` fills all fields that don't need app content
  (category, subcategory, learningOutcome, estimatedSeconds, commonMistakes, source, fingerprint,
  version) via Zod-parsed output — every normalized record is schema-valid by construction.
- The app layer adds **content cross-links** (`relatedLesson`, `relatedSigns`,
  `relatedVehicleParts`) using deterministic, high-precision matching against the real `LESSONS`,
  `SIGNS` (121), and `VEHICLE_PARTS` content:
  - **relatedLesson** — explicit lesson `quizQuestionIds`/`practiceQuestionIds` reference first,
    then a same-subject topic-word-coverage fallback.
  - **relatedSigns / relatedVehicleParts** — whole-phrase match of the specific sign/part _name_
    inside the question's folded text (parts only searched for `motor` questions) → low
    false-positive rate. Capped at 6 links each.
- Pure & deterministic (module-level indices built once; same input → same output — covered by a
  test).

### 3. Ingestion pipeline (`apps/web/lib/qip/ingest.ts`) — Part 1

An **auditable ingestion capability**, not a scraper (see Content & legal, below):
`ingestQuestion(raw, source, ctx)` validates against the schema → computes fingerprint → rejects
duplicate id / duplicate fingerprint → normalizes with **source attribution** → updates the
dedup context only on success. `ingestBatch()` returns an accepted/rejected report. Fingerprints
are option-order-independent, so a reworded-choices copy is caught as a duplicate.

### 4. Backfill (`apps/web/lib/qip/index.ts`)

`normalizedQuestions()` normalizes the entire bank once (memoized); `normalizedById()` indexes it;
`qipCoverage()` produces the real distribution/coverage report used below and in tests.

## Architecture

```
@ea/content-schema
  QuestionBase ──refine──► Question            (unchanged authored contract)
      └──extend──► NormalizedQuestion          (Part 2 unified schema)
  baseNormalize(), questionFingerprint(), foldText(), hash32()   (content-agnostic, pure)

apps/web/lib/qip
  normalize.ts  → normalizeQuestion()  (adds relatedLesson/Signs/VehicleParts from app content)
  ingest.ts     → ingestQuestion() / ingestBatch()  (validate → dedup → normalize + attribute)
  index.ts      → normalizedQuestions() / normalizedById() / qipCoverage()
```

Design choices: (a) the authored `Question` bank stays the lean source of truth — enrichment is a
derived layer, so the 1534 records were **not** edited and nothing downstream (exam/study/search/ai)
changed; (b) content-agnostic derivations live in the package, content-aware cross-links live in
the app where `SIGNS`/`LESSONS`/`VEHICLE_PARTS` are visible; (c) no external services — fingerprint
is a pure FNV-1a hash, so it runs identically in node, browser, and tests.

## Tests

- `@ea/content-schema`: +5 tests — `foldText` (Turkish folding), `hash32` determinism,
  `questionFingerprint` (order-independence), `baseNormalize` (Part 2 fill + overrides).
- `apps/web/lib/qip`: +19 tests — `containsPhrase` word-boundary matching, `deriveRelatedSigns`,
  full-bank normalization invariants (all 1534 normalize + schema-valid + required fields set),
  determinism, explicit-lesson linkage, `qipCoverage` consistency, and the full ingest matrix
  (accept, source attribution, AI-origin flag, schema reject, refine reject, duplicate-id,
  duplicate-fingerprint incl. shuffled options, context-not-polluted-on-reject, batch dedup,
  dedup vs. the existing bank).
- Web suite: **187 → 206** tests. Full workspace `pnpm test` green.
- Gates: `verify` ✓ · `lint` ✓ (0 errors, 1 pre-existing `db` `import()` warning) · `format` ✓ ·
  `typecheck` ✓ · `build` ✓.

## Performance

- Normalization is O(n) over the bank with per-question O(#signs + #parts) phrase checks, run
  **once** and memoized. Full-bank normalization + coverage completes well within the test's
  sub-second budget; no measurable impact on app build (25.6 s, unchanged shared JS 103 kB).
- Fingerprint is a single-pass 32-bit hash — negligible cost, no crypto dependency.

## Real coverage (measured, not estimated)

| Metric                         | Value                                                                   |
| ------------------------------ | ----------------------------------------------------------------------- |
| Questions normalized           | **1534** (100% of the bank)                                             |
| Categories                     | 5 — Trafik ve Çevre 368 · İlk Yardım 299 · Araç Tekniği 298 · Trafik Adabı 272 · Direksiyon 297 |
| Difficulty mix                 | kolay 546 · orta 719 · zor 269                                          |
| With `relatedLesson`           | 311 (20.3%)                                                             |
| With `relatedSigns`            | 235 (15.3%)                                                             |
| With `relatedVehicleParts`     | 200 (13.0%)                                                             |
| With ≥1 sign/part cross-link   | 425 (27.7%)                                                             |
| With `learningOutcome`         | 1481 (96.5%)                                                            |
| Unique fingerprints            | 1534 → **0 exact duplicates**                                           |
| Estimated total practice time  | 1487 min (~24.8 h)                                                      |

## Content & legal (guardrail honored)

Part 1 ("Question Discovery") is realized as an **ingestion pipeline capability**, not a web
scraper. The bank's standing policy is _özgün_ content authored in our own words from official
MEB/ODSGM curriculum + Karayolları Trafik mevzuatı ("Hiçbir uygulama/site sorusu kopyalanmamıştır").
Copyrighted third-party question banks are **not** copied/republished; `source.origin` distinguishes
`authored` / `ai-generated` (Phase 4) / `imported` (reserved for open-licensed/public sources only).

## Known limitations

- Cross-link coverage is intentionally high-precision (name-phrase / explicit-reference) rather
  than high-recall — many topically-related signs/lessons aren't linked yet. **Phase 3** (knowledge
  graph) raises recall; this phase provides the reliable, low-noise base.
- `category`/`subcategory` are currently subject/topic-derived. **Phase 2** (smart categorization)
  refines them (e.g. topic `hiz` → "Hız", `isaretler` → "Trafik İşaretleri").
- `qualityScore` is reserved (schema field present, unset) — **Phase 2** populates it.
- `estimatedSeconds` is a difficulty heuristic (45/60/80 s), not measured per-question timing —
  **Phase 5** analytics can calibrate it from real solve times.
- `image`/`video` are passthrough fields (no authored values yet) — **Phase 4/8** wire visuals.
- Library-only phase: **no UI shipped**, so browser/production validation is N/A (the admin
  intelligence surface arrives in Phase 2).

## Next phase prerequisites (Phase 2 — Categorization, Quality & Dedup)

- ✅ Unified `NormalizedQuestion` schema + `normalizedQuestions()` backfill available to build on.
- ✅ `foldText`/`hash32`/`questionFingerprint` primitives ready for near-duplicate detection.
- ✅ `qualityScore` field reserved and ready to populate.
- Phase 2 will add the smart classifier (refining category/subcategory/tags), the quality scorer,
  and near-duplicate detection (Jaccard/cosine on token shingles over the fingerprints), surfaced
  in an admin questions-intelligence dashboard (its browser-validation surface).

**Phase 1 is DONE per the Definition of Done. Proceeding to Phase 2.**
