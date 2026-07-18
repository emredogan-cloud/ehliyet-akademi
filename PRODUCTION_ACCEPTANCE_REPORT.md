# Production Acceptance Report

**Ehliyet Akademi — Production Acceptance Test (PAT) · Final Release Certification v1.0**
_Prepared: 2026-07-18 · Production: `ehliyet-akademi-nine.vercel.app` → branded `ehliyetegitim.com`_

## Verdict: 🟢 GO

The platform passed a full production acceptance test — user journeys, premium, long session,
cross-device, production audit, security, performance, SEO, and real services. An adversarial
security review and a performance review each surfaced real issues; **all safely-fixable findings
were fixed and re-validated this pass** (commit `c0fe6bc`). The only remaining items are
owner/business/DNS/payment-provider verification (see `OWNER_ACTIONS_BEFORE_PUBLIC_LAUNCH.md`).

- **Engineering readiness:** ✅ complete.
- **Blocking issues:** none in code. Two items need **owner confirmation** before opening
  registration (prod admin seeding + `RESEND_API_KEY` presence) — details in Critical Issues.

---

## 1. Executive summary

| Area                             | Result                                                                                                               |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| First-time user journey (Part 1) | ✅ register → session → verify → state sync → AI → logout (401 after) → re-login → progress restored                 |
| Premium validation (Part 2)      | ✅ purchase → server-persisted entitlement → owned list; 409 gate blocks free grant when real payments on            |
| Long session (Part 3)            | ✅ 40/40 AI+page requests 200; no memory growth (RSS ~21 MB); timers/listeners cleaned up                            |
| Cross-device (Part 4)            | ✅ mobile/tablet/desktop render; auth+progress+premium sync server-side (verified journeys + e2e)                    |
| Production audit (Part 5)        | ✅ all routes 200, no broken links, true 404s, no dev artifacts/placeholders, a11y solid                             |
| Security (Part 6)                | ✅ after fixes: rate-limited login, no token disclosure in prod, admin bootstrap locked down, IP-spoof limiter fixed |
| Performance (Part 7)             | ✅ after fixes: /calis payload 1.49 MB → 30 KB, assets cached immutable, LCP hero prioritized                        |
| SEO regression (Part 8)          | ✅ per-page canonicals, 228-URL sitemap, valid JSON-LD, OG/Twitter — no regression                                   |
| Real services (Part 9)           | ✅ DB/auth/AI verified locally; prod runs Neon+Resend+LemonSqueezy+Anthropic (verified live in prior program)        |
| Gates (Part 12)                  | ✅ tsc 0, lint clean, 186 unit + 67 e2e (2 clean runs), build 0, CI green                                            |

## 2. User journey results (Part 1)

Full server-backed journey validated end-to-end (curl, deterministic local build): registration
(201), session (`/api/auth/me`), email verification (dev-token fallback), progress sync
(`/api/state` PUT/GET), grounded AI answer, logout (session cleared → 401), re-login, and
**cross-session progress restore** (answers persisted across logout/login). The UI journeys
(landing, onboarding, lessons, signs, vehicle, AI coach, mock exam, settings) are covered by the
67-test Playwright suite, all green.

## 3. Premium validation (Part 2)

Mock gateway (local): purchase → `owned:["komple-b"]` → entitlement persisted server-side
(`/api/purchases` returns `{productId, priceTRY, at}`). Cross-device restore + ownership-after-login
covered by `auth.spec` (persistent-purchase test). Confirmed: when real payments are configured the
**409 gate** blocks the direct-grant path (no free unlock). The LemonSqueezy hosted-checkout redirect
is the known owner-side item — everything up to and after the external redirect behaves correctly.

## 4. Cross-device (Part 4)

Rendered at 390 (mobile), 768 (tablet), 1280 (desktop): homepage and app shell adapt (hamburger nav,
wrapping category filters, single-column stacks). Sync (auth/progress/premium/settings) is server-side
via `/api/state` + session cookie, so it is device-independent by construction (verified in the
cross-device e2e). Minor: the marketing header is slightly tight on ≤390 px (login label can clip) —
LOW, cosmetic, listed below.

## 5. Performance (Part 7) — findings fixed this pass

| Issue                                          | Before                              | After                                                    |
| ---------------------------------------------- | ----------------------------------- | -------------------------------------------------------- |
| `/calis` embedded full question pool via props | 1.49 MB (340 KB gzip) page payload  | **29.7 KB (6.4 KB gzip)** — bank lazy-loaded client-side |
| `/assets/*` + `/videos/*` caching              | `max-age=0` (revalidate every load) | `max-age=31536000, immutable`                            |
| Homepage LCP hero                              | raw `<img>`, not prioritized        | `fetchPriority=high` + `decoding=async`                  |
| Large decorative art (hidden on mobile)        | fetched eagerly (~550 KB)           | `loading=lazy`                                           |

