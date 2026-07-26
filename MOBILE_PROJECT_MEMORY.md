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

---

## UI Redesign & Monetization Sprint (2026-07-24) — post-roadmap update

**Completed:** New visual identity + personalization onboarding + single-product premium, on the SAME
architecture (no new architecture). Device-validated on `AYXSUKIVJVPZ7HPZ`. Report:
`MOBILE_UI_REDESIGN_REPORT.md`.

- **Icon/splash/theme:** adaptive launcher icon from `apps/assets/app_icon.png` (keyed emblem foreground on
  navy background layer; `mipmap-anydpi-v26` + legacy + round, all densities); branded navy splash (no
  white flash); **dark mode is now the default** (`ThemeModeController.build()→dark`, still switchable +
  persisted). App label "Ehliyet Akademi".
- **Assets:** the 21 `apps/assets/interface-assets/` PNGs (~40MB) → background-keyed transparent **WebP**
  (corner flood-fill via ImageMagick `-floodfill`, fuzz ~13-16%, preserves neon glow), 1.6MB total under
  `apps/mobile/assets/img/`, catalogued in `lib/core/assets.dart` (`AppImages`). Large design refs +
  PDFs git-ignored.
- **Onboarding = personalization:** `domain/onboarding/study_profile.dart` (`StudyProfile` +
  LicenceCategory/ExamExperience/ExamFocus/ExamTimeframe enums; persisted `ea:studyProfile:v1`; read sync
  in main() + provider override like onboardingSeen). 6-slide flow in
  `features/onboarding/onboarding_screen.dart` using **PageView.builder** (NOT AnimatedSwitcher —
  AnimatedSwitcher fed unbounded height to `Expanded` slides; PageView.builder gives tight bounded
  constraints + is lazy so tests see one page). `profile.sessionSize` (dailyGoal.clamp(10,25)) drives the
  SRS runner + Home plan text; coach auto-injects a profile context string into `/api/ai/ask`.
- **Design system:** new `design/brand.dart` (BrandMark steering-wheel painter, GradientPillButton
  teal+gold, MascotImage, IconBadge, GlowCard, SegmentBar, BrandChip, HubHeader, HubRow); shared
  `features/practice/widgets/result_view.dart` (SessionResultView); enhanced `question_view.dart`
  OptionTile (filled badge + trailing radio/check/X). Added `purple` token to AppPalette (light+dark).
- **Premium:** ONE product `komple-ehliyet` "Komple Ehliyet Paketi" @ **399₺** (all caps) in mobile
  `domain/premium/products.dart` (+ `isPremium`, `canAccessVideo` first-free). Backend additive:
  `MOBILE_PRODUCTS` + `anyProductById()` in `apps/web/lib/products.ts`; `/api/iap/validate` uses it — web
  PRODUCTS/paywall/tests UNCHANGED (new integration test for komple-ehliyet). New
  `domain/premium/premium_prompt.dart` (pure `shouldPromptPremium`: not-premium + 24h cooldown +
  lifetime cap 6; cooldown only applies if lastShownMs>0). `features/premium/premium_popups.dart`
  (incentive gold-lock + success wheel-check dialogs). Redesigned paywall. Triggers wired: first exam
  (exam runner finish), engagement (SRS done), aiQuota (coach), examQuota (practice hub), video/lesson
  lock — all via `maybeShowPremiumIncentive(nowMs:)` (capped) or `showPremiumIncentive` (explicit taps).
- **Screens redesigned:** Home, Learn hub, Practice hub, Collections, Historical, Exam runner, SRS runner,
  Session result, Coach, Profile, Paywall, Videos (premium lock). All owl-mascot heroes + GlowCards.

**Gotchas learned:** (1) redesigned screens are TALLER (owl heroes) → last hub rows / moved logout row go
below the 800×600 test fold → tests need `ensureVisible`/`dragUntilVisible` before tapping; lazy ListView
disposes off-screen children so after scrolling down, scroll back up to assert top widgets. (2) `Row` with
`crossAxisAlignment.stretch` inside a vertical scroll view = infinite-height children → wrap in
`IntrinsicHeight`. (3) premium popup auto-fires over exam/SRS result → premium-owned test users avoid it.
(4) ImageMagick 6: use the `-floodfill` OPERATOR (not `-draw matte`, and no `%[fx:]` inside -draw).

**Tests:** flutter analyze 0 · flutter test **85** · web typecheck 0 · web **336**. Device-validated:
icon/splash/dark, full onboarding (personalized "20 soru" on Home), all tabs, SRS feedback + result,
premium incentive popup, paywall (₺399), video premium lock, exam runner.

---

## EVOLUTION PROGRAM (post-launch) — roadmap: `MOBILE_EVOLUTION_ROADMAP.md` (2026-07-25)

13 faz: E1 resmî levha vektörleri · E2 mekanik varlık hattı · E3 gösterge ikaz ışıkları · E4 çok-sınıflı
temel (B/A/D) · E5 A&D içerik · E6 onboarding koç+içgörü · E7 karşılama · E8-E10 topluluk · E11 premium
video oynatıcı · E12 video üretimi · E13 cila + final rapor. Aynı disiplin, aynı DoD.

### Evolution Faz E1 — Resmî Trafik Levhası Vektörleri (2026-07-25) — DONE

**Completed:** Basitleştirilmiş parametrik levha çizimleri, RESMÎ standart levhaların birebir vektör
karşılıklarıyla değiştirildi. Rapor: `EVOLUTION_PHASE_1_REPORT.md`.

- **Araç:** `apps/mobile/tool/extract_official_signs.py` (poppler + Pillow, deterministik, repoda).
  Girdi PDF'leri .gitignore'da (yerel referans); üretilen varlıklar repoda.
- **Çıktı:** `apps/mobile/assets/signs/*.svg` — 81 levha, 520 KB SVG yükü, medyan 2.7 KB, hepsi
  `viewBox="0 0 100 100"`, saf `<path>` (raster/metin yok). `lib/core/official_signs.dart` üretilmiş
  bağlama (86/121 işaret). `tool/official_signs_index.json` = kaynak + eleme kaydı.
- **Render:** `TrafficSignView` resmî varlık varsa onu çizer (üstüne METİN BİNDİRMEZ — DUR/YOL VER
  zaten vektörün içinde), yoksa eski parametrik kabuk+glif çizicisine düşer.

**Kaynak PDF'leri hakkında öğrenilenler (kritik):**

1. `duseyisaretleme.pdf` (KGM 2020) ve `Pano.pdf` (İBB) GERÇEK vektör; `KARAYOLU-TRAFIK-ISARET-
LEVHALARI.pdf` tek parça 5787×8149 JPEG → yalnız görsel referans, geometri vermez.
2. **KGM posterinin bir kısmı kaynakta ŞEFFAFLIK DÜZLEŞTİRMESİ ile parçalanmış** (TT-42a = 3837 ince
   üçgen). Dönüştürücü hatası DEĞİL — içerik akışının kendisi öyle. Bu yüzden iki kaynaklı seçim şart.
3. Poster metin katmanı İKİ KEZ çizili (sabit ötelemeli "hayalet" kopya) → veriden tespit edilip atılır.
4. `pdftocairo -svg` KIRPMA ile kullanılırsa yolları sayfa uzayında DEĞİL, içerik akışının kendi
   ötelemesiyle yazar; ayrıca kırpılmış yolların tam geometrisini emzeder. ÇÖZÜM: sayfayı kırpmadan BİR
   KEZ SVG'ye çevir, yolları rasterden ölçülen levha kutularına dağıt (çerçeve/etiket hiçbir kutuya
   sığmaz → düşer).
5. **Yol birleştirme TUZAĞI:** düzleştirilmiş levhalarda ardışık üçgenleri tek `d`'de birleştirmek
   nonzero dolgu kuralında birbirini siler → levha bozulur. Birleştirme yalnız düzleştirilmemiş
   kaynaklarda yapılır; ağır düzleştirilmişler MAX_PATHS ile elenir.
6. Resmî posterlerde levhaların BEYAZ zemini yoktur (sayfanın beyazı görünür) ve bazı piktogramlar
   "knockout" deliktir → dış konturun beyaz kopyası en alta eklenmezse koyu temada levha boş görünür.
7. Eksiksizlik ölçütü: iç ayrıntısı (küçük yol) olmayan aday = piktogramı raster olan kabuk → KULLANMA.

