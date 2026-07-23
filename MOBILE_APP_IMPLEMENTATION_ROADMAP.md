# Mobile App Implementation Roadmap (permanent)

**Ehliyet Akademi · Flutter mobile app — the permanent implementation reference.**
_Every phase MUST read this file first, then work on exactly one phase._

Source-of-truth planning docs: `MOBILE_APP_MASTERPLAN.md`, `MOBILE_UX_AUDIT.md`,
`APP_ARCHITECTURE_PLAN.md`, `AI_MOBILE_BEHAVIOR.md`, `MOBILE_FEATURE_ROADMAP.md`. Execution
discipline mirrors `QUESTION_PLATFORM_WORKFLOW.md`.

---

## 1. Executive summary

Build a premium native **Flutter** app for Ehliyet Akademi that preserves the web identity, on top of
the existing Next.js backend (reused, extended with a mobile BFF). One phase at a time, each 100%
production-ready, real-device validated, CI-green, before the next.

## 2. Environment (verified 2026-07-23)

- **Flutter 3.41.9 stable**, Dart, Android SDK 36.1.0, Java 17 — all present.
- **Real device connected via USB:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG, android-arm64, **Android
  11 (API 30)**. Used for real-device validation each phase.
- **iOS: N/A on this platform.** iOS build/run requires macOS + Xcode; unavailable on Linux. The
  Flutter project still generates `ios/` config, but iOS build/run is documented as **N/A (no
  macOS)** per phase — not faked.
- **Web desktop/Chrome targets** not used (we target Android; web already exists as the Next.js app).

## 3. Architecture decisions (locked)

- **Client:** Flutter (`apps/mobile/` in the monorepo). **State:** Riverpod. **Routing:** go_router
  (5 bottom-tab nested navigators). **Network:** dio + interceptors. **Local DB:** drift (SQLite).
  **Secure storage:** flutter_secure_storage (tokens). **Models:** freezed + json_serializable.
- **Backend:** reuse the existing Next.js API; extend with a mobile BFF (token auth, content, exams,
  coach nudges, IAP validate, push) **just-in-time in the phase that needs it** (each such addition is
  a complete, tested unit, not a stub).
- **Design:** one token source → Flutter `ThemeData` (light+dark), 1:1 with the web
  (`APP_ARCHITECTURE_PLAN.md` §5).
- **Org / ids:** package `ehliyet_akademi`; application id `com.ehliyetegitim.app`.
- **Reuse, don't rewrite:** the QIP engine + content stay server-side / bundled; only the tiny pure
  SRS is ported to Dart for offline.

## 4. Implementation strategy & phase order

Each Flutter phase produces an **on-device-validated** increment. Backend BFF work is folded into the
phase that first needs it (cohesive, never partial).

| Phase | Title                              | Backend added                 | On-device milestone                                               |
| ----- | ---------------------------------- | ----------------------------- | ----------------------------------------------------------------- |
| **1** | Flutter Foundation & Design System | —                             | app installs; themed shell + 5 tabs + primitives + static home    |
| **2** | Mobile Auth                        | token-auth mode (JWT+refresh) | login/register/guest; secure session; real /api/state sync        |
| **3** | Content & Learn                    | content snapshot API          | lessons, signs (121 SVG), vehicle, videos — offline               |
| **4** | Practice & Exams                   | exam-build API                | SRS practice, 50-Q exam runner, collections, historical — offline |
| **5** | AI Coach & Notifications           | coach-nudge API + push token  | chat + proactive cards + FCM/local notifications                  |
| **6** | Progress & Gamification            | progress summary API (opt)    | readiness radar, XP, heatmap, achievements, study plan            |
| **7** | Premium (IAP)                      | IAP validate API              | native in-app purchase + entitlement sync                         |
| **8** | Onboarding & Launch Prep           | —                             | premium onboarding, store assets, offline hardening               |
| **9** | Final Polish & Delight             | —                             | senior-architect pre-launch review pass                           |

**Dependencies:** 1 → 2 → 3 → 4 → {5,6} ; 7 needs 2 (+ store accounts) ; 8,9 need all. Order is fixed
unless a blocker forces documented deviation.

## 5. Definition of Done (every phase)

A phase is DONE only when ALL hold:

