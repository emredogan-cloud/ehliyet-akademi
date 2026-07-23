# App Architecture Plan

**Ehliyet Akademi · Mobile technical architecture (Flutter + BFF)**
_Prepared: 2026-07-23 · Planning document. Parent: `MOBILE_APP_MASTERPLAN.md`._

This is the technical blueprint for the recommended path (Flutter client on a Backend-for-Frontend
API that reuses the existing QIP/content brains). Where the Capacitor path differs, it's noted.

---

## 1. Reuse-first principle

Keep the mature server-side assets; add a clean contract; do **not** re-implement the QIP engine or
content in Dart.

| Layer                                                                  | Decision                                                               |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Backend (Next.js API routes)                                           | **Reuse + extend** with a mobile-facing BFF surface                    |
| QIP engine (`apps/web/lib/qip`)                                        | **Reuse server-side**; expose lightweight views via API                |
| Content bank (`@ea/question-bank`, lessons, signs, vehicle, scenarios) | **Reuse** as a versioned snapshot delivered to the app                 |
| Content schema (`@ea/content-schema`)                                  | **Reuse** as the shared DTO contract (generate Dart models from it)    |
| SRS (`@ea/srs-engine`)                                                 | **Port to Dart** (small, pure) for offline; server stays authoritative |
| AI (`lib/server/ai.ts`)                                                | **Reuse** `/api/ai/ask` unchanged                                      |
| Auth/entitlements/state                                                | **Reuse** logic; add token auth + IAP validation                       |
| Design tokens (`globals.css`)                                          | **Reuse** via a single `design-tokens.json` → `ThemeData`              |
| Admin/CMS/SEO/media                                                    | **Stay web** — not in the app                                          |

---

## 2. The BFF API contract

The web app currently mixes server rendering with heavy client logic. For a Flutter client we need a
**stable JSON API**. Some already exist; the rest are new. Ship an **OpenAPI spec** as the shared
contract (contract-tested against both web and mobile).

### Exists (reuse)

- `POST /api/auth/{register,login,logout,forgot,reset,verify}`, `GET /api/auth/me`
- `GET/PUT /api/state` (sync of `ea:*` progress keys)
- `GET /api/purchases`, `POST /api/checkout`, `POST /api/webhooks/lemonsqueezy` (web billing)
- `POST /api/ai/ask` (grounded AI)
- `GET /api/qip/collections`, `GET /api/qip/historical` (+`/[id]`), `GET /api/qip/related/[id]`,
  `POST /api/qip/report`
- `GET /api/health`, `POST /api/support`, `POST /api/account` (delete)

### New (to build in Phase 0)

- **Token auth mode** on `login`/`register`: return `{ accessToken (short-lived JWT), refreshToken }`
  in addition to the cookie; `POST /api/auth/refresh`; accept `Authorization: Bearer` on all routes.
- **Content delivery:** `GET /api/content/manifest` → `{ version, hashes, urls }`; `GET
/api/content/bundle?since=<ver>` → questions + lessons + signs + vehicle + scenarios snapshot
  (delta-capable). (Alternative: bundle v1 content in the app binary; use the API for updates.)
- **Exam build:** `POST /api/exams/dynamic` (`{count, subjects?, difficultyBalance?, noRepeatImage?,
seed}`) → exam; wraps `buildDynamicExam`. (Historical/collections already exist.)
- **Coach nudges:** `GET /api/coach/nudges` (deterministic, per-user) + `POST /api/coach/ack`
  (see `AI_MOBILE_BEHAVIOR.md`).
- **IAP validation:** `POST /api/iap/validate` (`{platform, receipt/token, productId}`) → verifies
  with Apple/Google, writes to `purchases`, returns entitlements.
- **Push registration:** `POST /api/push/token` (`{fcmToken, platform, prefs}`).
- **Progress/analytics views** (optional convenience): `GET /api/progress/summary` (readiness, weak
  topics, XP, streak) so the app doesn't recompute the graph on device.

### Contract & security

- Versioned (`/api/v1/...` or header), rate-limited (existing limiter), CORS locked to the app,
  request signing optional. Errors in a consistent envelope. Everything a Bearer token or session.

---

## 3. Content & offline strategy

The bank (1562 Qs) + lessons + signs are ~1.5–3 MB — small enough to **ship offline**.

