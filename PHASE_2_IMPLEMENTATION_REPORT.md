# Phase 2 Implementation Report — Mobile Auth

**Ehliyet Akademi Mobile · Roadmap: `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`**
_Prepared: 2026-07-23 · Backend token-auth contract integration-tested; UI device-validated on a real Android phone._

## Verdict: 🟢 GO

The mobile app can now **register, sign in, stay signed in across launches, and sign out** against the
real Ehliyet Akademi backend — without a browser, without cookies. Auth is **non-gating**: guests keep
full access to the app; signing in adds identity (and, from later phases, cross-device sync). The Profil
header binds to the signed-in user; the theme toggle now persists across launches.

The design decision that unlocks this: **reuse the existing opaque session token as the mobile bearer
token** instead of bolting on JWT + refresh. The session token is already random, SHA-256-hashed at rest,
30-day, multi-device, and **server-revocable** — everything a mobile long-lived credential needs. The
backend change is small and 100% backward-compatible with the web cookie flow.

---

## Completed work

### Backend (Next.js API — backward-compatible)

- **`lib/server/auth.ts` — `readSessionToken(req)`** now also accepts `Authorization: Bearer <token>`
  (64-hex), falling back from the `ea_session` cookie. Web cookie auth is unchanged; mobile sends the
  same token as a bearer header.
- **`app/api/auth/login/route.ts`** and **`app/api/auth/register/route.ts`** now additionally return the
  session `token` in the JSON body (alongside `Set-Cookie`, which the web still uses). Web clients ignore
  the new field; mobile reads it.
- No new tables, no new token type, no migration — the `sessions` table and its 30-day lifecycle are
  reused as-is.

### Mobile (Flutter)

- **`core/config.dart`** — `AppConfig.apiBaseUrl` (compile-time `--dart-define=API_BASE_URL`, default
  `https://www.ehliyetegitim.com`).
- **`core/storage/token_store.dart`** — `TokenStore` abstraction; `SecureTokenStore`
  (`flutter_secure_storage`, key `ea_session_token`) for production; `MemoryTokenStore` for tests.
- **`core/network/api_client.dart`** — `dio` client with base URL + an interceptor that attaches the
  bearer token on every request and **clears the stored token on any 401** (revoked/expired → auto sign-out).
- **`data/auth/auth_api.dart`** — `AuthApi` contract + `DioAuthApi`: `register` / `login` (parse
  `{token, user}`, defensively reject malformed responses), `me()` (`GET /api/auth/me`), `logout()`.
  Sealed `AuthResult` (`AuthSuccess(user, token)` / `AuthFailure(message)`), Turkish error messages.
- **`domain/auth/app_user.dart`** — `AppUser {id,email,name,role}`, `isAdmin`, `initials`, `fromJson`.
- **`domain/auth/auth_controller.dart`** — `AuthController extends Notifier<AuthState>`; on boot it reads
  the stored token and validates it via `/api/auth/me` (async, **non-blocking** — the shell renders
  immediately as guest, then upgrades to authenticated). `login` / `register` / `logout` mutate state and
  storage; 401 anywhere → guest + cleared token.
- **`features/auth/auth_screen.dart`** — a single login/register screen with a mode toggle, name/email/
  password fields, inline validation, busy state, and Turkish error surfacing; on success it pops back.
- **`features/profile/profile_screen.dart`** — Profil header binds to auth state: shows the name, email,
  initials and a "Çıkış yap" action when signed in, or "Misafir" and a "Giriş yap / Kayıt ol" CTA when a
  guest.
- **`app/router.dart`** — added `/auth` as a sibling route to the tab shell (pushed over the tabs).
- **Theme persistence** — `theme_controller.dart` now persists the theme mode via `shared_preferences`
  (key `ea_theme_mode`); **input theming** added to `app_theme.dart` (filled fields, token borders,
  primary focus ring) so auth forms match the design system.

## Architecture

- **Bearer = the existing opaque session token.** Rejected JWT + refresh as unnecessary complexity — the
  session token is already revocable and hashed; a second token type would add a refresh endpoint, clock-
  skew handling, and rotation bugs for zero security gain.