1. Production-ready — **no TODO/FIXME, no placeholder UI, no broken/incomplete screens or nav**.
2. `flutter analyze` — **zero issues**.
3. `flutter test` — unit + widget + golden (where applicable) **all pass**.
4. **Android APK builds** (`flutter build apk --debug` min; release where relevant).
5. **Real-device validation** on `AYXSUKIVJVPZ7HPZ` — install, launch, exercise everything changed
   (navigation, animations, scrolling, touch, gestures, offline, loading, state restoration, and the
   phase's feature). Every discovered issue fixed before continuing.
6. iOS build — **N/A (no macOS)**, documented; iOS config kept valid.
7. Backend changes (if any) pass the **web gates + CI + CodeQL** (as in `QUESTION_PLATFORM_WORKFLOW.md`).
8. **Flutter CI** (`.github/workflows/mobile.yml`: analyze + test + build) green.
9. Repository verification (workspace verify still passes; `apps/mobile/` excluded from JS tooling).
10. `PHASE_<N>_IMPLEMENTATION_REPORT.md` written (template §9).
11. Project memory updated (decisions, new APIs, breaking changes, lessons).
12. Committed + pushed to `main`; **CI + CodeQL green** before continuing.

## 6. Testing requirements

- **Unit:** domain/use-cases, ported SRS, mappers — deterministic (inject clock/rng).
- **Widget:** each screen renders + key interactions.
- **Golden:** design-parity for core primitives (AppCard, QuizCard, PageHeader) + key screens, both
  themes. Golden baselines committed; regenerate only on intentional design change.
- **Integration** (`integration_test`): critical flows per phase (e.g., P2 login→home; P4
  practice→exam→result).
- **Backend:** new API routes get integration tests (mirror the web harness).

## 7. CI requirements

- **New:** `.github/workflows/mobile.yml` — on push touching `apps/mobile/**`: setup Flutter 3.41.9 →
  `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --debug`. Must be green.
- **Existing:** web CI + CodeQL for any `apps/web`/packages change. Both must be green before continuing.
- **Rule:** if any workflow fails → stop, investigate, fix, re-push, until all green.

## 8. Real-device validation requirements

Every phase, on the connected device: `flutter install` (or `flutter run` + screenshots via
`adb exec-out screencap`), then verify — navigation, animations, performance (smooth scroll, no
jank), touch/gestures, offline behavior, loading/empty/error states, state restoration, and the
phase's feature end-to-end. Capture at least one screenshot as evidence in the report. Fix everything
found.

## 9. Report template (`PHASE_<N>_IMPLEMENTATION_REPORT.md`)

```
# Phase <N> Implementation Report — <Title>
## Verdict: GO / NO-GO
## Completed work
## Architecture (decisions, packages, structure)
## Screens implemented
## Tests executed (analyze / unit / widget / golden / integration — with counts)
## Build (APK size, Android build; iOS = N/A no macOS)
## Performance
## Device validation (device, what was exercised, screenshot evidence)
## Known issues (must be empty to be GO)
## Next phase prerequisites
```

## 10. Git workflow

- Work on `main` (project deploys web on push to main; Flutter is client-only).
- One focused commit per phase (small fixups allowed). `Co-Authored-By` trailer.
- Push → verify **web CI + CodeQL + mobile CI** green → verify web deployment (if a web surface
  changed) → only then continue.

## 11. Production validation

- Backend/API changes: deploy (Vercel on push) → hit the live endpoint → confirm parity, as in prior
  programs. The Flutter app is not "deployed" to a store in these phases (store submission is Phase 8);
  its "production" surface is the real-device install.

## 12. Repository hygiene

- `apps/mobile/` is a Dart project inside the JS monorepo. **Exclude it from JS tooling**
  (eslint/prettier/verify/turbo) so it doesn't break web gates. Its own CI (mobile.yml) covers it.
- Never commit build artifacts (`build/`, `.dart_tool/`, `*.apk`), the pub cache, or signing secrets
  — Flutter `.gitignore` handles most; verify.

## 13. Quality bar

Senior-mobile-architect quality throughout: no placeholders, complete screens, complete animations,
consistent tokens, smooth 60fps, accessible, premium feel. Phase 9 (Final Polish & Delight) is a
dedicated pre-launch review beyond the planned scope.

---

**Mission:** one phase, one report, one commit, one push, green CI, real-device validation — then
continue. Build the highest-quality driving-education mobile app possible. Quality over speed.