- **v1:** bundle a content snapshot in the app binary (fast first run, zero-net practice). Store in a
  local **Drift** (SQLite) DB on first launch.
- **Updates:** on launch (online), check `/api/content/manifest`; if a newer version exists, fetch
  the delta and update the local DB. Versioned + hashed for integrity.
- **Offline generation:** exams/collections/historical use **deterministic seeds** (already in the
  QIP design — `seededRng`, `seedFromDate`), so the app can build the _same_ exams offline as the
  server. SRS runs locally (ported engine). Visual questions generate from bundled signs/parts.
- **Answer sync queue:** every answer/grade/XP event is written locally + queued; a background sync
  flushes to `/api/state` on reconnect (idempotent, last-write-wins per key, matching the current
  web sync model). Optimistic UI throughout.
- **What must be online:** AI chat, IAP, purchase, fresh coach nudges (cached copy shown offline).

---

## 4. Flutter application architecture

**Layered, feature-first, testable.**

```
lib/
  app/            # bootstrap, router, theme, DI
  core/           # tokens→theme, network client, storage, errors, result types
  design/         # AppCard, AppPageHeader, AppCallout, QuizCard, MasteryRadar, ... (parity set)
  data/           # DTOs (from content-schema), repositories, local (Drift), remote (dio)
  domain/         # entities, use-cases (practice, exam, readiness, nudges), SRS (ported)
  features/
    home/ learn/ practice/ exams/ coach/ progress/ premium/ onboarding/ auth/ settings/
  l10n/           # Turkish strings (single locale v1)
```

- **State management: Riverpod** (recommended). Rationale: compile-safe DI, testable, granular
  rebuilds, async/stream providers fit the sync+offline model, no BuildContext coupling. (Alternatives:
  Bloc — more ceremony but great for complex exam flows; acceptable. Avoid ad-hoc setState for app
  state.)
- **Routing: `go_router`** — declarative, deep-link/push-target friendly, nested navigators per
  bottom tab (preserve tab stacks).
- **Networking: `dio`** + interceptors (auth refresh, retry, offline detection) + `retrofit`
  optional. DTOs via `freezed` + `json_serializable`, generated from the shared schema.
- **Local DB: `drift`** (typed SQLite) for content snapshot + progress + sync queue. Secure key/value
  (`flutter_secure_storage`) for tokens.
- **Result/error:** `Result<T>`/`Either` types; no exceptions across layers.

---

## 5. Design tokens → ThemeData (preserve identity 1:1)

Single source: export `globals.css :root` into `design-tokens.json`, generate a `AppTheme`:

- **Colors:** `primary #0d9488`, `primaryBright #14b8a6`, `accent #f59e0b`, semantic
  red/green/blue/yellow, accent hues → `ColorScheme` (light + dark from the web's `data-theme=dark`
  palette).
- **Type scale:** `--fs-xs..3xl` → `TextTheme` (bodySmall…displayLarge); same font family (embed the
  web font or its closest; keep weights).
- **Spacing:** `--sp-1..12` → `AppSpacing` constants (8px grid). **Radius:** 16/10/22/pill →
  `AppRadii`. **Motion:** 140/240/400 ms + `Cubic(0.16,1,0.3,1)` → `AppMotion` (used by
  `flutter_animate`/implicit animations).
- **Both themes** ship day one; a `themeMode` provider mirrors the web toggle + system.

Golden tests lock the parity (a card, a quiz item, a header render pixel-close to the web reference).

---

## 6. Assets & animation

- **Traffic signs:** keep the **vector** system — render via `flutter_svg` from the same shape+glyph
  definitions (or export the 121 signs to SVG once). No raster regeneration (matches the web's
  Vienna-standard decision).
- **Photos/posters (vehicle, art):** bundle small ones; `cached_network_image` for the rest via CDN.
- **App icon / splash:** `flutter_launcher_icons` + `flutter_native_splash` from `public/new_icon.png`
  - brand teal.
- **Animations:** implicit animations + `flutter_animate` for micro-interactions (reveal, press,
  counters); **Lottie/Rive** for onboarding + celebration (confetti on exam pass, badge unlock);
  scenario scenes via `CustomPainter` (port `SceneCanvas`) or Rive. Honor reduced-motion.
- **Haptics:** `HapticFeedback` on select/success/tab.

---

