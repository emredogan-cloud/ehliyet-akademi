# Owner Actions Before Public Launch

**Ehliyet Akademi — Launch Candidate Program (LCP) · P8**
_Last updated: 2026-07-18_

This document lists **only** the actions that require **you (the owner)** — things I cannot do
autonomously because they need real accounts, real money, legal identity, credential entry, or
external verification. Everything technically completable in code has already been done and is
recorded in `LAUNCH_CANDIDATE_REPORT.md`.

The product **already runs end-to-end today** in a safe fallback mode (mock payments, console
email, in-memory/real DB). None of the items below block _running_ the app — they block turning on
**real revenue, real email, and a public announcement**. Work them top-to-bottom.

---

## Legend

| Priority         | Meaning                                                                                    |
| ---------------- | ------------------------------------------------------------------------------------------ |
| 🔴 **Blocker**   | Public launch should not happen until this is done.                                        |
| 🟠 **Important** | Launch is possible without it, but you are leaving money/trust/observability on the table. |
| 🟢 **Optional**  | Nice to have; safe to defer past launch.                                                   |

Each item says **where** to set it. All secrets go in **Vercel → Project → Settings → Environment
Variables** (Production scope), _never_ committed to the repo. `.env.local` is git-ignored and is
for your machine only.

---

## 1. Legal & business (🔴 Blocker — you must own these)

Turkey sells a paid education service here, so these are non-negotiable before taking money:

- [ ] 🔴 **Business registration / şahıs şirketi or LTD** — you need a legal seller entity to
      invoice and to sign a payment provider. Payments cannot go live without it.
- [ ] 🔴 **KVKK (data protection) compliance** — the app already ships `/kvkk`, `/gizlilik`
      (privacy), `/kullanim-kosullari` (terms), and `/cerez-politikasi` (cookie policy) pages.
      **Have a lawyer review the wording** and confirm your registered company name, address, and
      VERBİS registration (if required for your data-processing volume) are correct in them.
- [ ] 🔴 **Mesafeli Satış Sözleşmesi (Distance Sales Agreement)** and **İade/Cayma (refund/return)
      policy** — mandatory for selling digital goods to consumers in Turkey. Draft text and confirm
      it is linked from the checkout/pricing flow.
- [ ] 🟠 **"MEB/MTSK resmî sınavı değildir" disclaimer** — the app already states this in-product.
      Confirm the phrasing satisfies your legal counsel (you are a prep tool, not the official exam).
- [ ] 🟠 **Content licensing** — confirm you have the right to publish the question bank
      (1534 questions) and all generated illustrations commercially.

## 2. Payments — LemonSqueezy (🔴 Blocker for revenue)

The code is fully wired for LemonSqueezy (hosted checkout + webhook entitlement grant). It is
currently in **mock mode** because no keys are set. To turn on real payments:

- [ ] 🔴 **Create/verify a LemonSqueezy store** and complete their KYC/payout onboarding
      (bank account, tax details). This is the money-in path.
- [ ] 🔴 **Create a product + variant** in LemonSqueezy for each paid package you sell. Today only
      `komple-b` has a variant mapping in code; decide which packages are actually purchasable.
- [ ] 🔴 Set in Vercel (Production):
  - `LEMONSQUEEZY_API_KEY`
  - `LEMONSQUEEZY_STORE_ID`
  - `LEMONSQUEEZY_WEBHOOK_SECRET` — **required** if the API key is set; the app refuses to trust
    unverified webhooks (env-check warns loudly if this is missing).
  - `LEMONSQUEEZY_VARIANT_<PRODUCT_ID>` — one per purchasable package, e.g.
    `LEMONSQUEEZY_VARIANT_KOMPLE_B=<variant-id>`. Products without a variant automatically show
    **"Yakında"** (coming soon) and cannot be bought — this is by design, not a bug.
  - Optionally `NEXT_PUBLIC_PAYMENT_PROVIDER=lemonsqueezy` if you want the UI to advertise it.
- [ ] 🔴 **Register the webhook** in LemonSqueezy → point it at
      `https://<your-domain>/api/webhooks/lemonsqueezy` and enable `order_created`
      (and subscription events if you use them).
- [ ] 🔴 **Do one real test purchase** end-to-end after going live (LemonSqueezy has a test mode) and
      confirm the entitlement is granted server-side and survives cross-device restore.

> Once real payment keys are present, the app automatically **closes the free-grant path**
> (`/api/purchases` returns 409) so nobody can self-grant a package without paying. Verified in code
> and integration tests.

## 3. Transactional email — Resend (🟠 Important)

Email is in **console mode** (verification/reset tokens are logged, not sent). Auth still works, but
users cannot self-serve password reset by email.

- [ ] 🟠 **Create a Resend account** and verify your sending **domain** (add their DKIM/SPF/Return-Path
      DNS records at your domain registrar). Until the domain is verified, delivery is unreliable.
- [ ] 🟠 Set in Vercel (Production):
  - `RESEND_API_KEY`
  - `EMAIL_FROM` — e.g. `Ehliyet Akademi <noreply@your-domain.com>` (must be on the verified domain)
  - `SUPPORT_EMAIL` — where support replies/inbound should go