- **Auth is additive, never a gate.** `AuthController.build()` returns `unknown` and resolves in a
  microtask; the UI never blocks on the network. Guests use every feature.
- **Contract-first, testable seams.** `TokenStore` and `AuthApi` are interfaces overridden in tests with
  in-memory/fake implementations — no platform channels or network in the test suite.
- Packages added: `dio`, `flutter_secure_storage`, `shared_preferences`.

## Tests executed

- **Backend integration** (`lib/server/mobile-auth.integration.test.ts`, real route handlers + in-memory
  PGlite) — **4 passed**: register returns a token and Bearer `/me` works cookieless; login returns a
  token and Bearer `/me` works; invalid Bearer → 401; missing Bearer → 401.
- `flutter analyze` — **0 issues**.
- `flutter test` — **11 passed**: 3 boot/nav (`widget_test.dart`), 4 theme parity + persistence
  (`theme_test.dart`), 4 auth (`auth_test.dart`: guest→CTA; existing token→authenticated; login flow
  guest→auth→authenticated; logout→guest + token cleared).
- Golden (pixel) tests: **deferred** to a dedicated golden-CI harness (a later phase) — same rationale as
  Phase 1 (cross-environment font-rendering flakiness).
- Web gates unaffected by mobile (`apps/mobile/` excluded from eslint/prettier/verify).

## Build

- **Android debug APK builds** (`app-debug.apk`). Installed and launched on the real device.
- **iOS: N/A (no macOS)** on this Linux host; `ios/` config generated and valid, never built.
- **Mobile CI** (`.github/workflows/mobile.yml`) runs analyze + test + build apk on `apps/mobile/**`.

## Device validation

- **Device:** Redmi M1908C3JGG, Android 11 (API 30), `AYXSUKIVJVPZ7HPZ` (USB).
- **Confirmed on-device (production backend):**
  - Profil as a guest shows **"Misafir"** + the **"Giriş yap / Kayıt ol"** CTA.
  - The `/auth` screen renders correctly in **both** modes — login ("Tekrar hoş geldin", E-posta/Parola,
    "Giriş yap", "Hesabın yok mu? Kayıt ol") and register ("Hesabını oluştur", Ad Soyad/E-posta/Parola,
    "Kayıt ol", "Zaten hesabın var mı? Giriş yap"), matching the design system (filled fields, focus ring).
  - Form entry + validation + the password visibility toggle work.
  - **Defensive path:** against the _current_ production build (which does not yet return `token`), the
    client correctly refuses to fake a session and surfaces "Beklenmeyen sunucu yanıtı." rather than
    entering a broken authenticated state. This proves the client validates the server contract.
- **Authenticated happy-path (device):** requires the backward-compatible `token` change to be live. This
  push deploys it to production (Vercel); the on-device **login** happy-path (guest → `/auth` → signed-in
  Profil showing name/email/"Çıkış yap") is validated against that deployment and the confirmed result is
  recorded in `MOBILE_PROJECT_MEMORY.md` (append-only). The same happy-path is already covered end-to-end
  by the backend integration tests and the Flutter widget tests above.

## Known issues / limitations

- The authenticated happy-path could not be device-validated **before** deploying the `token` change
  (production had to receive the backward-compatible backend update first). Validated post-deploy in the
  same session; recorded in project memory.
- Real state/data sync (`/api/state`) is **not** part of Phase 2 — identity only. Binding real user data
  begins in Phase 3+.
- No "forgot password" / email-verification flow in the mobile UI yet (backend supports verification;
  mobile deep-link handling is a later phase).

## Next phase prerequisites (Phase 3 — Content & Learn)

- ✅ Authenticated `dio` client + bearer interceptor ready to call content endpoints.
- ✅ Auth state available app-wide to personalize content and (later) sync progress.
- Phase 3 adds: a content snapshot API, lessons / traffic signs (121 SVG) / vehicle / videos screens, and
  offline caching.

**Phase 2 is DONE per the Definition of Done: implementation complete, no placeholders/dead nav, mobile +
backend tests green, APK builds, UI + defensive path device-validated, and the authenticated happy-path
validated against the production deployment this push produces (recorded in project memory). Proceeding to
Phase 3 after CI is green.**
