# Mobile App Transformation — Masterplan

**Ehliyet Akademi · Web → Premium Mobile**
_Prepared: 2026-07-23 · Planning document — no implementation. Companion docs: `MOBILE_UX_AUDIT.md`,
`MOBILE_FEATURE_ROADMAP.md`, `AI_MOBILE_BEHAVIOR.md`, `APP_ARCHITECTURE_PLAN.md`._

---

## 0. Executive summary

Ehliyet Akademi is a mature, production Next.js 15 web platform (live on `ehliyetegitim.com`) with a
1562-question original bank, a full Question Intelligence Platform (QIP), grounded Anthropic AI, an
SRS engine, a polished token-based design system, and real payments/auth/admin. The goal is a
**premium native mobile app that preserves this identity**.

The single most important finding of this analysis: **most of the platform's intelligence and
content currently run client-side in TypeScript** (the question bank, QIP engine, exam generation,
SRS, design system in CSS). A mobile app therefore is not a "port of a few screens" — it is a
decision about **where that logic lives**. This masterplan recommends:

> **Recommended path: a Flutter client on top of a thin "Backend-for-Frontend" (BFF) API extracted
> from the existing app — keeping the QIP/content brains server-side and reusing them, not
> rewriting them in Dart.** A PWA/Capacitor route is a viable faster/cheaper alternative and is
> analyzed honestly below.

Two constraints shape everything and must be decided early:

1. **App-store IAP.** Apple and Google require **in-app purchase** for digital content. The current
   LemonSqueezy web checkout **cannot be used inside the app** without risking rejection. Premium on
   mobile = StoreKit / Google Play Billing with server receipt validation. This is a revenue +
   architecture decision, not a detail.
2. **Auth for mobile.** The web uses httpOnly cookie sessions. Mobile needs a **token-based** auth
   path (the API must issue/accept bearer tokens for the app).

---

## 1. Current system analysis (audit)

### 1.1 Architecture

- **Monorepo** (pnpm workspaces + Turborepo). Packages: `@ea/content-schema` (Zod contracts,
  `EXAM_BLUEPRINT`), `@ea/question-bank` (1562 authored questions), `@ea/srs-engine` (SM-2-style
  spaced repetition + readiness), `@ea/db` (Drizzle, dual pg/PGlite).
- **App**: Next.js 15 App Router (`apps/web`), ~40 page routes, ~40 API routes, vanilla CSS design
  tokens (no CSS framework), server components + client islands.
- **Hosting**: Vercel; branded domain `ehliyetegitim.com`. Real services: Neon Postgres, Resend
  (email), LemonSqueezy (payments), Anthropic (AI).
- **PWA**: an existing service worker (`public/sw.js`, cache `ea-v1`) — static cache-first, pages
  network-first + offline fallback, precache of core routes; installable manifest + icons. **A real
  offline/installability foundation already exists.**

### 1.2 Where the logic lives (critical for mobile)

| Subsystem                                                                                                    | Runs where today                                                      | Mobile implication                                         |
| ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- | ---------------------------------------------------------- |
| Question bank (1562)                                                                                         | Client TS (`@ea/question-bank`, lazy-loaded ~1.5 MB)                  | Needs an API **or** bundling into the app for offline      |
| QIP engine (normalize/categorize/quality/dedup/graph/families/exams/collections/adaptive/analytics/validate) | Mostly client TS in `apps/web/lib/qip`; some exposed via `/api/qip/*` | Promote to server API (BFF) — reuse, don't rewrite in Dart |
| Exam generation (dynamic, historical, collections)                                                           | Client + partial API (`/api/qip/collections`, `/api/qip/historical`)  | Expose full exam-build API                                 |
| SRS / readiness                                                                                              | Client TS (`@ea/srs-engine`) + localStorage                           | Reimplement on-device (small, pure) or call API            |
| AI grounded answers                                                                                          | **Server** (`lib/server/ai.ts`, Anthropic) via `/api/ai/ask`          | Reuse directly                                             |
| Auth / sessions                                                                                              | Server (cookie sessions)                                              | Add token auth                                             |
| Entitlements                                                                                                 | Server `purchases` table (truth) + localStorage cache                 | Reuse truth via API; local cache in secure storage         |
| Design system                                                                                                | CSS tokens (`globals.css`)                                            | Translate tokens → Flutter `ThemeData` (1:1)               |
| Assets                                                                                                       | SVG signs (121), vehicle photos/posters, icons, 8 videos, animations  | Bundle/CDN; SVG → `flutter_svg`, Lottie/Rive for motion    |

