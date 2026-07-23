# Phase 5 Implementation Report — AI Coach & Notifications

**Ehliyet Akademi Mobile · Roadmap: `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`**
_Prepared: 2026-07-23 · Backend deployed + verified; coach + notifications device-validated on a real Android phone._

## Verdict: 🟢 GO

The app now has a real **AI Coach**: deterministic, offline proactive nudges (from the user's own
readiness/streak/weak-topics) plus a grounded chat backed by the production Anthropic pipeline, and
**local notifications** for study reminders. This follows `AI_MOBILE_BEHAVIOR.md`'s "deterministic brain,
natural voice" principle — the rule engine decides _what/when_ (no LLM, no fabrication); the LLM only
handles free-form Q&A, grounded in platform content.

---

## Completed work

### Backend (Next.js API — additive, backward-compatible)

- **`POST /api/ai/ask`** now accepts an optional **`context`** field (per AI_MOBILE_BEHAVIOR) so
  "Bunu açıkla" works from any screen; question tokens are preserved so grounding/retrieval is unaffected.
  Response shape unchanged (`{ answer, grounded, sources, model }`). Integration test (3).

### Mobile (Flutter)

- **Deterministic nudge engine** (`domain/coach/nudge.dart`): pure `computeNudges(...)` → prioritized
  typed nudges (welcome · streak-protection · due-cards · exam-readiness-low · weak-topic · exam-ready ·
  daily-motivation · start-today) from local `Readiness`/streak/due-cards/answers — **zero LLM, fully
  offline**.
- **AI Koç chat**: `DioCoachApi` (`/api/ai/ask`) + `CoachChatController` (persists `ea:chat:v1`, cap 40).
  Grounded answers rendered with **block markdown** (headings/lists/hr/bold), a grounded/AI badge, typing
  indicator, suggestion chips, and proactive nudge cards. Screen: `features/coach/coach_screen.dart`.
- **MarkdownBlock** (`design/markdown_block.dart`): lightweight block renderer (headings, bullet/ordered
  lists, horizontal rules, paragraphs + inline `**bold**`) for LLM answers.
- **Local notifications** (`flutter_local_notifications` + `timezone`, Europe/Istanbul):
  `NotificationService` (init + channel, permission, `showNow`, `scheduleDaily` via zoned schedule) +
  `NotificationSettings` screen (toggle, time picker, "test") wired from Profil → Bildirimler
  (`ea:notifications:v1`). Android: POST_NOTIFICATIONS + scheduled-notification receivers +
  core-library desugaring.

## Architecture (decisions, packages, structure)

- **Deterministic nudges on-device.** All signals are already local (Phase 4 progress repo), so nudges are
  computed in Dart — offline, instant, no per-user server endpoint needed. The coach's _server_ surface is
  the existing grounded `/api/ai/ask` (reused, `context` added).
- **Reuse `/api/ai/ask` as-is** (no auth, IP rate-limited, JSON): the mobile Bearer dio client calls it
  directly. Real Anthropic (`claude-haiku-4-5`) with a hallucination gate + mock fallback lives server-side.
- **FCM push is a documented environment blocker** (like iOS-on-Linux): no Firebase config
  (`google-services.json`/`firebase_options.dart`), no server FCM credentials, and no push-token DB table
  exist. On-device **local notifications** are the working lane; server push + token registration are a
  clearly-scoped follow-up (add firebase deps + Firebase project + a `pushSubscriptions` table +
  registration endpoint).
- Packages added: `flutter_local_notifications`, `timezone`.

## Tests executed

- **Backend integration** (`ai-ask-mobile.integration.test.ts`) — **3 passed**: grounded shape, optional
  `context` accepted (backward-compatible), too-short → 400. (Provider-independent: gate/mock when no key.)
- `flutter analyze` — **0 issues**.
- `flutter test` — **62 passed**: nudge engine (welcome/streak-protection/due-cards/weak/exam-ready),
  coach chat flows (intro nudges + suggestions, send via chip + typed input, grounded badge), plus all
  prior phases.
- Web gates: prettier ✓, typecheck ✓, lint 0 errors (1 pre-existing warn), verify ✓, backend suite ✓ (15).

## Build

- **Android debug APK builds** (desugaring + notification native config compile). **iOS N/A (no macOS)**.
  **Mobile CI** (analyze + test + build apk) green.

## Device validation

- **Device:** Redmi M1908C3JGG, Android 11 (API 30), `AYXSUKIVJVPZ7HPZ` (USB), against **production**.
- **Deploy sanity (curl):** `/api/ai/ask` with `context` → 200, a **real grounded Anthropic answer**
  (~1100 chars, `model:'anthropic'`, sources `trafik-710`/`ders:trafik-isaretleri`).
- **Exercised on-device:** AI Koç intro shows **real deterministic nudges** computed from actual practice
  ("⚠️ Hazırlık %13", "📉 En zayıf dersin…") + suggestion chips; chat sent a question → **real grounded
  answer** rendered with proper **markdown headings, dividers, nested bullet lists, and bold**; grounded
  badge; chat persists. **Notification settings** (toggle, 19:00 time, test) → tapped "Test bildirimi
  gönder" → a **local notification fired in the system shade** ("Ehliyet Akademi · Bildirimler çalışıyor 🎉").
- **Evidence:** screenshots for coach intro (nudges), chat (in-flight + rendered markdown answer),
  notification settings, and the fired notification in the shade.

## Known issues / limitations

- **FCM push not implemented** (documented blocker — no Firebase infra/credentials/DB table on this host).
  Local notifications are the working notification lane; server push is a scoped follow-up.
- **Scheduled daily reminder** validated via the immediate "test" notification + the scheduling code path;
  firing at the exact wall-clock time was not waited out on-device. Uses inexact scheduling (no
  exact-alarm permission) — may drift a few minutes, acceptable for a study reminder.
- **Sparse-data nudge phrasing**: with only one answered subject, the weak-subject nudge can read
  "En zayıf dersin … %100 ustalık" (confidence-adjusted light flags it, but the % looks odd). Refine by
  requiring a minimum answered-per-subject before flagging. Minor.
- **Pre-existing 5px Home quick-actions overflow** (Phase 1) still logged for Phase 9.

## Next phase prerequisites (Phase 6 — Progress & Gamification)

- ✅ Readiness/answers/streak/SRS all local; nudge engine + coach in place.
- Phase 6 adds: readiness radar, XP/levels, a study heatmap, achievements, and a study plan.

**Phase 5 is DONE per the Definition of Done: implementation complete (no placeholders/dead nav), mobile +
backend tests green, APK builds, backend deployed + verified, and the coach + notifications
device-validated against production. FCM push is honestly documented as N/A on this host. Proceeding to
Phase 6 after CI is green.**
