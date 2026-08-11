# Founder Release Handbook — Ehliyet Akademi 1.0.0

**Written:** 10 August 2026 · **Branch:** `release/preproduction-1.0.0` · **Package:** `com.ehliyetegitim.ehliyet_akademi`

This document contains **only** the actions I cannot legitimately perform. Everything that could be
automated has been automated and is already committed. Each task below fails one of three tests:

- it requires **legal ownership or a legal decision** (company identity, retention periods),
- it requires **credentials or account access** I must never hold (Play Console, service accounts),
- it requires a **real-money or real-device action** whose evidence cannot be fabricated.

> **Never commit a secret to git.** Every value below goes into an environment-variable store
> (Vercel) or the Play Console — never into a file in this repository. `gitleaks` runs on every push
> and will block a commit containing a key.

---

## How to read a task

| Field               | Meaning                                                |
| ------------------- | ------------------------------------------------------ |
| **Blocks release?** | Whether production submission is impossible without it |
| **Where**           | The exact screen/console/file                          |
| **Value**           | Exactly what to enter                                  |
| **Evidence**        | What to send back so I can verify                      |
| **Then I will**     | What I do once you confirm                             |

---

## F-01 · Legal entity identity (data controller)

**Blocks release? YES — 🔴** · **Owner:** founder + legal counsel

### Why

`/gizlilik` and `/kvkk` previously shipped a "Taslak belge uyarısı" and `[Şirket Ünvanı]`,
`[VKN]`, `[Adres]`, `[KEP adresi]`, `[destek e-postası]` placeholders. Google's User Data policy
requires the privacy policy to name the developer and give a working contact route. **I cannot
invent a company name or a tax number** — a fabricated VKN would make the policy not merely
incomplete but _misleading_, which is a worse violation than the placeholder was.

The code is already finished: `apps/web/lib/legal-entity.ts` reads these five values from the
environment, and the pages render the real identity the moment all five are present. Until then they
render an honest "not yet published" notice — no placeholders, no draft banner.

### Where

**Vercel → Project `ehliyet-akademi` → Settings → Environment Variables → Production**

### Value

| Variable              | What to enter                                 | Format note                            |
| --------------------- | --------------------------------------------- | -------------------------------------- |
| `LEGAL_COMPANY_NAME`  | Full registered trade name                    | e.g. `Örnek Eğitim Teknolojileri A.Ş.` |
| `LEGAL_TAX_ID`        | VKN (10 digits) or T.C. kimlik no (11 digits) | digits only                            |
| `LEGAL_ADDRESS`       | Full address valid for legal service          | single line                            |
| `LEGAL_KEP_ADDRESS`   | Registered e-mail (KEP) address               | e.g. `ornek@hs01.kep.tr`               |
| `LEGAL_SUPPORT_EMAIL` | **A mailbox someone actually reads**          | see F-02                               |

**All five are required.** The code deliberately refuses partial identity: with four of five set it
still shows the "not published" notice, because a half-filled legal notice is unreadable as to which
part is real.

### Evidence

Redeploy, then send me the output of:
`curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "henüz yayımlanmadı"` → must be `0`.

### Then I will

Re-run the live verification, mark R-01 PASS in the roadmap and the final audit.

---

## F-02 · A monitored support mailbox

**Blocks release? YES — 🔴** · **Owner:** founder

### Why

KVKK gives data subjects a statutory response window (30 days). The address in `LEGAL_SUPPORT_EMAIL`
is where deletion and access requests will arrive. An unmonitored address converts a legal
obligation into a silent breach.

### Where

Your mail provider, then F-01's `LEGAL_SUPPORT_EMAIL`.

### Evidence

Send a test message to the address and confirm it was received by a human.

---

## F-03 · Legal review of the privacy policy and KVKK text

**Blocks release? YES — 🔴** · **Owner:** lawyer

### Why

I rewrote both pages to match the **actual architecture** — every sentence traces to a code path,
and I removed the contradiction where the policy claimed approximate-location IP logging while the
Data Safety form declares no location collection. That makes the text _accurate_. It does not make
it _legally reviewed_, and I am not qualified to sign off on Turkish data-protection wording.

### Where

`https://www.ehliyetegitim.com/gizlilik` · `https://www.ehliyetegitim.com/kvkk`

### What the lawyer should check

- Whether the sub-processor list (Vercel, Neon, Anthropic, Resend, Google) needs explicit
  cross-border transfer wording under KVKK m.9