## 7. Auth & session on device

- Login/register → `{accessToken (JWT, ~15 min), refreshToken (long, rotating)}` stored in secure
  storage. `dio` interceptor refreshes on 401. Optional biometric unlock (`local_auth`) to re-enter.
- Guest mode: local progress (Drift) with a "sync when you sign up" merge (mirrors the web
  guest→register carryover; reuse the `bindSession` clearing logic conceptually).
- Logout clears secure storage + user-scoped local data (parity with web `clearUserScoped`).

---

## 8. Payments — the IAP constraint (must-solve)

**App stores require in-app purchase for digital goods.** LemonSqueezy web checkout cannot be used
inside the app.

- **Plugin:** `in_app_purchase` (StoreKit 2 on iOS, Google Play Billing on Android).
- **Products:** define the single Komple B entitlement as a non-consumable / subscription in App
  Store Connect + Play Console (price parity with web where possible; note Apple's 15–30% cut affects
  margin — model it).
- **Flow:** purchase → obtain receipt/purchase token → `POST /api/iap/validate` → server verifies with
  Apple/Google → writes `purchases` → returns entitlements → local cache updates (reuse the existing
  entitlement reconcile model; **server is the source of truth**).
- **Restore purchases** button (Apple requirement). Cross-platform entitlement: a purchase on any
  platform grants access everywhere (server-linked to the user account).
- **Web keeps LemonSqueezy**; the two billing sources reconcile into the same `purchases` table.
- **Compliance:** don't link to external web payment from inside the iOS app (Apple rules); the web
  remains the place for web purchases.

---

## 9. Push & notifications

- **FCM** (Android + iOS via APNs). Register token → `POST /api/push/token`.
- **Server**: the deterministic nudge engine (cron) sends targeted push (opted-in, capped, quiet
  hours) with deep links.
- **On-device**: `flutter_local_notifications` for time-based reminders (study time), scheduled
  locally so they fire offline; respects quiet hours + category prefs.
- This is a key reason Flutter/Capacitor beats pure PWA (iOS PWA push is limited).

---

## 10. Repo & tooling

- **Monorepo home:** add `apps/mobile` (Flutter) beside `apps/web`, sharing `design-tokens.json` + the
  OpenAPI contract + (generated) Dart models from `@ea/content-schema`. Keeps tokens/contract in sync.
- **Flavors:** `dev` (staging API) / `prod`. Env via `--dart-define`.
- **CI/CD:** GitHub Actions or **Codemagic** + **Fastlane** — build, test, sign, TestFlight/Play
  internal track, then production. Contract tests run against the API in CI.
- **Testing:** unit (domain/use-cases/ported SRS), widget (screens), golden (design parity),
  integration (`integration_test`, critical flows: onboarding→practice→exam→sync, IAP sandbox),
  contract (mobile DTOs vs OpenAPI). Mirror the web's rigor (the web is at 314 tests).
- **Observability:** crash reporting (Sentry/Crashlytics), analytics events (reuse the web analytics
  event vocabulary), performance traces.

---

## 11. Estimated development order (see `MOBILE_FEATURE_ROADMAP.md` for detail)

`Phase 0 (BFF API + token auth + IAP validate + tokens export + content snapshot)` → `Phase 1 (shell,
theme, nav, auth, home)` → `Phase 2 (learn)` → `Phase 3 (practice + exams + offline)` → `Phase 4 (AI
coach + nudge engine + push)` → `Phase 5 (progress + gamification)` → `Phase 6 (premium IAP)` →
`Phase 7 (onboarding, animation, a11y, tablet, launch)`.

Phase 0 is backend-only and benefits the web too; do it first regardless of client strategy.

---

## 12. Key decisions to lock before coding

1. **Client strategy** — Flutter+BFF (this plan) vs Capacitor beachhead vs both (recommended hybrid).
2. **Content delivery** — bundle vs API snapshot vs both (recommend: bundle v1 + API updates).
3. **IAP product model** — one-time vs subscription; price parity; margin after store cut.
4. **Token auth design** — JWT lifetimes, refresh rotation, guest→account merge.
5. **State management** — Riverpod (recommended) confirmed.
6. **Where SRS runs** — ported to Dart for offline (recommended) vs API-only.

Once these are approved and Phase 0 contracts are drafted, implementation can begin — not before.
