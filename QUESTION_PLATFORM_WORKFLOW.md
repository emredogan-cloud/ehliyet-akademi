# Question Platform — Execution Protocol (permanent)

**This is the permanent execution protocol for the Question Intelligence Platform (QIP)
program.** Every phase MUST read this file first, then read `BANK_QUESTİON.md` (the master
roadmap), then work on exactly one phase.

> `BANK_QUESTİON.md` is the master roadmap (18 Parts). `ROADMAP.md` / `PROGRAM_2_ROADMAP.md`
> remain the historical roadmaps. This program is a **content-intelligence** program layered on
> the existing, already-shipped product — **not** a redesign and **not** a UI rewrite.

---

## 1. Execution rules

- Execution order is **fixed**: Phase 1 → 2 → 3 → 4 → 5 → 6. No skipping. No reordering.
- Work on **one phase at a time**. Never start a new phase before the current one is DONE.
- Never partially complete a phase. No placeholder code, no TODOs deferred to future phases.
- Future phases must **never** influence the current implementation. Solve the current phase
  completely with the abstractions it needs, not speculative hooks for later phases.
- After a phase is DONE: update memory, then re-read this file + `BANK_QUESTİON.md`, then begin
  the next phase.

## 2. Phase map (18 Parts → 6 Phases)

The roadmap's 18 Parts are grouped into 6 executable phases. This mapping is fixed for the program.

| Phase | Roadmap Parts         | Theme                                                                                                                                                                      |
| ----- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | 1, 2, 15 (foundation) | **Schema & Normalization Foundation** — unified normalized question schema; ingestion/normalization pipeline with source attribution; backfill the whole bank.             |
| **2** | 4, 5, 6               | **Categorization, Quality & Duplicate Detection** — deterministic classifier; quality scoring; near-duplicate/fingerprint detection + admin intelligence dashboard.        |
| **3** | 3, 9                  | **Knowledge Graph & Question Families** — typed node/edge graph over questions↔lessons↔signs↔parts↔laws↔scenarios↔topics; concept families for adaptive learning.          |
| **4** | 7, 8, 14              | **Generation, Visual Questions & AI Reviewer** — Anthropic-grounded original question generation; visual (identify-the-sign) questions; automated AI review gate.          |
| **5** | 10, 11, 12, 16        | **Dynamic Exams, Collections, Adaptive Learning & Analytics** — constraint-based unique exam generation; auto exam collections; weak-topic adaptivity; question analytics. |
| **6** | 13, 17, 18            | **Community Review, Final Validation & Report** — report/moderation flow; integrity/duplicate/quality/graph validation; `QUESTION_INTELLIGENCE_REPORT.md`.                 |

## 3. Definition of Done (every phase)

A phase is DONE **only** when ALL of the following hold:

1. **Engineering / architecture / implementation complete** — production-ready, no placeholders,
   no temporary implementations, no TODOs.
2. **Tests complete** — new unit tests for all new logic; existing suites still pass.
3. **Lint clean** — `pnpm lint` (ESLint) and `pnpm format` (Prettier check) pass.
4. **Typecheck clean** — `pnpm typecheck` (0 errors; pre-existing db-generate warning tolerated).
5. **Build green** — `pnpm build` (turbo) succeeds; `pnpm --filter @ea/web build` for the app.
6. **CI green** — pushed to `main`; GitHub Actions + CodeQL pass.
7. **Browser validation** — where the phase ships UI, validated in a real browser (and on the live
   site where a production surface is affected). Library-only phases state "N/A (no UI)" explicitly.
8. **Production validation** — where applicable (a deployed surface changed), verified on the live
   site; otherwise stated as N/A with reason.
9. **Documentation updated** — relevant docs/READMEs reflect the change.
10. **Report written** — `PHASE_<N>_REPORT.md` (template in §7).
11. **Memory updated** — key decisions recorded in project memory (`MEMORY.md` index +
    `project-*.md` file) so future phases read them before starting.
