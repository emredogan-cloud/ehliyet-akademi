# Founder Release Checklist — Ehliyet Akademi 1.0.0

Tick as you go. Full instructions for every line: **`FOUNDER_RELEASE_HANDOOK.md`**.

> **The release verdict cannot be PASS while any 🔴 box is unticked.** Send me the evidence column
> and I will re-run the affected verification and update `FINAL_PRE_PRODUCTION_AUDIT.md`.

---

## A · Legal and identity

- [ ] **F-01** 🔴 Five legal env vars set in Vercel → Production
  - [ ] `LEGAL_COMPANY_NAME`
  - [ ] `LEGAL_TAX_ID`
  - [ ] `LEGAL_ADDRESS`
  - [ ] `LEGAL_KEP_ADDRESS`
  - [ ] `LEGAL_SUPPORT_EMAIL`
  - **Evidence:** `curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "henüz yayımlanmadı"` returns `0`
- [ ] **F-02** 🔴 Support mailbox exists and a human reads it
- [ ] **F-03** 🔴 Lawyer reviewed `/gizlilik` and `/kvkk`
- [ ] **F-06** 🔴 Retention periods decided and sent to me
  - [ ] purchase/invoice records
  - [ ] community reports under review
  - [ ] deletion-request turnaround (page currently promises 30 days — confirm achievable)

## B · Billing

- [ ] **F-04** 🔴 Service account created, granted **View financial data** + **Manage orders and subscriptions**
- [ ] **F-04** 🔴 `GOOGLE_PLAY_SA_JSON` set in Vercel → Production
  - ⚠️ Only now is this safe. The verification stub that made this dangerous was removed in this release.
- [ ] **F-12** 🔴 Three products defined in Play Console
  - [ ] `komple_ehliyet` — one-time (managed)
  - [ ] `premium_haftalik` — subscription, weekly
  - [ ] `premium_aylik` — subscription, monthly
- [ ] **F-12** Lifetime price confirmed (documentation records ₺479,99)
- [ ] **F-05** 🔴 Licence tester account added
- [ ] **F-05** 🔴 Real purchase — `komple_ehliyet` **Evidence:** screenshot
- [ ] **F-05** 🔴 Real purchase — `premium_haftalik` (**never exercised before this release**) **Evidence:** screenshot
- [ ] **F-05** 🔴 Restore after clean reinstall works
- [ ] **F-05** 🔴 Entitlement follows the account on a second device

## C · Android configuration

- [ ] **F-07** 🟠 `ANDROID_SHA256_FINGERPRINTS` set from **App signing key** (not upload key)
  - **Evidence:** `curl -s https://www.ehliyetegitim.com/.well-known/assetlinks.json` returns a populated array
- [ ] **F-15** 🔴 Production keystore available and backed up

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

Once the 🔴 boxes are ticked and evidence is in, I will:

1. Re-probe `/gizlilik`, `/kvkk`, `/hesap-silme` and `assetlinks.json` live
2. Re-run the purchase-verification path against your real test purchase
3. Re-run the connected-device E2E for the purchase and deletion flows
4. Update `FINAL_PRE_PRODUCTION_AUDIT.md` — every BLOCKED row becomes PASS or FAIL with evidence
5. Rebuild the production AAB from the final verified commit and reissue `FINAL_RELEASE_AAB_REPORT.md`

**Until then the release verdict stays BLOCKED — not PASS.**
