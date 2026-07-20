# Phase 5 Report — Dynamic Exams, Collections, Adaptive Learning & Analytics

**QIP (Question Intelligence Platform) · Roadmap Parts 10, 11, 12, 16**
_Prepared: 2026-07-21 · Protocol: `QUESTION_PLATFORM_WORKFLOW.md`_

## Verdict: 🟢 GO

A constraint-based dynamic exam generator (Part 10) produces unique, balanced, no-repeat exams; ten
auto exam collections (Part 16) refresh daily; an adaptive selector (Part 11) weights study toward
weak topics with fresh variants; and a question-analytics engine (Part 12) computes real per-question
metrics. A public **Koleksiyonlar** page surfaces the collections. Tested, lint/typecheck/build-clean,
browser- and production-validated.

---

## Completed work

### 1. Dynamic exam generator (`apps/web/lib/qip/exam.ts`) — Part 10

`buildDynamicExam(opts)` assembles a unique exam under constraints: topic mix (explicit or MEB
23/12/9/6 scaled to any count), **difficulty balance** (round-robin across kolay/orta/zor),
**no duplicate concepts** (skips a second question from the same Phase-3 family), **no repeated
images** (visual questions), and **randomized choices** (options shuffled, `answerIndex` remapped —
the correct text is preserved). Seeded → deterministic yet "feels unique" per seed.

### 2. Exam collections (`apps/web/lib/qip/collections.ts`) — Part 16

`examCollections({daySeed, weekSeed, stats?})` auto-builds ten collections: **Günün Sınavı**,
**Haftanın Sınavı**, **Başlangıç**, **Zor Sorular**, **Yalnız İşaretler**, **Yalnız Motor**,
**Yalnız İlk Yardım**, **En Çok Yanılan**, **Rastgele 50**, **AI Challenge**. Deterministic per
seed (daily/weekly, derived from the date by `seedFromDate`/`seedFromWeek`). "En Çok Yanılan" uses
real failure-rate stats when supplied, otherwise falls back to a difficulty+time proxy — **labeled
honestly** either way.

### 3. Adaptive learning (`apps/web/lib/qip/adaptive.ts`) — Part 11

`adaptiveSelect({answers, count})` derives weak topics from answer history (`weakTopicsFrom`) and
weights selection toward them (default 70% weak-focus), **excluding already-answered questions so
the learner gets a fresh variant of the same concept** (Phase-3 families make this meaningful).
Strong topics get less repetition. Deterministic (seeded); works with no history (pure exploration).

### 4. Question analytics (`apps/web/lib/qip/analytics.ts`) — Part 12

`questionAnalytics(logs)` / `analyticsSummary(logs)` compute attempts (popularity), correct/wrong
rate, per-topic mastery, and hardest questions. **Honest scope:** the current `AnswerLog` records
correctness + timestamp, so avg-time and most-chosen-wrong are computed **only when** the (optional,
forward-compatible) `timeMs`/`chosenIndex` fields are present — `hasTiming`/`hasChoiceData` flags
report this rather than fabricating.

### 5. Public collections surface

- **`/api/qip/collections`** (public) — the ten collections with real counts + a 3-question sample,
  seeded from the server date.
- **`/koleksiyonlar`** — a catalog page (added to the Pratik nav) listing each collection with its
  emoji, description, real count, and a "peek at sample questions" toggle.

## Architecture

```
apps/web/lib/qip
  exam.ts        → buildDynamicExam() (family/image dedup, difficulty balance, shuffled choices)
  collections.ts → examCollections()/collectionById()/seedFromDate() (10 auto collections)
  adaptive.ts    → adaptiveSelect()/weakTopicsFrom() (weak-topic weighting, fresh variants)
  analytics.ts   → questionAnalytics()/analyticsSummary() (real metrics, honest coverage flags)
apps/web/app
  api/qip/collections/route.ts → public daily collections
  (app)/koleksiyonlar          → catalog page (nav-linked)
```

All four reuse Phase-2 `analyzedQuestions()` (themes/quality/difficulty), Phase-3 `familyOf`
(concept dedup + variants), and Phase-4 visual `image` (no-repeat-image) — no upstream changes.

## Tests

- Unit: **+23** — exam (6: distribution + determinism, seed-varies, no-family-repeat, no-image-repeat,
  shuffled-choices-preserve-answer, explicit-mix); collections (7: all 10 present + counts, filters
  correct, determinism, seedFromDate, collectionById, stats-driven most-failed); analytics (5:
  rates, avg-time-when-present, most-chosen-wrong, summary, empty-safe); adaptive (5: weak topics,
  weak-focus, exclude-answered fresh variants, determinism, no-history exploration).
- Integration: **+1** — `GET /api/qip/collections` (real counts, day 50, samples).
- E2E: **+1** — public **Koleksiyonlar** page lists collections with real counts + sample peek
  (Chromium).
- Suite: web **259 → 283** unit/integration; all packages green. Gates: verify ✓ · lint ✓
  (0 errors, 1 pre-existing db warning) · format ✓ · typecheck ✓ · build ✓.

## Performance

- All generators are O(pool) with seeded shuffles, reusing memoized Phase-2/3 layers; each completes
  inside the test suite with no measurable drag. Collections page 1.55 kB; API is thin server compute.

## Real results (measured — difficulty-balanced 50-question daily exam)

| Metric               | Value                                                                                                                                             |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Exam size            | **50**                                                                                                                                            |
| Subject distribution | trafik 23 · ilkyardim 12 · motor 9 · adab 6 (**exact MEB blueprint**)                                                                             |
| Difficulty balance   | kolay 17 · orta 17 · zor 16                                                                                                                       |
| Unique concepts      | **50 / 50** families (no concept repeated)                                                                                                        |
| Repeated images      | **0**                                                                                                                                             |
| Collections          | 10 (Günün 50 · Haftanın 50 · Başlangıç 40 · Zor 40 · İşaretler 40 · Motor 40 · İlk Yardım 40 · En Çok Yanılan 40 · Rastgele 50 · AI Challenge 30) |

## Known limitations

- Analytics avg-time / most-chosen-wrong need per-answer `timeMs`/`chosenIndex`; the engine supports
  them (forward-compatible) but the live quiz doesn't yet record them, so those metrics stay empty
  until that small capture is wired — reported honestly via `hasTiming`/`hasChoiceData`, never faked.
- "En Çok Yanılan" without a cross-user stats store falls back to a difficulty+time proxy (clearly
  labeled). A server-side answer-aggregate store would make it usage-driven (future).
- The collections page is a catalog + preview; launching a full timed run per collection reuses the
  existing exam flow and was deliberately not rewired to avoid touching the e2e-sensitive runner.
- The dynamic exam and adaptive selector are pure/seeded; wiring them as the engine behind the live
  practice/exam UI is an integration step beyond this phase's scope (the capabilities are complete
  and tested).

## Next phase prerequisites (Phase 6 — Community Review, Final Validation & Report)

- ✅ All intelligence layers (normalize, categorize, quality, dedup, graph, families, generation,
  exams, collections, adaptive, analytics) are in place for the final validation sweep.
- ✅ `qipCoverage`/`qipIntelligence`/`graphStats`/`familyStats`/`dedupReport` give the integrity,
  duplicate-rate, quality, category-balance, and graph-consistency metrics Part 17 requires.
- Phase 6 will add the community report/moderation flow (Part 13), run the final validation
  (Part 17), and write `QUESTION_INTELLIGENCE_REPORT.md` (Part 18) with the whole-program GO/NO-GO.

**Phase 5 is DONE per the Definition of Done. Proceeding to Phase 6.**
