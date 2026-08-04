# Ehliyet Akademi — Project Status

**Snapshot date:** 4 August 2026 · **Branch:** `main` @ `55151b4` · **App version:** `1.0.0+5`

> **This is the single source of truth for project state.** Every number below was measured from
> the repository or the live API on the snapshot date — not copied from older reports.
> `STATUS.md` (16 July) and `NEXT_SESSION_START.md` (26 July) are **stale**; prefer this file.
> Per-sprint reports remain as history only.

---

## 1. Executive Summary

Turkish driving-licence (ehliyet) exam-prep product: a **Flutter Android app** backed by a
**Next.js web app + API** in a pnpm/Turborepo monorepo. It is **in Google Play Closed Beta**,
feature-complete for its beta scope, and fully green on CI.

Scale today: **1,605 text questions + ~665 device-generated visual questions**, 29 lessons,
31 database tables, 58 API routes, ~140k lines of first-party code, **1,796 automated tests**.

The defining engineering property is a **measured content-quality gate**. An audit found 91.1% of
the bank was answerable without reading the question (pick the longest option); that is now
**21.6%**, against a 25% random baseline — i.e. option length no longer carries information. The
gate is a **ratchet**: thresholds may only move down, and CI enforces today's best value.

---

## 2. Completed Milestones

| System                       | State                                                                                                                             |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Mobile app**               | Complete beta scope: onboarding, coach marks, learn, practice, exams, collections, profile, settings, dark/light, offline mode    |
| **Question engine (QIP v3)** | 8 question kinds, 6 exam modes, difficulty balancing, option shuffling, visual-question generation, `ExamPlan` self-reporting     |
| **Question quality program** | Measured gate + ratchet; 494 questions rewritten, 43 authored, 60 shipped truncated answers repaired, answer positions rebalanced |
| **Visual questions**         | 0 → ~665 generatable, drawn on-device from existing catalogues, **zero new asset bytes**                                          |
| **Lessons**                  | 18 `CustomPainter` diagrams (theme-aware, scale-aware, zero bytes); 19 of 29 lessons carry a figure                               |
| **Exam library**             | "Sınav Arşivi" — 6 categories, deterministic date-seeded generation, 3 free exams catalogue-wide                                  |
| **Duel mode**                | Matchmaking, 10 questions × 20 s, accuracy-weighted scoring, energy limits, anti-farming                                          |
| **Premium / billing**        | Play Billing via `in_app_purchase`; 3 packages; live localised pricing verified on device                                         |
| **Social / community**       | Profiles, friends, discussions, messaging, groups, leaderboards — **off by default**, explicit opt-in gate                        |
| **AI**                       | Grounded Q&A (Claude Haiku 4.5) with hallucination gate, sources, disclaimer, mock fallback; on-device coach heuristics           |
| **Auth**                     | Email/password, Google Sign-In, guest mode with progress preservation                                                             |
| **Play readiness**           | Signed AAB, Play App Signing, closed beta live, store listing + data-safety content drafted                                       |
| **CI/CD**                    | 3 workflows (CI, Mobile CI, CodeQL) + gitleaks + commitlint + Playwright E2E — all green on `main`                                |

---

## 3. Current Architecture

- **Mobile** — Flutter 3.41 / Dart 3.11, 46,495 lines across 207 files. Riverpod providers,
  freezed models, `CustomPainter` for all diagrams, `AppPalette`/`AppSpacing` design tokens.
  minSdk 24 / targetSdk 36. 23 runtime dependencies. Offline-first with a local content cache.
- **Web** — Next.js App Router (~49,552 lines TS/TSX): marketing site, SEO pages, admin/CMS UI,
  and the API the mobile app consumes.
- **Backend** — 58 API routes in the same Next.js deployment on Vercel. Mobile reads exactly two:
  `/api/mobile/question-bank` and `/api/mobile/content-snapshot`.
- **Database** — PostgreSQL (Neon), `drizzle-orm`. **31 tables** bootstrapped by idempotent
  `CREATE TABLE IF NOT EXISTS` in `packages/db/src/index.ts` (no migration files). CMS tables
  (`content_items`, `content_versions`, `media_assets`, `audit_logs`) use JSONB payloads validated
  by Zod, so content shape can evolve without migrations.
