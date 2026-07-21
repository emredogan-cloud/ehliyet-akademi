# PDF Archive Analysis Report

**QIP 2.0 Content Expansion · Phase 1 — Archive Analysis**
_Prepared: 2026-07-21 · Reference-layer only (no verbatim import)_

## Verdict: 🟢 GO (analysis complete; reference layer established)

The local archive `sınav-soruları-pdf/` was inventoried and analyzed as a **pattern/format
reference only**. No question wording or images were extracted, stored, or republished — the
archive is copyrighted MEB exam material and is now **git-ignored** so it can never be committed.
What this phase produces is factual metadata (session dates, format) + an aggregate topic signal —
never expression.

---

## What the archive is (measured)

| Metric                             | Value                                                          |
| ---------------------------------- | -------------------------------------------------------------- |
| PDF files                          | **21**                                                         |
| Scanned image PDFs (no text layer) | **20** (~12 words each = only the Google-Drive wrapper header) |
| Text-layer PDFs                    | **1** (`13120202_MTSK_K` = the 10.02.2018 session, 2802 words) |
| Unique real exam sessions          | **18** (3 files are duplicates)                                |
| Date span                          | **2015-01-10 → 2018-08-04**                                    |
| Years                              | 2015 (6 sessions) · 2016 (4) · 2017 (5) · 2018 (3)             |

All 21 are real MEB e-Sınav (MTSK) exam papers collected from a third-party Google Drive archive —
**not** MEB's official publication channel, and **not** the curriculum framework (the one text PDF's
header confirms it is the 10.02.2018 exam booklet: "soru sayısı 50, sınav süreniz 60 dakika").

## Reference-only handling (the important part)

- **The 20 scanned papers were NOT OCR'd.** Their content is raster images of copyrighted exam
  pages; OCR-then-store would be extracting expression + copying their images — exactly what the
  mandate forbids ("extract knowledge, not expression"). They contribute **session date + format**
  only.
- **The 1 text-layer paper** was read to derive an **aggregate keyword-frequency signal** (below) —
  counts only, no question text retained anywhere.
- **`sınav-soruları-pdf/` is git-ignored** — the copyrighted archive is never committed/republished.
- The only artifacts this phase adds to the codebase are **facts**: the 18 real session dates
  (`lib/qip/archive.ts` `HISTORICAL_SESSIONS`) — public record of when exams occurred — which drive
  the Phase 6 historical-format browsing with **original** practice exams.

## Exam pattern (the reference we actually use)

The authoritative exam structure is already encoded as `EXAM_BLUEPRINT`: **50 questions**, pass 35,
distribution **trafik 23 · ilkyardim 12 · motor 9 · adab 6**. The archive confirms this format held
across 2015–2018 (the 2018 booklet states 50 questions / 60 min; current e-Sınav is 45 min). This
blueprint — not any copied paper — is what Phase 6's original practice exams replicate.

### Aggregate topic signal (from the single text-layer session, indicative only)

Keyword-frequency across the 2018-02-10 paper (occurrences, **not** per-question counts, **not**
verbatim): motor 33 · hız 27 · ilkyardım 14 · işaret/levha 12 · adab 6 · kavşak 4 · yaya 4 ·
öncelik 1 · emniyet-kemeri 1. This is one session and a rough signal — it merely confirms coverage
spans all four MEB subjects; it is **not** used as a precise histogram.

## Cross-reference with the current bank

The current QIP bank already measures its own coverage far more reliably than 21 scanned papers can:
**1534 questions** — trafik 368 · ilkyardim 299 · motor 298 · adab 272 · pratik 297; 32 themes;
difficulty kolay 546 / orta 719 / zor 269. The bank already exceeds a single exam's breadth many
times over, so the archive's role is **format/cadence reference**, not a content source. The
detailed coverage-gap comparison is Phase 3 (`CONTENT_GAP_REPORT.md`).

## Deliverables

- `lib/qip/archive.ts` — `HISTORICAL_SESSIONS` (18 factual session dates) + `sessionsByYear()` +
  `historicalSessionById()`; `HISTORICAL_EXAM_BLUEPRINT`. Pure, tested (4 tests).
- `.gitignore` — `sınav-soruları-pdf/` excluded.
- This report.

## Known limitations

- 20/21 PDFs are scans with no text layer; by mandate they are not OCR'd, so the archive yields
  session dates + format, not machine-readable content.
- The one text-layer paper is a single session — its topic signal is indicative, not a distribution.
- Real, reliable topic/difficulty targets for generation come from the encoded blueprint + the
  existing bank's measured coverage (Phase 3), not from the scanned archive.

## Next phase (Phase 2 — Knowledge Extraction)

Extract structured driving knowledge (rules, limits, definitions, procedures) — from official
public standards and the existing content, connected into the knowledge graph — **as knowledge, not
question wording** — to feed the gap analysis and original generation.

**Phase 1 is complete. The archive is established as a reference layer, nothing copied.**