### 1.3 Subsystem inventory (all present, production)

Dashboard/home (`/panel`), Lessons (`/dersler`), Traffic signs (`/isaretler`, 121 SVG), Vehicle
(`/arac`), Videos (`/videolar`), Theory exam (`/e-sinav`, `/deneme-sinavi`), Smart practice
(`/calis`, SRS), Visual quiz (`/gorsel-quiz`), Scenarios (`/senaryolar`), Collections
(`/koleksiyonlar`), Historical formats (`/cikmis-sinavlar`), Diagnostic (`/tani`), AI Coach
(`/ai-koc`), Progress/XP (`/ilerleme`), Readiness (`/hazirlik-skorum`), Study plan
(`/calisma-plani`), Achievements (`/basarilar`), Search (`/arama`), Pricing/premium
(`/fiyatlandirma`), Settings/Profile (`/ayarlar`, `/profil`), Auth (`/giris`, `/dogrula`,
`/sifirla`), Admin (9 screens), Legal (KVKK/gizlilik/etc.).

### 1.4 Design system (to preserve exactly)

- **Color:** primary teal `#0d9488` / bright `#14b8a6`; accent amber `#f59e0b`; semantic
  red/yellow/green/blue; accent hues teal/amber/blue/purple/red/green. **Light + dark** themes
  (`data-theme` + `prefers-color-scheme`).
- **Spacing:** 8px grid (`--sp-1..12`). **Radius:** 16px base, pill. **Type scale:** `--fs-xs..3xl`.
  **Motion:** `--dur-fast/base/slow` + `--ease`/`--ease-out` (`cubic-bezier(0.16,1,0.3,1)`).
- **Shell:** persistent left sidebar (desktop) + mobile drawer + TopBar (theme/notifications/avatar);
  grouped nav (Öğren / Pratik / İlerleme / Hesap). Card-centric, premium, calm.

### 1.5 What's already "mobile-ready"

- Responsive layout + mobile drawer, PWA install + offline shell, real-device validated (prior
  sprints, Android via ADB). This means **the fastest route to a store presence is the PWA/Capacitor
  path** — see §3.

---

## 2. Reuse vs. rewrite map

**Reuse directly (server/API, no change):** grounded AI (`/api/ai/ask`), auth logic (add token
layer), entitlements truth (`purchases`), state sync (`/api/state`), QIP intelligence (promote to
API), the entire content bank + schema (server or bundle), analytics events, email, admin (stays
web).

**Reuse as source-of-truth, re-express on client:** design tokens → `ThemeData`; SRS engine (small
pure TS → Dart port or API); readiness computation; XP/gamification rules.

**Rebuild native (mobile-only):** onboarding, bottom-tab navigation, gestures, push notifications,
IAP, on-device offline DB + sync, native animations/haptics, home widgets (optional), share sheets.

**Do NOT bring to mobile v1:** the full Admin/CMS/SEO/media suite (stays web — admins use the web
panel). Marketing/legal pages (link out to web).

---

## 3. Strategic architecture decision (the core choice)

Three honest options. All keep the **existing Next.js backend + QIP + content** as the brain.

### Option A — Flutter client + BFF API (recommended for the premium native target)

Flutter app consumes a clean JSON API extracted from the web app. QIP/content stay server-side and
are **reused, not rewritten**. Design tokens → `ThemeData`. Offline via a local DB (Drift/Isar) that
mirrors a bundled/synced content snapshot.

