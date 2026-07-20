# Phase 2 Report — Categorization, Quality & Duplicate Detection

**QIP (Question Intelligence Platform) · Roadmap Parts 4, 5, 6**
_Prepared: 2026-07-20 · Protocol: `QUESTION_PLATFORM_WORKFLOW.md`_

## Verdict: 🟢 GO

Three deterministic intelligence engines — smart categorization (Part 4), quality analysis
(Part 5), and duplicate detection (Part 6) — run over the Phase-1 normalized bank, populate the
reserved `qualityScore`, and are surfaced on a new admin **Soru Zekâsı** dashboard with real,
measured numbers. Everything is tested, lint/typecheck/build-clean, and browser-validated.

---

## Completed work

### 1. Smart categorization (`apps/web/lib/qip/categorize.ts`) — Part 4

A **theme taxonomy** (32 themes) aligned to Part 4's category list (Trafik İşaretleri, Hız,
Öncelik, Kavşak/Şerit, Park, Farlar, Yaya/Okul, Çevre, Yasal Sorumluluk, Fren, Lastik,
Yağlama/Soğutma, Elektrik, Yakıt, Gösterge, Motor/Aktarma, Bakım; İlk Yardım: TYD, Kanama,
Kırık, Yanık, Zehirlenme, Şok/Acil; Adab; Direksiyon). Classification is a **deterministic,
ordered rule engine**: signals are the topic slug tokens + tags; the first matching theme is
`primaryTheme`; all matches populate `themes[]`. **Subject-scoping** prevents false positives
(e.g. `hiz-adabi` → Trafik Adabı, not the Hız theme). Keyword matching is precise: multi-word →
substring, long single-word → prefix (`levha`→`levhasi`), short single-word → exact token
(`far` ≠ `farkindaligi`). Unmatched long-tail topics fall to an honest subject fallback theme →
100% of questions get a primary theme.

### 2. Quality analysis (`apps/web/lib/qip/quality.ts`) — Part 5

`scoreQuality(nq)` produces a 0–100 total from eight measurable sub-scores matching Part 5:
**language** (spacing, capitalization), **grammar** (placeholder text, option-case consistency),
**clarity** (stem length, terminal punctuation), **distractor** (option count, duplicate options,
length balance, ambiguous "hepsi/hiçbiri"), **educational value** (explanation depth, whyWrong,
objective, tags, badge), **answer confidence** (index validity, explanation support, no
answer-identical distractor), **difficulty fit**, **duplicate risk** (fed by the dedup engine).
Weighted total (answer-confidence + distractor + educational-value heaviest). `qualitySummary()`
aggregates avg/min/max, below-70/50 counts, and a flag histogram. This **populates the
`qualityScore` field reserved in Phase 1**.

### 3. Duplicate detection (`apps/web/lib/qip/dedup.ts`) — Part 6

