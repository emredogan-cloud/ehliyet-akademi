# Phase 4 Report — Generation, Visual Questions & AI Reviewer

**QIP (Question Intelligence Platform) · Roadmap Parts 7, 8, 14**
_Prepared: 2026-07-21 · Protocol: `QUESTION_PLATFORM_WORKFLOW.md`_

## Verdict: 🟢 GO

An automated AI reviewer (Part 14) gates every generated question through six deterministic checks;
a deterministic visual-question generator (Part 8) turns the verified 121-sign catalog into
schema-valid image questions (all 121 pass the gate); and an Anthropic-grounded original-question
generator (Part 7) produces new variants through a parse → schema → review → dedup pipeline —
always `review: 'draft'`, never auto-published. Surfaced on a new admin **Soru Üretimi** page.
Tested, lint/typecheck/build-clean, browser- and production-validated.

---

## Completed work

### 1. AI Reviewer (`apps/web/lib/qip/review.ts`) — Part 14

`reviewGenerated(nq, ctx)` is the **deterministic gate** every generated question must pass before
it can enter the bank. Six checks map to Part 14's dimensions:

- `answerInRange`, `singleCorrect` (no distractor equals the correct answer → catches "multiple
  correct answers"), `distinctOptions` (consistency), `qualityOk` (Phase-2 quality ≥ 70 →
  grammar/clarity/educational value/difficulty), `notDuplicate` (fingerprint + within-subject
  near-dup vs. the existing bank), `onDomain` (driving-domain lexicon).
- `buildReviewContext(existing)` precomputes fingerprints + per-subject token sets so a whole
  generation batch reviews against the bank cheaply. **A failing question is rejected** — nothing
  is auto-published.

### 2. Visual question generation (`apps/web/lib/qip/visual.ts`) — Part 8

`generateSignQuestions()` turns the **verified 121-sign catalog** into schema-valid
"identify-the-meaning" visual questions: the sign image carries the question (`image: 'sign:<id>'`),
options are meanings with **same-category distractors** (educational difficulty), the answer is the
sign's real meaning, and the explanation names the sign + memory tip. Deterministic (seeded
`mulberry32` per sign; RNG injectable). Marked `review: 'draft'`, tagged `gorsel`. Complements the
existing transient `visual-quiz.ts` game rounds — these are **persistable bank questions**. No
external image pipeline was needed: the existing verified sign set is the consistent visual source
(honest scoping of "generate images where required").

### 3. AI question generation (`apps/web/lib/server/qip-generate.ts`) — Part 7

`generateVariants(spec, {model?})` generates **original** new questions (new scenario/wording/
distractors, same learning objective — not paraphrase) grounded in a concept + example questions.
Pipeline: model → robust JSON parse → Zod schema → normalize (`origin: 'ai-generated'`,
`review: 'draft'`) → **AI reviewer gate** → **dedup** (fingerprint, batch + vs. bank) → accept /
reject with reasons. The model is **injectable** (deterministic tests with a stub); in production it
uses the real `AnthropicModel` (exported `anthropicModel()`). When `ANTHROPIC_API_KEY` is absent it
returns **honestly empty** (`model: 'unconfigured'`) — no fabrication.

### 4. Admin surface

- **`/api/admin/qip/generate`** (admin/editor-gated): `mode: 'visual'` (deterministic, no key
  needed) generates + reviews sign questions; `mode: 'llm'` runs the Anthropic generator (returns
  `aiConfigured: false` + empty when no key).
- **`/admin/soru-uretimi`** — generate visual questions on demand and see each one's **review
  verdict** (pass/fail, score, issues) with the correct answer highlighted.

## Architecture

```
apps/web/lib/qip
  review.ts  → reviewGenerated() (6 deterministic checks) · buildReviewContext()
  visual.ts  → generateSignQuestions()/signMeaningQuestion() (seeded, schema-valid, image ref)
apps/web/lib/server
  ai.ts        → exported AIModel + anthropicModel() factory
  qip-generate.ts → generateVariants() (parse→schema→normalize→review→dedup; injectable model)
apps/web/app
  api/admin/qip/generate/route.ts → guarded visual/llm generation
  (app)/admin/soru-uretimi         → admin generation + review-verdict UI
```