12. **Git commit created + pushed** — a focused commit on `main`, pushed to `origin`.

## 4. Testing requirements

- Unit tests for every new pure function/module (vitest). Deterministic — inject RNG/clock; **no
  reliance on `Date.now()`/`Math.random()`** in test-critical paths without injection.
- Any new API route gets an integration test; any new user-facing flow gets/extends a Playwright
  e2e spec. **Preserve all existing `data-testid`s and e2e selectors** — grep specs before renaming.
- e2e runs with mocks forced (`ANTHROPIC_API_KEY=''`, `DATABASE_URL=''`, `PGLITE_DIR='memory://'`,
  `workers:3`) per `apps/web/playwright.config.ts`. Admin content-pipeline specs cold-start flake
  under single-threaded PGlite — re-run in isolation for a true signal (CI has `retries:2`).
- Run the full local gate before committing: `pnpm verify && pnpm lint && pnpm typecheck &&
pnpm test && pnpm build` (`pnpm gates`).

## 5. Documentation requirements

- Each phase updates any doc it makes stale and writes `PHASE_<N>_REPORT.md`.
- The final phase writes `QUESTION_INTELLIGENCE_REPORT.md` (roadmap Part 18).
- Reports use **REAL numbers only** — never fabricate counts, rates, ratings, or reviews. If a
  metric can't be measured, say so.

## 6. Memory requirements

- After each phase, add/update a `project-*.md` memory file capturing the phase's key
  implementation decisions, new modules/APIs, and any gotchas; add a one-line pointer in `MEMORY.md`.
- The next phase reads those memories (and this file) before starting.

## 7. Git requirements

- Branch: work on `main` (the project deploys on push to `main`).
- One focused commit per phase (small follow-up fixups allowed). Message ends with the
  `Co-Authored-By` trailer. Push to `origin/main`; confirm CI + CodeQL green before declaring DONE.

## 8. Content & legal guardrails (apply to every phase)

- **No scraping/republishing of copyrighted third-party question banks.** The bank's standing
  policy is _özgün_ content: authored in our own words from official MEB/ODSGM curriculum and
  Karayolları Trafik mevzuatı (every source file states "Hiçbir uygulama/site sorusu
  kopyalanmamıştır"). Part 1 "Question Discovery" is therefore realized as an **ingestion pipeline
  capability** populated with own-authored + AI-original (Phase 4) content — not scraped material.
- **REAL DATA ONLY** — never fabricate metrics, ratings, or reviews.
- AI-generated questions are always `review: 'draft'` and pass the AI Reviewer + schema + dedup
  gate before entering the bank. Never auto-publish generated content.
- Preserve existing functionality, entitlements, and e2e selectors. This is additive intelligence,
  not a redesign.

## 9. Report template (`PHASE_<N>_REPORT.md`)

```
# Phase <N> Report — <Theme>
## Verdict: GO / NO-GO
## Completed work
## Architecture
## Tests
## Performance
## Known limitations
## Next phase prerequisites
```

## 10. Report ledger

| Phase | Report                                                  | Status  |
| ----- | ------------------------------------------------------- | ------- |
| 1     | `PHASE_1_REPORT.md`                                     | ✅ done |
| 2     | `PHASE_2_REPORT.md`                                     | ✅ done |
| 3     | `PHASE_3_REPORT.md`                                     | ✅ done |
| 4     | `PHASE_4_REPORT.md`                                     | ✅ done |
| 5     | `PHASE_5_REPORT.md`                                     | ✅ done |
| 6     | `PHASE_6_REPORT.md` + `QUESTION_INTELLIGENCE_REPORT.md` | ✅ done |

---

**Mission:** build the most complete driving-license question intelligence platform possible —
capable of tens of thousands of categorized questions, dynamic exams, AI-generated variants,
adaptive learning, and future mobile apps. One phase, done perfectly, then the next. Quality over
speed.