- The retention periods (F-06)
- Whether the 18+ target audience statement is consistent with A-class candidates who may be 16–17

### Evidence

Written confirmation. If wording changes are required, send them to me and I will implement them.

---

## F-04 · Google Play service account for receipt verification

**Blocks release? YES — 🔴** · **Owner:** founder

### Why — read this carefully

The server-side purchase verification **is now real** (`apps/web/lib/server/play-billing.ts`,
28 unit tests). Until this task is done, `/api/iap/validate` returns **503 in production** and no
purchase can be granted. That is deliberate fail-closed behaviour.

> **⚠️ Previously the opposite advice was recorded in this repository.** Older documents said
> "set `GOOGLE_PLAY_SA_JSON` to fix the billing blocker". At that time the verification function
> returned `valid: true` for any token of 4+ characters, so setting the variable would have let any
> logged-in user grant themselves lifetime premium with a four-character string. **That advice was
> unsafe and is now obsolete** — the real check exists, so setting the variable is now correct.

### Where

1. **Google Cloud Console** → the project linked to your Play Console
   → IAM & Admin → Service Accounts → **Create service account**
   → name it e.g. `play-purchase-verifier`, no roles needed at project level
   → Keys → **Add key → JSON** → download
2. **Play Console** → Setup → **API access** → link the Google Cloud project
   → find the service account → **Grant access**
   → Permissions: **View financial data** and **Manage orders and subscriptions**
   (these two are enough; do not grant release-management rights)
3. **Vercel → Environment Variables → Production**

### Value

| Variable              | Value                                                                    |
| --------------------- | ------------------------------------------------------------------------ |
| `GOOGLE_PLAY_SA_JSON` | The **entire contents** of the downloaded JSON file, pasted as one value |

Notes:

- Paste the raw JSON. The code handles `\n`-escaped private keys, so either form works.
- **Do not commit the file.** Delete the download after pasting.
- If the value is malformed, the code treats it as _not configured_ and keeps returning 503 rather
  than silently accepting purchases — a partial configuration is never treated as working.

### Evidence

After redeploy, confirm the endpoint no longer 503s for an authenticated request. Then F-05.

### Then I will

Verify the verification path end to end against your test purchase.

---

## F-05 · One real purchase and one restore, on a device

**Blocks release? YES — 🔴** · **Owner:** founder

### Why

No automated test can cover Play Billing end to end. This is the only way to prove the money path
works. It is also the single most commonly skipped pre-launch step.

### Where

1. **Play Console → Setup → License testing** → add your Google account as a licence tester
2. Install the closed-testing build on a real device with that account
3. Buy the **lifetime** package (`komple_ehliyet`)
4. Then buy or verify a **subscription** package (`premium_haftalik`) — this path was **completely
   broken** until this release (the server returned 404 for both subscriptions), so it has never
   been exercised
5. Uninstall, reinstall, sign in, and press **restore**
6. Sign in on a **second device** and confirm the entitlement follows the account

### Evidence

For each of the three products: a screenshot of the purchase confirmation and of premium being
active afterwards, plus confirmation that restore worked on a clean install.

---

## F-06 · Retention-period decision

**Blocks release? YES — 🔴 (content of a published page)** · **Owner:** founder + legal

### Why

`/hesap-silme` states that purchase and invoice records are retained "for the period required by
tax and commercial legislation" **without naming a number**. I deliberately did not invent one:
a wrong retention period on a published legal page is a false statement, and the correct figure is
a legal determination.

### Where

`apps/web/app/(marketing)/hesap-silme/page.tsx` §4 — send me the figure and I will publish it.

### Value needed

- Retention period for purchase/invoice records
- Retention period for community reports under review
- The window between a deletion request and permanent erasure (the page currently promises
  **30 days** for e-mail requests — confirm this is achievable)

---

## F-07 · Play App Signing SHA-256 fingerprint

**Blocks release? NO (degrades referral links)** · **Owner:** founder

### Why

`https://www.ehliyetegitim.com/.well-known/assetlinks.json` currently returns `[]`. Android App
Links verification therefore fails and `https://…/davet/<KOD>` invite links open in the browser
instead of the app. The custom scheme `ehliyetakademi://app/davet/<KOD>` still works, so the flow is
degraded rather than broken.

**The route needs no code change** — this was a finding I corrected during re-inspection. It already
reads the fingerprint from the environment, validates the format, and deliberately returns `[]` when
unset rather than shipping a fabricated fingerprint.

### Where

