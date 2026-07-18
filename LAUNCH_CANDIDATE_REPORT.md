# Launch Candidate Report

**Ehliyet Akademi — Launch Candidate Program (LCP) · Final Product Hardening v1.0**
_Prepared: 2026-07-18_

## Verdict: 🟢 GO (as a launch candidate)

The platform is **production-ready from an engineering standpoint** and can be deployed to
production today. It runs end-to-end, every quality gate is green, and every real integration for
which credentials exist is live and verified. The remaining gate to a **public, revenue-taking
launch** is **owner/business setup, not code** — legal contracts, a live payment provider, and a
production domain. Those are enumerated in `OWNER_ACTIONS_BEFORE_PUBLIC_LAUNCH.md`.

- **Ship the code:** ✅ ready now.
- **Take real money & announce publicly:** ⏳ gated on the owner checklist (payments, legal, domain).

---

## 1. Scope of this program

LCP was a **hardening** pass, not feature development. No new product surface was added; the goal was
to make the existing product launch-safe. Concretely, this program:

- Polished asset/visual integration so illustrations blend into the UI (not bare rectangles).
- Enabled every real service with available credentials (DB, AI) and left the rest fallback-ready.
- Hardened performance, security, accessibility, SEO, error handling, and PWA/offline.
- Ran a full production audit for dead code, placeholders, mock data, debug artifacts, and dead links.
- Made the E2E suite deterministic and fast.
- Produced this report and the owner-actions checklist.

## 2. Quality gates — all green

The full CI-parity gate (`pnpm gates` + E2E, mirroring `.github/workflows/ci.yml`) passes:

| Gate                             | Result                                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------------------ |
| Workspace verify (`pnpm verify`) | ✅ 358 files scanned — no placeholder/secret residue                                       |
| Prettier format check            | ✅ All files conform                                                                       |
| ESLint                           | ✅ No warnings or errors                                                                   |
| TypeScript typecheck             | ✅ Clean across all packages                                                               |
| Unit tests                       | ✅ 186 (apps/web) + 35 (packages: content-schema 9, srs-engine 12, question-bank 10, db 4) |
| Production build                 | ✅ Compiles; all routes prerendered/typed                                                  |
| Playwright E2E                   | ✅ **61/61 passing**, deterministic (~11s)                                                 |

## 3. Performance (Core Web Vitals posture)

The main risk was the **1534-question bank** leaking into first-load JS. It was pulled out of the
critical path on the three heaviest routes via lazy `import()` and code-splitting:

| Route      | Before | After      |
| ---------- | ------ | ---------- |
| `/ai-koc`  | 624 kB | **160 kB** |
| `/arama`   | 584 kB | **104 kB** |
| `/e-sinav` | 590 kB | **128 kB** |

Full route table: shared baseline **~103 kB** First Load JS; the heaviest route is `/ai-koc` at
160 kB; everything else sits between 103–144 kB — comfortably within budget. Content-heavy pages
(`/dersler/[slug]`, `/arac/[id]`) are **statically prerendered** (SSG) for fast first paint and SEO.

Supporting perf work: WebP assets throughout, dark/light theme applied pre-paint (no FOUC), service
worker caches static assets cache-first and pages network-first.

## 4. Assets & visual integration

- All generated illustrations were processed to WebP and composed into the UI as **hero
  backgrounds, banners, lesson/feature icons, mascots, and section art** — not raw rectangles.
- Reusable CSS composition primitives (`.banner-art`, `.level-avatar`, `.coach-hero__img`,
  `.lesson-card__img`, `.mk-feature__img`, `.poster-card`, etc.) blend art with masks/fades.
- A dedicated **1200×630 `og.jpg`** social card was produced for link previews.
- The served, referenced assets live under `apps/web/public/assets/**` (tracked). Raw source image
  working directories are git-ignored to keep the repo lean.

## 5. Security

All six production security headers verified on the live response:

