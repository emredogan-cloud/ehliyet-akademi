# Founder Release Checklist — Ehliyet Akademi 1.0.0

**Updated:** 11 August 2026. Tick as you go. Full instructions for every line:
**`FOUNDER_RELEASE_HANDOOK.md`**.

> **The release verdict cannot be PASS while any 🔴 box is unticked.** Send me the evidence and I
> will re-run the affected verification and update `FINAL_PRE_PRODUCTION_AUDIT.md`.

---

## ✅ Already done — no action needed

These were open on 10 August and are now closed. Listed so you do not redo them.

- [x] **F-04** 🔴 Play service account created, granted, and `GOOGLE_PLAY_SA_JSON` set
  - **I verified it against Google's live API on 11 Aug**: our package answers `400` to a bogus
    token while a foreign package answers `401`. That difference proves the Console grant exists,
    for both the product and the subscription endpoints.
- [x] **F-15** 🔴 Production keystore present and Gradle signing is fail-closed
  - ⚠️ **Still yours:** back up the keystore and its passwords off this machine.
- [x] **F-02** partial — `support@ehliyetegitim.com` created and wired into both env vars
- [x] **F-06** Retention periods defined, published, and enforced by a daily job

---

## A · Legal and identity

- [ ] **F-01** 🔴 Four legal env vars still missing in Vercel → Production
  - [ ] `LEGAL_COMPANY_NAME`
  - [ ] `LEGAL_TAX_ID`
  - [ ] `LEGAL_ADDRESS`
  - [ ] `LEGAL_KEP_ADDRESS`
  - [x] `LEGAL_SUPPORT_EMAIL` — set by me, 11 Aug 2026
  - ⚠️ **All five must be present.** With four of five the page still shows "not yet published".
  - **Then redeploy.** Env changes do not affect the running deployment.
  - **Evidence:** `curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "henüz yayımlanmadı"` → `0`
- [ ] **F-02** 🔴 Confirm a human actually reads `support@ehliyetegitim.com`
- [ ] **F-03** 🔴 Lawyer reviewed `/gizlilik`, `/kvkk` and `/hesap-silme`
- [ ] **F-06** 🟡 Lawyer confirms or overrides my retention defaults
  - [ ] 365 days anonymous analytics · 90 days error logs · 180 days closed moderation records
  - [ ] **Decision needed:** purchase records are now **deleted with the account**; the financial
        record lives with Google Play. Confirm this satisfies your book-keeping obligations.

## B · Billing

- [ ] **F-12** 🔴 Three products created in Play Console — **IDs use underscores**
  - [ ] `komple_ehliyet` — one-time (managed), **Active**
  - [ ] `premium_haftalik` — subscription, weekly base plan, **base plan Active**
  - [ ] `premium_aylik` — subscription, monthly base plan, **base plan Active**
  - [ ] No free trial / introductory offer (no listing text claims one)
  - [ ] Türkiye pricing set; lifetime price confirmed (documentation records ₺479,99)
  - **Evidence:** screenshot of the products list showing all three Active, with prices
- [ ] **F-05** 🔴 Licence tester account added
- [ ] **F-05** 🔴 Real purchase — `komple_ehliyet` **Evidence:** screenshot
- [ ] **F-05** 🔴 Real purchase — `premium_haftalik` (**never exercised before this release**)
- [ ] **F-05** 🔴 Restore after clean reinstall works
- [ ] **F-05** 🔴 Entitlement follows the account on a second device
  - ⏸️ **Do not start F-05 until the newest AAB is on closed testing and reaches your tester account.**
- [ ] **F-16** ⚪ _Optional:_ RTDN Pub/Sub topic, to close the refund/revocation gap
- [ ] ⚪ _Optional housekeeping:_ delete `REVENUECAT_SECRET_KEY` from Vercel — nothing reads it

> **Do not configure RevenueCat.** It is not in the current architecture. Handbook explains why.

## C · Android configuration

- [ ] **F-07** 🟠 `ANDROID_SHA256_FINGERPRINTS` set from **App signing key** (not upload key)
  - **Evidence:** `curl -s https://www.ehliyetegitim.com/.well-known/assetlinks.json` → populated array

## D · Play Console — App content

- [ ] **F-08** 🔴 Data Safety form completed per declarations guide §6–§8
  - [ ] Privacy policy URL: `https://www.ehliyetegitim.com/gizlilik`
  - [ ] Data deletion URL: `https://www.ehliyetegitim.com/hesap-silme`
  - [ ] **Photos declared as COLLECTED** (avatar upload — older doc said otherwise)
  - [ ] **Community UGC declared** (older doc covered only AI Koç)
- [ ] **F-09** 🔴 Content rating completed — **user-to-user interaction = YES**
- [ ] **F-09a** 🔴 Alcohol-content answer decided (curriculum covers alcohol and driving)
- [ ] **F-10** 🔴 Target audience: **18 and over**
- [ ] **F-10** 🔴 Ads: **No**
- [ ] **F-10** 🔴 News app: **No**
- [ ] **F-10** 🔴 Government app: **No** (no MEB affiliation claimed anywhere)
- [ ] **F-10** 🔴 Health app: **No**
- [ ] **F-10** 🔴 Generative AI declared with safeguards
- [ ] **F-10** 🔴 Independent security review **NOT** ticked (none was commissioned)

## E · Store listing

- [ ] **F-11** 🔴 App name: `Ehliyet Akademi: Deneme Sınavı`
- [ ] **F-11** 🔴 Short description pasted (74 chars)
- [ ] **F-11** 🔴 Full description pasted (3.056 chars)
- [ ] **F-11** 🔴 Eight screenshots uploaded from `apps/ASO_IMAGE/PLAY_READY/` **in filename order**
- [ ] **F-11** 🔴 Feature graphic uploaded
- [ ] **F-11** 🔴 App icon uploaded (one, global)
- [ ] **F-11** Nothing pasted from `STORE_LISTING.md` (superseded)
- [ ] **F-13** 🟡 Reviewer notes added

## F · Release

- [ ] **F-14** 🔴 Closed-testing requirements met (tester count + continuous days), if applicable
- [ ] **F-14** 🔴 Production access confirmed
- [ ] Final AAB uploaded (I build it — see `FINAL_RELEASE_AAB_REPORT.md`)
- [ ] Release notes pasted (tr-TR)
- [ ] Staged rollout percentage chosen

---

## What I still owe you after you finish

1. Re-probe `/gizlilik`, `/kvkk`, `/hesap-silme` and `assetlinks.json` live
2. Re-run the purchase-verification path against your real test purchase
3. Re-run the connected-device E2E for the purchase and deletion flows
4. Update `FINAL_PRE_PRODUCTION_AUDIT.md` — every BLOCKED row becomes PASS or FAIL with evidence
5. Rebuild the production AAB from the final verified commit and reissue `FINAL_RELEASE_AAB_REPORT.md`

**Until then the release verdict stays BLOCKED — not PASS.**