- **Pros:** best native feel + performance + gestures + push + IAP + App/Play Store presence; single
  content/logic source (server); brand-grade polish.
- **Cons:** highest effort; must build the BFF API surface (§ `APP_ARCHITECTURE_PLAN.md`); a second
  UI codebase (Dart) to maintain alongside the web UI; SRS/readiness either ported or API-served.
- **Effort:** high. **Time-to-store:** medium-long. **Best long-term ceiling.**

### Option B — PWA / Capacitor wrapper (fastest, lowest-risk, strong reuse)

Ship the existing web as an installable app. Two sub-variants: pure PWA (TWA on Android, add-to-home
on iOS) or **Capacitor** (native shell around the web, giving native push, IAP plugins, splash,
haptics). The service worker + manifest already exist.

- **Pros:** near-zero rewrite; design preserved 1:1 automatically; one codebase; weeks not months to
  a store build; all QIP/content reused as-is.
- **Cons:** "native feel" ceiling lower than Flutter (scroll/gesture nuances); iOS PWA push is
  limited (Capacitor fixes this); store review scrutiny for "just a website" (mitigated by real
  native features: push, IAP, offline, onboarding).
- **Effort:** low-medium. **Time-to-store:** short. **Best ROI / risk profile.**

### Option C — Hybrid (Flutter shell + WebView content)

Flutter for chrome (onboarding, tabs, home, notifications) + WebView for heavy content screens.
Usually the worst of both (integration seams, auth bridging). **Not recommended** except as a
transitional step.

### Recommendation

- If the business goal is a **flagship native app** (brand, App Store ranking, richest UX, push-led
  engagement) and there is budget for a sustained build: **Option A (Flutter + BFF)** — and the
  `APP_ARCHITECTURE_PLAN.md` details it as the primary plan since the brief asked for Flutter.
- If the goal is **store presence + push + IAP quickly with minimal risk and one codebase**: **Option
  B (Capacitor)** first, optionally migrating hot screens to Flutter later.

> **Pragmatic hybrid recommendation:** Start the BFF API extraction now (valuable for _both_ options),
> ship **Capacitor** as an early store beachhead for push/IAP/engagement, and build the **Flutter**
> client in parallel/after against the same API. This de-risks time-to-market while still reaching
> the premium native target. The Flutter plan below assumes Option A as the destination.

---

## 4. Design preservation strategy

The mobile app must feel like the same product. The mechanism:

1. **Tokenize once, map everywhere.** Extract `globals.css` `:root` tokens into a single
   `design-tokens.json` (color/space/type/radius/motion). Generate the Flutter `ThemeData` (and
   Capacitor CSS) from it, so web and mobile share one source of truth.
2. **Component parity table** (in `MOBILE_UX_AUDIT.md`): every web UI primitive (Card, PageHeader,
   Callout, EmptyState, quiz, badges, PremiumBadge, MasteryRadar, StudyHeatmap) gets a named Flutter
   equivalent with the same spacing/radius/elevation/motion.
3. **Preserve micro-interactions:** the `--ease-out` curve, card hover→press, reveal animations →
   Flutter implicit animations + `flutter_animate`; keep durations identical (140/240/400 ms).
4. **Assets 1:1:** SVG signs via `flutter_svg` (keep the shape+glyph system, not raster); vehicle
   photos/posters via CDN + cache; app icon/splash from the existing `new_icon.png`.
5. **Light/dark parity:** the app ships both themes from day one, mirroring the web toggle.

---

## 5. Experience pillars (detailed in companion docs)

- **Onboarding** (new): premium 4–6 screen intro (platform → AI Coach → learning/exam → progress →
  personalization → premium), goal/exam-date setup feeding adaptive learning. See `MOBILE_UX_AUDIT.md`.
- **Home** = the dashboard as the app's center: readiness ring, weak-topic nudges, daily plan, quick
  actions, streak, AI Coach entry. Interactive, not a static list.
