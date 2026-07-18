# Owner SEO Actions

**Ehliyet Akademi — PROGRAM SEO · Part 17**
_Last updated: 2026-07-18 · Production domain: `https://ehliyetegitim.com`_

This lists **only** the SEO tasks that require **you (the owner)** — DNS, domain, and search-engine
account verification that I cannot do autonomously. Everything technically completable in code is
done and recorded in `SEO_IMPLEMENTATION_REPORT.md`.

Priority: 🔴 do before/at launch · 🟠 soon after · 🟢 optional.

---

## 1. Domain & DNS (🔴 the foundation for everything below)

- [ ] 🔴 **Point `ehliyetegitim.com` at the Vercel project** (Vercel → Project → Domains → add
      `ehliyetegitim.com` and `www.ehliyetegitim.com`). Add the A/CNAME records Vercel shows at your
      DNS provider (Cloudflare or registrar). Pick one canonical host (apex `ehliyetegitim.com`
      recommended) and 301-redirect the other — the code already treats the apex as canonical.
- [ ] 🔴 **Set `NEXT_PUBLIC_SITE_URL=https://ehliyetegitim.com`** in Vercel (Production). The code
      already defaults to this domain, but setting the env makes it explicit and covers previews.
- [ ] 🟠 If you use **Cloudflare**, keep SSL "Full (strict)", enable HTTP/2/3 and Brotli (Vercel does
      this by default anyway), and do **not** enable Cloudflare's "Auto Minify" on HTML (can break
      inline JSON-LD in rare cases).

## 2. Google Search Console (🔴)

- [ ] 🔴 **Add the property** for `https://ehliyetegitim.com` (Domain property via DNS TXT is best —
      covers all subpaths + protocols).
- [ ] 🔴 **Verify.** Two supported methods, pick one:
  - DNS TXT record (Domain property) — preferred.
  - HTML meta tag — set `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION=<token>` in Vercel; the code already
    renders `<meta name="google-site-verification">` from it automatically. Redeploy, then verify.
- [ ] 🔴 **Submit the sitemap:** `https://ehliyetegitim.com/sitemap.xml` (228 URLs).
- [ ] 🟠 Request indexing for the homepage and a few key hubs (`/dersler`, `/isaretler`, `/arac`).
- [ ] 🟠 Check **Enhancements → FAQ, Breadcrumbs, Video, Course** reports after a few days to confirm
      rich results are picked up.

## 3. Bing Webmaster Tools + IndexNow (🟠)

- [ ] 🟠 **Add & verify** `ehliyetegitim.com` (you can import directly from Google Search Console).
  - Or set `NEXT_PUBLIC_BING_VERIFICATION=<token>` → the code renders the `msvalidate.01` meta tag.
- [ ] 🟠 **Submit the sitemap** in Bing Webmaster.
- [ ] 🟢 **IndexNow is already wired.** The key file is live at
      `https://ehliyetegitim.com/<KEY>.txt` (see `apps/web/lib/seo/indexnow.ts` for the key). Bing
      auto-detects it. To change the key, set `INDEXNOW_KEY` env and rename the public key file to
      match. You can push URL updates any time from **Admin → SEO → "IndexNow'a gönder"**.

## 4. Yandex Webmaster (🟢 — meaningful traffic share in TR)

- [ ] 🟢 **Add & verify** the site (DNS or `NEXT_PUBLIC_YANDEX_VERIFICATION=<token>` → the code
      renders the yandex-verification meta tag).
- [ ] 🟢 Submit the sitemap. Yandex also consumes IndexNow (already set up).

## 5. Google Business Profile & Knowledge Panel (🟠 — entity/brand SEO)

- [ ] 🟠 If you register a legal business, create a **Google Business Profile** for "Ehliyet Akademi"
      so the brand can earn a knowledge panel. Use the same name, logo, and `ehliyetegitim.com`.
- [ ] 🟢 Create the brand's **social profiles** (X/Twitter, Instagram, YouTube, LinkedIn) and add
      their URLs to `SITE_SAME_AS` in `apps/web/lib/seo/site.ts` (currently empty — I do not invent
      profiles). This wires them into the Organization `sameAs` for the knowledge graph. Redeploy.

## 6. Social preview & analytics verification (🟢)

- [ ] 🟢 After the domain is live, paste the homepage into the
      [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/) and
      [Twitter Card Validator](https://cards-dev.twitter.com/validator) to confirm the `og.jpg` card
      renders with the branded domain.
- [ ] 🟢 Validate a few pages in Google's
      [Rich Results Test](https://search.google.com/test/rich-results): homepage (Course, FAQ), a
      sign (`/isaretler/dur` → DefinedTerm, Breadcrumb), a vehicle part with steps (HowTo), `/videolar`
      (Video). The code emits valid JSON-LD; this just confirms Google accepts it live.
- [ ] 🟢 Confirm analytics is live if you set it (`NEXT_PUBLIC_GA_ID` / PostHog / Clarity) — SEO and
      analytics are independent, but you'll want traffic data before/after launch.

## 7. Content authority (🟢 — ongoing, human)

- [ ] 🟢 Get the question bank **expert sign-off** (questions currently carry `review: 'draft'`).
      Real E-E-A-T (author credentials, review dates) strengthens ranking for YMYL-adjacent education
      content. When you have a named reviewer, we can add `reviewedBy` / author schema.
- [ ] 🟢 Do **not** add fake reviews/ratings. When you have genuine, verifiable student reviews, they
      can be added with real `Review`/`AggregateRating` schema — the code deliberately omits these
      until they are real.

---

## Summary — the minimum to be discoverable

1. DNS: point `ehliyetegitim.com` at Vercel + set `NEXT_PUBLIC_SITE_URL` (§1).
2. Google Search Console: verify + submit `sitemap.xml` (§2).
3. Bing: verify + submit sitemap (IndexNow already live) (§3).

Everything in code — canonical, 228-URL sitemap, robots, structured data (11 schema types),
favicons, verification meta hooks, IndexNow — is done and deployed. See
`SEO_IMPLEMENTATION_REPORT.md` for the full record and GO/NO-GO.