- **Authentication** — email/password with verification + reset tokens, Google Sign-In, guest mode.
  Bearer sessions in a `sessions` table. **Google login requires the
  `GOOGLE_SERVER_CLIENT_ID` dart-define at build time** — omit it and the button silently vanishes.
- **Premium / Billing** — `in_app_purchase` → Play Billing. Three packages: weekly ₺50 and monthly
  ₺200 (subscriptions), **lifetime ₺479.99 (one-time, recommended)**. The lifetime product ID stays
  `komple-ehliyet` for backward compatibility — a test locks this. RevenueCat was removed
  (dead code, −1.59 MB APK). Prices shown on screen come **only** from the store, never the catalogue.
- **AI** — Anthropic Claude Haiku 4.5 server-side. A grounding gate refuses ungrounded questions,
  answers carry sources and a disclaimer, and an offline mock composer is the fallback. The mobile
  AI Coach (insights, 7-day plan, nudges) is **on-device heuristics**, not an LLM call.
- **Question engine** — Zod content schema; questions live **in code** (`packages/question-bank`,
  38 files) for offline shipping. Visual questions are generated **on the device** from bundled
  catalogues (121 signs, 60 warning lights, 101 mechanical parts), so the server never ships a
  question whose image the device lacks. Quality metrics and thresholds live in
  `packages/content-schema/src/quality.ts`.

**Critical operational fact:** questions and lessons reach users from the **deployed API**, not the
APK. A content change is only live after a web deploy — a locally built APK will not show it.

---

## 4. Current Product Status

A user today can: onboard and get a personalised plan; study 29 lessons with drawn diagrams;
practise with spaced repetition; sit full 50-question MEB-format exams (45 min) or quick/adaptive
sets; browse the exam archive with 3 free exams; answer visual questions on signs, warning lights
and mechanical parts; play Duel mode against a deterministic AI opponent; track readiness, streaks,
badges and levels; ask the AI coach grounded questions; invite friends via deep links for rewards;
opt into community features; buy premium at live Play pricing; and **use the whole app offline**
from cache.

**Live in production (verified this snapshot):** the API is serving **1,605 questions** — including
the 43 new ones — and **19 figure-bearing lessons**. The content work from the last two sprints has
reached users.

---

## 5. Remaining High-Priority Work

### P0 — Blocks public launch (security)

1. **Server-side Play receipt verification is a scaffold, not an implementation.**
   `verifyPlayPurchase` in `apps/web/app/api/iap/validate/route.ts:33` returns `valid: true` for any
   token ≥ 4 characters; there is no `googleapis` dependency and no `androidpublisher` call anywhere.
   Today production is safe _only because_ the env var is unset: the route returns 503 when
   `GOOGLE_PLAY_SA_JSON` is missing. **Setting that variable removes the fail-closed guard and
   activates the stub** — any authenticated user could then self-grant lifetime premium with a
   4-character string. Older docs list "set `GOOGLE_PLAY_SA_JSON`" as the fix for this blocker; that
   advice is actively unsafe until the real check exists. Implement verification and the env var
   together, never separately.

### P1 — Before public launch (owner/manual)

2. **Play "Data Safety" form** — content already drafted in `PLAY_DATA_SAFETY.md`.
3. **App Links** — refresh `assetlinks.json` with the Play App Signing SHA-256; sideloaded builds
   cannot pass verification (custom scheme `ehliyetakademi://` works regardless).
4. **Price consistency** — docs and catalogue say ₺399, the store charges ₺479.99. Screens already
   show only the store price; the documents need reconciling.

### P2 — Product depth

5. **347 questions** still flag on the longest-option metric (trafik 200, pratik 89, ilkyardım 58).
   Below the random baseline, so not an exploitable tell — but their options are unreviewed.
6. **Voice narration** — model, provider abstraction and UI rule are done; no audio exists, so the
   player correctly renders nothing. Needs a TTS provider and files under the agreed naming scheme.
