# Phase 3 Report — Knowledge Graph & Question Families

**QIP (Question Intelligence Platform) · Roadmap Parts 3, 9**
_Prepared: 2026-07-21 · Protocol: `QUESTION_PLATFORM_WORKFLOW.md`_

## Verdict: 🟢 GO

A typed knowledge graph (Part 3) connects every question to lessons, signs, vehicle parts,
scenarios, topics, themes, and subjects — powering a graph-driven recommendation API — and a
question-families layer (Part 9) clusters questions into concept variants that support adaptive
learning. Both are surfaced on the admin **Soru Zekâsı** dashboard with real numbers. Tested,
lint/typecheck/build-clean, browser- and production-validated.

---

## Completed work

### 1. Knowledge graph (`apps/web/lib/qip/graph.ts`) — Part 3

A typed node/edge graph built from the real content + Phase-1 cross-links + Phase-2
classification:

- **8 node types**: `question`, `lesson`, `sign`, `part`, `topic`, `theme`, `subject`, `scenario`.
- **6 edge types**: `belongs-to` (→ subject), `about-topic`, `classified-as` (→ theme),
  `related-lesson` (question/sign/part/scenario → lesson), `depicts-sign`, `depicts-part`.
- Query API: `neighbors(node, {edgeType?, nodeType?})`, and the recommendation engine
  `relatedContent(questionId)` (1-hop lessons/signs/parts + 2-hop sibling questions ranked by
  shared connections + related scenarios) / `relatedQuestions(questionId)`. This realizes Part 3's
  "the graph should support future recommendations".
- Built once and memoized; pure/deterministic; no external services.

### 2. Question families (`apps/web/lib/qip/families.ts`) — Part 9

"One concept → many variants." Union-find clusters questions by (a) same subject + topic, (b)
identical learning outcome, (c) near-duplicate bridges (from the Phase-2 dedup engine). Each family
has a human concept label, all member ids, and a **representative** (highest `qualityScore`).
`familyOf` / `familyVariants` are the **adaptive-learning hook** — when a learner struggles on a
question, the engine can serve a _different variant of the same concept_ (the actual adaptive loop
lands in Phase 5; Part 9's job is to make it possible, which this does).

### 3. Recommendation API + dashboard

- **`/api/qip/related/[id]`** (public — returns only public content refs) → graph-driven related
  lessons/signs/parts/scenarios/sibling-questions for a question.
- **`/admin/soru-zekasi`** extended with a **Bilgi Grafiği** section (node/edge counts by type,
  avg question degree, orphan count) and a **Soru Aileleri** section (family counts, largest,
  adaptive coverage). `qipIntelligence()` now includes `graph` + `families` stats.

## Architecture

```
apps/web/lib/qip
  graph.ts    → buildGraph() (memoized) · neighbors() · relatedContent()/relatedQuestions() · graphStats()
  families.ts → buildFamilies() (union-find over topic/outcome/near-dup) · familyOf/familyVariants · familyStats()
  index.ts    → qipIntelligence() now carries graph + families
apps/web/app
  api/qip/related/[id]/route.ts   → public graph-driven recommendations
  (app)/admin/soru-zekasi          → + Bilgi Grafiği & Soru Aileleri sections
```

Graph and families reuse the Phase-1 normalized cross-links and Phase-2 `analyzedQuestions()` +
`bankDedup()` — no re-computation of upstream layers, no change to them. `UnionFind` is shared
between dedup and families.

## Tests

- Unit: **+13** — graph (7: real node counts by type, determinism/caching, question→subject/topic/
  theme neighbors, relatedContent self-exclusion + non-empty, relatedQuestions limit/self-exclusion,
  unknown-id empties, graphStats consistency); families (6: full partition with no loss +
  size-sorted, representative membership + concept label, familyOf contains self, familyVariants
  self-exclusion + limit, unknown-id undefined, familyStats consistency).
- Integration: **+2** — `GET /api/qip/related/[id]` (known id → related content self-excluded;
  unknown id → empty). Extended the admin-qip integration test to assert graph + families present.
- E2E: extended the admin **Soru Zekâsı** test to assert the `qip-graph` + `qip-families` sections
  render (Chromium, real admin session).
- Suite: web **226 → 241** unit/integration; all packages green. Gates: verify ✓ · lint ✓
  (0 errors, 1 pre-existing db warning) · format ✓ · typecheck ✓ · build ✓.

## Performance

- `buildGraph` is O(nodes + edges) over the bank + content, run once and memoized; `relatedContent`
  is a bounded 2-hop traversal. `buildFamilies` is near-linear union-find. All complete inside the
  test suite with no measurable drag; the dashboard route is 2.85 kB.

## Real results (measured)

| Metric                  | Value                                                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Graph nodes             | **2576** — question 1534 · topic 788 · sign 121 · part 70 · theme 32 · lesson 19 · scenario 7 · subject 5                     |
| Graph edges             | **8764** — belongs-to 4621 · about-topic 1534 · classified-as 1534 · related-lesson 509 · depicts-part 312 · depicts-sign 254 |
| Avg question degree     | 3.6                                                                                                                           |
| Questions w/o rich link | 853 (only subject/topic/theme, no lesson/sign/part) — honest connectivity gap                                                 |
| Question families       | **794** — 329 multi-variant, 465 singletons                                                                                   |
| Largest family          | 24 (Kanama ve Yaralanma — `kanama`)                                                                                           |
| Adaptive coverage       | **1069** questions live in multi-variant families                                                                             |
| Example recommendation  | `trafik-101` → lesson `trafik-isaretleri` + 5 sibling questions                                                               |

## Known limitations

- 853 questions (55%) have no lesson/sign/part edge — a real consequence of Phase 1's
  high-precision/low-recall cross-linking. The graph still connects them via subject/topic/theme
  (so recommendations work), and this number is the honest measure of the linking gap; raising it
  is future content work, not a blocker.
- `relatedQuestions` ranks by shared-connection count (structural), not semantic similarity — good
  for "same lesson/theme" recommendations; semantic ranking is out of scope here.
- Families use topic + learning-outcome + near-dup signals; a concept split across differently-named
  topics with distinct outcomes won't merge. This keeps families precise (largest is 24, no runaway
  merges) at the cost of some recall.
- The recommendation API is not yet wired into a learner-facing page — it's a capability consumed in
  Phase 5 (adaptive) and by the AI Coach; browser validation this phase is via the admin dashboard.

## Next phase prerequisites (Phase 4 — Generation, Visual Questions & AI Reviewer)

- ✅ `relatedContent`/graph gives generation grounding context (a question's lesson/signs/theme).
- ✅ Families give the "generate another variant of this concept" target and dedup guards against
  generating something that already exists.
- ✅ `ingestQuestion` (Phase 1) already gates on schema + fingerprint dedup with `origin:
'ai-generated'` support — the entry point for generated questions.
- Phase 4 will add the Anthropic-grounded generator, visual (identify-the-sign) questions, and the
  automated AI reviewer, with generated questions always `review: 'draft'` behind the review gate.

**Phase 3 is DONE per the Definition of Done. Proceeding to Phase 4.**
