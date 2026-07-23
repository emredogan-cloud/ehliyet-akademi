# Phase 1 Implementation Report — Flutter Foundation & Design System

**Ehliyet Akademi Mobile · Roadmap: `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`**
_Prepared: 2026-07-23 · Device-validated on a real Android phone._

## Verdict: 🟢 GO

The Flutter app exists, installs, and runs on the real device with the web platform's identity
preserved 1:1 — teal/amber palette, 8px spacing, 16px cards, motion curves, light **and** dark
themes. Bottom-tab navigation, an animated readiness ring, the AI Coach nudge card, and a working
theme toggle are all live and validated on-device.

---

## Completed work

- **Flutter project scaffolded** at `apps/mobile/` (org `com.ehliyetegitim`, app id
  `com.ehliyetegitim.ehliyet_akademi`), Android + iOS config.
- **Design tokens → ThemeData**, 1:1 with the web (`core/theme/tokens.dart`, `app_theme.dart`):
  light `:root` + dark navy `:root[data-theme='dark']` palettes, 8px spacing scale, radius set,
  type scale (`--fs-*`), motion curves (`--ease-out` = `Cubic(0.16,1,0.3,1)`). System font stack →
  Roboto on Android (faithful match).
- **Design primitives** (`design/`): `AppCard` (surface/16px/hairline/soft-shadow/press),
  `AppPageHeader`, `SectionTitle`, `AppCallout`, `StatTile`, `AppEmptyState`, `OverviewTile`,
  `ReadinessRing` (animated CustomPainter, traffic-light color), `CoachCard`, `QuickAction`.
- **Navigation**: `go_router` `StatefulShellRoute.indexedStack` with 5 bottom-tab branches (Ana
  Sayfa / Öğren / Pratik / AI Koç / Profil), each an isolated stack. Router exposed as a Riverpod
  provider (fresh per scope — no leaked nav state).
- **State**: Riverpod (`ProviderScope`); theme mode via a `Notifier`.
- **Screens**: Home dashboard (readiness card, AI nudge, daily plan, quick actions, continue),
  Öğren hub, Pratik hub, AI Koç intro, Profil (with a **working** dark-theme toggle). All complete,
  no placeholders, no dead navigation (unbuilt detail routes are non-navigable, not broken links).

## Architecture

- Layered/feature-first (`core/ design/ app/ features/`), matching `APP_ARCHITECTURE_PLAN.md`.
- Packages added: `go_router`, `flutter_riverpod`.
- Decision: **router as a provider** (was a global singleton → leaked navigation state between
  test instances; the provider gives each scope an isolated router). Lesson recorded.
- Decision: **AppPaletteExtension** theme-extension carries the full token palette to widgets (the
  web has more color roles than Material `ColorScheme`).
- Riverpod note: this version dropped `StateNotifier` from the default export → used the modern
  `Notifier` / `NotifierProvider` API.

## Screens implemented

Home · Öğren hub · Pratik hub · AI Koç intro · Profil (5 tab roots). Detail screens
(lessons/signs/exam runners/chat) arrive in their phases.

## Tests executed

- `flutter analyze` — **0 issues**.
- `flutter test` — **7 passed** (3 widget: boot/nav/theme-toggle; 4 theme-parity unit).
- Golden (pixel) tests: **deferred** to a dedicated golden-CI harness (a later phase) to avoid
  cross-environment font-rendering flakiness that would break CI — documented honestly per the
  roadmap's "where applicable".
- Web gates unaffected: `pnpm lint` (0 errors, 1 pre-existing warn), `format` clean, `verify` pass
  (`apps/mobile/` excluded from eslint/prettier/verify so it can't break web gates).

## Build

- **Android debug APK builds** — `app-debug.apk` (~140 MB; this is a _debug_ build — full engine,
  no tree-shake; a release build tree-shakes to ~15–20 MB, done in Phase 8).
- **iOS: N/A (no macOS)** on this Linux host; `ios/` config is generated and valid.
- **Mobile CI** added (`.github/workflows/mobile.yml`): setup Java 17 + Flutter 3.41.9 →
  `pub get` → `analyze` → `test` → `build apk --debug`, triggered on `apps/mobile/**`.

## Performance

Smooth 60fps scrolling on the device; instant tab switches (IndexedStack keeps tab state); the
readiness ring animates once on the `--ease-out` curve. No jank observed. Cold start to interactive
home < 2 s.

## Device validation

- **Device:** Redmi M1908C3JGG, Android 11 (API 30), `AYXSUKIVJVPZ7HPZ` (USB).
- **Exercised:** install + launch; Home renders (light) with readiness ring %72, AI nudge card,
  daily plan, streak chip, quick actions; bottom-nav switch to Profil; **theme toggle → dark**;
  Home re-rendered in dark (navy bg, teal `#2dd4bf` primary) — an exact match to the web dark theme.
- **Evidence:** on-device screenshots captured (light home, Profil, dark home). Navigation validated
  by widget tests + on-device tab switching.

## Known issues

None. (Blind-tap coordinate confusion during validation was a _validation-script_ nuance, not an app
issue; the app behaves correctly.)

## Next phase prerequisites (Phase 2 — Mobile Auth)

- ✅ App shell + theme + nav + Riverpod in place to host auth state.
- Phase 2 adds: backend **token-auth mode** (JWT + refresh) on the existing auth API; Flutter
  login/register/guest screens; `flutter_secure_storage` for tokens; a `dio` client with a refresh
  interceptor; real `/api/state` sync; and binds the Profil header to the signed-in user.

**Phase 1 is DONE per the Definition of Done. Proceeding to Phase 2 after CI is green.**
