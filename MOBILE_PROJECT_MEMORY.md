# Mobile Project Memory (permanent, append-only)

Long-term engineering memory for the Ehliyet Akademi mobile app. **Append after every phase; never
overwrite previous entries.** The next phase reads this to recover full context. Read order each
phase: `MOBILE_ENGINEERING_DISCIPLINE.md` → this file → `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`.

## Progress

- [x] **Phase 1 — Flutter Foundation & Design System** (2026-07-23) — DONE, CI green, device-validated
- [x] **Phase 2 — Mobile Auth** (2026-07-23) — DONE, CI green, device-validated (bearer-token auth)
- [x] **Phase 3 — Content & Learn** (2026-07-23) — DONE, CI green, device-validated (offline-first content)
- [x] **Phase 4 — Practice & Exams** (2026-07-23) — DONE, CI green, device-validated (offline SRS + exams)
- [x] **Phase 5 — AI Coach & Notifications** (2026-07-23) — DONE, CI green, device-validated (nudges + grounded chat + local notif)
- [x] **Phase 6 — Progress & Gamification** (2026-07-23) — DONE, CI green, device-validated (XP/radar/heatmap/badges + bound Home)
- [x] **Phase 7 — Premium (IAP)** (2026-07-24) — DONE, CI green, device-validated (paywall + gating + quotas; real Play purchase store-gated)
- [x] **Phase 8 — Onboarding & Launch Prep** (2026-07-24) — DONE, CI green, device-validated (onboarding + release build + overflow fix)
- [x] **Phase 9 — Final Polish & Delight** (2026-07-24) — DONE, CI green, device-validated (a11y + radar polish + offline hardening)

## ✅ ROADMAP 100% COMPLETE (2026-07-24) — see `MOBILE_FINAL_IMPLEMENTATION_REPORT.md`

## Standing facts (environment / repo)

- Flutter 3.41.9 at `/home/emre/dev/flutter/bin`; Android SDK `/home/emre/Android/Sdk`; Java 17.
- Real device: `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG, Android 11 / API 30), 1080×2340. Build/install:
  `export PATH="$PATH:/home/emre/dev/flutter/bin"`; `adb -s AYXSUKIVJVPZ7HPZ install -r
build/app/outputs/flutter-apk/app-debug.apk`; launch `monkey -p com.ehliyetegitim.ehliyet_akademi`;
  screenshot `adb -s AYXSUKIVJVPZ7HPZ exec-out screencap -p > x.png`. In-app bottom nav ~ y=2150;
  system nav bar is lower (~2270 — don't tap there).
- **iOS build = N/A (no macOS on Linux).** ios/ config valid, never built.
- Flutter app: `apps/mobile/`, app id `com.ehliyetegitim.ehliyet_akademi`. Excluded from JS tooling
  (eslint.config.mjs, .prettierignore, verify-workspace SKIP_DIRS 'mobile'). CI: mobile.yml.
- Web CI runs on every push; format gate (`prettier --check .`) catches unformatted **reports** too.
- Backend API is live at `https://www.ehliyetegitim.com` (Vercel). Auth = opaque session tokens
  (`ea_session` cookie / sessions table, SHA-256 hashed, 30-day, multi-device).

---

## Phase 1 — Flutter Foundation & Design System (2026-07-23)

**Completed:** Flutter scaffold; design tokens → `ThemeData` (light + dark 1:1 with web); primitives
(AppCard, PageHeader, Callout, EmptyState, OverviewTile, ReadinessRing, CoachCard, QuickAction);
go_router 5 bottom tabs; Riverpod; 5 complete tab screens (home dashboard, learn/practice hubs, coach
intro, profile w/ working dark toggle).

**Architecture decisions:**

- State = **Riverpod**; routing = **go_router** `StatefulShellRoute.indexedStack`.
- **Router exposed as a provider** (`routerProvider`), NOT a global singleton — a global leaked
  navigation state between test instances (test 2 left it on /profile, breaking test 3).
- `AppPaletteExtension` (ThemeExtension) carries the full token palette to widgets (web has more color
  roles than Material `ColorScheme`).
- Theme mode via `Notifier<ThemeMode>` (in-memory; persistence deferred to Phase 2 via secure/local
  storage).

**Design decisions:** light primary teal `#0D9488` / bg `#F4F6FB`; dark navy primary `#2DD4BF` / bg
`#050B16`; accent amber `#F59E0B`; 8px spacing; radius 16; motion `Cubic(0.16,1,0.3,1)` @ 140/240/400ms.
System font stack → Roboto on Android (faithful match; no custom font needed).

**Packages added:** `go_router`, `flutter_riverpod`.

**Lessons learned / problems solved:**

- This Riverpod version **dropped `StateNotifier` from the default export** → use `Notifier` /
  `NotifierProvider`.