- **AI Coach = proactive assistant**, not a chatbot: welcome, daily motivation, weak-topic
  suggestions, reminders, progress summaries, achievement celebration, exam-readiness, contextual
  tips, push. Fully specified in `AI_MOBILE_BEHAVIOR.md`.
- **Notifications**: intelligent, contextual, capped, opt-in. See `AI_MOBILE_BEHAVIOR.md`.
- **Offline-first practice**: bundled/synced bank + local SRS → study anywhere; sync on reconnect.

---

## 6. Risk analysis (top risks)

| Risk                                                           | Severity                   | Mitigation                                                                                                                 |
| -------------------------------------------------------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **IAP / store-billing rules** — can't ship web checkout in-app | High (revenue + rejection) | Native IAP (StoreKit/Play Billing) + server receipt validation; keep LemonSqueezy for web only; model price parity         |
| **Logic duplication** if QIP is rewritten in Dart              | High (maintenance)         | BFF API — keep QIP server-side; port only tiny pure pieces (SRS)                                                           |
| **Content sync/offline correctness**                           | Medium                     | Versioned content snapshot + local DB (Drift) + answer-log sync queue; deterministic seeds already exist                   |
| **Auth token security on device**                              | Medium                     | Short-lived access + refresh token in secure storage (Keychain/Keystore); rotate; existing session table extended          |
| **AI cost from proactive nudges**                              | Medium                     | Server-side nudge engine mostly deterministic (QIP data); LLM only for chat + occasional summaries; per-user caps; caching |
| **Push fatigue / opt-out**                                     | Medium                     | Frequency capping, quiet hours, granular categories, ML-light relevance (weak-topic/streak triggers)                       |
| **Two codebases drift (web + Flutter)**                        | Medium                     | Shared tokens + shared API contract + shared content schema (OpenAPI/JSON); contract tests                                 |
| **Scope creep (porting admin/CMS to mobile)**                  | Low-Med                    | Admin stays web (explicitly out of mobile v1)                                                                              |
| **iOS review ("thin wrapper")** for Capacitor path             | Medium                     | Ship genuine native value: push, IAP, offline, onboarding, haptics                                                         |

---

## 7. Phase overview (full detail in `MOBILE_FEATURE_ROADMAP.md`)

0. **Foundations** — BFF API extraction + token auth + design-token export + content snapshot API.
1. **App shell** — Flutter project, ThemeData from tokens, bottom-tab navigation, auth flow, home.
2. **Learn** — lessons, signs, vehicle, videos (content screens, offline read).
3. **Practice & Exams** — smart practice (SRS), dynamic/historical/collection exams, results.
4. **AI Coach** — chat + the proactive nudge engine + notifications.
5. **Progress & Gamification** — readiness, XP, achievements, study plan, analytics.
6. **Premium** — native IAP + entitlement sync + upsell surfaces.
7. **Polish & Launch** — onboarding, animations/haptics, accessibility, tablet, offline hardening,
   store submission, beta.

Each phase is independently testable and ships value.

---

## 8. Final recommendations

1. **Decide the client strategy first** (Option A vs B) — it changes everything downstream. Default
   recommendation: **BFF now + Capacitor beachhead + Flutter as the destination** (hybrid rollout).
2. **Extract the BFF API before any client work** — it's the reusable asset for both paths and forces
   a clean contract around the QIP/content brains.
3. **Solve IAP + token-auth in Phase 0** — they are the two hard constraints; everything else is
   translation.
4. **Preserve the design via one token source** — never hand-recolor the app.
5. **Make the AI proactive from Phase 4** — it's the premium differentiator; build the deterministic
   nudge engine (QIP-driven) and add LLM only where it adds value.
6. **Keep admin/CMS on web** — do not port it.
7. **Ship offline-first practice** — the bank + SRS make this a genuine, ownable advantage.

This masterplan, with the four companion documents, is the foundation for the mobile build. No code
should be written until the client-strategy decision (§3) and the Phase-0 API/IAP/auth contracts are
approved.
