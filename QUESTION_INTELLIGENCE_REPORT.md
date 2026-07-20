# Question Intelligence Report

**Ehliyet Akademi — Question Intelligence Platform (QIP)**
_Program driven by `BANK_QUESTİON.md` · Protocol `QUESTION_PLATFORM_WORKFLOW.md` · Completed 2026-07-21_

## Verdict: 🟢 GO — all 6 phases complete, final validation 100/100

The QIP program transformed the existing question system into a full content-intelligence platform:
a unified schema, smart categorization, quality scoring, duplicate detection, a knowledge graph,
question families, AI + visual question generation with an automated reviewer, a dynamic exam
engine, auto collections, adaptive learning, question analytics, community moderation, and a final
validation sweep. Every layer is deterministic, tested, and reuses the same authored bank — **no
scraping, no fabricated numbers, and the authored 1534-question source was never modified.**

---

## By the numbers (all measured)

### Questions collected

- **1534** questions — authored in our own words from official MEB/ODSGM curriculum + Karayolları
  Trafik mevzuatı. Standing policy: "Hiçbir uygulama/site sorusu kopyalanmamıştır." Part 1
  "Discovery" is realized as an **auditable ingestion pipeline** (validate → fingerprint-dedup →
  source attribution), not a scraper. `source.origin` ∈ authored | ai-generated | imported (the
  last reserved for open-licensed sources only).
- Distribution: trafik 368 · ilkyardim 299 · motor 298 · adab 272 · pratik 297.
- Difficulty: kolay 546 · orta 719 · zor 269. Estimated practice content: ~1487 minutes (~24.8 h).

### Images collected

- **121** verified traffic signs (own SVG, Vienna-standard) + 70 vehicle parts + 7 scenarios, all
  reused as the consistent visual source. **121 visual "identify-the-meaning" questions** are
  generatable from the sign catalog — **all 121 pass the AI reviewer**. No external image pipeline
  was needed (the verified vector set is the consistent style).

### Categories created

- 5 subject domains → **32 cross-cutting themes** (aligned to roadmap Part 4). **1132 / 1534
  (73.8%)** questions map to a specific theme; the rest fall to an honest subject-fallback theme.
  Top themes: Trafik Adabı 228 · Direksiyon Sınavı 115 · Trafik İşaretleri 99 · Kavşak/Şerit 88 ·
  Temel Yaşam Desteği 86.

### Knowledge graph

- **2576 nodes** (question 1534 · topic 788 · sign 121 · part 70 · theme 32 · lesson 19 · scenario 7
  · subject 5) and **8764 edges** across 6 typed relations. Avg question degree 3.6. Powers a
  graph-driven recommendation API (`/api/qip/related/[id]`). Honest gap: 853 questions (55%) have no
  lesson/sign/part edge (still connected via subject/topic/theme).

### Duplicates removed

- **0 exact duplicates** in the bank (unique fingerprints across all 1534). Near-duplicate detection
  (Jaccard ≥ 0.82, inverted-index + union-find) found **1 near-duplicate pair** (`trafik-136` ≈
  `trafik-237`, 0.86) — a flagged **merge candidate**, surfaced not silently dropped. Duplicate rate
  **0.1%**.

### Questions generated

- **Visual:** 121 schema-valid sign questions (deterministic, reviewed, `review: 'draft'`).
- **AI (LLM):** an Anthropic-grounded generator produces original variants (new scenario/wording/
  distractors, same objective) through a strict pipeline (parse → schema → **AI reviewer** →
  dedup); always `review: 'draft'`, **never auto-published**; honest-empty when unconfigured.
- **AI reviewer:** 6 deterministic gates (answer-in-range, single-correct, distinct options,
  quality ≥ 70, not-duplicate, on-domain).

### Question families

- **794 families** ("one concept → many variants"): 329 multi-variant, 465 singletons, largest 24
  (Kanama). **1069 questions** live in multi-variant families — the adaptive-learning substrate
  (serve a fresh variant of the same concept).

### Dynamic exam system

