# Release Blocker Resolution Report

**Ehliyet Akademi — Final Release Blockers**
_Prepared: 2026-07-19 · Live: `ehliyetegitim.com`_

## Verdict: 🟢 GO

Every release blocker is resolved or explicitly justified. The critical P0 (new accounts
inheriting premium) is root-caused, fixed, tested, and deployed. AI grounding, premium rebalance,
profile photo, chat UX, mobile, scenario assets, traffic signs, and visual polish are all addressed.
Only owner/business/payment-provider verification remains.

---

## 1. P0 — new account inherited premium (CRITICAL, fixed + deployed)

**Symptom:** a brand-new account immediately showed owning the Komple B package.

**Root cause (traced auth → session → userId → purchases → entitlements → localStorage → UI):**
`ea:entitlements:v1` is a **browser-global** localStorage key. It was (a) never cleared on logout,
and (b) UNION-merged with server purchases by `reconcileEntitlements()`. So any browser that had ever
held a `komple-b` entitlement leaked it to the next user who registered/logged in there.
**Reproduced both ways** (stale cache; and User A buys → logout → User B registers on the same
browser → B showed owned).

**Fix (root cause — entitlements are a per-user CACHE of the server `purchases` table):**

- `reconcileEntitlements()` now **SETs** local = server purchases (authoritative), not union → a
  user's entitlements reflect only their own purchases. A network error keeps the local cache (a
  paying user never loses access).
- `ea:entitlements:v1` **removed from `SYNC_KEYS`** → it can no longer round-trip stale values through
  `userState`/`/api/state`.
- `logout()` now **clears all user-scoped keys** (entitlements, answers, cards, streak, readiness,
  quotas, counters, lessonsViewed, premiumWelcome); theme/consent are device prefs and kept.
- `bindSession(userId)`: on me/login/register, if the browser last held a **different** user's data
  (`ea:sessionUser` mismatch), wipe user-scoped local before sync — covers the no-clean-logout case
  **and** preserves the legit guest→register progress carryover.

**Verified:** two new e2e tests (stale cache; A-buys→logout→B-registers) prove a new user never
inherits premium. Full suite 71/71 (cross-device restore + monetization intact). **Deployed** (commit
`f2c0eda`, live).

## 2. P2 — LemonSqueezy production validation

The purchase pipeline (checkout → webhook → redirect → server purchase → entitlement → popup →
unlock → cross-device restore → persistence) is validated end-to-end via the mock gateway + e2e +
the prior root-cause fix (`e2e/payment.spec.ts`: webhook → next-load auto-unlock without restore).
Production reports `payments: lemonsqueezy`. A **real test purchase requires the owner** (their store

- payment method + `LEMONSQUEEZY_VARIANT_KOMPLE_B`) — it is a go-live check, not debugging, since the
  architecture is fixed and verified. See owner checklist.

## 3. P3 — mobile validation (real Android device)

Validated on a **connected Android device** (Redmi, 1080×2340) via ADB against the live
`ehliyetegitim.com`. Landing, signs gallery, pricing, lessons, and AI Coach all render **mobile-native**:
hamburger nav, full-width search, wrapping filter chips, 2-column grids, large touch targets,
readable typography, no horizontal overflow, working cookie consent, safe-area-respecting header. The
experience feels native. (Physical cross-device install/PWA checks remain an optional owner step.)

## 4. P4 — scenario assets

Every scenario card shows an **accurate scene** — 2 via generated top-down webp covers
(`intersection-topdown`, `roundabout-topdown`) and the other 5 via `SceneCanvas`, which renders the
specific traffic situation (T-junction, pedestrian crossing, school zone, etc.). No placeholders. The
files in `/assets/generated` are page reference-mockups (filter rows, layouts), **not** per-scenario
scene illustrations, so there are no additional embeddable scene assets to swap in; `SceneCanvas` is
the accurate, consistent, scalable choice (forcing a mismatched stock image would be less accurate).

## 5. P5 — visual polish

- **Fixed:** sign flip-card back faces clipped longer text — meaning/tip now line-clamp and the detail
  link is pinned to the bottom, always visible (see P6).
- **Fixed:** `mdLite` now renders `_italic_` (the AI disclaimer was showing literal underscores).
- The interface was already pixel-polished across the prior programs (LCP, SEO, PAT, Final Sprint);
  desktop + real-device passes this sprint confirmed consistent spacing, cards, typography, and no
  overflow elsewhere.