1. **Play Console → your app → Test and release → Setup → App integrity → App signing**
2. Copy the **SHA-256 certificate fingerprint** under **App signing key certificate**
   — **not** the upload key certificate. Using the upload key is the classic mistake here: locally
   signed builds would verify, Play-distributed builds would not.
3. **Vercel → Environment Variables → Production**

### Value

| Variable                      | Value                                                                                                                      |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `ANDROID_SHA256_FINGERPRINTS` | `AA:BB:CC:…:FF` — 32 colon-separated hex pairs. Multiple values comma-separated if you also want the upload key to verify. |

### Evidence

`curl -s https://www.ehliyetegitim.com/.well-known/assetlinks.json` → must return a populated array.

---

## F-08 · Data Safety form

**Blocks release? YES — 🔴** · **Owner:** founder

### Why

A binding declaration to Google. It must match the code and the privacy policy exactly.

### Where

**Play Console → App content → Data safety**

### Value

Every answer, with its code justification, is in **`PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §6–§8**.
Work from that document field by field. Two corrections it carries that differ from the older
`PLAY_DATA_SAFETY.md`:

- **Photos: COLLECTED.** The older document said not collected. The community avatar upload writes
  a `media_assets` row on the server (`apps/web/app/api/community/avatar/route.ts`), so the image
  _is_ collected. Declaring otherwise would be false.
- **Community UGC must be declared** under "Other user-generated content" — the older document
  covered only the AI Koç text.

Also required on this screen:

| Field              | Value                                       |
| ------------------ | ------------------------------------------- |
| Privacy policy URL | `https://www.ehliyetegitim.com/gizlilik`    |
| Data deletion URL  | `https://www.ehliyetegitim.com/hesap-silme` |

---

## F-09 · Content rating questionnaire

**Blocks release? YES — 🔴** · **Owner:** founder

### Why

The app ships free-text chat, discussions and groups. `STORE_LISTING.md` said "no user-to-user
content" — that is false and is now marked superseded.

### Where

**Play Console → App content → Content rating**

### Value