- `Content-Security-Policy` (strict; `script-src 'self' 'unsafe-inline'`, no `unsafe-eval`)
- `Strict-Transport-Security` (2-year max-age, preload)
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy` (camera/mic/geo/interest-cohort all denied)

Additional posture: rate limiting on auth and AI endpoints; password reset/verify tokens are SHA-256
hashed at rest with expiry; **free-grant purchase path auto-closes (409) once real payments are
configured**; webhooks require a secret (env-check refuses partial payment config); admin access is
allowlist-driven in production; CodeQL runs in CI.

## 6. Accessibility

- Every `<img>` carries an `alt` (decorative images use `alt=""`); 87 explicit `aria-label`s across
  icon-only controls.
- Chat/live regions use `aria-live`; forms use labeled inputs; focus and hover states are styled.
- Color themes maintain contrast in both light and dark.

## 7. SEO & structured data

- `sitemap.xml` (26 URLs) and `robots.txt` both serve 200.
- Canonical URLs, OpenGraph (with `og.jpg`), and Twitter `summary_large_image` card in metadata.
- JSON-LD structured data across **6 schema types**: Organization, WebSite, LearningResource,
  Course, Quiz, AlignmentObject.
- `manifest.webmanifest` generated (installable PWA), Turkish locale, theme colors.

## 8. Reliability & error handling

- Route-level error boundary (`app/error.tsx`) **and** root-level boundary
  (`app/global-error.tsx`, added in this program) for full coverage.
- `not-found.tsx` custom 404. Service worker offline fallback serves the precached home shell.
- API endpoints degrade honestly (friendly 503 when a service is unconfigured) rather than crashing.

## 9. Real services status

| Service              | Provider                  | Status in this environment    | Verified                                                              |
| -------------------- | ------------------------- | ----------------------------- | --------------------------------------------------------------------- |
| Database             | Neon Postgres             | ✅ Live (`DATABASE_URL`)      | Register, `/api/state` sync, content pipeline all round-trip via curl |
| AI Koç               | Anthropic                 | ✅ Live (`ANTHROPIC_API_KEY`) | Real grounded markdown response returned                              |
| Email                | Resend                    | ⚠️ Fallback (console mode)    | Auth works; owner must add `RESEND_API_KEY`                           |
| Payments             | LemonSqueezy              | ⚠️ Fallback (mock)            | Full code path ready; owner must add keys + variant                   |
| Analytics/Monitoring | GA/PostHog/Clarity/Sentry | ⚪ Off until IDs set          | Consent-gated hooks in place                                          |

The fallback modes are **deliberate and honest** — the app is fully usable without paid services, and
flips to real behavior the moment credentials are supplied. No mock data is presented to users as if
it were real.

## 10. E2E determinism (engineering note)

The suite was made reliable by isolating it from external-service latency (which had made it flaky):

- AI forced to the deterministic MockModel for tests (real API is ~5 s/req and rate-limited).
- DB forced to a **fresh in-memory PGlite** per run (removes real-Neon network latency and cross-run
  state accumulation that had produced an intermittent "restore" failure).
- Worker concurrency capped to **3** so the single-threaded PGlite backend is never saturated (the
  12-core default of 6 workers caused 30 s timeouts).
- A latent controlled-input race in the AI Koç chat (a lazy import's late re-render could reset the
  input) was fixed by splitting the read-only rail into its own component.

Real-service integration is verified separately (curl + integration tests), so forcing mocks in E2E
does not reduce coverage of the production paths.

## 11. Known limitations (not launch blockers)

- **Email and payments run in fallback mode here** because no credentials are set. They are
  code-complete and flip on when the owner supplies keys (see owner checklist §2–§3).
- **`OPENAI_API_KEY` is present but unused** — the AI path uses Anthropic. Owner should remove it or
  wire it intentionally.
- **Analytics/Sentry are off** until IDs are provided (consent-gated).
- These are all **owner-configuration** items, not defects.

## 12. Next step

Follow `OWNER_ACTIONS_BEFORE_PUBLIC_LAUNCH.md`. The minimum path to a public, revenue-taking launch:
legal entity + consumer contracts, LemonSqueezy live with a test purchase, a production domain with
`NEXT_PUBLIC_SITE_URL`, and (strongly recommended) Resend email + Sentry before sending traffic.

**Engineering readiness: complete. The product is a GO to deploy as a launch candidate.**