- [ ] 🟠 After enabling, request a password reset in prod and confirm the email arrives and the link
      works. (With email configured, the dev-token fallback disappears automatically.)

## 4. Domain & site URL (🔴 Blocker for a public brand)

- [ ] 🔴 **Buy/assign the production domain** and attach it to the Vercel project
      (Vercel → Domains). The app currently defaults to `ehliyet-akademi-nine.vercel.app`.
- [ ] 🔴 Set `NEXT_PUBLIC_SITE_URL=https://<your-domain>` in Vercel (Production). This drives
      canonical URLs, OpenGraph/Twitter card URLs, `sitemap`/`robots`, and email links. Without it,
      email links and social cards use the fallback Vercel URL.
- [ ] 🟢 After DNS propagates, re-check the OG/Twitter preview with the real domain (see §7).

## 5. API billing / cost controls (🟠 Important)

- [ ] 🟠 **Anthropic (AI Koç)** — a real `ANTHROPIC_API_KEY` is already configured and the live AI
      path is verified. Before opening to the public, **set a monthly spend limit / budget alert** in
      the Anthropic console so a traffic spike (or abuse) cannot run up an unbounded bill. The app
      rate-limits AI to 20 req/min per client, and falls back to a deterministic grounded mock if the
      API errors — but you still want a hard cost ceiling.
  - [ ] 🟢 Optionally pin `ANTHROPIC_MODEL` (defaults to a Haiku-class model — cheap and fast).
- [ ] 🟠 **Neon (Postgres)** — confirm your Neon plan matches expected concurrency and set a
      spend/branch cap. Confirm connection pooling (the app uses the pooled `DATABASE_URL`).
- [ ] 🟢 `OPENAI_API_KEY` is present in your env but the product's AI path uses Anthropic. Remove it if
      unused, or wire it intentionally — don't leave an unused paid key exposed.

## 6. Monitoring & analytics (🟠 Important / 🟢 Optional)

The app has provider-agnostic hooks; nothing is sent until you supply IDs.

- [ ] 🟠 **Error monitoring** — set `SENTRY_DSN` (the error boundaries already have a "connect to
      Sentry here" seam). Strongly recommended so you see production errors instead of guessing.
- [ ] 🟢 **Product analytics** — set any of `NEXT_PUBLIC_GA_ID`, `NEXT_PUBLIC_POSTHOG_KEY`
      (+ `NEXT_PUBLIC_POSTHOG_HOST`), or `NEXT_PUBLIC_CLARITY_ID`. The cookie-consent banner already
      gates these behind user consent (KVKK-friendly).
- [ ] 🟢 **Search** — `SEARCH_PROVIDER` lets you plug Meili/Typesense/Algolia. A working local search
      is the default; upgrade only if you outgrow it.
- [ ] 🟢 **Admin allowlist** — set `ADMIN_EMAILS` (comma-separated) for production so admin access is
      explicit. (The `admin-e2e-*` pattern is test-only and not used in prod.)

## 7. Post-deploy verification (🟠 do this on the live URL, after §2–§4)

- [ ] 🟠 Register a real account → confirm it persists (Neon).
- [ ] 🟠 Complete a real (test-mode) purchase → confirm entitlement + cross-device restore.
- [ ] 🟠 Trigger a password reset → confirm the email arrives (needs §3).
- [ ] 🟠 Ask the AI Koç a question → confirm a real grounded answer.
- [ ] 🟢 Paste the homepage URL into the [Facebook Sharing Debugger] and
      [Twitter Card Validator] → confirm the `og.jpg` card renders.
- [ ] 🟢 Run Lighthouse on the live URL → confirm Core Web Vitals stay green under real network.
- [ ] 🟢 Submit `sitemap.xml` to Google Search Console for the production domain.

## 8. App store / distribution (🟢 Optional — PWA is already installable)

The app is an installable PWA today (manifest + service worker + offline fallback). Native store
listings are optional:

- [ ] 🟢 **Google Play** via TWA (Trusted Web Activity) / Bubblewrap if you want a Play listing.
- [ ] 🟢 **Apple App Store** — requires a native wrapper and an Apple Developer account ($99/yr).
- [ ] 🟢 Prepare store assets (icons, screenshots, description) — reuse the generated brand assets.

---

## Summary: the minimum set to take real money and announce

1. Legal entity + consumer contracts reviewed (§1).
2. LemonSqueezy live + webhook + one test purchase (§2).
3. Production domain + `NEXT_PUBLIC_SITE_URL` (§4).
4. (Strongly recommended) Resend email (§3) and Sentry (§6) before you send traffic.

Everything else in this repo is done, tested, and deployment-ready. See
`LAUNCH_CANDIDATE_REPORT.md` for the full engineering record and the GO/NO-GO verdict.

[Facebook Sharing Debugger]: https://developers.facebook.com/tools/debug/
[Twitter Card Validator]: https://cards-dev.twitter.com/validator
