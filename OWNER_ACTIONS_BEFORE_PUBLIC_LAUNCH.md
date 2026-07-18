# Owner Actions Before Public Launch

**Ehliyet Akademi — Final owner checklist**
_Last updated: 2026-07-18 (after Production Acceptance Test)_

All engineering is complete: the Launch Candidate, Program SEO, and the Production Acceptance Test
are done, committed, and deployed. Code is production-ready and hardened (see
`PRODUCTION_ACCEPTANCE_REPORT.md`, `LAUNCH_CANDIDATE_REPORT.md`, `SEO_IMPLEMENTATION_REPORT.md`).

This list contains **only** the actions that require **you (the owner)** — things I cannot do because
they need real money, legal identity, credential entry, DNS control, or search-engine account access.
Nothing here is a code task.

Priority: 🔴 before opening registration/taking money · 🟠 at/around launch · 🟢 soon after.

---

## 1. Production admin & email (🔴 before opening registration)

- [ ] 🔴 **Confirm a production admin exists.** The app no longer auto-promotes the first registrant
      to admin in production (security hardening). Set `ADMIN_EMAILS=you@yourdomain.com` (or
      `ADMIN_EMAIL_PATTERN`) in Vercel → Production, then register/verify that account is admin.
- [ ] 🔴 **Audit the prod `users` table for unexpected admins.** Earlier internal tests may have left
      an `admin-e2e-*` account with the admin role in the production database — remove any admin you
      don't recognize.
- [ ] 🔴 **Confirm `RESEND_API_KEY` is set in Vercel Production** (it is, per verification). Without
      it the app now fails closed on password reset (no token is ever returned), so email must work.

## 2. Payments — LemonSqueezy (🔴 for revenue)

> **The "premium not granted after payment" bug is FIXED in code.** Root cause: the webhook wrote the
> `purchases` table but the client only synced entitlements from a separate store, so the paid
> package never auto-unlocked. The app now reconciles server purchases → entitlements on every load
> and on checkout return (`?checkout=success`), sets the checkout `redirect_url`, and shows a success
> popup. Verified end-to-end in tests. Your remaining steps are a normal go-live check, not debugging.

- [ ] 🔴 **Set `LEMONSQUEEZY_VARIANT_KOMPLE_B`** in Vercel Production to the variant id of your one
      package (the app is now a **single-package** model — only Komple B is sold).
- [ ] 🔴 **Do one real (test-mode) purchase** on the live site and confirm: checkout opens → after
      paying you land back on `/fiyatlandirma?checkout=success` → the premium popup appears → premium
      is unlocked (and restores on another device via login).
- [ ] 🔴 **Confirm store payout/KYC is complete** (bank + tax) so money can settle.
- [ ] 🟢 **Upload the product image** to LemonSqueezy: use
      `apps/web/public/new_icon-lemonsqueezy.png` (1024×1024, generated for this).

## 3. Domain & DNS (🔴 for the branded site)

- [ ] 🔴 **Point `ehliyetegitim.com` at the Vercel project** (add apex + `www`, set the DNS records).
      The code already treats `ehliyetegitim.com` as canonical.
- [ ] 🔴 **Set `NEXT_PUBLIC_SITE_URL=https://ehliyetegitim.com`** in Vercel Production (makes it
      explicit for canonicals/OG/email links).
- [ ] 🟠 **Redirect the old `ehliyet-akademi-nine.vercel.app` → `ehliyetegitim.com`** once DNS is
      live, so the old URL isn't indexed as a duplicate. (The sitemap already emits only the branded
      domain, so there is nothing to remove there — this is just a 301 on the old host.)

## 4. Search engines (🟠 at launch)

- [ ] 🟠 **Google Search Console:** add + verify `ehliyetegitim.com` (DNS TXT, or set
      `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION` → the meta tag renders automatically), then submit
      `https://ehliyetegitim.com/sitemap.xml`.
- [ ] 🟠 **Bing Webmaster:** verify (or import from Google) + submit the sitemap. (IndexNow is already
      wired — the key file is live at `/<KEY>.txt`.)
- [ ] 🟢 **Yandex Webmaster:** verify (`NEXT_PUBLIC_YANDEX_VERIFICATION`) + submit sitemap.

## 5. Legal & business (🔴 before taking money)

- [ ] 🔴 **Legal seller entity** registered (to invoice + sign the payment provider).
- [ ] 🔴 **Consumer contracts reviewed by a lawyer:** the in-app `/kvkk`, `/gizlilik`,
      `/kullanim-kosullari`, `/cerez-politikasi` + a Distance Sales Agreement + refund/return policy —
      confirm your registered company name/address and VERBİS status are correct.
- [ ] 🟢 **Content authority:** get the question bank expert-reviewed (currently `review: 'draft'`).

## 6. Cost & monitoring (🟠 before real traffic)

- [ ] 🟠 **Set an Anthropic spend cap / budget alert** (AI Koç). The app rate-limits AI and falls back
      to a deterministic mock, but a hard ceiling prevents abuse-driven bills.
- [ ] 🟠 **Confirm Neon plan** matches expected concurrency; set a spend cap.
- [ ] 🟠 **Add error monitoring:** set `SENTRY_DSN` (the error boundaries already have the seam).
- [ ] 🟢 **Remove the unused `OPENAI_API_KEY`** from prod env (the AI path uses Anthropic).
- [ ] 🟢 **Analytics (optional):** set `NEXT_PUBLIC_GA_ID` / PostHog / Clarity (consent-gated).

---

## Minimum to open to the public

1. Prod admin confirmed + `RESEND_API_KEY` set (§1).
2. LemonSqueezy redirect verified + one real test purchase (§2).
3. `ehliyetegitim.com` DNS pointed + `NEXT_PUBLIC_SITE_URL` set (§3).
4. Legal entity + consumer contracts reviewed (§5).

Then submit the sitemap to Google/Bing (§4) and set an Anthropic cost cap + Sentry (§6). Everything
else in the product is done, tested, hardened, and deployed.