7. **Missing sign pictograms** — 18 signs need real artwork (prompts written in
   `ASSET_GENERATION_LIBRARY.md` §7). 17 numeric speed-limit signs are deliberately procedural.
8. **Mascot animation** — blink/gaze needs 5-layer assets (prompts in §8); current motion is
   procedural transforms only.
9. **Exam modes `quick` / `random` / `adaptive`** are callable in code but have no UI entry point.

---

## 6. Known Limitations / Technical Debt

- **Play receipt verification stub** — see P0; the single most consequential item in the repo.
- **Documentation sprawl** — ~130 markdown files at repo root, most of them per-phase history.
  `STATUS.md` and `NEXT_SESSION_START.md` are stale and contradict current numbers.
- **Web integration tests are flaky** — several hit a shared Neon database concurrently and time out
  on first run, passing on retry. Product code is not implicated.
- **No migration files** — schema is bootstrapped by idempotent SQL. Fine so far; a real
  destructive schema change will need a migration story.
- **`.env` formatting trap** — `GOOGLE_SERVER_CLIENT_ID ="…"` has a space before `=` and a trailing
  comment; `source .env` silently skips it and naive `sed` extraction embeds the comment, producing
  a build with a broken client ID.
- **Device coverage is narrow** — most verification is on Redmi Note 8 (Android 11). The preferred
  Redmi Note 11R (Android 13) carries a Play-installed beta, so locally signed builds refuse to
  install; clearing it is the owner's decision. The Huawei (Android 9, 360 dp) is effectively unusable.
- **Web `LessonFigure` lags mobile** — 12 SVGs vs 18 mobile figures; unknown IDs render nothing.
- **`lean()` projection drops `image`** — irrelevant while visual questions are device-generated,
  but blocks any future server-sent visual question.
- **Hotspot regions** are reserved in the schema but not drawn.

---

## 7. Recommended Next Sprint Order

1. **Implement real Play receipt verification** (P0) — `googleapis` + `purchases.products.get`,
   `purchaseState == 0`, then set `GOOGLE_PLAY_SA_JSON`. Nothing else should ship before this.
2. **Close the owner-side launch blockers** — Data Safety form, `assetlinks.json`, price reconciliation.
3. **Finish the question-quality pass** — the remaining 347 questions, using the existing
   `quality-worklist.mjs` / `apply-option-patches.mjs` tooling.
4. **Documentation consolidation** — retire or archive the ~130 root reports behind this snapshot.
5. **Voice narration** — connect a TTS provider to the finished abstraction.
6. **Visual asset production** — the 18 sign pictograms and the 5-layer mascot.
7. **Expose the unused exam modes** and broaden real-device coverage (Android 13, 360 dp).

---

## 8. Production Readiness

**Ready today:** the mobile app (signed AAB, closed beta live), the question engine and content
pipeline, the web app and API, authentication including Google Sign-In, the database layer, AI Q&A
with its hallucination gate, community features behind an opt-in gate, and the full CI suite
(1,796 tests, CodeQL, secret scanning, E2E).

**Requires manual work before public release:** implementing Play receipt verification (P0); the
Play Data Safety form; `assetlinks.json` with the production signing fingerprint; price
reconciliation; and a first real-money purchase performed by the owner to validate the end-to-end
entitlement flow. Purchases will not sync across devices until item 1 is genuinely done.

**Build note:** release builds **must** pass
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com`, or Google login
disappears from the binary with no error.

---

## 9. Long-Term Vision

Grow the bank well beyond 1,605 questions while holding the quality gate — the ratchet makes
"more content" and "worse content" mutually exclusive by construction. Extend visual coverage into
photorealistic scenarios (engine bay, cockpit, intersections, first aid) once assets exist. Ship
real voice narration on the abstraction already in place. Take Duel mode online through the existing
`DuelOpponent` interface, which was designed so the screen code will not change. Evolve the AI coach
from on-device heuristics toward genuinely adaptive, grounded tutoring. Then iOS/App Store, which
requires a billing abstraction the current Play-only path does not yet have.
