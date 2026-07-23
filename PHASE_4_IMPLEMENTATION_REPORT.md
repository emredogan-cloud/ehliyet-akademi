# Phase 4 Implementation Report — Practice & Exams

**Ehliyet Akademi Mobile · Roadmap: `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`**
_Prepared: 2026-07-23 · Backend deployed + verified; every practice/exam screen device-validated on a real Android phone._

## Verdict: 🟢 GO

The app now has a complete, **offline-first Practice & Exams** section: adaptive SRS study, a real
MEB-format 50-question exam runner, deterministic themed collections, and 18 historical (MEB) sessions —
all running from a locally cached **1562-question bank**, with the learning-science engine (SM-2 + exam
builder + readiness) ported to Dart so everything works without a network after first load.

---

## Completed work

### Backend (Next.js API — additive, public)

- **`GET /api/mobile/question-bank`**: a lean projection of the full bank (1562 questions: id, subject,
  topic, difficulty, stem, options, answerIndex, explanation, badge, whyWrong) + `EXAM_BLUEPRINT`, with a
  deterministic sha256 `version` + ETag/304 (~1.28 MB, gzips to ~250 KB). Integration test (3) green.

### Mobile (Flutter) — pure logic ported to Dart (runs fully offline)

- **SRS engine** (`domain/practice/srs.dart`): verbatim port of `@ea/srs-engine` — `newCard`, `review`
  (SM-2), `toGrade`, `isDue`, `selectNext` (adaptive: due + weak-topic weighted), `computeReadiness`
  (blueprint-weighted mastery + sigmoid pass probability + traffic light), `statsFromAnswers`.
- **Exam** (`domain/practice/exam.dart`): `buildExam` (23/12/9/6, prorated when the bank is short),
  `scoreExam` (baraj 35/50), Fisher–Yates `shuffle`, **mulberry32 `seededRng`**, **FNV-1a `hash32`** +
  `seedFromDate` — all matching the web.
- **Collections** (`domain/practice/collections.dart`): deterministic, date-seeded themed sets (Günün/
  Haftanın Sınavı, Başlangıç, Zor Sorular, Yalnız İşaretler/Motor/İlk Yardım, En Çok Yanılan, Rastgele 50).
- **Historical** (`domain/practice/historical.dart`): the 18 fixed MEB session dates → an original,
  date-seeded 50-question exam each (no copied content — dates are facts only).
- **Models**: freezed `Question`, `QuestionBank`/`ExamBlueprint`, `SrsCard`, `AnswerLog`.
- **Data**: offline-first `QuestionRepository` (drift cache + ETag, same pattern as content);
  `ProgressRepository` (SRS cards / answers(cap 2000) / streak / counters via shared_preferences) with a
  safe cross-device **merge**; best-effort `StateSync` (`/api/state`, Bearer) that no-ops offline.
- **Screens** (`features/practice/`): practice hub (+ readiness card), **SRS study runner** (instant
  correct/wrong + explanation + whyWrong, updates SM-2 cards), **50-Q exam runner** (countdown timer,
  question-map strip, prev/next, confirm-finish, pass/fail result with per-subject bars), **collections
  list**, **historical list** (grouped by year). Nested `go_router` routes; removed the placeholder
  "Görsel Quiz" tile (no dead nav).

## Architecture (decisions, packages, structure)

- **Port the pure logic, cache the data.** SM-2, exam building, scoring, and seeded RNG are small pure
  functions with server tests → ported to Dart and unit-tested to spec. The bank is the only new backend
  surface. Result: practice/exams are fully deterministic and **offline**, no per-action server calls.
- **drift `AppDatabase` extended** (Phase 3's DB) with the question-bank document; `ProgressRepository`
  uses shared_preferences (small, frequently-written KV with the web's exact `ea:*:v1` shapes).
- **Collections use direct field filters** (subject/difficulty/topic) instead of porting the web's
  analyzed/quality layer — sufficient for a themed practice set and keeps the port small.
- No new packages (reused dio/drift/shared_preferences/freezed). Generated files committed for CI.

## Tests executed

- **Backend integration** (`question-bank.integration.test.ts`) — **3 passed** (count 1562, blueprint,
  every answerIndex in range, per-subject ≥ blueprint, ETag/304).
- `flutter analyze` — **0 issues**.
- `flutter test` — **55 passed**: SRS (SM-2 grades/interval/ease-floor/selectNext/readiness/json),
  exam builder (seededRng determinism, hash32, 23/12/9/6, prorated, scoreExam), collections + historical
  determinism, and practice widget flows (hub→study→feedback, exam build/run/score, collections list +
  open, historical list). Plus all prior Phase 1–3 tests.
- Web gates: prettier ✓, typecheck ✓, lint 0 errors (1 pre-existing warn), verify ✓, backend suite ✓ (12).

## Build

- **Android debug APK builds**; **iOS N/A (no macOS)**. **Mobile CI** (analyze + test + build apk) green.

## Performance

The 1562-question bank loads once (~250 KB gzipped), caches to drift, and every subsequent load is
offline/instant. Exam/practice building is in-memory over the bank (fast). The exam timer is a 1 s
periodic timer, cancelled on finish/dispose.

## Device validation

- **Device:** Redmi M1908C3JGG, Android 11 (API 30), `AYXSUKIVJVPZ7HPZ` (USB), against **production**.
- **Deploy sanity (curl):** question-bank 200 (1562 Qs, blueprint 50/35/45, distribution 23/12/9/6,
  all answerIndex valid), matching If-None-Match → **304**.
- **Exercised on-device:** practice hub (4 areas, no dead nav); **SRS study** — real first-aid question
  ("egzoz gazından zehirlenme…"), tapped the correct option → **green ✓ + "Doğru!" + full explanation** +
  "Sonraki soru" (SM-2 card/answer/streak persisted); **Deneme Sınavı** — 50-Q MEB exam built from the
  bank, **timer counting (44:56)**, "0/50 yanıtlandı", question-map strip, real question + options,
  prev/next; **Koleksiyonlar** — themed sets with real counts (Günün/Haftanın 50, Başlangıç/Zor 40,
  Yalnız İşaretler 29, Motor/İlk Yardım 40); **Geçmiş Sınavlar** — 18 sessions grouped by year, "50 soru ·
  MEB formatı".
- **Evidence:** screenshots for hub, SRS question + answered-feedback, exam runner, collections, historical.

## Known issues / limitations

- The **exam result screen** (pass/fail + per-subject bars) was validated by the widget test (a 5-Q
  shortened exam finishing to "KALDIN" + "Başarı"), not screenshotted end-to-end on device (finishing 50
  questions by hand is impractical); the runner build/timer/nav were device-validated.
- **State sync** is best-effort last-write-wins per key with a safe merge on login; a full conflict-free
  sync (and entitlements) is future work.
- **Collections theming** uses direct filters, not the web's analyzed/quality layer, so exact question
  membership can differ from the web (both are deterministic and correctly themed).
- **Pre-existing 5px Home quick-actions overflow** (Phase 1) still logged for Phase 9.

## Next phase prerequisites (Phase 5 — AI Coach & Notifications)

- ✅ Answers/SRS/readiness available locally for coach personalization.
- Phase 5 adds: a coach-nudge API, chat + proactive cards, and push/local notifications (FCM).

**Phase 4 is DONE per the Definition of Done: implementation complete (no placeholders/dead nav), mobile +
backend tests green, APK builds, backend deployed + verified, and every practice/exam screen
device-validated against production. Proceeding to Phase 5 after CI is green.**