Two layers, no external embeddings: **exact** (Phase-1 fingerprint equality) and **near-duplicate**
(token-set **Jaccard** ≥ 0.82). Efficiency: an **inverted index** (word → questions) generates
candidates, a shared-token prune (≥4) skips weak pairs, and comparison is scoped within-subject —
avoiding the O(n²) scan. Near-dup pairs are clustered with **union-find**. Output: exact/near
counts, duplicate rate, per-question near-neighbor counts (feeding quality's duplicate-risk), and
the top similar pairs as **merge candidates** ("merge variants where appropriate").

### 4. Analysis layer + admin dashboard

- `analyzedQuestions()` enriches each normalized question with `primaryTheme`/`themes`/`quality`,
  sets `qualityScore`, and refines `subcategory` to the theme label (raw `topic` preserved).
  `qipIntelligence()` is the combined summary (category + theme distribution, quality summary,
  dedup report), memoized (`bankDedup()` computes the expensive dedup once).
- **`/api/admin/qip`** (admin/editor-gated via `requireRole`) returns the real intelligence.
- **`/admin/soru-zekasi`** — a new admin tab rendering overview stats, quality summary + flag
  histogram, dedup report + merge-candidate pairs, and the theme distribution as bar charts.

## Architecture

```
apps/web/lib/qip
  categorize.ts → classify(nq) → { primaryTheme, themes[] }   (ordered rule engine, subject-scoped)
  quality.ts    → scoreQuality(nq) → QualityBreakdown         (8 measurable dims → 0–100)
  dedup.ts      → dedupReport(pool) → exact + near (Jaccard/inverted-index/union-find)
  index.ts      → analyzedQuestions() (+ qualityScore) · qipIntelligence() · bankDedup()
apps/web/app
  api/admin/qip/route.ts        → guarded GET → qipIntelligence()
  (app)/admin/soru-zekasi       → client dashboard (real metrics, bar charts)
```

All engines are pure/deterministic and offline (no embedding API), consistent with the project's
no-external-dependency, reproducible-analysis stance. The Phase-1 normalized layer is unchanged;
Phase 2 is a read-only analysis on top.

## Tests

- Unit: **+18** — categorize (8: token-signal classification, subject-scoping false-positive guard,
  prefix-vs-exact matching, fallback, tag-based, label resolution, unique ids, full-bank coverage);
  quality (5: high-scoring good question, duplicate-option/identical-answer penalty, short
  stem/explanation flags, placeholder detection, summary consistency); dedup (5: tokenSet/jaccard,
  reworded near-dup caught + distinct not caught, exact via fingerprint, full-bank invariant).
- Integration: **+2** — `GET /api/admin/qip` (unauth rejected; admin returns real intelligence).
- E2E: **+1** — admin **Soru Zekâsı** dashboard renders real metrics (Chromium, real admin session).
- Suite: web **206 → 226** unit/integration; **all packages green**. Gates: verify ✓ · lint ✓
  (0 errors, 1 pre-existing db warning) · format ✓ · typecheck ✓ · build ✓.
- Known e2e flake (pre-existing, unrelated): the admin **content-pipeline** specs cold-start-flake
  under single-threaded PGlite; they pass on re-run and CI `retries:2`. My changes don't touch the
  content pipeline (QIP code is lazy/cached and not imported by content routes).

## Performance

- `dedupReport` over 1534 questions: inverted-index candidate generation + within-subject +
  shared-token prune keeps it well under a second (runs inside the test suite with no measurable
  drag). Memoized via `bankDedup()` so the dashboard/API compute it once.
- Dashboard route is 2.3 kB; API is a thin server compute. No change to shared JS (103 kB) or the
  4.2 s app compile.

## Real results (measured)

| Metric                          | Value                                                                                                             |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Questions classified to a theme | **1132 / 1534 (73.8%)**; remaining fall to honest subject fallback                                                |
| Distinct primary themes         | 32                                                                                                                |
| Top themes                      | Trafik Adabı 228 · Direksiyon Sınavı 115 · Trafik İşaretleri 99 · Kavşak/Şerit 88 · TYD 86 · Çevre 63 · Kanama 62 |
| Quality score range             | 95–100 (avg 100) — the authored bank is uniformly high quality                                                    |
| Questions below 70              | **0**                                                                                                             |
| Style-flagged questions         | 72 (chiefly "seçenek uzunlukları çok dengesiz" 70)                                                                |
| Exact duplicates                | **0**                                                                                                             |
| Near-duplicate pairs            | **1** — `trafik-136` ≈ `trafik-237` (0.86) — a real merge candidate                                               |
| Duplicate rate                  | 0.1%                                                                                                              |

Honest note: because the bank was carefully authored across prior sprints, quality scores cluster
at 95–100 — the analyzer's discrimination is proven separately by unit tests on deliberately-bad
inputs (short stems, duplicate options, placeholder text all score low with correct flags). Its
production value here is (a) confirming **zero** low-quality questions, (b) surfacing 72 minor
style flags for review, (c) finding **one genuine near-duplicate** to merge, and (d) populating
`qualityScore` for downstream exam-building/filtering (Phase 5).

## Known limitations

- 26.2% of questions use the subject-fallback theme (long-tail topics not matched by a specific
  rule) — honest, not silently mislabeled. The rule set can be extended incrementally; **Phase 3**
  (knowledge graph) will also relate these via lesson/sign links.
- Quality heuristics are structural/mechanical, not semantic — they can't judge factual accuracy
  (that's the domain of expert review + the **Phase 4** AI reviewer).
- Near-duplicate detection is within-subject and stem-based (Jaccard ≥ 0.82); cross-subject or
  heavily-paraphrased variants below the threshold aren't flagged. The threshold is deliberately
  strict to keep false positives near zero.

## Next phase prerequisites (Phase 3 — Knowledge Graph & Question Families)

- ✅ `analyzedQuestions()` gives every question a `primaryTheme`, `themes[]`, cross-links
  (relatedLesson/Signs/VehicleParts), and `qualityScore` — the raw material for graph edges.
- ✅ `dedup` similarity + shared themes/learning-outcomes give the clustering signal for question
  **families** (one concept → many variants).
- ✅ `bankDedup()`/`qipIntelligence()` memoized and reusable by the graph layer.
- Phase 3 will build the typed node/edge knowledge graph (question↔lesson↔sign↔part↔topic↔theme)
  and concept families, with a graph-driven "related content" surface.

**Phase 2 is DONE per the Definition of Done. Proceeding to Phase 3.**