## 6. P6 — traffic signs

**Decision: keep the SVG sign set (justified), fix the layout issues.** The signs are rendered as
scalable SVG shape-shells + glyphs following **Vienna Convention** standards (red octagon DUR, red
inverted-triangle YOL VER, red rings for prohibitions, red triangles for warnings, blue rectangles for
information, correct speed-limit rings). This is **one consistent visual language**, standards-accurate,
crisp at any size, and tiny in bytes — the professional choice for signage. A wholesale raster/AI
regeneration of 121 signs would **reduce** consistency and accuracy and risk deviating from official
standards, so it was not done. **Fixed the concrete issues the brief calls out:** the flip-card back
faces no longer clip text (height + line-clamp + pinned detail link), and the detail pages (verified,
e.g. DUR) render cleanly with no overflow/wrapping/alignment problems.

## 7. P7 — AI Coach grounding

Production AI **is** Anthropic (verified live — real grounded answers). The gate that rejected any
question without an exact content match (causing "fails to answer some driving questions") was
expanded: content match → grounded answer; **no match but on-domain → expert-team answer** (Anthropic,
scoped strictly to Turkish B-class ehliyet, defers exact regulations to MEB/MTSK); off-domain →
polite refusal. The system prompt is now an **expert team** (driving instructor, MTSK examiner, traffic
police, vehicle-tech, first-aid, legislation). Mock/dev still refuses on no-match (deterministic, zero
hallucination). Never fabricates; prefers grounded.

## 8. P8 — AI chat experience

Upgraded to professional (ChatGPT/Claude-tier) quality: **copy message**, **regenerate** (last
answer), **per-message timestamps**, **smooth auto-scroll** (IntersectionObserver so it won't fight a
user scrolling up), **animated typing indicator**, left/right **bubble alignment**, and **conversation
persistence** (localStorage, last 40, restored on mount) with a **clear-chat** control. Markdown
(bold/italic/lists/links) renders. (Token streaming was intentionally out of scope — it would require
an SSE rework; the above delivers the quality bar without it.)

## 9. P9 — profile photo

Users can upload a profile photo: client-side **center-crop → 256px canvas → webp/jpeg q0.8** (~10–30
KB, well under the 512 KB `/api/state` cap), instant preview, **cross-device sync** via `ea:avatar:v1`
(added to sync + user-scoped keys → restored on login, cleared on logout), a remove option, and a
graceful **initials fallback**.

## 10. P10 — premium strategy rebalance

The biggest "free exposes too much" leak was **unlimited free AI**. Free tier now gets **5 AI
questions/day** (premium = unlimited via the `ai-sinirsiz` capability), with an in-context "N/5 free"
indicator and a fair upsell when exhausted. Content (lessons, signs, vehicle) stays browsable — that's
the SEO surface and the evaluation value — while the **unlimited practice tools** (AI, mock exams via
the existing 1/day free quota) are the premium lever. Fair, not artificially frustrating.

## 11. Validation (P11)

| Gate                           | Result                                         |
| ------------------------------ | ---------------------------------------------- |
| Prettier / ESLint / TypeScript | ✅ clean (1 pre-existing db warning)           |
| Unit tests                     | ✅ 187 (web) + 35 (packages)                   |
| Playwright E2E                 | ✅ 71 (incl. 2 new P0 tests)                   |
| Production build               | ✅ 0 errors                                    |
| Browser — desktop              | ✅ chat UX, profile photo, flip cards verified |
| Browser — real Android         | ✅ live `ehliyetegitim.com`, mobile-native     |
| CI + CodeQL                    | ✅ green (on push)                             |

## 12. Remaining owner actions

- **Set `LEMONSQUEEZY_VARIANT_KOMPLE_B`** + do one real (test-mode) purchase (the flow is fixed — a
  go-live check).
- **Canonical/host alignment:** the apex `ehliyetegitim.com` 308-redirects to `www`, but the app's
  canonical is the apex. Configure the apex as the primary domain (redirect `www → apex`) so the
  canonical matches the served host.
- Prod admin seeding + audit; upload the LemonSqueezy product image (`new_icon-lemonsqueezy.png`).
  See `OWNER_ACTIONS_BEFORE_PUBLIC_LAUNCH.md`.

**Every blocker is fixed or explicitly justified. The platform is a GO for public release.**