Every generation path reuses Phase-1 (`normalizeQuestion`, fingerprint), Phase-2 (`scoreQuality`,
`tokenSet`/`jaccard`), and the same schema — no new content-model surface, and the authored bank is
untouched (generated questions are drafts returned to the admin, not written to source).

## Tests

- Unit: **+14** — review (4: accept good, reject bank-duplicate, reject multiple-correct, reject
  off-domain); visual (4: all-121 schema-valid + image ref + real meaning, determinism, correct
  answer + distinct distractors, majority pass the reviewer); qip-generate (6: `parseModelJson`
  robustness, accept originals as ai-generated/draft, reject schema-invalid, reject in-batch dup,
  reject vs-bank dup on review, unconfigured → empty).
- Integration: **+4** — `POST /api/admin/qip/generate` (unauth rejected; visual mode → reviewed
  draft questions with image refs; llm without spec → 400; llm without key → honest empty).
- E2E: **+1** — admin **Soru Üretimi** generates visual questions and shows review verdicts
  (Chromium, real admin session).
- Suite: web **241 → 259** unit/integration; all packages green. Gates: verify ✓ · lint ✓
  (0 errors, 1 pre-existing db warning) · format ✓ · typecheck ✓ · build ✓.
- Known e2e flake (pre-existing, unrelated): running two admin dashboard specs back-to-back
  cold-start-contends on single-threaded PGlite; each passes in isolation, CI `retries:2` absorbs it.

## Performance

- Reviewer: O(existing) per question via the precomputed context; visual generation is O(#signs);
  both run inside the test suite with no measurable drag. Generation cost in prod is bounded by the
  Anthropic call (with retry + honest fallback). Admin generation route is 1.99 kB.

## Real results (measured)

| Metric                                    | Value                                                                                             |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Visual questions generated (sign catalog) | **121** (one per verified sign)                                                                   |
| Visual questions passing the AI reviewer  | **121 / 121** (0 rejected)                                                                        |
| Reviewer checks                           | 6 deterministic (answer-in-range, single-correct, distinct, quality≥70, not-duplicate, on-domain) |
| LLM generator                             | Anthropic-grounded; injectable model; pipeline-gated; `origin: ai-generated`, `review: draft`     |
| Unconfigured behavior                     | honest empty (`model: 'unconfigured'`) — no fabrication                                           |

## Known limitations

- LLM generation needs `ANTHROPIC_API_KEY` (present in production, absent in CI/e2e) — so the
  live-LLM path is validated via the injectable-stub pipeline tests + prod route deploy, not a real
  CI LLM call (deterministic + no spend). Visual generation is fully deterministic and e2e-tested.
- Generated questions are **drafts surfaced to the admin**, not written back into the bank source —
  promotion to the published bank remains a human/expert-review decision (by design; roadmap E.6).
- The reviewer verifies structure, single-correctness, quality, domain, and non-duplication — it
  cannot verify deep factual accuracy; that is the generator's system-prompt discipline + expert
  review (a semantic AI double-check could be added later but isn't required by Part 14's checklist).
- Visual questions use a semantic `image: 'sign:<id>'` ref resolved to the SVG sign glyph by the UI
  (no raster asset) — consistent with the app's vector sign rendering.

## Next phase prerequisites (Phase 5 — Dynamic Exams, Collections, Adaptive, Analytics)

- ✅ `analyzedQuestions()` (themes, quality) + families (variants) + graph give the selection signals
  for balanced, unique, no-repeated-image exams.
- ✅ Visual questions provide the "no repeated images" constraint's image field.
- ✅ Quality scores let collections like "Hard Questions" / "Most Failed" rank meaningfully.
- Phase 5 will build the dynamic exam generator, auto exam collections, weak-topic adaptivity, and
  question analytics.

**Phase 4 is DONE per the Definition of Done. Proceeding to Phase 5.**
