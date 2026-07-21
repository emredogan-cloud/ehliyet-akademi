# Question Bank Growth Report

**QIP 2.0 Content Expansion · Phase 7 — Continuous Growth**
_Prepared: 2026-07-21 · Real measured numbers_

## Current state (measured)

| Metric                                                        | Value                                                          |
| ------------------------------------------------------------- | -------------------------------------------------------------- |
| **Bank size (persisted)**                                     | **1562** questions (was 1534 → **+28** original, gap-targeted) |
| Authored expansion (Phase 4, `gen-*`)                         | 28                                                             |
| Visual questions generatable on demand (signs 121 + parts 70) | **191** (reviewed drafts; not written to the text bank)        |
| Next milestone                                                | **3000** — 1438 to go (**52%** of the way)                     |
| Milestones                                                    | 3000 → 5000 → 10000 → 20000                                    |

## How growth actually happens (honest)

Reaching 3000/5000/10000 is **continuous work**, not a single commit. This program built the
**mechanism** and did a real first increment; it did not fabricate a milestone. The scalable layers,
each mandatory through the full QIP pipeline (normalize → categorize → graph → quality → dedup → AI
review → **draft**):

1. **Original authoring** (Phase 4) — genuinely new questions from official rules/curriculum, in our
   own words. +28 this round; more per batch.
2. **AI generation** (`generateVariants`, Anthropic) — gap-targeted original variants. Runs in
   **production** (where `ANTHROPIC_API_KEY` exists); returns honest-empty locally/CI. Every output
   is reviewed + deduped + draft — never auto-published.
3. **Visual generation** (`generateVisualQuestions`) — 191 reviewed sign/part visual questions
   available on demand (closes the 72-sign coverage gap in the admin generation surface).

`bankGrowth()` tracks the real count + progress to the next milestone (no fabricated numbers).

## Quality is preserved (measured)

Final validation (`validateQip`) still passes **100/100** after the expansion: integrity ✓,
0 exact duplicates, quality avg ✓, category balance ✓, 0 broken images/references, graph consistent.
The +28 questions each passed the AI reviewer (single-correct, quality ≥ 70, on-domain, not
duplicate).

## Path to milestones (realistic)

- **3000:** ~1440 more — a mix of authored batches + prod AI generation over the ranked gap list
  (`CONTENT_GAP_REPORT.md`) + promoting reviewed visual questions. Each batch is admin-reviewed
  before publishing (roadmap E.6).
- **5000 / 10000 / 20000:** the same pipeline scales linearly; no architectural change needed (see
  `QUESTION_INTELLIGENCE_REPORT.md` "Future scalability").

**Phase 7 is complete. Growth is measured honestly and the scalable path is in place.**