- Constraint-based generator: MEB-scaled or explicit subject mix, difficulty balance, **no repeated
  concept** (family), **no repeated image**, randomized choices (answer preserved), seeded
  uniqueness. Measured 50-question balanced exam: **exact 23/12/9/6**, difficulty 17/17/16, **50/50
  unique families, 0 repeated images**.
- **10 auto collections** (Günün/Haftanın Sınavı, Başlangıç, Zor Sorular, Yalnız İşaretler/Motor/İlk
  Yardım, En Çok Yanılan, Rastgele 50, AI Challenge) — daily-seeded, surfaced at `/koleksiyonlar`.
- **Adaptive learning:** weak-topic weighting (70%) with fresh variants; **analytics:** attempts,
  correct/wrong rate, per-topic mastery (avg-time / most-chosen-wrong when the optional
  `timeMs`/`chosenIndex` are captured — honest coverage flags, never faked).
- **Community review:** report/moderation flow (`/api/qip/report` → `/admin/bildirimler`).

### Final validation (Part 17) — score **100/100**, PASSED

integrity ✅ · duplicates ✅ (0 exact) · quality ✅ (avg 100) · category balance ✅ · broken images
✅ (0) · broken references ✅ (0) · knowledge-graph consistency ✅.

---

## Architecture summary

| Layer                                      | Module                                                                 | Roadmap              |
| ------------------------------------------ | ---------------------------------------------------------------------- | -------------------- |
| Schema + normalization + ingestion         | `@ea/content-schema` NormalizedQuestion · `lib/qip/{normalize,ingest}` | Parts 1, 2, 15       |
| Categorization / quality / dedup           | `lib/qip/{categorize,quality,dedup}`                                   | Parts 4, 5, 6        |
| Knowledge graph / families                 | `lib/qip/{graph,families}`                                             | Parts 3, 9           |
| Generation / visual / reviewer             | `lib/qip/{review,visual}` · `lib/server/qip-generate`                  | Parts 7, 8, 14       |
| Exams / collections / adaptive / analytics | `lib/qip/{exam,collections,adaptive,analytics}`                        | Parts 10, 11, 12, 16 |
| Community / validation / report            | `lib/server/reports` · `lib/qip/validate` · this file                  | Parts 13, 17, 18     |

Admin surfaces: `/admin/soru-zekasi` (intelligence + validation), `/admin/soru-uretimi`
(generation), `/admin/bildirimler` (moderation). Public: `/koleksiyonlar`, `/api/qip/{related,
collections,report}`.

## Test + gate summary

- Web unit/integration suite grew **187 → 289** across the program; all packages green each phase.
- Per-phase gates (verify/lint/format/typecheck/build) + CI + CodeQL green; browser (Playwright) and
  production validation each phase. Per-phase reports: `PHASE_1..6_REPORT.md`.

## Remaining limitations

- Cross-link recall is intentionally conservative (853 questions lack a rich edge) — future content
  work, not a correctness issue; the graph still connects everything via subject/topic/theme.
- Analytics avg-time / most-chosen-wrong await capturing `timeMs`/`chosenIndex` in the live quiz
  (engine is ready; reported honestly via `hasTiming`/`hasChoiceData`).
- Generated questions are admin-surfaced **drafts**; promotion to the published bank stays a
  human/expert-review decision (roadmap E.6).
- Validation is structural/statistical; deep factual re-verification remains expert review.
- The dynamic-exam / adaptive engines are complete, tested capabilities; wiring them as the backend
  of the live practice/exam UI is an integration step beyond this content-intelligence program.

## Future scalability

- The unified schema + ingestion pipeline + AI generator + reviewer gate mean the platform can grow
  to **tens of thousands** of categorized, deduplicated, reviewed questions without architectural
  change — every new question flows through the same normalize → classify → quality → dedup → review
  pipeline.
- Deterministic, offline analysis (no embedding service) keeps it reproducible and cheap; the
  Anthropic generator is the only paid path and is gated + honest-fallback.
- The knowledge graph + families + analytics are the substrate for future recommendations, adaptive
  study plans, and mobile apps.

**The Ehliyet Akademi question system is now a complete, validated question intelligence platform.**