- go_router builders: use Dart wildcards `(_, _)` not `(_, __)` (lint `unnecessary_underscores`).
- Null-aware element: `?trailing` in a children list (lint `use_null_aware_elements`).
- Widget tests: off-fold `ListView` children aren't built in the 800×600 test viewport → use
  `dragUntilVisible` / `ensureVisible` before asserting/tapping.
- **CI format gate:** wrote the phase report after the local format pass → it committed unformatted →
  web CI failed. Fix: always `prettier --write` reports before committing. (Now rule #13 in discipline.)

**Known limitations / technical debt:**

- Golden (pixel) tests **deferred** — cross-environment font rendering would flake CI. Add a proper
  golden-CI harness (baseline images committed, tolerance config) in a later phase before relying on
  them.
- Debug APK ~140 MB (normal for debug; release tree-shakes to ~15–20 MB — Phase 8).
- Home/hub screens use representative **static** data; real data binds from Phase 2 (auth/state) on.

**Risk register (rolled forward):**

- IAP/store billing (Phase 7) — highest risk (rejection/margin). Native IAP + server validation.
- Offline sync correctness (Phase 3/4) — deterministic seeds + sync queue + tests.
- Golden/CI flakiness — deferred until a stable harness exists.
- Two-codebase drift — shared tokens + shared API contract mitigate.

**For the next phase (Phase 2 — Auth):** the app shell + Riverpod + theme are ready to host auth
state. Plan: reuse the existing opaque session token as the **mobile bearer token** (extend
`readSessionToken` to accept `Authorization: Bearer <token>`; return the token in login/register
response bodies) — simpler and more revocable than JWT, reuses the sessions table. Add secure storage,
a dio client with the bearer + refresh-on-401, auth Riverpod state, login/register/guest screens, and
bind the Profil header to the signed-in user.

---

## Phase 2 — Mobile Auth (2026-07-23)

**Completed:** Bearer-token mobile auth end-to-end. Backend (backward-compatible): `readSessionToken`
also accepts `Authorization: Bearer <64-hex>`; `login`/`register` routes also return the session
`token` in the JSON body (cookies untouched). Mobile: `AppConfig.apiBaseUrl`
(`--dart-define=API_BASE_URL`, default prod); `TokenStore` (Secure + Memory); `dio` client + bearer
interceptor (clears token on any 401); `AuthApi`/`DioAuthApi`; `AppUser`; `AuthController`
(`Notifier<AuthState>`, non-blocking boot resolve via `/api/auth/me`); `/auth` login/register screen;
Profil header bound to auth state; input theming; theme mode now persisted via `shared_preferences`.

**Architecture decisions:**

- **Bearer = the existing opaque session token** (NOT JWT+refresh). Session tokens are already random,
  SHA-256-hashed at rest, 30-day, multi-device, server-revocable — a second token type would add a
  refresh endpoint + rotation bugs for zero gain. Backend change stays 100% backward-compatible; web
  keeps using cookies, mobile reads the same token from the body.
- **Auth is additive, never a gate.** `AuthController.build()` returns `unknown` + resolves in a
  microtask; the shell renders immediately as guest and upgrades to authenticated. Guests keep full
  app access.
- **Contract seams for tests:** `TokenStore` + `AuthApi` interfaces overridden with in-memory/fake
  impls → zero platform channels / network in the suite. `pumpApp` test helper mocks SharedPreferences
  and overrides `tokenStoreProvider`/`authApiProvider`.
- 401 handling is centralized in the dio interceptor (clears token) — controllers don't each re-check.

**API decisions:** `POST /api/auth/{login,register}` → `{ user, token }` (+ `Set-Cookie` for web).
`GET /api/auth/me` (bearer) → `{ user }`. `POST /api/auth/logout` (bearer, best-effort). Mobile stores
`token` under secure-storage key `ea_session_token`.

**Packages added:** `dio`, `flutter_secure_storage`, `shared_preferences`.

**Lessons learned / problems solved:**

- **On-device happy-path needs the backend live first.** Production didn't yet return `token`, so the
  client (correctly) rejected the tokenless response with "Beklenmeyen sunucu yanıtı." — proof the
  client validates the server contract, but it means the authenticated happy-path can only be
  device-validated **after** the backward-compatible backend deploys. Sequencing rule for any phase
  that changes an API the app calls: **deploy the backend change, then device-validate the happy path.**
- **adb blind-tap form entry is fragile** — the soft keyboard shifts the scroll view, so a tap
  coordinate captured before the keyboard opened lands on the wrong field (the E-posta field silently
  stayed empty on the first register attempt). Fix: enter fields top-to-bottom, re-tap each field
  _after_ the keyboard is already up (using the on-screen, above-keyboard position), and screenshot to
  verify each value before submitting.
- `flutter analyze` flagged an unused `package:flutter/widgets.dart` import in the test helper →
  removed → clean.

**Known limitations / technical debt:**

- No mobile "forgot password" / email-verification UI yet (backend supports verification; mobile
  deep-link handling deferred to a later phase).
- Real user-data sync (`/api/state`) is NOT in Phase 2 — identity only. Data binding starts Phase 3+.
- Two junk test accounts (`mobil-p2-*@ea.dev`, `mobilp2*@ea.dev`) were created against the prod DB
  during device validation (register hit prod before the token change; throwaway `@ea.dev` addresses).
  Harmless; note for any future "test-account cleanup" pass.

**Risk register (rolled forward):** unchanged from Phase 1 — IAP/billing (Phase 7) highest; offline
sync correctness (Phase 3/4); golden/CI flakiness (deferred); two-codebase drift (mitigated by shared
tokens + shared API contract, now also a shared auth token).

**Post-deploy device validation (bearer happy-path) — CONFIRMED (2026-07-23):** after the Phase 2 push
(commit `26a88da`) went green on all three workflows (CI, Mobile CI, CodeQL) and Vercel deployed the
backward-compatible `token` change, the full auth lifecycle was validated on the real device
(`AYXSUKIVJVPZ7HPZ`) against **production** `https://www.ehliyetegitim.com`, using a rebuilt-from-HEAD
debug APK and a throwaway account created via the deploy probe (`deploychk-5589570@ea.dev`):
(1) guest Profil shows "Misafir" + "Giriş yap / Kayıt ol"; (2) login → Profil shows name "DeployCheck",
email, initials "DE", and "Çıkış yap"; (3) force-stop + relaunch → **still authenticated** (secure token
read on boot, re-validated via `/api/auth/me`); (4) "Çıkış yap" → back to guest, token cleared. Deploy
sanity via curl beforehand: `register`→201 `{user,token}` (64-hex), `login`→200 `{user,token}`, Bearer
`/me`→200. Phase 2 fully device-validated end-to-end.

**For the next phase (Phase 3 — Content & Learn):** authenticated `dio` client + bearer interceptor are
ready; auth state is app-wide. Build a content snapshot API + lessons / traffic signs (121 SVG) /
vehicle / videos screens + offline caching. Reminder: signs are 121 SVGs — plan an asset-bundling +
offline-cache strategy; do NOT verbatim-import copyrighted MEB/third-party content.

---

## Phase 3 — Content & Learn (2026-07-23)

**Completed:** Offline-first Learn section end-to-end. Backend: `GET /api/mobile/content-snapshot`
(public, additive) serializes the static content arrays (19 lessons, 121 signs, 70 vehicle parts, 6
videos) with a deterministic sha256 `version` + ETag/304. Mobile: freezed content models; drift
(SQLite) offline cache behind a `ContentLocalStore` interface; offline-first `ContentRepository`;
faithful Dart port of the 121-sign renderer; Lessons/Signs/Vehicle/Videos list+detail screens; nested
go_router routes; `MarkdownText` for content `**bold**`.

**Architecture decisions:**

- **Content = a single versioned snapshot document**, not per-resource APIs — content is static +
  non-user-specific, so one cacheable JSON + ETag delta is the correct offline model. (Questions stay
  separate; they come in Phase 4.)
- **drift honored as the local DB (rule #10)** but **abstracted behind `ContentLocalStore`** →
  `flutter test` uses an in-memory fake (no native sqlite on the host/CI); the real drift store is
  device-validated. Phase 4 extends the SAME `AppDatabase` (`data/local/app_database.dart`) with
  relational SRS/attempt/exam tables — that is where drift earns its keep.
- **Signs: reconstruct the exact web SVG string in Dart + flutter_svg**, NOT a hand-rolled CustomPainter
  — copying the verbatim path `d` data maximizes fidelity and minimizes transcription error. Text
  (glyphText / `DUR` / `YOL VER`) is overlaid as Flutter widgets because flutter_svg `<text>` is
  unreliable. Shape foreground: white on disc/rect-blue/rect-green, else dark (matches web `fgFor`).
- **Codegen files are committed** (freezed/json/drift `*.g.dart`/`*.freezed.dart`) because Mobile CI runs
  analyze+test+build **without** build_runner. `.gitignore` does not exclude them (verified).

**API decisions:** `GET /api/mobile/content-snapshot` → `{ version, generatedAt, counts, lessons, signs,
vehicleParts, videos }`; ETag = `"<version>"`; `If-None-Match` match → 304 (empty body). Videos are
self-hosted under `/videos/*` at the origin; the mobile client resolves relative media paths against
`AppConfig.apiBaseUrl` (mp4 serves **206** range requests → streaming; posters 200).

**Packages added:** `flutter_svg`, `video_player`, `drift`, `drift_flutter` (+ `sqlite3_flutter_libs`),
`freezed`/`freezed_annotation`, `json_serializable`/`json_annotation`, dev `build_runner`, `drift_dev`.

**Lessons learned / problems solved:**

- **freezed 3.x syntax**: `@freezed abstract class X with _$X { const factory X({...}) = _X; factory
X.fromJson(...) => _$XFromJson(...); }`. Enum wire values via `@JsonValue('...')` on constants
  (Turkish/hyphenated: `'çok yüksek'`, `'inv-triangle'`, `'motor-bolmesi'`).
- **explicitToJson is OFF by default** → `model.toJson()` leaves nested objects un-serialized until
  `jsonEncode`. The cache path round-trips via `jsonEncode`/`jsonDecode` (raw network Map), so it is
  correct; tests must round-trip the same way, not `fromJson(toJson())` directly.
- **AppCard `accent:` broke inside a scroll view** — a bare `crossAxisAlignment: stretch` Row forces
  infinite height in an unbounded-height ListView. Fixed by wrapping the accent Row in `IntrinsicHeight`
  (the standard full-height-accent-bar pattern); only affects the accent path.
- **Widget-test fold**: off-screen ListView items are disposed → use `scrollUntilVisible` before
  asserting/tapping below the 800×600 test fold.
- **Riverpod 3.x**: `AsyncValue.value` (nullable), not `valueOrNull`.
- **Device validation caught raw `**bold**`** in lesson/sign/vehicle prose (content is markdown-light;
  the web renders it via `mdBold`). Fixed with a `MarkdownText` primitive applied to all content prose.

**Known limitations / technical debt:**

- Vehicle **photos** not shown on mobile (`photo` is a web asset-manifest id, not a snapshot URL) —
  detail is text-first (complete). Bundling vehicle photos is a later enhancement.
- **Scenarios** excluded (Phase 3 scope = lessons/signs/vehicle/videos); available for a later phase.
- **Pre-existing 5px bottom overflow** on Home "Hızlı işlemler" quick-action cards (Phase 1 screen, not
  touched here; debug-only banner) → fix in Phase 9 (Final Polish).
- `hillUp` glyph's embedded `%10` relies on flutter_svg `<text>` (best-effort); the hill shape reads fine.

**Risk register (rolled forward):** IAP/billing (Phase 7) highest; **offline sync correctness now
partly de-risked** (content snapshot is atomic + versioned; Phase 4 SRS/attempt sync is the harder part);
golden/CI flakiness (deferred); two-codebase drift (mitigated by shared tokens + shared API contract).

**Device-validation summary (production, rebuilt-from-HEAD APK):** hub counts 19/121/70/6; all sign
shapes/glyphs/text overlays (incl. `DUR` octagon, `YOL VER` inv-triangle, speed rings, `GÜMRÜK`, Ana Yol
diamond); search + empty state; sign/lesson/vehicle details (compare table + markdown bold render
correctly); videos list (posters from prod) + **video player streaming/playing** with seekable chapters.

**For the next phase (Phase 4 — Practice & Exams):** extend `AppDatabase` with drift tables for SRS
scheduling, per-question attempts, and exam sessions; add an exam-build API; build SRS practice, a
50-question exam runner, collections, and historical exams — offline. The question bank (~1562 Qs) is
separate from the content snapshot; decide bundle-vs-fetch for questions (they are static + large).

---

## Phase 4 — Practice & Exams (2026-07-23)

**Completed:** Offline-first practice + exams end-to-end. Backend: public `GET
/api/mobile/question-bank` (lean 1562-question projection + `EXAM_BLUEPRINT`, sha256 version + ETag/304).
Mobile: the learning-science engine PORTED to Dart (runs offline from the cached bank) + SRS study
runner, 50-Q exam runner, collections, historical screens.

**Architecture decisions:**

- **Port the pure logic, cache the data.** SM-2, `buildExam`/`scoreExam`, mulberry32 `seededRng`, FNV-1a
  `hash32`/`seedFromDate` are small pure fns with server tests → ported to `domain/practice/{srs,exam,
collections,historical}.dart` and unit-tested to spec. The question bank is the only new backend
  surface. Practice/exams are fully deterministic + **offline** (no per-action server calls).
- **Reuse the Phase-3 drift DB** (`AppDatabase.getDocument/putDocument`) for the question-bank document
  (key `question-bank`) via a parallel `QuestionLocalStore` (Drift + Memory-fake for tests). NOTE:
  `appDatabaseProvider` lives in `data/content/content_repository.dart` — question repo imports it from
  there (don't duplicate).
- **Progress** (`ProgressRepository`, shared_preferences) mirrors the web `ea:*:v1` shapes exactly
  (`ea:cards:v1` = questionId→SrsCard, `ea:answers:v1` = AnswerLog[] cap 2000, `ea:streak:v1`,
  `ea:counters:v1`) + a safe cross-device merge on login. `StateSync` (`/api/state`, Bearer) is
  best-effort last-write-wins, no-ops offline/guest.
- **Collections use direct field filters** (subject/difficulty/topic-contains-'isaret') instead of
  porting the web's analyzed/quality layer — smaller port, correctly themed, deterministic.
- **Exam runner is one screen** for standard/collection/historical (via an `ExamSource` enum + id);
  builds the exam ONCE in the data callback (guard flag) to avoid re-shuffle on rebuild. Timer =
  1 s `Timer.periodic`, cancelled on finish/dispose (no pending-timer error in tests; pumpAndSettle does
  not advance fake time enough to fire it).

**API decisions:** `GET /api/mobile/question-bank` → `{ version, generatedAt, count, blueprint,
questions[] }`. Questions have NO images (all text) — confirmed. Bank counts: trafik 380, ilkyardim 303,
motor 310, adab 272, pratik 297 (pratik excluded from theory exams).

**Lessons learned / problems solved:**

- **JS 32-bit ops in Dart**: ported `Math.imul` (16×16 split) + kept everything masked to `& 0xFFFFFFFF`
  with `>>>` so mulberry32 / FNV-1a reproduce JS bit-for-bit. (Exact server match isn't required for
  mobile determinism, but it's free with careful masking.)
- SM-2 float math matches JS (both IEEE754); use `closeTo` in tests for `ease`.
- `flutter analyze` flagged an unused import after refactors twice — keep imports tight.

**Known limitations / technical debt:**

- Exam **result screen** validated via widget test (5-Q shortened exam → KALDIN + Başarı), not
  screenshotted at 50-Q on device (impractical to finish by hand); build/timer/nav were device-validated.
- State sync = best-effort last-write-wins + safe merge; full conflict-free sync + entitlements later.
- Collections membership can differ from web (no analyzed layer) — both deterministic + themed.
- Home quick-actions 5px overflow (Phase 1) still deferred to Phase 9.

**Risk register (rolled forward):** IAP/billing (Phase 7) highest; **offline correctness now largely
de-risked** (content + questions atomic/versioned; SRS/exam deterministic + unit-tested); golden/CI
flakiness (deferred); two-codebase drift (mitigated — SRS/exam/scoring ported and tested to spec).

**Device-validation summary (production, rebuilt-from-HEAD APK):** hub (4 areas, no dead nav); SRS study
(real first-aid Q → correct green ✓ + "Doğru!" + explanation, persisted); Deneme Sınavı (50-Q built,
timer 44:56, question map, options, nav); Koleksiyonlar (real counts: 50/50/40/40/29/40/40); Geçmiş
Sınavlar (18 sessions grouped by year).

**For the next phase (Phase 5 — AI Coach & Notifications):** add a coach-nudge API (uses the existing
Anthropic key server-side; AI content stays `review:'draft'`, never auto-published), a chat screen +
proactive coach cards personalized from local answers/SRS/readiness, and push/local notifications (FCM +
flutter_local_notifications). Reminder: app-store IAP is Phase 7; notifications need a push token
registered server-side.

---

## Phase 5 — AI Coach & Notifications (2026-07-23)

**Completed:** Real AI Koç (deterministic offline nudges + grounded chat) + local notifications. Backend:
`POST /api/ai/ask` extended with optional `context` (backward-compatible; question tokens preserved so
retrieval/grounding unaffected). Mobile: nudge engine, coach chat, MarkdownBlock, local notifications +
settings.

**Architecture decisions:**

- **"Deterministic brain, natural voice" (AI_MOBILE_BEHAVIOR).** Nudges are computed ON-DEVICE in Dart
  (`domain/coach/nudge.dart` `computeNudges` — pure, offline) from local Readiness/streak/due-cards; the
  LLM only does free-form grounded Q&A. No new nudge server endpoint needed (all signals are local).
- **Reuse `/api/ai/ask`** (no auth, IP rate-limited, JSON not SSE) directly from the mobile Bearer dio
  client. Server does the real Anthropic call (`claude-haiku-4-5`) + hallucination gate + mock fallback.
  In tests, no key → gate/mock (no network) → integration test is provider-independent.
- **FCM push = documented environment blocker** (like iOS-on-Linux): NO Firebase config
  (google-services.json/firebase_options.dart), NO server FCM credentials, NO push-token DB table exist.
  Local notifications are the working lane; server push + `pushSubscriptions` table + registration endpoint
  are a scoped follow-up. Do NOT claim FCM works.
- **MarkdownBlock vs MarkdownText**: lesson prose uses only `**bold**` → inline `MarkdownText`. LLM coach
  answers use full markdown (headings/lists/hr) → new block renderer `design/markdown_block.dart`. (Found
  on device: inline renderer showed `#`/`---`/`- ` literally.)

**Packages added:** `flutter_local_notifications` (22.x), `timezone`. Android config: POST_NOTIFICATIONS +
RECEIVE_BOOT_COMPLETED perms, ScheduledNotification(+Boot)Receiver in manifest, **core-library
desugaring** in `android/app/build.gradle.kts` (`isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs`).

**API decisions:** `/api/ai/ask` body `{ question, context? }` → `{ answer, grounded, sources, model }`.
Chat persisted locally `ea:chat:v1` (cap 40); notification prefs `ea:notifications:v1` (enabled/hour/minute).

**Lessons learned / problems solved:**

- **flutter_local_notifications 22.x is all named params**: `initialize(settings:)`, `show(id:title:body:
notificationDetails:)`, `zonedSchedule(id:scheduledDate:notificationDetails:androidScheduleMode:)`,
  `cancel(id:)`. Timezone hardcoded `Europe/Istanbul` (Turkish app) → no flutter_native_timezone dep.
  Inexact scheduling (`AndroidScheduleMode.inexactAllowWhileIdle`) → no SCHEDULE_EXACT_ALARM permission.
- **StreakState moved from `data/practice/progress_repository.dart` → `domain/practice/srs.dart`** so the
  domain nudge engine can use it without a domain→data import.
- Device is API 30 (Android 11) → POST_NOTIFICATIONS runtime prompt not required; notifications show by
  default. On API 33+, `requestNotificationsPermission()` handles it (wired in `setEnabled(true)`).

**Known limitations / technical debt:**

- FCM push N/A on this host (see above). Scheduled reminder validated via immediate "test" + code path,
  not waited out at wall-clock. Sparse-data weak-subject nudge can read "%100 ustalık" oddly (refine:
  min answered-per-subject before flagging). Home 5px overflow (Phase 1) still deferred to Phase 9.

**Risk register (rolled forward):** IAP/billing (Phase 7) highest — needs real store accounts +
`pushSubscriptions`-style infra parallels; FCM/push infra deferred; offline correctness de-risked; golden
tests deferred.

**Device-validation summary (production):** `/api/ai/ask?context` → real grounded Anthropic answer; AI Koç
nudges from real practice (Hazırlık %13, weak-subject); chat → grounded answer with markdown headings/
lists/bold; notification settings + a local notification fired in the shade.

**For the next phase (Phase 6 — Progress & Gamification):** build readiness radar (per-subject from
`computeReadiness`), XP/levels + a study heatmap (from `ea:answers:v1` timestamps), achievements, and a
study plan. All data is already local (progress repo). Optional `progress summary API` per roadmap — but
on-device computation (like nudges) is the offline-first default.

---

## Phase 6 — Progress & Gamification (2026-07-23)

**Completed:** On-device progress + gamification (no backend change). Gamification domain (XP/levels/
achievements/heatmap), a Progress screen (radar + heatmap + XP + badges), and the Home dashboard rebound
to REAL local data.

**Architecture decisions:**

- **On-device computation, not a server "progress summary API"** (roadmap marked it optional). All signals
  are local (Phase 4 progress repo) → progress/gamification is offline + instant + deterministic, matching
  the coach nudge engine. No deploy this phase.
- **CustomPainter charts, no chart package**: `ReadinessRadar` (4-axis spider, grid rings, data polygon)
  and `StudyHeatmap` (7×N-week grid, intensity by daily answer count) are hand-drawn with design tokens
  (light+dark). Zero new dependencies.
- **Home is now a ConsumerWidget** bound to `progressRepositoryProvider`: readiness ring/message
  (`computeReadiness`), streak, answered/accuracy/level, top `computeNudges` card, today's plan
  (studied-today + due-card count), deep-linked quick actions. Graceful "get started" copy before data.

**Domain (`domain/progress/gamification.dart`):** `xpFromAnswers` (correct=10, wrong=3); `levelForXp`
(level L starts at `50*L*(L-1)` XP → 0/100/300/600/1000…) with `LevelInfo.progress`/`xpToNext`;
`computeAchievements` (7 deterministic badges); `answersPerDay` (local day → count).

**Lessons learned / problems solved:**

- **Two-scrollable widget tests**: Home has a nested `GridView` (quick actions) and Progress has the
  heatmap's inner horizontal `SingleChildScrollView` → `scrollUntilVisible` must pass
  `scrollable: find.byType(Scrollable).first` (the outer list) to avoid "Too many elements"/ambiguous.
- `pumpApp` gained a `prefs` param to seed `ea:*` keys (SharedPreferences.setMockInitialValues) for the
  populated progress-screen test.

**Known limitations / technical debt:**

- Radar axis label can overlap the data dot at sparse (single-subject) data — cosmetic, refine offset in
  Phase 9. Home quick-actions 5px overflow (Phase 1) still deferred to Phase 9.

**Risk register (rolled forward):** IAP/billing (Phase 7) highest — real store-signed IAP needs Play
Console products + store connection; expect a documented partial on this host (build the flow + validate
contract + unit tests, like FCM/iOS). Offline correctness de-risked; golden tests deferred.

**Device-validation summary:** Home real data (readiness %13, streak 1, 1 soru/%100/Lv1, nudge, plan);
Progress screen (Seviye 1 10XP, radar with İlk Yardım 100%, heatmap today-cell, badges 1/7 İlk Adım).

**For the next phase (Phase 7 — Premium / IAP):** add native `in_app_purchase` (Play Billing), a purchase
flow (products from `apps/web/lib/products.ts` / capabilities like `sinirsiz-deneme`), an
`/api/iap/validate` backend endpoint (verify the store receipt server-side → grant entitlement in
`purchases` table), and entitlement sync to `ea:entitlements:v1`. Gate premium content
(`Lesson.premium`, free exam/AI quotas — web uses `lib/payments.ts` `FREE_AI_DAILY`/exam quota). App-store
IAP is REQUIRED for digital goods (LemonSqueezy web checkout can't ship in-app). Real store validation
needs a signed build + Play Console; document honestly what can't be end-to-end tested on this host.

---

## Phase 7 — Premium / IAP (2026-07-24)

**Completed:** Premium monetization surface. Backend `POST /api/iap/validate` (Bearer, catalog integrity,
idempotent grant, FAIL-CLOSED in production). Mobile: products/capabilities/entitlements/quotas (Dart
port), entitlements repo, in_app_purchase service, paywall, premium-lesson gating, AI+exam quota gates.

**Architecture decisions:**

- **Ownership derived from server, NEVER a synced key** (web P0: a synced `ea:entitlements:v1` could leak
  between users on a shared device). Mobile `EntitlementsController` re-derives from `GET /api/purchases`
  → owned list → caches `ea:entitlements:v1` (SET, server wins). `hasCapability(owned, cap)` drives gates.
- **Server: catalog price integrity + idempotent insert** (unique(user,product)), `provider:'google_play'`,
  `externalRef=purchaseToken` — same pattern as the LemonSqueezy webhook (a 4th provider path).
- **FAIL-CLOSED (SECURITY):** real Play token verification needs a Google service account (absent here).
  Grants without verification are allowed ONLY when `NODE_ENV!=production` (or `IAP_DEV_ACCEPT=1`);
  production returns **503**. Closed a hole where any Bearer user could self-grant premium. Verified live:
  prod `/api/iap/validate` → 503. Mirror of the mock-payment `paymentConfigured` guard.
- **Free-tier quotas** (`QuotaRepository`): 5 AI/day + 1 exam/day (`ea:aiQuota:v1`/`ea:examQuota:v1`,
  `{day,count}`), bypassed by `ai-sinirsiz`/`sinirsiz-deneme`. Gated in coach send + practice-hub exam tile.

**Packages added:** `in_app_purchase` (3.x).

**Lessons learned / problems solved:**

- **`vitest` does NOT run `tsc`** — a `process.env.NODE_ENV='production'` assignment passed vitest but
  FAILED CI typecheck (TS2540 read-only). FIX: use `vi.stubEnv('NODE_ENV', ...)` + `vi.unstubAllEnvs()`
  (type-safe + no cross-test pollution). **ALWAYS run `pnpm --filter @ea/web typecheck` before pushing
  web changes**, not just vitest.
- **Deployed a security hole first** (dev-accept granted premium to any user in prod). Caught during
  device/curl validation → added the fail-closed guard + redeployed + re-verified 503. Lesson: an
  IAP-validate endpoint MUST fail closed when verification isn't configured.

**Known limitations / technical debt:**

- **Real Play purchase UNTESTABLE on this host** (documented, like iOS/FCM): needs Play Console + 5 managed
  products (`premium_teori`/…/`komple_b`) + a signed AAB installed from Play + `GOOGLE_PLAY_SA_JSON` for
  server verification. Flow/contract/gating/quotas built + tested; purchase round-trip is store-gated.
- iOS/StoreKit path unbuilt (no macOS). A throwaway account got premium-teori during dev-mode testing
  (before fail-closed) — note for test-data cleanup. Home 5px overflow (Phase 1) still deferred to Phase 9.

**Risk register (rolled forward):** IAP now BUILT but store-gated (go-live needs Play Console + signing +
service account). golden tests deferred; offline correctness de-risked. Phase 8 release build needs a
signing keystore (may be a documented partial).

**Device-validation summary:** Paywall renders (5 packs, Komple B "EN AVANTAJLI" 449₺, honest "Mağaza
kullanılamıyor" + disabled Satın al, Geri yükle). Prod curl: validate (dev) granted + restore returned it;
post-fix validate → 503. Lesson-lock + quota logic unit/widget tested.

**For the next phase (Phase 8 — Onboarding & Launch Prep):** premium onboarding flow (first-run
walkthrough), store assets/metadata (icon exists at `@mipmap/ic_launcher`; screenshots/description), and a
RELEASE build (`flutter build apk --release` / appbundle). Release signing needs a keystore
(`android/key.properties` + keystore file) — if absent, document as a partial (debug-signed) like IAP/iOS.
Also: offline hardening pass (verify all screens degrade gracefully offline), and wire the 5px Home
overflow fix here or defer to Phase 9. App id `com.ehliyetegitim.ehliyet_akademi`.

---

## Phase 8 — Onboarding & Launch Prep (2026-07-24)

**Completed:** First-run onboarding, Home overflow fix, release build validation, store metadata. No
backend change.

**Architecture decisions:**

- **Onboarding via a go_router `redirect`** gated on `ea:onboardingSeen:v1`. The seen-flag is read
  SYNCHRONOUSLY in `main()` (`readOnboardingSeen()`) and injected via
  `onboardingSeenProvider.overrideWith(() => OnboardingController(seen))` → no intro flash for returning
  users. `_buildRouter(ref)` now takes `ref` for the redirect (uses `ref.read`, not watch, to avoid router
  rebuilds). `markSeen()` sets state + persists, then `context.go('/home')`. Route `/onboarding`.
  `pumpApp` gained an `onboardingSeen` param (default true) so existing tests still boot on Home.
- **Home 5px overflow (Phase 1 debt) FIXED**: quick-actions `GridView childAspectRatio 0.82 → 0.72`.

**Build/launch facts:**

- **Release APK builds**: `flutter build apk --release` → ~66 MB universal (debug-signed; fonts
  tree-shaken 99%). Debug ~205 MB. Play artifact = `flutter build appbundle` (per-device ~20-25 MB).
- **Production signing needs a keystore** (`android/key.properties` + `.jks`) — ABSENT here → documented
  partial (like IAP/iOS). `STORE_LISTING.md` has the Play metadata + go-live checklist (5 managed product
  ids `premium_teori`/…/`komple_b`, `GOOGLE_PLAY_SA_JSON`, keystore, 512² icon, feature graphic, privacy
  URL).

**Lessons learned:** installing a release APK over a debug one works only because release uses the debug
signingConfig (same key). `adb shell pm clear <pkg>` resets `ea:onboardingSeen:v1` → true first-run test.

**Known limitations / technical debt:** store signing/upload untestable here (keystore + Play Console).
iOS/StoreKit N/A. Radar label-overlap (Phase 6) + micro-polish deferred to Phase 9.

**Device-validation summary (release build, cleared data):** onboarding first slide → Devam×3 → Başla →
Home; quick-actions render with NO overflow (fix confirmed); fresh Home shows welcome nudge + plan.

**For the FINAL phase (Phase 9 — Final Polish & Delight):** a senior pre-launch review pass, NOT new
features. Sweep: (1) micro-interactions/animation consistency (AppMotion curves), (2) every empty/error/
loading state, (3) offline hardening — verify all screens degrade gracefully with no network (content +
question repos are offline-first; check coach/paywall/entitlements handle offline), (4) accessibility —
tap-target sizes, contrast in light+dark, Semantics labels for icon-only buttons, (5) fix the radar
axis-label overlap (`readiness_radar.dart` label offset at sparse data), (6) final consistency check
across all screens. Then generate a COMPREHENSIVE FINAL implementation report summarizing the entire
mobile transformation (all 9 phases, architecture, testing, CI/CD, device validation, limitations, launch
readiness) — the user explicitly requested this at 100%.

---

## Phase 9 — Final Polish & Delight (2026-07-24) — FINAL PHASE

**Completed:** Senior pre-launch review pass (no new features). No backend change.

- **Radar:** directional axis-label placement (right→left-align, left→right-align, top/bottom center) so
  a label never overlaps the data dot at sparse data (Phase 6 known issue fixed); `Semantics` summary.
- **Accessibility:** `Semantics(label:'Gönder', button:true)` on the coach send button; `tooltip` on the
  signs-search clear button.
- **Offline hardening (verified):** dio already has `connectTimeout` 12s / `receiveTimeout` 20s; content +
  question repos are offline-first (cached content renders with no network); no-cache-while-offline →
  loading→retry (no crash). Confirmed on-device in airplane mode.

**flutter analyze 0; flutter test 79.** Device: airplane-mode offline check passed (Home + cached render;
cold no-cache screen shows loading→retry gracefully).

**COMPREHENSIVE FINAL REPORT written:** `MOBILE_FINAL_IMPLEMENTATION_REPORT.md` — the full 9-phase
transformation summary (architecture, feature inventory, 79 flutter + 21 backend integration tests, 3
green CI workflows, real-device validation per phase, honest infra-gated limits: iOS N/A, FCM N/A, real
Play IAP + store signing pending Play Console/keystore/service-account, golden tests deferred, launch
checklist).

**MOBILE TRANSFORMATION COMPLETE — 9/9 phases, all CI-green + device-validated.** Backend endpoints added:
Bearer auth, `/api/mobile/content-snapshot`, `/api/mobile/question-bank`, `/api/ai/ask` (+context),
`/api/iap/validate` (fail-closed). Packages: go_router, flutter_riverpod, dio, flutter_secure_storage,
shared_preferences, flutter_svg, video_player, drift/drift_flutter, freezed/json_serializable,
flutter_local_notifications, timezone, in_app_purchase. Release APK ~66 MB (debug-signed). To ship:
keystore + Play Console 5 managed products + `GOOGLE_PLAY_SA_JSON` + store assets (see STORE_LISTING.md).