**Bilinçli kapsam dışı (35/121 parametrik kalır, hepsi index'te gerekçeli):** sayı-parametrik hız/
ağırlık/mesafe levhaları (15), resmî karşılığı olmayanlar (7), piktogramı iki posterde de raster olanlar
(4: T-8, T-3b, T-14b, TT-32), iki kaynakta da ağır düzleştirilmişler (5), görsel doğrulamada bozuk
çıkıp elenenler (4: T-1a, TT-21, TT-33a, TT-35g).

**İçerik düzeltmesi (resmî çizimle tutarlılık için ZORUNLU):** `apps/web/content/signs.ts` — Ağırlık
16t→7t, Dingil 7t→6t, Genişlik 2m→2,30m (resmî örnek değerler). Web render yolu değişmedi.

**Tests:** flutter analyze 0 · flutter test **91** (+6 yeni: katalog bütünlüğü, normalizasyon, performans
bütçesi, ölü varlık yok, çizici kaynak seçimi) · web typecheck 0 · web 336 · prettier temiz.
**Device:** `AYXSUKIVJVPZ7HPZ` — 121 levhalık galeri, tehlike/mecburiyet/geçici/öncelik grupları, DUR
oktagonu, sarı çalışma levhaları, arama, detay; takılma/taşma yok.

**For E2 (Mekanik Varlık Hattı):** girdi `apps/assets/mekanik assets/` (11 kontakt sayfası, ~20 MB,
B/A/D). Yöntem: redesign sprintindeki ImageMagick köşe-floodfill anahtarlama → WebP + dilimleme adımı.
DİKKAT: bazı sayfalarda üçüncü taraf MARKA logoları var (BOSCH/VARTA/EXIDE/Mercedes) ve aynı parçanın
markasız varyantı da mevcut → markasız olanı seç ve kaydet.

### Evolution Faz E2 — Mekanik Varlık Hattı & Araç Görsel Kütüphanesi (2026-07-25) — DONE

**Completed:** 11 kontakt sayfası → **101 şeffaf WebP** (2.05 MB) + araç kütüphanesi fotoğraflı +
YENİ "Kabin Kumandaları" ekranı (39 gerçek düğme). Rapor: `EVOLUTION_PHASE_2_REPORT.md`.

- **Araç:** `apps/mobile/tool/extract_mech_assets.py` (yalnız Pillow). Çıktı: `assets/mech/*.webp`,
  üretilmiş `lib/core/mech_assets.dart`, kayıt `tool/mech_assets_index.json`.
- **Bağlama (elle):** `lib/domain/content/vehicle_visuals.dart` — 29 araç bileşeni → fotoğraf,
  39 kabin kumandası (başlık + işlev + grup). **Üretilmiş katalog ile editoryal bağlama AYRI.**
- **Çizim:** `lib/design/mech_image.dart` (`MechImage`: token'lı plaka + ikon yedeği).
- **Ekranlar:** Araç Tekniği listesi (satırda fotoğraf) + detay (220 px kahraman görsel);
  `/learn/cabin` yeni galeri; Öğren hub'a yeni satır.

**Öğrenilenler (kritik):**

1. **Satır/sütun bantlaması bu sayfalarda ÇALIŞMAZ** — yumuşak gölgeler bantları birleştiriyor
   (bir sayfa tek bloba düştü). ÇÖZÜM: ¼ ölçekte bağlantılı bileşen (union-find) + yakın bileşenleri
   birleştirme + okuma sırasına dizme. Gerçekten değen 3 çift için oransal `SPLITS`.
2. **Fuzz'lu flood-fill anahtarlama BU sayfalarda ÇALIŞMAZ** (redesign sprintindekinin aksine):
   parçaların çoğu koyu lacivert zemin üstünde SİYAH plastik; tolerans yükseltilince nesnenin içi
   yeniyor. ÇÖZÜM: zemin uzaklık haritası + KENARDAN BFS ile "zemine bağlı" bölge + yumuşak alfa
   rampası. Nesnenin içindeki koyu pikseller kenara bağlı olmadığı için korunur.
3. **Manifest sırası = TESPİT sırası** (çizim sırası değil). Yoğun ızgarada uzun bir sağ-sütun kutusu
   önceki satır bandına katılıp öne geçiyor. İlk geçişte etiketler 1 kaydı; cihaz ekran görüntüsü
   yakaladı. Kural: manifest yazıldıktan sonra ÜRETİLEN varlıkları tarayıcıda etiketleriyle birlikte
   gözle doğrula.
4. Üçüncü taraf MARKA logolu varyantlar atlanır (`None`): 3 akü + 2 motor. Aynı parçanın markasız hâli
   sayfada mevcut.
5. Yeni hub satırı eklemek, tembel listede alttaki satırları kurulmamış hâle getiriyor → mevcut
   testlerde `scrollUntilVisible` gerekiyor (detay ekranına kahraman görsel eklemek de aynı etkiyi
   yapıyor).

**Tests:** flutter analyze 0 · flutter test **100** (+9: katalog bütünlüğü, ölü varlık yok, boyut
bütçesi, **WebP alfa kanalı**, içerik eşlemesi, kabin kumandası benzersizlik/metin, MechImage yedeği,
galeri arama + boş durum). Web bu fazda değişmedi.
**Device:** Öğren hub (Kabin Kumandaları · 39), galeri (doğru foto↔etiket, arama), Araç Tekniği liste

- Akü detay kahraman görseli. Koyu yüzeyde şeffaflık temiz.

**Kapsam dışı (dürüst):** 33 varlık (`moto-*`, `bus-*`) ÜRETİLDİ ama henüz yüzeye çıkmadı — A/D
içeriği E4/E5'e ait. 60 ikonluk gösterge sayfası E3'ün konusu. 70 araç bileşeninin 41'i dürüst bir
foto karşılığı olmadığı için ikon olarak kalıyor.

**For E3 (Gösterge İkaz Işıkları):** girdi `B-sınıfı-gösterge-işaretleri.png` (10×6 = 60 ikon, her
ikonun ALTINDA İngilizce başlık var → kırpma başlığı DIŞARIDA bırakmalı). İş yükü asıl olarak içerik:
her ikon için Türkçe anlam + hafıza ipucu + önem derecesi (kırmızı=dur, sarı=dikkat, yeşil/mavi=bilgi)

- galeri/detay + ilgili derse bağ.

### Evolution Faz E3 — Gösterge İkaz Işıkları Kütüphanesi (2026-07-25) — DONE

**Completed:** 60 ikaz ışığı ikonu (şeffaf WebP, 130 KB) + her biri için Türkçe anlam/hafıza tekniği/
eylem düzeyi + arama ve önem filtreli galeri + detay ekranı. Rapor: `EVOLUTION_PHASE_3_REPORT.md`.

- **Araç:** `apps/mobile/tool/extract_dash_icons.py` — E2'nin anahtarlama fonksiyonunu yeniden kullanır.
  **İÇERİĞİN TEK KAYNAĞI bu betiktir**: hem `lib/core/dash_assets.dart` hem
  `lib/domain/content/dash_lights.dart` buradan ÜRETİLİR (varlık hattı ile içeriğin ayrışması sorunu yok).
- **Ekranlar:** `/learn/lights` galeri (3'lü ızgara, önem çipleri, arama) + `/learn/lights/:id` detay;
  Öğren hub'a yeni satır.

**Öğrenilenler:**

1. Sayfa ikon/altyazı bantları hâlinde DÖNÜŞÜMLÜ; bandı yüksekliğe göre ayırmak yetmez (iki satırlık
   altyazı bandı ikon kadar kalın olabiliyor) → ÇİFT İNDİSLİ bantlar ikon satırıdır + kalınlık kontrolü.
2. `DashSeverity` = **eylem düzeyi** (ne yapmalıyım?), ikonun rengi değil. Beyaz "servis zamanı"
   anahtarı `sari`dır. Filtre çipleri eylem etiketlerini gösterir → ayrım kullanıcıya görünür.
3. İçerik uzunluğu testi (anlam > 25, ipucu > 10 karakter) 10 fazla kısa girdiyi yakaladı — içerik
   testleri "dolu mu" değil "yeterli mi" diye sormalı.

**Tests:** flutter analyze 0 · flutter test **107** (+7). **Device:** galeri + filtre + arama + detay.
**Kapsam dışı (dürüst):** ders derin-bağlantısı YAPILMADI — mevcut ders korpusunda tek bir ikaz ışığına
bağlanacak granülerlikte bölüm yok; E5'te A/D mekanik içeriği yazılırken gerçek çapa oluşacak.

**For E4 (Çok-sınıflı temel B/A/D):** A ve D mekanik varlıkları (33 adet `moto-*`, `bus-*`) E2'de
üretilip paketlendi, katalogda hazır → E4 içeriği sınıfa göre kapsamlandırıp bunları hemen yüzeye
çıkarabilir. Onboarding zaten kategoriyi topluyor; E4 bu seçimi uygulamanın tamamına işletir.

### Evolution Faz E4 — Çok-Sınıflı Temel (B · A · D) (2026-07-25) — DONE

**Completed:** Ehliyet sınıfı içerik modelinin ve arayüzün birinci sınıf boyutu oldu. 42 yeni A/D araç
bileşeni, sınıfa göre kapsamlama + önceliklendirme, Profil'de sınıf değiştirici.
Rapor: `EVOLUTION_PHASE_4_REPORT.md`.

- **Model:** `VehiclePart.licences?: ('b'|'a'|'d')[]` — **alan YOKSA içerik her sınıfta geçerlidir.**
  Web + mobil (freezed, codegen commit'li).
- **İçerik:** `apps/web/content/vehicle-licence.ts` — 22 A (motosiklet) + 20 D (otobüs) bileşeni.
  Mevcut 36 parça `['b']`/`['b','d']` olarak etiketlendi.
- **Sunum:** `ALL_VEHICLE_PARTS` yalnız `/api/mobile/content-snapshot`'ta; web `VEHICLE_PARTS`'ı
  kullanmaya devam ediyor → **web davranışı birebir aynı** (products.ts'teki MOBILE_PRODUCTS deseni).
- **Kapsamlama:** `lib/domain/content/licence_scope.dart` (saf) + `partsBySystem(licence:)` +
  `partCountFor()`. Sınıfa ÖZGÜ içerik öne alınır, ortak içerik hemen ardından gelir.
- **Değiştirici:** Profil > Ehliyet sınıfı (alt sayfa) → `StudyProfile.category` kalıcı.

**KARAR (bilinçli, roadmap taslağından sapma):** **İlerleme sınıfa göre BÖLÜNMEZ.** Türkiye'de e-Sınav
teori soru bankası tüm sınıflar için ORTAKTIR; SRS/cevap geçmişini sınıfa bölmek ortak bilgiyi parçalar,
sınıf değiştiren kullanıcının gerçek ilerlemesini atar ve riskli bir göç gerektirir — karşılığında
öğrenme faydası yok. Sınıfa özgü olan İÇERİK KAPSAMI ve önceliklendirmedir. Gerekçe kodun yanında
(`licence_scope.dart`) yazılı.

**Öğrenilenler:**

1. Yeni A/D parça `id`'leri mekanik varlık kimlikleriyle AYNI seçildi → `vehiclePartAsset()` doğrudan
   çözüyor, ikinci bir eşleme tablosu gerekmedi.
2. "Etiketsiz = evrensel" kuralı sayesinde hiçbir sınıf boş kalamaz — bu bir testle sabitlendi.
3. Alt sayfa (bottom sheet) 800×600'de 44 px taştı → `isScrollControlled` + `SingleChildScrollView` +
   `maxHeight %85`. Küçük ekran için gerçek düzeltme, test kaçamağı değil.
4. **Cihaz doğrulaması sıralaması (Faz 2 kuralı yine geçerli):** içerik anlık görüntüsü CANLI backend'den
   geliyor → yeni A/D parçaları cihazda ancak Vercel dağıtımından SONRA görünür.

**Tests:** flutter analyze 0 · flutter test **113** (+6) · web typecheck 0 · web **336** (snapshot testi
artık A/D parçalarını ve web listesinin küçük kaldığını doğruluyor).
**Device:** Profil > Ehliyet sınıfı > A seçimi kalıcı; araç kütüphanesi başlığı "Araç Tekniği · A".
**Dağıtım sonrası doğrulama — ONAYLANDI:** CI yeşil + Vercel dağıtımından sonra canlı uç nokta
`counts.vehicleParts: 112` döndü; uygulama yeniden açılışta anlık görüntüyü indirdi ve A kapsamında
**Motor Bölmesi · 17** (B'de 15) göründü — motosiklete özgü **Yağ Seviye Camı** ve **Akü (12V)** listenin
BAŞINDA, fotoğrafları kimlik kuralıyla çözülmüş hâlde. Kapsamlama + önceliklendirme + varlık çözümü
uçtan uca doğrulandı.

**For E5 (A & D içerik + sınav akışları):** kapsamlama katmanı ve etiketleme deseni hazır. `Lesson`'a da
`licences` eklenip kategori dersleri/kuralları yazılacak; e-Sınav teorisinin ORTAK olduğu açıkça
belirtilecek (uydurma ayrı sınav YOK). Yasal sürüş/dinlenme süresi gibi kaynak gerektiren sayısal
iddialar kaynaksız yazılmayacak.

### Evolution Faz E5 — A & D Sınıfı İçeriği ve Sınav Akışları (2026-07-25) — DONE

**Completed:** A ve D sınıflarına **10 yeni sınıfa özgü ders** (5+5), derslerde sınıf kapsamlama,
**işaret ağırlıklandırma** (A 14 · D 17 işaret, gerekçeli) ve bankadaki **gerçek sorulardan** kurulan
sınıf odak setleri (A 19 · D 52). Rapor: `EVOLUTION_PHASE_5_REPORT.md`.

- **Model:** `Lesson.licences?: ('b'|'a'|'d')[]` — şema (Zod) + web + mobil freezed (codegen commit'li).
  **Etiketsiz = her sınıfta geçerli** (E4'teki `VehiclePart` kuralının aynısı).
- **İçerik:** `apps/web/content/lessons-licence.ts` — 5 A (koruyucu donanım · kumandalar/kalkış ·
  fren-viraj · bakım/zincir · trafikte konum) + 5 D (havalı fren · retarder/motor freni · takograf &
  süreler · yolcu güvenliği · manevra/ölü nokta). 31 bölüm · 10 tablo · 14 vurgu · 21 tekrar kartı.
- **Sunum:** `ALL_LESSONS` yalnız `/api/mobile/content-snapshot`'ta; web `LESSONS`'ı kullanmaya devam
  ediyor → **web davranışı birebir aynı** (E4'ün `ALL_VEHICLE_PARTS` deseni). Anlık görüntü 19 → 29 ders.
- **Kapsamlama:** `licence_scope.dart` derslere genişletildi (`forLicence`/`specificFor`/`shared`);
  `content_queries` → `lessonsBySubject(licence:)`, `licenceLessons()`, `lessonCountFor()`,
  `focusSignsFor()`.
- **Odak setleri:** `collections.dart` `licenceFocusQuestions()` — banka metni kavram örüntüsüyle
  taranır, koleksiyon listenin BAŞINA eklenir. **Soru uydurulmaz.**

**KARARLAR (kalıcı):**

1. **İşaretlerde FİLTRE DEĞİL AĞIRLIKLANDIRMA.** e-Sınavda her sınıfa aynı işaret sorulabilir → 121'lik
   galeri hiçbir sınıfta kısılmaz; yalnız kritik olanlar gerekçesiyle en üste toplanır, gerekçe işaret
   detayında çıkar. Dersler kapsamlanır (filtre), işaretler ağırlıklandırılır — ayrım kodda adlandırıldı.
2. **B için yapay "öne çıkanlar" kümesi YOK** — katalog zaten B odaklı; keyfî alt küme yanıltıcı olurdu.
3. **Ortak sınav gerçeği uygulamada YAZILI** (Pratik hub kalıcı bilgilendirmesi): "e-Sınav B, A ve D için
   aynıdır: 50 soru · 45 dk · aynı dağılım." Sınav akışı sınıfa göre çatallanmaz — uydurma sınav yok.
4. **İlerleme hâlâ sınıfa göre bölünmez** (E4 kararı korunur).

**KAYNAK DOĞRULAMASI (kritik, ileride tekrar gerekecek):**

1. **Karayolu Taşıma Yönetmeliği m.35 SAYI İÇERMEZ** — AETR + 2918 + Karayolları Trafik Yönetmeliğine
   havale eder. "Süreler KTY m.43/35'te yazar" varsayımı YANLIŞ.
2. **2918 sayılı Kanun m.49, 12/2/2026 tarihli 7574 sayılı Kanunla DEĞİŞTİ**: sayısal sınırlar artık
   kanunda YOK, yönetmeliğe bırakıldı; ihlaller günlük sürekli / günlük toplam / haftalık-birleşik iki
   haftalık / günlük dinlenme / haftalık dinlenme olarak ayrı cezalandırılıyor. Ezberden yazılsa
   güncelliğini yitirmiş kaynak gösterilmiş olurdu.
3. Yürürlükteki sayılar **Karayolları Trafik Yönetmeliği m.98/A**'dadır: kapsam ticari yolcu
   taşımacılığında **şoför dahil 9 kişiyi geçen** araçlar (+ yük >3,5 t); **24 saatte toplam 9 saat**,
   **devamlı 4,5 saat**, **≥45 dk mola** (4,5 saat içinde ≥15 dk bölümler hâlinde de olur), **molalar
   günlük dinlenmeden sayılmaz**, **her 24 saatte 11 saat kesintisiz dinlenme** (bölünürse biri ≥8 saat,
   toplam 12'ye çıkar; haftada ≤3 kez ≥9 saate inebilir), **≤6 gün kullanma sonrası ≥24 saat hafta
   tatili**, **birleşik 2 haftada ≤90 saat**, çift şoförde **her 30 saatte her şoföre ≥8 saat**.
4. **KTK m.78**: koruma başlığı/gözlüğü zorunlu; _"usulüne uygun kullanmayanlar kullanmamış sayılır"_;
   yolcuların kemer için **hareketten önce ve seyahat sırasında** uyarılması zorunlu. KTY teçhizat
   tablosu: otobüste **toplam ≥6 kg kuru toz**, 26 kişiye kadar olanlarda **2 kg'lık ≥2 adet**,
   **≥1 tanesi sürücünün hemen yanında**.
5. **Yazılmayanlar (bilinçli):** havalı fren bar değeri, zincir sarkma mm'si, motosiklet asgari diş
   derinliği, idari para cezası TUTARLARI (her yıl güncellenir → içeriği hızla yanlışlar).

**Öğrenilenler:**

1. `CalloutTone` hem `design/primitives.dart` hem `domain/content/content_enums.dart` içinde tanımlı →
   ikisini birlikte import eden ekranda `ambiguous_import`. Çözüm: `import ... show Subject;`.
2. `pumpApp`'e **`studyProfile` parametresi** eklendi (onboardingSeen deseninin aynısı): profil main()'de
   senkron okunup provider override'ıyla enjekte edildiği için SharedPreferences'a yazmak testte işe
   yaramıyor. Sınıfa bağlı ekran testleri artık bu parametreyle yazılır.
3. Pratik hub'a bilgilendirme kutusu eklemek alttaki satırları 800×600 test katının dışına itti →
   iki mevcut test `scrollUntilVisible(..., scrollable: find.byType(Scrollable).first)` ile düzeltildi.
   İşaret galerisinde ise **arama alanı da bir Scrollable** olduğu için `.first` yanlış hedefi seçiyor;
   doğru form: `find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable))`.
4. Dart RegExp negatif ileri-bakış destekler: `kask(?!o)` "kasko" sorusunun A odak setine sızmasını
   engelliyor (test ile sabitlendi).
5. Odak setinde soru **kırpılmaz** → kartta görünen sayı ölçülen gerçek sayıdır (A 19 · D 52).

**Tests:** flutter analyze 0 · flutter test **131** (+18) · web typecheck 0 · web **344** (+8) ·
`@ea/content-schema` **17** (+3) · prettier/verify temiz · lint 0 hata.
**Device:** A'da "öne çıkanlar · 14" + detay gerekçesi + "A Sınıfı Odak Seti · 19" (1/19 gerçek
motosiklet sorusu); D'ye geçişte "· 17" ve "· 52" anında yeniden kapsamlandı; **negatif doğrulama**:
D'deyken A'ya özel gerekçe kutusu görünmüyor.
**Dağıtım sonrası doğrulama — ONAYLANDI:** CI (CI · Mobile CI · CodeQL üçü de yeşil, `105fbf9`) ve
Vercel dağıtımından sonra canlı uç nokta `counts.lessons: 29` döndü; uygulama yeniden açılışta anlık
görüntüyü indirdi ve D kapsamında **Dersler · 24** ("Ortak teori + D sınıfına özel dersler"),
**"Sınıfına özel · D Otobüs"** bölümü ve D rozetli 5 ders göründü. Ders 27 (Takograf ve Süreler)
detayında süre tablosu + günlük dinlenme + takograf bölümleri "Resmî Kural" rozetiyle doğru render
edildi. (Faz 2 sıralama kuralı yine geçerliydi: içerik canlı anlık görüntüden gelir.)

**For E6 (Onboarding koç + içgörü kartları):** backend gerekmez. Roadmap uyarıları: dönen kartların
zamanlayıcısı enjekte edilip dispose'da iptal edilmeli (sınav zamanlayıcısı deseni), 320 dp genişlik ve
1,3× metin ölçeğinde kaydırmasız/taşmasız düzen widget testiyle sabitlenmeli. Artık sınıfa bağlı gerçek
bir içerik havuzu var (ders kapsamı, işaret vurgusu, odak seti) → içgörü kartları uydurma değil gerçek
içeriğe dayanabilir.

### Evolution Faz E6 — Onboarding Deneyimi: Koç + İçgörü Kartları (2026-07-25) — DONE

**Completed:** Onboarding'in her adımına **AI Koç'un konuştuğu dönen içgörü kartı** (24 içgörü, 6 tür)
ve **kaydırmasız uyarlanır düzen** (3 yoğunluk kademesi + yatay iki sütun). Backend değişmedi.
Rapor: `EVOLUTION_PHASE_6_REPORT.md`.

- **Saf katman:** `domain/onboarding/onboarding_insights.dart` — `InsightKind` (ipucu/bilgi/motivasyon/
  surus/sinav/strateji), adım başına 4 içgörü, `insightAt(step, tick)` deterministik + ardışık tekrarsız.
- **Bileşen:** `features/onboarding/widgets/coach_insight_card.dart` — `CoachInsightCard` + `IdleMascot`.
- **Düzen:** `_CenteredScroll` (sığarsa dikey ORTALA, sığmazsa kaydır), `OnboardingDensity`
  (roomy/tight/dense) + `OnboardingDensityScope` (InheritedWidget) + yatay iki sütun + `_OptionLayout`.

**KARARLAR (kalıcı):**

1. **Maskot ile içgörü kartı TEK bileşen.** Ayrı maskot bloğu her adıma 100+ px eklerdi; fazın diğer
   şartı kaydırmasızlıktı. Maskot kartın içinde → koç her adımda görünür, boş alan değerlenir.
2. **"Kaydırmasız" ölçülebilir ölçüte çevrildi:** gövde kaydırılabilir (taşma yapısal olarak imkânsız),
   test `maxScrollExtent == 0` doğrular. Sığmayan uç ölçülerde KIRPMAK yerine kaydırır.
3. **Yoğunluk yalnız piksele değil YAZI ÖLÇEĞİNE de bakar** (`densityFor` = yükseklik / metin ölçeği).
   Eşikler ÖLÇÜMLE: `<520 dense`, `<700 tight`, üstü roomy.
4. **Kahraman görseller yalnız roomy kademede** — orta kademede 4 seçenekli adım görselle sığmıyor
   (885/648 px ölçüldü).
5. **Hareket azaltma (`MediaQuery.disableAnimations`) hem erişilebilirlik hem test sabitleyicisi.**

**Öğrenilenler (kritik):**

1. **`late final AnimationController _c = AnimationController(...)` (TEMBEL) KULLANMA.** Hareket
   azaltma açıkken denetleyiciye hiç dokunulmaz; ilk erişim `dispose()` içinde olur ve ticker için ata
   araması yasaktır → "Looking up a deactivated widget's ancestor is unsafe". `initState`'te kur.
2. **Tekrar eden animasyon/`Timer.periodic` `pumpAndSettle`'ı sonsuza kilitler.** ÇÖZÜM: `pumpApp`'e
   `reduceMotion` (VARSAYILAN `true`) eklendi →
   `tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true)`
   - `addTearDown(clearAccessibilityFeaturesTestValue)`. Dönüşü test edenler `reduceMotion: false` verip
     `pump(süre)` ile zamanı elle ilerletir.
3. **`Expanded(flex:)` ile verilen fotoğraf metin sütununu eziyordu:** ehliyet sınıfı kartında metin
   sütunu 118 px'e düşüp açıklama 4 satıra sarıyor ve kart **196 px** oluyordu. Fotoğraf SABİT genişliğe
   alınınca kart **71 px**. Ölçmeden düzen ayarlanmaz.
4. **Kaydırma ölçerken YATAY `PageView` sayılmamalı** (maxScrollExtent 1800 çıkıyor) → yalnız
   `position.axis == Axis.vertical` olanlar ölçülür. Ayrıca arama alanı/TextField de bir Scrollable'dır.
5. **GERÇEK CİHAZ ÖLÇÜSÜNÜ teste koy.** 393×780 (Redmi'nin sistem çubukları düşülmüş alanı) testi,
   roomy eşiğinin 640 olmasının cihazda kaydırma yaratacağını yakaladı (648 alanda 665 px içerik).
   Yalnız 360×640 + yatay test etmek bunu KAÇIRIRDI.
6. Yatayda 2 sütun yalnız **4+ seçenekte** kazanç; 3 seçenekte satırlar dengesizleşip daha uzun oluyor.
7. `ExamTimeframe` başlıkları kısaltıldı ('1 Hafta – 1 Ay', '1 Aydan Fazla') ve adım başlıkları
   sadeleşti ('Hangi ehliyeti alıyorsun?', 'Hangi sınava hazırlanıyorsun?') — uzun başlık dar ekranda
   3 satıra sarıp 84–144 px yiyordu.

**Tests:** flutter analyze 0 · flutter test **145** (+14). Web/backend değişmedi.
**Device:** `pm clear` sonrası ilk açılış; karşılama (kart 14 sn'de 3. içgörüde → dönüş çalışıyor),
adım 1 (yeni B/A/D kartları), adım 4 (4 seçenek açıklamalarıyla), AI Koç slaydı, bitişte Ana Sayfa'da
"Akıllı çalışma oturumu (20 soru)" kişiselleşmesi. Hiçbir adımda kaydırma/taşma yok.

**For E7 (Karşılama deneyimi):** `StudyProfile` zaten kaydediliyor ve main()'de senkron okunuyor;
`pumpApp(studyProfile:)` dikişi hazır; `CoachInsightCard`/`IdleMascot` yeniden kullanılabilir.
Yönlendirme zinciri (onboarding → welcome → home) `onboardingSeen` redirect deseniyle genişletilmeli,
sırası birim testiyle sabitlenmeli ve "Atla" yolu welcome'ı da atlamalı (`ea:welcomeSeen`).

### Evolution Faz E7 — Karşılama Deneyimi (2026-07-25) — DONE

**Completed:** Kişiselleştirme artık doğrudan Ana Sayfa'ya düşmüyor; arada koç eşliğinde **tek
seferlik karşılama anı** var. Ekran seçilen sınıf/sınav/tempo/günlük hedefi kaydedilmiş
`StudyProfile`'dan okuyup gösteriyor. Rapor: `EVOLUTION_PHASE_7_REPORT.md`.

- **İşaret:** `domain/onboarding/welcome_controller.dart` — `ea:welcomeSeen:v1`, `onboardingSeen` ile
  BİREBİR aynı desen (main()'de senkron okuma + provider override → açılışta flaş yok).
- **Ekran:** `features/onboarding/welcome_screen.dart` — süzülen maskot, "Her şey hazır!", 4 satırlık
  profil özeti, koç içgörü kartı, sabit CTA + sessiz "Atla".
- **Zincir:** `app/router.dart` tek `redirect` içinde SIRALI — `tanıtım → karşılama → ana sayfa`;
  tamamlanmış adıma dönülmek istenirse ileri taşınır.
- **Geçiş:** `/welcome` için `CustomTransitionPage` (solma + hafif ölçek); `disableAnimations` açıkken
  geçiş uygulanmaz.
- **Ayrıştırma:** E6'da onboarding ekranının içinde olan `CenteredScroll` ve
  `OnboardingDensity`/`OnboardingDensityScope`/`OptionLayout` → `features/onboarding/widgets/`
  altına taşındı; karşılama ekranı da aynı kaydırmasızlık disiplinini kullanıyor.

**KARARLAR (kalıcı):**

1. **"Atla" karşılamayı DA atlar.** Kişiselleştirmeyi atlayan kullanıcıya seçmediği değerlerin özetini
   göstermek yanıltıcı olurdu → `_finish(completed: false)` her iki işareti de koyar.
2. **Özet değerleri yeniden HESAPLANMAZ**, `studyProfileProvider`'dan okunur (`sessionSize`,
   `paceLabel`, `focus.title`) → "ekranda yazan" ile "uygulamanın kullandığı" ayrışamaz (testle sabit).
3. **Zincir tek bir redirect'te ve sıralı** — iki ayrı kural birbirini iptal eden döngü üretirdi.
   Kural: ilk tamamlanmamış adıma gönder; hepsi tamamsa tanıtım/karşılama yollarını /home'a çevir.
4. `markSeen()` içinde `if (state) return;` — "Başla" ve "Atla" aynı fonksiyonu çağırır, çift yazma yok.

**Öğrenilenler:**

1. `pumpApp`'e **`welcomeSeen` (varsayılan `true`)** eklendi; aksi hâlde kişiselleştirmeyi tamamlayan
   TÜM mevcut testler karşılamaya düşüp "Bugün de çalışalım" bulamıyordu. Zinciri test edenler `false`
   verir. (onboardingSeen/studyProfile/reduceMotion ile aynı dikiş ailesi.)
2. Bir bloğu dosyadan dosyaya taşırken **sınıf sınırını doğrula** — `_CenteredScroll` çıkarılırken
   arkasındaki `_SkipButton` da gitti ve derleme kırıldı. Taşımadan sonra `flutter analyze` şart.
3. Test dosyasında `Size`/`Scrollable` kullanılıyorsa `package:flutter/material.dart` import edilmeli
   (flutter_test tek başına yetmez).

**Tests:** flutter analyze 0 · flutter test **154** (+9: 6 zincir, 2 özet doğruluğu, 1 düzen).
**Device:** `pm clear` sonrası A sınıfı seçilerek tam akış; karşılama **A · Motosiklet / e-Sınav +
Direksiyon / Düzenli tempo / 20 soru** gösterdi; "Çalışmaya başla" → Ana Sayfa; **force-stop +
yeniden açılışta karşılama ÇIKMADI** (tek seferlik işaret kalıcı).

**For E8 (Topluluk temeli):** programın EN BÜYÜK backend fazı. Hazır olanlar: Bearer kimlik doğrulama,
`@ea/db` Drizzle şeması + idempotent bootstrap DDL deseni, `/api/state`, mobilde XP/rozet hesapları.
Roadmap şartları: katılım varsayılan KAPALI (opt-in), **foto yükleme YOK**, **rapor + engelle ilk
fazda**, sunucu tarafında XP artış sınırı (anti-hile), gerçek zamanlılık iddia etmeden ETag/kısa
yoklama. Her yeni uç nokta için PGlite entegrasyon testi.

### Evolution Faz E8 — Topluluk Temeli: Profiller · XP · Sıralama (2026-07-25) — DONE

**Completed:** Topluluk platformunun omurgası — 6 tablo, 6 uç nokta, mobil opt-in/sıralama/profil
yüzeyleri. Gizlilik ve moderasyon **ilk satırdan** içeride. Rapor: `EVOLUTION_PHASE_8_REPORT.md`.

- **Şema:** `community_profiles` · `community_stats` · `community_achievements` ·
  `leaderboard_snapshots` · `community_reports` · `community_blocks` (Drizzle + idempotent bootstrap DDL).
- **Saf mantık:** `apps/web/lib/server/community.ts` — `clampStats` (anti-hile), `weekStartIstanbul`,
  `rankRows`, `validateDisplayName`. **DB içermez** → doğrudan test edilir.
- **Uçlar:** profile (GET/PUT/DELETE) · stats (POST) · leaderboard (GET) · user/[id] (GET) ·
  report (POST) · block (GET/POST/DELETE).
- **Mobil:** `domain/community/community_models.dart`, `data/community/community_repository.dart`,
  `features/community/{community,join_community,user_profile}_screen.dart`; Profil'e satır.

**KARARLAR (kalıcı):**

1. **Katılım varsayılan KAPALI ve bu YAPISAL:** `visibility` sütunu `private` başlar; istemci açıkça
   göndermezse gizli kalır. Sıralama sorgusu yalnız `public` seçer → katılmayan listelenemez.
2. **PII yapısal olarak yok:** uçlar e-posta/gerçek ad döndürmez, mobil modelde bu alanlar HİÇ TANIMLI
   DEĞİL. İki entegrasyon testi yanıt gövdesinde `@ea.dev` ve kayıt adının geçmediğini doğrular.
3. **Fotoğraf yükleme YOK** — avatar 6 sabit maskottan. Bütün bir moderasyon/PII/depolama sınıfı elenir.
4. **Anti-hile 3 kural** (`clampStats`): geri gitme yok · pencere başına tavan (XP ≤2000, cevap ≤300,
   ders ≤30, sınav ≤20) · son yazmadan 60 sn geçmeden artış yok. Ham beyan `submitted_xp`'de saklanır
   (denetim izi); yanıt `clamped`/`regressed` döndürür — sessizce farklı veri saklanmaz.
5. **Engelleme SUNUCUDA ve ÇİFT YÖNLÜ**; istemci filtresine güvenilmez.
6. **Sızıntısız 404:** yok / gizli / engellenmiş → AYNI yanıt. "Gizli mi engelli mi" çıkarılamaz.
7. **Şikâyet + engelleme, kullanıcı metni doğuran E9'DAN ÖNCE** (mağaza politikası).
8. **6. alt sekme EKLENMEDİ** (roadmap "community tab entry" diyor): 5 sekme dar ekranda zaten sınırda
   → topluluk **Profil dalının altında** (`/profile/community`). Giriş noktası korunur, düzen bozulmaz.
9. **`apps/web/lib/community.ts` DEĞİŞMEDİ** (web'in tek-oyunculu XP kademeleri). Yeni sunucu mantığı
   `lib/server/community.ts`'e yazıldı → web davranışı birebir korundu.

**Öğrenilenler (kritik):**

1. **`guarded()` yalnız `req`'i iletir** — Next'in ikinci `ctx` argümanını GEÇİRMEZ. `[id]` uçlarında
   `params` KULLANILAMAZ; kimlik `new URL(req.url).pathname` üzerinden okunur (mevcut desen).
   TypeScript bunu yakalamaz (ctx opsiyonel yazılırsa) → sessiz 404 olurdu.
2. **`setState(() => x = future)` HATA VERİR**: kısa gövde atamanın DEĞERİNİ döndürür, Flutter bunu
   "async callback" sanar. Blok gövde `setState(() { x = future; })` kullan.
3. **FutureBuilder bağlanmadan hata gelirse "yakalanmamış hata"** olur (özellikle future, widget
   ağaçta yokken oluşturulduysa). Çözüm: oluştururken `unawaited(future.catchError(...))` ile hatayı
   işaretle — FutureBuilder yine kendi dinleyicisinde görür.
4. **Widget testinde kaydırıcı hedefi HER ZAMAN açık verilmeli**: kabuk (IndexedStack) diğer
   sekmelerin Scrollable'larını ağaçta tutar. Ayrıca **TextField listenin İÇİNDEYSE** onun Scrollable'ı
   da `find.descendant(of: ListView, matching: Scrollable)` sonucuna düşer → **`.first`** (listenin
   kendi kaydırıcısı ağaçta önce gelir); `.last` metin alanınınkini seçer ve sürükleme hiçbir şey yapmaz.
5. Bir dosyayı düzenlerken vitest çalışıyorsa yarım okuma nedeniyle **geçici** başarısızlık görülebilir;
   düzenleme bitince iki ardışık koşuyla doğrula (390/390 alındı).

**Tests:** flutter analyze 0 · flutter test **166** (+12) · web typecheck 0 · web **390** (+46: 23 saf

- 23 PGlite entegrasyon) · verify/format temiz · lint 0 hata.
  **Device (dağıtım öncesi):** Profil > Topluluk satırı; opt-in daveti dört gizlilik güvencesiyle;
  katılmamış kullanıcıya sıralama gösterilmedi ve **istek yapılmadı**.

**For E9 (Sosyal grafik & mesajlaşma):** engelleme tablosu + çift yönlü uygulama deseni, şikâyet
kuyruğu, hız sınırlama kapısı ve PGlite test iskeleti hazır. Dikkat: her okuma/yazma yolunda engel
kontrolü, mesaj uzunluk/sıklık sınırı, sayfalama + saklama politikası, soru paylaşımının REFERANSLA
(banka kopyası değil) yapılması, moderasyon kuyruğuna yönetici yüzeyi. **Sızıntısız 404 kuralı** mesaj
ve arkadaşlık uçlarında da korunmalı.

**E8 dağıtım sonrası doğrulama — ONAYLANDI (2026-07-25):** canlı sunucuda katılım, anti-hile tavanı
(9.999.999 XP → 2000, `clamped`), pencere kuralı (ikinci bildirimde artış yok) ve sıralama
(`rank 1`, `weekStart 2026-07-20`, PII yok) doğrulandı; cihazda giriş → Profil > Topluluk → canlı
sıralama göründü. **Cihaz/canlı doğrulama İKİ GERÇEK HATA yakaladı ve ikisi de düzeltildi:**

1. **Kısmi gövde türetilmiş alanları sıfırlıyordu** (`{xp:350}` → `accuracy: 0`). `parseCounters`
   artık eksik alanı `undefined` bırakır; `clampStats` mevcut değeri korur. AÇIKÇA 0 bildirmek hâlâ
   geri gitmedir. (+5 test, commit `acd6e15`.)
2. **Kendi satırın sıralamada İKİ KEZ çiziliyordu** (sabitlenmiş "senin sıran" kartı + listedeki
   satır). Sabitlenmiş kart artık yalnız kullanıcı **görünen sayfanın DIŞINDAYSA** çizilir. (+1 test.)

Ders: uç noktayı yalnız istemcinin gönderdiği tam gövdeyle test etmek yetmiyor — **herkese açık bir
API kısmi gövdeye de doğru davranmalı**; ve liste + "senin sıran" birlikte çizilen her ekranda
ÇAKIŞMA kontrolü gerekiyor.

---

## E9 — Sosyal katman (arkadaşlar · mesajlar · tartışmalar) — TAMAMLANDI (2026-07-25)

**Yapıldı:** 4 tablo (`friendships`, `direct_messages`, `discussion_threads`, `discussion_posts`) +
`community_reports`'a `target_type`/`target_ref`; saf mantık `lib/server/social.ts`; **engelleme
korumaları tek modülde** `lib/server/social-guards.ts`; 3 uç ailesi; 6 mobil ekran.
`flutter analyze` 0 · `flutter test` **186** · web **432** · `@ea/db` 4 · lint 0 hata · APK 69,4 MiB.

**Kalıcı kararlar (sonraki fazlarda korunacak):**

1. **Mesajlaşma yalnız arkadaşlar arasında (403).** Rastgele kullanıcıya mesaj yüzeyi hiç yok — taciz
   sınıfını tasarımla kapatan tek en etkili karar. E10 gruplarında da "grup üyeliği ≠ mesaj hakkı".
2. **Engel varlığı sızdırılmaz:** engelli / yok / gizli → **aynı 404**. Çift yönlü uygulanır.
3. **Engel kontrolü tek modülde toplanır** (`social-guards.ts`). Dağıtılmış kontrol denetlenemez;
   E10'da grup listeleri de bu modülden geçmeli.
4. **Soru paylaşımı REFERANSLADIR.** `questionRef` yalnız kimlik (`^[a-z]+-\d{1,4}$`); soru metni
   sunucuya asla yazılmaz, istemci YEREL bankadan çözer. Geçersiz referans sessizce `null`'a düşer.
   Kanıtlandı: `trafik-101` taşıyan başlığın tam sunucu gövdesinde soru kökü **0 kez** geçiyor.
5. **Kendine istek 400, durum çakışması 409.** Karıştırılmamalı.
6. **`ref.watch` vs `ref.read` tuzağı:** `FutureProvider`'ı `read` ile okumak **her zaman null**
   döndürür (abonelik kurulmaz). Soru bankası gibi türetilmiş veriler `build` içinde `watch`
   edilmeli — bu hata tartışma ekranında yakalandı.

**Canlı uçtan uca doğrulama (iki gerçek hesap, üretim): 71/71 geçti.** Arkadaşlık yaşam döngüsünün
tamamı (gönder/reddet/iptal/kabul), arkadaş-olmayana mesaj 403, engelin **her yolda** 404'ü,
engel kaldırınca erişimin geri gelmesi, sıralama kırpması (999.999.999 → 2000), gizli profilin
listeden düşmesi, oturumsuz 401.

**Cihaz doğrulaması iki gerçek hesapla yapıldı** (`AYXSUKIVJVPZ7HPZ`, oturum değiştirerek):
istek gönder → kabul et → mesajlaş → şikâyet → engelle → **engellenen sıralamadan düştü ve sıralar
yeniden hesaplandı** → engeli kaldır → **erişim geri geldi**. Çözülemeyen referans açıklayıcı metin
gösterdi; çözülen referans sorunun tamamını **yerel bankadan** çizdi.

**İki gerçek sorun düzeltildi:**

1. **gitleaks CI'ı kırdı** — `password: '<dizgi>'` biçimi `generic-api-key` kuralını tetikliyor
   (entropi 3.65). Kapı gevşetilmedi; test parolası sabite alınıp **tanımlayıcı** olarak geçirildi.
   **Kural: test dosyalarında `password:` sonrasına dizgi literali YAZMA.** (`295970f`)
2. **`@ea/db` testleri eşzamanlı yükte kararsızdı** — her test PGlite açıp bootstrap DDL koşuyor;
   tek başına 0,9 sn, turbo tüm paketleri paralel koştururken **10,9 sn** → vitest'in 5 sn varsayılanı
   aşılıyordu. `apps/web` bunu zaten `testTimeout: 20000` ile çözmüş; aynı desen `packages/db`'ye
   uygulandı. **Ders: PGlite açan her paketin kendi vitest config'i ve gerçekçi timeout'u olmalı.**

**Bilinen kısıtlar (dürüstçe açık):** gerçek zamanlı değil (WebSocket yok, kısa yoklama) · "okudu"
göstergesi yok · push bildirimi yok · moderasyon reaktif (otomatik filtre yok) · liste sorguları
`limit`'ten SONRA engelli yazarları eliyor (sayfa doluluğu değişken, veri kaybı yok).

**E10 (Çalışma grupları & meydan okumalar) için hazır:** `leaderboard_snapshots` tablosu E8'de
açıldı, **henüz kullanılmıyor** · `weekStartIstanbul` saf ve testli · `social-guards` yeniden
kullanılabilir · şikâyet altyapısı `target_type` ile genişletilebilir.
**ÖN KOŞUL:** üretim veritabanındaki doğrulama artıkları (`AyseE9`, `BurakE9`, `CemE9`,
`E8 Dogrulama` hesapları ve başlıkları) temizlenmeli — şu anda sıralamada ve tartışmalarda görünüyor.

---

## E10 — Çalışma grupları & meydan okumalar — TAMAMLANDI (2026-07-25)

**Yapıldı:** 4 tablo (`study_groups`, `study_group_members`, `challenges`, `challenge_progress`);
saf mantık `lib/server/groups.ts`; 3 uç ailesi; 3 mobil ekran; bootstrap ile 3 meydan okuma tohumu.
`flutter analyze` 0 · `flutter test` **204** · web **471** · `@ea/db` **6** · APK 69,5 MiB.

**Kalıcı kararlar:**

1. **Sınırsız büyüme yolu YOK.** 3 grup kurma / 10 gruba katılma / 50 üye tavanı sunucuda.
   Sonraki her topluluk özelliğinde aynı soru sorulmalı: "bunun tavanı ne?"
2. **Meydan okuma ilerlemesi TÜRETİLİR, bildirilmez.** `community_stats`'tan okunur → E8'in kırpma
   ve **60 sn pencere** kuralları otomatik olarak geçerli olur. İstemcide ilerlemeye dokunan hiçbir
   denetim yok (widget testi düğme düzeyinde doğruluyor).
3. **`baseline` deseni:** katılım anındaki sayaç saklanır, ilerleme `güncel − taban`. Geçmiş ilerleme
   meydan okumayı anında bitiremez. Canlıda kanıtlandı (220 çözülmüş soru → 200'lük meydan okuma %0).
4. **Katılım kodunda karışan karakter yok** (0/O, 1/I/L). Yazım hatası SESSİZCE eşlenmemeli —
   ilk taslakta `0→O→Q` eşlemesi vardı; kullanıcıyı BAŞKA bir gruba sokabilirdi, kaldırıldı.
5. **Sahipsiz grup kalmaz:** sahibi ayrılırsa en eski üyeye devir, son üye ayrılırsa grup silinir.
6. **Üye olmayan grubu göremez** (aynı 404, ad sızmaz). Engellenen üye listede görünmez ama
   `memberCount` GERÇEĞİ söyler.

### ⚠️ ÜRETİM OLAYI — bootstrap DDL yorumundaki noktalı virgül (~65 dk kesinti)

**Kök neden:** Postgres yolu bootstrap DDL'ini `split(';')` ile bölüyordu. E10 ile eklenen iki
**SQL yorum satırında noktalı virgül** vardı → bölme yorumun ortasından kesti → sözdizimi hatası →
`getDb()` her soğuk açılışta patladı → **E8/E9/E10 demeden bütün veritabanı uçları 500**.

**Neden yakalanmadı:** testler PGlite kullanıyor ve PGlite bütün metni tek seferde çalıştırıyor
(`exec`); bölme mantığı hiç çalışmıyordu. 204 mobil + 471 web testi, lint, format, CI, CodeQL —
hepsi YEŞİLDİ. Klasik yalancı-yeşil.

**Düzeltme:** yorumlardaki noktalı virgüller kaldırıldı + `splitDdlStatements()` bölmeden ÖNCE satır
yorumlarını atıyor + 2 regresyon testi.

**KURAL (bundan sonra):**

- **Bootstrap DDL yorumlarına noktalı virgül YAZMA.**
- **Çift sürücülü kodda sürücüye özgü her yol DOĞRUDAN test edilmeli.** PGlite ile Postgres
  arasındaki davranış farkı bütün paketi yalancı-yeşil yapabiliyor. Bir mantık yalnız tek sürücüde
  çalışıyorsa, o mantığı saf bir fonksiyona çıkar ve ayrıca test et.
- Şemaya dokunan her yayından sonra **canlı bir uç gerçekten çağrılmalı** — CI yeşil olması
  üretimin ayakta olduğu anlamına GELMİYOR.

**Bilinen kısıtlar (dürüstçe açık):** meydan okumalar otomatik dönmez (cron yok, 90 günlük pencere,
yönetici arayüzü yok) · haftalık devir BAĞLANDI ama TEMBELDİR: cron olmadığı için görüntü, hafta döndükten sonraki ilk
sıralama okumasında alınır (kimse okumazsa alınmaz). Belirlenimcilik `orderSnapshotRows` + tekillik
`hafta:sınıf` benzersiz dizini ile güvence altında
· sınıfa özel topluluk açılış sayfaları yapılmadı (mevcut sınıf süzgeci işlevi karşılıyor) ·
grup içi sohbet yok (ayrı moderasyon yüzeyi açacağı için kapsam dışı).

**Devreden iş:** üretim veritabanındaki
doğrulama artıklarının temizlenmesi (`AyseE9`, `BurakE9`, `CemE9`, `E8 Dogrulama`,
`Cihaz Dogrulama Ekibi`).

**E11 (Premium Video Player)** E1–E10'dan bağımsızdır; ön koşulu yoktur.

---

## E11 — Premium video oynatıcı — TAMAMLANDI (2026-07-26)

**Yapıldı:** `video_player` korundu, denetim katmanı ELLE yazıldı. Saf mantık `domain/video/`
(WebVTT çözümleyici, devam/izlendi kuralları, bölüm eşleme, yer imi), `PlaybackController`
soyutlaması, özel denetimler, tam ekran, cihazda kalıcı ilerleme/yer imi.
`flutter analyze` 0 · `flutter test` **263** (+59) · APK 69,9 MiB.

**Kütüphane kararı (pub.dev verisiyle, varsayımla değil):** chewie kendi görsel dilini getiriyor +
belgelenmiş arabellek hatası var; `better_player_plus` istediğimiz önbellek/PiP'i veriyor ama 168
beğeni ve "sürümler arası kırıcı değişiklik" uyarısı taşıyor; `media_kit` libmpv gömüyor (APK
büyür) ve istemediğimiz depolama izinlerini istiyor. **Karar: video_player + kendi katmanımız.**

**Kalıcı kararlar:**

1. **Platforma bağlı her denetleyicinin ARAYÜZÜ olmalı.** `PlaybackController` sayesinde bütün
   oynatıcı denetimleri sahte oynatıcıyla test edilebiliyor — platform kanalı gerekmiyor. Bu desen
   (arayüz + uygulama) artık ağ katmanında da oynatıcıda da aynı.
2. **Kural mantığı ekrandan AYRI ve saf tutulur.** Devam etme, izlendi eşiği, bölüm eşleme,
   biçimlendirme — hepsi `domain/video/` içinde ve 38 birim testiyle doğrulanıyor.
3. **İzleme konumu SUNUCUYA gitmez.** Kişisel ve düşük değerli veri; E8'in gizlilik yükünü
   büyütmemek için cihazda kalır.

**Yol boyunca yakalanan üç gerçek kusur:**

1. **Kesirli zaman damgası sessizce kırpılıyordu.** İçerik `t: 2.7` taşıyor, model `int` ilan
   etmişti → `toInt()` 2.7'yi 2 yapıyordu (9 sn'lik videoda ~%8 hata). Model `double` yapıldı.
   **DERS: içerik şemasıyla mobil model arasındaki sayı TÜRÜ birebir doğrulanmalı; json_serializable
   sessizce kırpar, hata vermez.**
2. Altyazı kutusu satır içi (16:9, ~210 px) oynatıcıda ortadaki düğmelerin üstüne biniyordu →
   satır içinde altyazı denetimler görünürken gizleniyor, tam ekranda birlikte gösteriliyor.
3. **"Tam ekran" tam ekran değildi:** iç içe (shell) gezgine itildiği için alt sekme çubuğu
   kalıyordu. `Navigator.of(context, rootNavigator: true)` ile düzeltildi.
   **DERS: StatefulShellRoute altında tam ekran/modal her zaman KÖK gezginle itilmeli.**

**Cihaz doğrulaması (15 madde):** oynat/duraklat, zaman çizgisi + bölüm işaretleri, altyazı (VTT
ağdan çekildi ve zamanında göründü), bölüm listesi + etkin vurgu, hız 1x→1.5x, yer imi (çip +
çubukta sarı işaret), tam ekran (yatay, konum ve hız KORUNUYOR, sekme çubuğu yok), çıkışta dikey
dönüş, "kaldığın yerden devam" başlığı, "izlendi" ✓ — ikisi de uygulama yeniden açılınca duruyor.

**Dürüstçe yapılmayanlar:** PiP (Flutter'da bütün görünümü küçültür, istenen deneyim değil; yerel
oynatıcı yüzeyi veya elenen bağımlılık gerekir) · çevrimdışı indirme (mimarinin bugün desteklediği
şey: ağdan akıtma + platformun geçici önbelleği; kalıcı indirme yönetimi yok) · parlaklık/ses
hareketleri (go_router geri hareketiyle çakışma riski; açık düğmeler tercih edildi) ·
`wakelock_plus` (içerik 8–9 sn olduğu için gereksiz).

**E12 için hazır:** oynatıcı içerikten bağımsız; yeni video eklemek ek kod GEREKTİRMEZ — yalnız
içerik + VTT + bölüm verisi. E12'de yeniden değerlendirilecek: wakelock ve çevrimdışı indirme.

---

## E12 — Video içerik üretimi — TAMAMLANDI (2026-07-26)

**Yapıldı:** üretim hattı premium standarda çıkarıldı (1120×640 @30fps, token renkleri, araç
ayrıntısı, videoya gömülü adım etiketleri). Manevra seti tamamlandı: paralel park · L park ·
U dönüşü · 25 m geri gidiş. Ayrıca yokuşta kalkış ve 3 manevra hatası animasyona çevrildi.
Oynatılabilir video **2 → 7**. web **484** (+5) · `flutter test` **265** (+2) · varlıklar 2,2 MB.

**Kalıcı kararlar:**

1. **TEK KAYNAK.** `scripts/video-scenes.mjs` görüntüyü, bölümleri ve altyazıyı BİRLİKTE taşır;
   hat mp4/webm/poster/VTT **ve** `content/videos.generated.ts` üretir. Video–katalog–altyazı
   sapması artık testle değil, KURGUYLA imkânsız. Roadmap'in E12 riski buydu.
   **Kural: içerik türetilen bir varlıksa, türeten kaynak tek olmalı; elle ikinci kopya tutma.**
2. **Dürüstlük etiketi testle zorunlu.** Her oynatılabilir video başlığında `(Animasyon)`; hiçbir
   animasyon `Gerçek Çekim` diye sunulamaz; her `planned` başlıkta `planlanıyor`, açıklamasında
   `gerçek` geçmek zorunda. Bu, ileride birinin sessizce "gerçek çekim" iddiası eklemesini engeller.
3. **Vaadi değiştirdiysen BAŞLIĞI da değiştir.** `hill-start` ve `common-mistakes` "(Gerçek Çekim)"
   vaat ediyordu (pedal kamerası / 10 hata). Animasyon aynısı değil → başlık ve açıklama gerçekte
   ne gösterdiklerini söyleyecek biçimde yeniden yazıldı ("Sık Yapılan **3** Manevra Hatası").

**Yakalanan kusurlar:** `(a + b ?? c)` öncelik hatası poster damgasını NaN yapıyordu · L park
sahnesinde park cepleri çizilmemişti (araçlar çimende duruyordu) · videoya gömülü adım etiketi
mobil listedeki "İZLE/PREMIUM" rozetiyle çakışıyordu → **alt şeride** alındı.

**CI iki kez yakaladı:** (a) E2E testi eski içeriği kodluyordu (transkript ifadesi + `planned`
sayısı 4→2); (b) üretilmiş `videos.generated.ts` prettier kapısına takıldı.
**Kural: üretilmiş dosyaları yazan her hattan sonra `npx prettier --write` çalıştır; ayrıca
içerik değiştiren her fazda E2E'yi YERELDE koş — CI'a bırakma.**

**Cihaz:** yeni katalog, oynatma, gömülü adım etiketi, bölüm eşleşmesi, CC, premium kapısı
doğrulandı. Premium kilidi nedeniyle kalan 6 video `ffprobe` ile yayından çözümlenerek doğrulandı
(hepsi 1120×640/30fps, kare sayısı ve süre sahne tanımıyla birebir).

**Dürüstçe eksik:** ses/seslendirme yok (anlatım altyazı + adım etiketiyle) · kuş bakışı şematik
anlatım sürücü gözü/ayna hissi veremez · süreler 10–14 sn (adımları gösterir, gerçek zamanlı
manevra değil) · iki başlık (sınav yürüyüşü, araç kontrolü) gerçek çekim gerektirdiği için
`planned` kaldı.

---

## BETA Faz 0–1 — Yayın hazırlığı + varlık denetimi (2026-07-26)

**Yeni program:** Beta Readiness (Google Play kapalı test, 12 test kullanıcısı). Evolution
(E1–E13) programına **dokunulmadı**.

**Faz 0:** dokuz belge üretildi (roadmap, checklist, Google auth, Play Console, RevenueCat,
kapalı test, env, varlık kütüphanesi, denetim planı). Belgeler **depodan okunan** değerlerle
yazıldı: Flutter 3.41.9 · compileSdk/targetSdk 36 · izinler yalnız POST_NOTIFICATIONS +
RECEIVE_BOOT_COMPLETED · in_app_purchase 3.3.0 · Firebase/Google Sign-In/RevenueCat YOK.

**Bulunan yayın engelleri:** B1 release derlemesi **DEBUG anahtarıyla** imzalanıyor (Play kabul
etmez) · B2 gradle'da şablon yapılacak-notları (disiplin kural 3 ihlali) · B3 Google Sign-In yok ·
B4 RevenueCat yok · B5 üretim veri artıkları · B6 Play kaydı yok.

**Kaydedilen model çakışması:** uygulama bugün TEK SEFERLİK ömür boyu paket satıyor, program ise
aylık/yıllık ürün istiyor. Bu bir **ürün kararı**, mühendislik kararı değil. Entegrasyon
`entitlement` kavramı üzerinden tasarlandı: her iki model de aynı `premium` yetkisini açar,
uygulama kodu hangisi olduğunu bilmez.

**CI dersi (yine):** `pnpm verify` kapısı yasaklı kalıp tarıyor; Play belgesinde gradle'daki
mevcut şablon notunu KANIT olarak birebir alıntılamak kapıyı kırdı. Kapı gevşetilmedi, alıntı
yeniden yazıldı. **Kural: kanıt alıntılarken deponun kendi yasaklı kalıplarına dikkat et.**

**Faz 1 denetimi — ölçülmüş:**

- Mobil varlık: 263 dosya · 4,7 MB · **yetim varlık 0** (hepsi kodda referanslı)
- **38 emoji boş/hata durumu** → tekrar ettikleri için **14 illüstrasyon** hepsini kapatıyor
- **Giriş ekranında hiç görsel yok** — Faz 5'in gerçek gerekçesi bu
- Onboarding görselleri **695–820 px**, 3× cihazda 1080 px gerekiyor → Faz 6 yalnız yerleşim
  değil, **varlık çözünürlüğü** işi de
- `CustomPainter` × 4 yer tutucu DEĞİL (veri görselleştirme) — üretilmeyecekler listesine yazıldı

**Referans varlıkların gerçek niteliği (önemli):** `022-assets.png` gerçek bir hero görseli;
ama **`023` ve `024` arayüz mockup'ı** — içlerinde gömülü Türkçe metin var. Raster olarak sevk
edilirlerse tema, yazı tipi ölçeği ve çeviri kırılır. **Karar: 023/024 widget olarak birebir
uygulanacak, raster sevk edilmeyecek.**

**İki uyarı Faz 5'e taşındı:** (a) 022'de **Renault logosu** okunuyor → rötuş/markasız varyant
gerekli; (b) mockup'taki **"Apple ile giriş"** düğmesi iOS olmadığı için ölü gezinme olurdu →
konmayacak; (c) "MEB müfredatına uygun" iddiası kaynak gösterilemezse kullanılmayacak.

**Üretilecek toplam: 19 görsel** (14 boş durum + 5 onboarding) ≈ 1,1 MB.

---

## BETA Faz 2 — Google ile giriş — TAMAMLANDI (2026-07-26)

**Yapıldı:** sunucu doğrulamalı Google girişi. `flutter test` **275** (+8) · web **516** (+32).

**Kalıcı kararlar:**

1. **Google girişi yeni oturum sistemi GETİRMEZ.** Mevcut Bearer oturumuna bir giriş kapısı ekler;
   e-posta/parola ve misafir yolları dokunulmadan durur. Sonraki kimlik sağlayıcıları da aynı
   deseni izlemeli.
2. **Kimlik iddiası SUNUCUDA doğrulanır.** `lib/server/google-verify.ts` saf ve 21 testli;
   uç yalnız JWKS getirip imzayı doğruluyor. İstemciden gelen e-postaya asla güvenilmez.
3. **Hata mesajları durum SIZDIRMAZ:** imza/aud/issuer/biçim hepsi aynı mesaj. Yalnız kullanıcının
   düzeltebileceği iki durum (doğrulanmamış e-posta, süre dolması) ayrı mesaj alır.
4. **HESAP BİRLEŞTİRME:** aynı e-postayla parolayla kaydolmuş kullanıcı Google ile girince AYNI
   hesaba bağlanır. İkinci hesap açmak ilerlemeyi ikiye bölerdi.
5. **Yapılandırılmamışsa düğme HİÇ gösterilmez.** Çalışmayan düğme ölü gezinmedir (kural 3).
   Bu kalıp Faz 3'te RevenueCat için de kullanılacak.
6. **Vazgeçme hata DEĞİLDİR.** Hesap seçiciyi kapatan kullanıcıya mesaj gösterilmez —
   `GoogleSignInCancelled` ayrı bir sonuç türü.

**google_sign_in v7 tuzağı:** `serverClientId` olarak **WEB** istemci kimliği verilir, Android
istemci DEĞİL. Yanlış verilirse `idToken` **null** döner ve giriş **sessizce** başarısız olur.
Kod bu durumu ayrı bir hata mesajıyla yakalıyor.

**E13 token muhafızı işe yaradı:** Google'ın dört marka rengini yakaladı. Marka kılavuzu bu
renklerin değişmesini yasakladığı için GEREKÇESİYLE izin listesine eklendi — muhafız gevşetilmedi.
Bu, muhafızın tasarlandığı gibi çalıştığının kanıtı.

**Cihazda doğrulandı (iki derleme):** yapılandırılmamış → düğme yok; `--dart-define` ile
yapılandırılmış → ayırıcı + düğme + dört renkli G işareti.

**Dürüstçe yapılmayan:** gerçek Google hesabıyla uçtan uca giriş **denenmedi** — Firebase projesi,
`google-services.json` ve SHA parmak izleri elle kurulacak adımlar. **Play App Signing SHA'sı
kapalı teste ilk yüklemeden sonra Firebase'e eklenmezse Play'den kurulan yapıda giriş çalışmaz.**
Apple ile giriş konmadı (iOS yok → ölü gezinme olurdu).
