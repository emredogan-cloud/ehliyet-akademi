# Content Gap Report

**QIP 2.0 Content Expansion · Phase 3 — Gap Analysis**
_Prepared: 2026-07-21 · Real measured coverage_

## Verdict: 🟢 GO — gaps identified and ranked

`analyzeGaps()` compares the current bank's real coverage against the theme / rule / difficulty /
sign yardsticks and ranks the shortfalls by priority. This is the **target list for Phase 4**
(original generation) — no content was copied; this is measurement.

---

## Summary (measured)

| Metric                | Value                                                                        |
| --------------------- | ---------------------------------------------------------------------------- |
| Total ranked gaps     | **12** (11 theme, 1 sign)                                                    |
| Rule coverage         | **26 / 26** rule-facts have ≥3 questions on their topics (no uncovered rule) |
| Traffic-sign coverage | **49 / 121** signs have ≥1 question — **72 signs (60%) have none**           |
| Difficulty balance    | no subject falls below the 10% floor for kolay/zor → no difficulty gap       |

## Top-priority gaps (ranked)

| #   | Kind  | Target                   | Current               | Priority |
| --- | ----- | ------------------------ | --------------------- | -------- |
| 1   | theme | Işıklı İşaret Cihazları  | 5 / 30                | 78       |
| 2   | theme | Gösterge Paneli          | 11 / 30               | 64       |
| 3   | theme | Periyodik Bakım          | 11 / 30               | 64       |
| 4   | theme | Kırık, Çıkık ve Burkulma | 11 / 30               | 64       |
| 5   | theme | Duraklama ve Park        | 12 / 30               | 62       |
| 6   | sign  | Signs with no question   | 49 / 121 (72 missing) | 51       |
| 7   | theme | Güvenlik Donanımı        | 17 / 30               | 50       |
| 8   | theme | Fren Sistemi             | 19 / 30               | 46       |
| 9   | theme | Yakıt Sistemi            | 21 / 30               | 41       |
| 10  | theme | Farlar ve Aydınlatma     | 24 / 30               | 34       |

(Plus thinner tails: Kavşak/Şerit-adjacent and other themes above 24 are near target.)

## Interpretation

- **Thin themes** cluster in **Araç Tekniği** (Gösterge Paneli, Periyodik Bakım, Fren, Yakıt) and a
  few specific traffic themes (Işıklı İşaret Cihazları, Duraklama/Park, Güvenlik Donanımı). These
  are the highest-value targets for original question generation.
- **Traffic signs are the biggest single opportunity:** 72 of 121 signs have zero questions. The
  Phase-4 **visual generator already turns every sign into a reviewed visual question** — running it
  over the 72 uncovered signs closes this gap directly and legally (own SVG assets).
- **Rules are well covered** (26/26) — every authored rule-fact's topic has questions; the bank's
  factual foundation is solid.
- **Difficulty is balanced** — no subject is starved of easy or hard questions.

## How Phase 4 uses this

The ranked `topGaps` become the generation targets: for each thin theme, the Anthropic generator
(grounded in `DRIVING_RULES` + curriculum) produces original questions on that theme's topics; for
the 72 uncovered signs, `generateSignQuestions()` produces reviewed visual questions. Everything
flows through the mandatory pipeline (normalize → categorize → graph → quality → dedup → AI review →
draft).

## Deliverables

- `lib/qip/gaps.ts` — `analyzeGaps()` → ranked gaps + theme/rule/sign coverage. Pure, tested.
- This report.

**Phase 3 is complete. The expansion now has a real, prioritized target list.**