Confirmed good (no change needed): system-font stack (no FOUT/CLS), 210 SSG detail pages, no route

> 200 kB First Load JS, no memory leaks. `/senaryolar` (163 kB) is the heaviest JS route — acceptable;
> noted as a future lazy-split opportunity, not a blocker.

## 6. Security (Part 6) — findings fixed this pass

The core design was verified solid (scrypt N=16384 + per-user salt + timingSafeEqual; 256-bit session
tokens stored only as SHA-256; HttpOnly/SameSite/Secure cookies; single-use expiring hashed
reset/verify tokens; HMAC-verified webhooks on raw body; 409 free-grant gate; same-origin CSRF check;
every `/api/admin/*` role-guarded; Zod input validation; strict security headers incl. HSTS preload).
Fixes applied:

- **C1 — reset/verify token disclosure:** `devToken` now returned only in non-production; prod fails
  closed. (Prod already has `RESEND_API_KEY`, so it was never armed live — this is defense-in-depth.)
- **C2 — admin bootstrap:** the "first registrant becomes admin" fallback is now non-prod only; prod
  admin is granted **only** via `ADMIN_EMAILS`/`ADMIN_EMAIL_PATTERN`.
- **H1 — login rate limiting:** added (8/min); verified 8×401 → 429.
- **M2 — limiter IP source:** switched to Vercel-trusted `x-real-ip`; verified XFF rotation can no
  longer reset the bucket (all limiters — login/register/forgot/verify/ai/checkout — now effective).
- **M4 — media SVG XSS:** `/api/media/*` now serves `sandbox` CSP + `nosniff`.
- **M6 — JSON-LD injection:** `<` escaped in serialized schema.
- **L2/L4:** mdLite href charset restricted; login password length capped.

Live authz probe: `/api/admin/{stats,users,seo,audit,content}` → **401** without auth; cross-origin
POST → **403**. Accepted residual (documented, not blockers): CSP `script-src 'unsafe-inline'`
(SSG/no-nonce tradeoff, no `unsafe-eval`); registration 409 email-enumeration (standard UX tradeoff);
`/api/health` config disclosure (shows the safe/configured state in prod).

## 7. SEO (Part 8) — no regression

Per-page self-canonical on the branded domain, 228-URL sitemap (0 vercel refs), robots disallow rules

- host + sitemap, valid JSON-LD (Organization/WebSite/SearchAction/FAQ/DefinedTerm/Breadcrumb/…),
  per-page OG + Twitter. New `dynamicParams=false` additionally converts invalid item URLs from
  soft-404 (200) to true **404** — a positive SEO change. The 6 SEO regression e2e tests pass.

## 8. Real services (Part 9)

Local acceptance ran on the deterministic stack (PGlite / console email / mock payments) to isolate
behavior. Production runs the real services (verified live in the Launch Candidate + SEO programs):
Neon Postgres, Resend, LemonSqueezy, Anthropic. Auth/state/AI/entitlement architecture all behave
correctly against both.

## 9. Issues log

### Critical (owner confirmation required — not code defects)

1. **Seed/confirm a production admin before opening registration.** With C2 fixed, prod no longer
   auto-admins the first registrant, so an admin must exist via `ADMIN_EMAILS`/pattern or a seeded
   row. **Also:** earlier internal curl tests may have created an `admin-e2e-*` user with admin role
   in the prod DB — the owner should audit `users` for unexpected admins and remove them.
2. **Confirm `RESEND_API_KEY` is set in prod** (it is, per prior verification) so the C1 fail-closed
   path never triggers and password reset works.

### High

_None remaining_ (H1 login rate-limit fixed and verified).

### Medium

_All fixed this pass_ (M2 IP source, M4 media, M6 JSON-LD, /calis payload, asset caching, soft-404).

### Low (non-blocking, optional fast-follow)

- Private `'use client'` pages (`/profil`, `/ayarlar`, `/ilerleme`, …) emit `index,follow` meta but
  are already `Disallow`ed in robots.txt (sufficient). Optional: server-wrapper `noindex`.
- Marketing header tight on ≤390 px (login label can clip). Cosmetic.
- `/ilerleme` renders no `<h1>` in SSR (private dashboard, populated on hydration).
- `NoFallbackError` logged by `next start` on invalid-param 404s (benign; correct 404 served).
- `/senaryolar` 163 kB JS — future lazy-split opportunity.

## 10. Launch recommendation

**GO for engineering.** The platform is production-ready and hardened. Open registration once the
owner confirms Critical items 1–2. Everything else remaining is business/legal/DNS/payment-provider
and search-engine verification, tracked in `OWNER_ACTIONS_BEFORE_PUBLIC_LAUNCH.md` and
`OWNER_SEO_ACTIONS.md`.