Answers in `PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §3. The decisive one:

> **"Does the app allow users to interact or exchange content with other users?" → YES**

Expect a rating above 3+. That is the correct outcome; do not try to engineer a lower one.

**One answer needs your judgement (F-09a):** the curriculum covers **alcohol and driving** as a
traffic-safety topic. If the questionnaire asks about references to alcohol, answer **Yes** and
explain the educational context. I cannot make this call for you because it depends on how the
current IARC wording is phrased.

---

## F-10 · Target audience, ads, and remaining App content declarations

**Blocks release? YES — 🔴** · **Owner:** founder

| Screen                      | Answer                                                                                                                                               | Source                        |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| Target audience             | **18 and over** only                                                                                                                                 | Declarations guide §4         |
| Children under 13           | **No**                                                                                                                                               | §4                            |
| Ads                         | **No ads**                                                                                                                                           | §2 — no ad SDK, no ad ID read |
| News app                    | **No**                                                                                                                                               | §5                            |
| Government app              | **No** — and **no MEB affiliation may be claimed anywhere**                                                                                          | §11                           |
| Health app                  | **No** — first aid is exam content, not health guidance                                                                                              | §11                           |
| Generative AI               | **Yes**, with the safeguards listed in §12                                                                                                           | §12                           |
| Independent security review | **Do not tick** unless one was actually commissioned. `SECURITY_REVIEW.md` in this repo is an internal review, which is not what the question means. | §8                            |

---

## F-11 · Store listing text and assets

**Blocks release? YES** · **Owner:** founder

### Where

**Play Console → Grow → Store presence → Main store listing**

### Value

From `ASO_PROMPT_LIBRARY.html` → "Play Store liste metni (tr-TR)":

| Field             | Value                                                                        | Length      |
| ----------------- | ---------------------------------------------------------------------------- | ----------- |
| App name          | `Ehliyet Akademi: Deneme Sınavı`                                             | 30/30       |
| Short description | `1.605 soru, 29 ders ve gerçek e-Sınav biçiminde denemeler. Hesap gerekmez.` | 74/80       |
| Full description  | the block in that section                                                    | 3.056/4.000 |

Upload the eight screenshots from `apps/ASO_IMAGE/PLAY_READY/` **in filename order** — slot order is
a conversion decision and the order is deliberate (see `ASO_FINAL_VALIDATION_REPORT.md`).

**Do not** paste anything from `STORE_LISTING.md`.

---

## F-12 · Play Console product catalogue

**Blocks release? YES** · **Owner:** founder

### Why

The app offers three packages. The server now recognises all three (it recognised only one before,
so subscription purchases silently produced no entitlement).

### Where

**Play Console → Monetise → Products**

| Store product ID   | Type                           | Notes                                           |
| ------------------ | ------------------------------ | ----------------------------------------------- |
| `komple_ehliyet`   | **One-time (managed product)** | ID is historical and test-locked; do not rename |
| `premium_haftalik` | **Subscription**, weekly       |                                                 |
| `premium_aylik`    | **Subscription**, monthly      |                                                 |

Prices are whatever you set in the Console — the app reads them from the store and never from the
catalogue. Confirm the lifetime price so the documentation matches (currently recorded as ₺479,99).

**Do not configure a free trial** unless you intend one; no listing text claims a trial, and adding
one silently would create a claim the listing does not carry.

---

## F-13 · Reviewer notes

**Blocks release? NO — strongly recommended** · **Owner:** founder

### Why

Two surfaces need an account (Topluluk and the referral code). Everything else works as a guest. A
reviewer who does not know this may conclude a feature is broken.

### Where

**Play Console → App content → App access**

### Suggested text

> Uygulamanın tamamı hesap açmadan kullanılabilir: dersler, soru bankası, deneme sınavları, Sınav
> Arşivi'ndeki ücretsiz sınavlar, Düello ve AI Koç giriş gerektirmez.
>
> Yalnız iki yüzey hesap ister: **Topluluk** sekmesi (isteğe bağlı katılım) ve **davet kodu**.
> Kayıt açıktır, davet gerektirmez ve e-posta doğrulaması beklemeden oturum açılır.
>
> Premium satın alma Google Play üzerinden yapılır; lisans test hesabı tanımlıdır.

---

## F-14 · Closed testing requirements and production access

**Blocks release? YES if your account is subject to them** · **Owner:** founder

Google requires a minimum number of opted-in testers over a continuous period before production
access for some developer accounts. Only you can see the current state.

**Play Console → Test and release → Testing → Closed testing**

---

## F-15 · Production keystore

**Blocks release? YES** · **Owner:** founder

### Why

I can build a release AAB, but the production signing keystore is not in this environment and must
never be. Without it the artefact I produce is not the artefact that can be uploaded.

### Where

`apps/mobile/android/key.properties` + the `.jks` file — **both gitignored, both stay on your
machine or in your secret store.**

### Note

If Play App Signing is enabled (it is — see F-07), the upload key signs the AAB and Google re-signs
with the app signing key. Losing the upload key is recoverable; losing it silently is not.

---

## Summary table

| ID   | Task                                                | Blocks?          | Owner           |
| ---- | --------------------------------------------------- | ---------------- | --------------- |
| F-01 | Legal entity identity (5 env vars)                  | 🔴 YES           | founder + legal |
| F-02 | Monitored support mailbox                           | 🔴 YES           | founder         |
| F-03 | Legal review of privacy/KVKK text                   | 🔴 YES           | lawyer          |
| F-04 | Play service account → `GOOGLE_PLAY_SA_JSON`        | 🔴 YES           | founder         |
| F-05 | Real purchase + restore on device (×3 products)     | 🔴 YES           | founder         |
| F-06 | Retention periods                                   | 🔴 YES           | founder + legal |
| F-07 | App Signing SHA-256 → `ANDROID_SHA256_FINGERPRINTS` | 🟠 degrades      | founder         |
| F-08 | Data Safety form                                    | 🔴 YES           | founder         |
| F-09 | Content rating (incl. alcohol answer)               | 🔴 YES           | founder         |
| F-10 | Target audience / ads / AI / health declarations    | 🔴 YES           | founder         |
| F-11 | Store listing text + screenshots                    | 🔴 YES           | founder         |
| F-12 | Product catalogue (3 products)                      | 🔴 YES           | founder         |
| F-13 | Reviewer notes                                      | 🟡 recommended   | founder         |
| F-14 | Closed testing / production access                  | 🔴 if applicable | founder         |
| F-15 | Production keystore                                 | 🔴 YES           | founder         |

---

_Machine-checkable checklist: `FOUNDER_RELEASE_CHECKLIST.md`. Every answer's code justification:
`PLAY_CONSOLE_DECLARATIONS_GUIDE.md`. Findings and evidence: `PLAY_STORE_REVIEW_AUDIT.md` and
`PLAY_STORE_PREPRODUCTION_ROADMAP.md`._
