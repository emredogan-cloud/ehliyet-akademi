# Founder Release Handbook — Ehliyet Akademi 1.0.0

**Updated:** 11 August 2026 · **Branch:** `release/preproduction-1.0.0` · **Package:** `com.ehliyetegitim.ehliyet_akademi`

This document contains **only** the actions I cannot legitimately perform. Everything that could be
automated has been automated and is already committed. Each task below fails one of three tests:

- it requires **legal ownership or a legal decision** (company identity, retention periods),
- it requires **credentials or account access** I must never hold (Play Console, keystore),
- it requires a **real-money or real-device action** whose evidence cannot be fabricated.

> **Never commit a secret to git.** Every value below goes into an environment-variable store
> (Vercel) or the Play Console — never into a file in this repository. `gitleaks` runs on every push
> and will block a commit containing a key.

---

## Status key

| Marker               | Meaning                                                                |
| -------------------- | ---------------------------------------------------------------------- |
| **AGENT COMPLETE**   | I finished it; evidence recorded. Nothing for you to do.               |
| **FOUNDER COMPLETE** | You already did it and I **verified** it. Evidence recorded.           |
| **FOUNDER BLOCKED**  | Waiting on you. Release cannot proceed (or degrades) until it is done. |
| **NOT VERIFIED**     | Believed done but I could not obtain evidence. Treat as not done.      |

## Task index

| ID   | Task                                                | Status                                                  | Blocks release?             |
| ---- | --------------------------------------------------- | ------------------------------------------------------- | --------------------------- |
| F-01 | Legal entity identity (5 env vars)                  | **FOUNDER BLOCKED** (4 of 5)                            | 🔴 YES                      |
| F-02 | Monitored support mailbox                           | **FOUNDER COMPLETE** (needs monitoring confirmation)    | 🔴 YES                      |
| F-03 | Legal review of privacy/KVKK text                   | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-04 | Play service account → `GOOGLE_PLAY_SA_JSON`        | **FOUNDER COMPLETE — VERIFIED**                         | 🔴 YES                      |
| F-05 | Real purchase + restore on device (×3 products)     | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-06 | Retention periods                                   | **AGENT COMPLETE** (defaults shipped; you may override) | 🟡                          |
| F-07 | App Signing SHA-256 → `ANDROID_SHA256_FINGERPRINTS` | **FOUNDER BLOCKED**                                     | 🟠 degrades                 |
| F-08 | Data Safety form                                    | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-09 | Content rating (incl. alcohol answer)               | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-10 | Target audience / ads / AI / health declarations    | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-11 | Store listing text + screenshots                    | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-12 | Product catalogue (3 products)                      | **FOUNDER BLOCKED**                                     | 🔴 YES                      |
| F-13 | Reviewer notes                                      | **FOUNDER BLOCKED**                                     | 🟡 recommended              |
| F-14 | Closed testing / production access                  | **FOUNDER BLOCKED**                                     | 🔴 if applicable            |
| F-15 | Production keystore                                 | **FOUNDER COMPLETE** (present on the build machine)     | 🔴 YES                      |
| F-16 | Real-time Developer Notifications (optional)        | **FOUNDER BLOCKED**                                     | ⚪ no — closes a refund gap |

---

## How to read a task

| Field               | Meaning                                                |
| ------------------- | ------------------------------------------------------ |
| **Blocks release?** | Whether production submission is impossible without it |
| **Where**           | The exact screen/console/file                          |
| **Value**           | Exactly what to enter                                  |
| **Evidence**        | What to send back so I can verify                      |
| **If skipped**      | What actually breaks                                   |

> **A note on Play Console UI labels.** Google renames Console menus regularly. Every label below
> was taken from this repository's own setup notes and from the API behaviour I could verify.
> Where a label may have moved, it is marked **⚠️ label may have changed** — navigate by meaning,
> not by exact string, and tell me what you actually saw so I can correct this document.

---

## F-01 · Legal entity identity (data controller)

**FOUNDER BLOCKED — 4 of 5 values missing** · **Blocks release? YES — 🔴** · **Owner:** founder + legal counsel

### Why

Google's User Data policy requires the privacy policy to name the developer and give a working
contact route. **I cannot invent a company name or a tax number** — a fabricated VKN would make the
policy not merely incomplete but _misleading_, which is a worse violation than a placeholder.

The code is finished: `apps/web/lib/legal-entity.ts` reads five values from the environment, and the
pages render the real identity the moment **all five** are present. Until then they render an honest
"not yet published" notice — no placeholders, no draft banner.

### Where

**Vercel → Project `ehliyet-akademi` → Settings → Environment Variables → Production**

### Value

| Variable              | What to enter                                 | Status                        |
| --------------------- | --------------------------------------------- | ----------------------------- |
| `LEGAL_COMPANY_NAME`  | Full registered trade name                    | ⛔ **missing**                |
| `LEGAL_TAX_ID`        | VKN (10 digits) or T.C. kimlik no (11 digits) | ⛔ **missing**                |
| `LEGAL_ADDRESS`       | Full address valid for legal service          | ⛔ **missing**                |
| `LEGAL_KEP_ADDRESS`   | Registered e-mail (KEP) address               | ⛔ **missing**                |
| `LEGAL_SUPPORT_EMAIL` | `support@ehliyetegitim.com`                   | ✅ **set by me, 11 Aug 2026** |

**All five are required.** The code deliberately refuses partial identity: with four of five set it
still shows the "not published" notice, because a half-filled legal notice is unreadable as to which
part is real. I set the one value you supplied; the other four are legal facts only you hold.

I also reconciled `SUPPORT_EMAIL` (the support-form inbox) to the same address in Production and
Preview, because you designated it as the canonical support mailbox.

### After you set them

Environment changes only take effect on the **next deployment**. Redeploy, then:

```bash
curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "henüz yayımlanmadı"   # must be 0
```

### Evidence

That command returning `0`.

### If skipped

The privacy policy never names a data controller. This is a documented Play rejection reason under
the User Data policy, and it fails KVKK m.10 (aydınlatma yükümlülüğü) independently of Play.

---

## F-02 · A monitored support mailbox

**FOUNDER COMPLETE — needs one confirmation** · **Blocks release? YES — 🔴**

You created `support@ehliyetegitim.com`. It is now wired into `LEGAL_SUPPORT_EMAIL` and
`SUPPORT_EMAIL`.

**One thing I could not verify:** that a human actually reads it. KVKK gives data subjects a
statutory response window (30 days) and `/hesap-silme` §6 publishes that promise. An unmonitored
address converts a legal obligation into a silent breach.

> **I also fixed a related defect.** The code's fallback addresses pointed at
> `destek@ehliyetakademi.app` and `bilgi@ehliyetakademi.app`. **That domain has no DNS record at
> all** (`getent hosts ehliyetakademi.app` returns nothing). Any support request that fell through
> to the fallback was mailed into a black hole. Both now point at `ehliyetegitim.com`.

### Evidence

Send a test message to `support@ehliyetegitim.com` from an outside address and confirm a human
received it.

---

## F-03 · Legal review of the privacy policy and KVKK text

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴** · **Owner:** lawyer

### Why

I rewrote both pages to match the **actual architecture** — every sentence traces to a code path.
That makes the text _accurate_. It does not make it _legally reviewed_, and I am not qualified to
sign off on Turkish data-protection wording.

### What the lawyer should check

- Whether the sub-processor list (Vercel, Neon, Anthropic, Resend, Google) needs explicit
  cross-border transfer wording under KVKK m.9
- **The retention periods now published on the pages** (see F-06) — these are my engineering
  defaults, not a legal determination
- The claim that purchase records are deleted with the account and the financial record of the
  transaction lives with Google Play — confirm this satisfies your tax/commercial obligations
- Whether the 18+ target audience statement is consistent with A-class candidates who may be 16–17

### Where

`https://www.ehliyetegitim.com/gizlilik` · `/kvkk` · `/hesap-silme`

---

## F-04 · Google Play service account for receipt verification

**FOUNDER COMPLETE — I VERIFIED IT WORKS** · **Blocks release? YES — 🔴**

### What I verified, and how

`GOOGLE_PLAY_SA_JSON` is set in Vercel Production. I could not read its value (Vercel redacts
sensitive variables), so I verified the **service account itself** against Google's live API using
the key file on the build machine
(`play-purchase-verifier@ehliyet-akademi-sinav-2026.iam.gserviceaccount.com`):

| Check                                                           | Result                                  |
| --------------------------------------------------------------- | --------------------------------------- |
| RS256 JWT → OAuth2 token exchange                               | **OK** — key valid, API enabled         |
| `purchases.products.get` on `com.ehliyetegitim.ehliyet_akademi` | **HTTP 400 “Invalid Value”**            |
| `purchases.subscriptionsv2.get` on the same package             | **HTTP 400 “Invalid Value”**            |
| **Control:** same calls against a package we do not own         | **HTTP 401 “insufficient permissions”** |

The control test is what makes this conclusive. A deliberately bogus purchase token returns
**400 (“I accept you, that token is malformed”)** for our package but **401 (“I don't know you”)**
for a foreign one. That difference proves the Play Console grant exists and covers **both** the
one-time-product and the subscription verification endpoints the server actually calls.

**Nothing for you to do here.** Recorded because the older documents in this repo said this task was
outstanding, and because it removes a blocker from the critical path.

> **⚠️ Historical warning, now obsolete.** Older documents said "set `GOOGLE_PLAY_SA_JSON` to fix the
> billing blocker". At that time `verifyPlayPurchase` returned `valid: true` for **any token of 4+
> characters**, so setting the variable would have let any logged-in user grant themselves lifetime
> premium with a four-character string. That advice was unsafe. The real check now exists
> (`apps/web/lib/server/play-billing.ts`, 28 unit tests), so the variable is now correct to set.

### If it is ever removed

`/api/iap/validate` returns **503 in production** and no purchase can be granted. That is deliberate
fail-closed behaviour — a missing or malformed key is never treated as "verification passed".

---

## F-05 · One real purchase and one restore, on a device

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴**

### Why

No automated test can cover Play Billing end to end. This is the only way to prove the money path
works. **Do not do this until the newest AAB is on the closed-testing track and you have confirmed
it reached your licence-tester account** — you asked me to hold this, and I have.

### Prerequisites (all now met except the upload)

- ✅ Server verification is real and fail-closed (F-04)
- ✅ All three products exist in the server catalogue
- ⛔ Products must exist in Play Console (**F-12**)
- ⛔ Licence tester must be added (below)
- ⛔ AAB uploaded to closed testing (**F-14**)

### Where

1. **Play Console → Setup → License testing** ⚠️ _label may have changed_ — add your Google account
   as a licence tester. Licence testers are charged **nothing** and can buy repeatedly.
2. Install the closed-testing build on a real device signed in with **that exact account**.
3. Buy the **lifetime** package (`komple_ehliyet`).
4. Then buy a **subscription** (`premium_haftalik`). **This path has never been exercised** — until
   this release the server returned 404 for both subscriptions, so a user who bought weekly or
   monthly paid Google and received no server-side entitlement at all.
5. Uninstall, reinstall, sign in, press **restore**.
6. Sign in on a **second device** and confirm the entitlement follows the account.

### What "correct" looks like

| Step                    | Expected                                                                 |
| ----------------------- | ------------------------------------------------------------------------ |
| Purchase completes      | Play shows the confirmation sheet; app unlocks premium immediately       |
| Server records it       | You receive a purchase-confirmation e-mail (sent by `/api/iap/validate`) |
| Restore after reinstall | Premium returns **without paying again**                                 |
| Second device           | Premium appears after sign-in, with no purchase on that device           |
| Subscription expiry     | Access ends automatically once Google's `expiryTime` passes (see F-16)   |

### Common failure modes

| Symptom                                 | Cause                                                                                     |
| --------------------------------------- | ----------------------------------------------------------------------------------------- |
| "Ürün bulunamadı" / item unavailable    | Product ID mismatch — see the ID warning in F-12                                          |
| Purchase succeeds, premium not restored | `GOOGLE_PLAY_SA_JSON` missing → endpoint 503. Check F-04.                                 |
| 402 "Satın alma doğrulanamadı"          | Google says the token is invalid/cancelled/pending. Pending = cash payment, not yet paid. |
| Works on device A, not device B         | You signed in with a different app account, not a different Google account                |

### Evidence

For each of the three products: a screenshot of the purchase confirmation and of premium active
afterwards, plus confirmation that restore worked on a clean install.

---

## F-06 · Retention periods

**AGENT COMPLETE — defaults shipped; override if your lawyer says otherwise** · **🟡**

### What changed

Previously `/hesap-silme` §4 said purchase records are retained "for the period required by tax and
commercial legislation" **without a number**, and analytics/error records had **no upper bound at
all** — they were kept forever.

Both are fixed. Retention is now **data**, in `apps/web/lib/retention.ts`. The legal pages render
that list, and a daily cron job (`/api/cron/retention`, 03:20 UTC) **enforces** it. The published
period and the applied period cannot drift apart.

| Data                               | Retention                    | Configurable via               |
| ---------------------------------- | ---------------------------- | ------------------------------ |
| Account, learning data, community  | Deleted with the account     | —                              |
| **Purchase (entitlement) records** | **Deleted with the account** | —                              |
| Anonymous usage events             | **365 days**                 | `RETENTION_ANALYTICS_DAYS`     |
| Error / crash reports              | **90 days**                  | `RETENTION_ERROR_REPORTS_DAYS` |
| Closed community reports           | **180 days**                 | `RETENTION_MODERATION_DAYS`    |
| Deletion-request turnaround        | **30 days** (published)      | —                              |

> **These are engineering defaults, not legal determinations.** None of them claims "the law
> requires this". Each is the shortest period that still serves the stated purpose. If your lawyer
> specifies different figures, set the environment variable — no code change is needed.

### The one decision I could not make for you

I corrected the page to say purchase records are **deleted** with the account, because that is what
the database actually does (`purchases.user_id` is `ON DELETE CASCADE`). The financial record of the
transaction is held by **Google Play**, who collected the money. **Confirm with your lawyer that
this satisfies your tax and commercial book-keeping obligations.** If it does not, tell me and I
will change the schema to retain a de-identified financial row instead.

---

## F-07 · Play App Signing SHA-256 fingerprint

**FOUNDER BLOCKED** · **Blocks release? NO — degrades referral links** · **🟠**

### Why

`https://www.ehliyetegitim.com/.well-known/assetlinks.json` currently returns `[]` (verified live,
11 Aug 2026). Android App Links verification therefore fails and `https://…/davet/<KOD>` invite
links open in the browser instead of the app. The custom scheme `ehliyetakademi://app/davet/<KOD>`
still works, so the flow is degraded rather than broken.

**The route needs no code change.** It reads the fingerprint from the environment, validates the
format, and deliberately returns `[]` when unset rather than shipping a fabricated fingerprint.

### Where

1. **Play Console → Test and release → Setup → App integrity → App signing** ⚠️ _label may have changed_
2. Copy the **SHA-256 certificate fingerprint** under **App signing key certificate**
   — **not** the upload key certificate. Using the upload key is the classic mistake here: locally
   signed builds would verify, Play-distributed builds would not.
3. **Vercel → Environment Variables → Production**, then redeploy.

### Value

| Variable                      | Value                                                                                                                      |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `ANDROID_SHA256_FINGERPRINTS` | `AA:BB:CC:…:FF` — 32 colon-separated hex pairs. Multiple values comma-separated if you also want the upload key to verify. |

### Evidence

`curl -s https://www.ehliyetegitim.com/.well-known/assetlinks.json` → a populated array.

---

## F-08 · Data Safety form

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴**

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

> **Do not answer a question in whichever way seems most likely to pass review.** Data Safety is a
> binding declaration; a wrong answer discovered later is an enforcement action, not a correction.
> If an answer is genuinely unclear, tell me the exact question and I will trace the code.

---

## F-09 · Content rating questionnaire

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴**

### Where

**Play Console → App content → Content rating**

### Value

Answers in `PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §3. The decisive one:

> **"Does the app allow users to interact or exchange content with other users?" → YES**

The app ships free-text chat, discussions and groups. `STORE_LISTING.md` said "no user-to-user
content" — that is false and that file is now marked superseded.

Expect a rating above 3+. That is the correct outcome; do not try to engineer a lower one.

**One answer needs your judgement (F-09a):** the curriculum covers **alcohol and driving** as a
traffic-safety topic (4 questions carry the `alkol` topic tag). If the questionnaire asks about
references to alcohol, answer **Yes** and explain the educational context. I cannot make this call
for you because it depends on how the current IARC wording is phrased.

---

## F-10 · Target audience, ads, and remaining App content declarations

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴**

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

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴**

### Where

**Play Console → Grow → Store presence → Main store listing**

### Value — verified against the live API on 11 August 2026

| Field             | Value                                                                        | Length      |
| ----------------- | ---------------------------------------------------------------------------- | ----------- |
| App name          | `Ehliyet Akademi: Deneme Sınavı`                                             | 30/30       |
| Short description | `1.605 soru, 29 ders ve gerçek e-Sınav biçiminde denemeler. Hesap gerekmez.` | 74/80       |
| Full description  | the block in `ASO_PROMPT_LIBRARY.html` → "Play Store liste metni (tr-TR)"    | 3.056/4.000 |

Every number in that copy was re-verified against the production API today:

| Claim in the listing                                            | Live value                                     | Verdict |
| --------------------------------------------------------------- | ---------------------------------------------- | ------- |
| 1.605 soru                                                      | `/api/mobile/question-bank` → `count: 1605`    | ✅      |
| 29 ders                                                         | `/api/mobile/content-snapshot` → `lessons: 29` | ✅      |
| 121 trafik işareti                                              | `signs: 121`                                   | ✅      |
| 112 araç parçası                                                | `vehicleParts: 112`                            | ✅      |
| 60 gösterge ikaz ışığı                                          | 60 entries bundled in the app + 60 asset files | ✅      |
| trafik 396 / ilk yardım 303 / motor 329 / adab 272 / pratik 305 | exact per-subject counts, sum 1605             | ✅      |
| 50 soru · 45 dk · 35 doğru                                      | live exam blueprint                            | ✅      |

**The listing must never claim 10.000+ questions.** That figure appears only in the audit documents
that record it as a banned claim.

Upload the eight screenshots from `apps/ASO_IMAGE/PLAY_READY/` **in filename order** — slot order is
a conversion decision and the order is deliberate.

**Do not** paste anything from `STORE_LISTING.md` (superseded).

---

## F-12 · Play Console product catalogue

**FOUNDER BLOCKED** · **Blocks release? YES — 🔴**

### Why

The app offers three packages. The server now recognises all three; it recognised only one before,
so **subscription purchases silently produced no entitlement**.

### ⚠️ The product ID rule — get this exactly right

The app's internal IDs use **hyphens**; the Play Console IDs use **underscores**. The app converts
between them (`storeProductId => id.replaceAll('-', '_')`). If you type a Console ID that does not
match, the store returns "item unavailable" and the purchase never starts.

| Create this in Play Console | Type                           | App's internal ID  |
| --------------------------- | ------------------------------ | ------------------ |
| `komple_ehliyet`            | **One-time (managed product)** | `komple-ehliyet`   |
| `premium_haftalik`          | **Subscription**, weekly       | `premium-haftalik` |
| `premium_aylik`             | **Subscription**, monthly      | `premium-aylik`    |

`komple_ehliyet` is historical and test-locked — **do not rename it.**

### Step by step

**Managed product (`komple_ehliyet`)**

1. **Play Console → Monetise → Products → In-app products** ⚠️ _label may have changed_
2. **Create product**
3. Product ID: `komple_ehliyet` — **this can never be changed after saving**
4. Name / description: user-facing Turkish text
5. Set the price. Documentation records **₺479,99** — confirm or correct it and tell me.
6. **Activate** the product. A product left inactive is invisible to the app.

**Subscriptions (`premium_haftalik`, `premium_aylik`)**

1. **Play Console → Monetise → Products → Subscriptions**
2. **Create subscription** → Product ID `premium_haftalik`
3. Add a **base plan**:
   - Base plan ID: e.g. `haftalik-otomatik`
   - **Auto-renewing**
   - Billing period: **Weekly** (Monthly for `premium_aylik`)
   - Set the price, then **Activate the base plan** — the subscription itself is not purchasable
     until a base plan is active
4. **Offers: do not create one** unless you intend it. No listing text claims a free trial or an
   introductory price, and adding one silently would create a claim the listing does not carry.
5. Repeat for `premium_aylik` with a Monthly billing period.

### Prices

The app reads prices **from the store**, never from its own catalogue, so whatever you set is what
users see. The server catalogue's `priceTRY` is used only for the internal purchase record and the
confirmation e-mail — tell me the final prices and I will align it.

### Expected result

With all three active, the paywall shows three packages with store-formatted Turkish prices.

### Common failure modes

| Symptom                   | Cause                                                             |
| ------------------------- | ----------------------------------------------------------------- |
| Paywall shows no products | Products inactive, or the build is not on a track Play recognises |
| Only lifetime appears     | Subscriptions have no **active base plan**                        |
| "Item unavailable" on tap | Product ID typo — underscores, exactly as above                   |
| Prices show in USD        | Country pricing not set for Türkiye                               |

### Evidence

A screenshot of the products list showing all three **Active**, and the exact prices.

---

## F-13 · Reviewer notes

**FOUNDER BLOCKED** · **Blocks release? NO — strongly recommended**

Two surfaces need an account (Topluluk and the referral code). Everything else works as a guest. A
reviewer who does not know this may conclude a feature is broken.

**Play Console → App content → App access**

> Uygulamanın tamamı hesap açmadan kullanılabilir: dersler, soru bankası, deneme sınavları, Sınav
> Arşivi'ndeki ücretsiz sınavlar, Düello ve AI Koç giriş gerektirmez.
>
> Yalnız iki yüzey hesap ister: **Topluluk** sekmesi (isteğe bağlı katılım) ve **davet kodu**.
> Kayıt açıktır, davet gerektirmez ve e-posta doğrulaması beklemeden oturum açılır.
>
> Premium satın alma Google Play üzerinden yapılır; lisans test hesabı tanımlıdır.

---

## F-14 · Closed testing requirements and production access

**FOUNDER BLOCKED** · **Blocks release? YES if your account is subject to them**

Google requires a minimum number of opted-in testers over a continuous period before production
access for some developer accounts. Only you can see the current state.

**Play Console → Test and release → Testing → Closed testing**

This is also the gate for F-05: the real purchase test happens on a closed-testing build, and you
asked me to hold that test until you confirm the newest AAB has reached your tester account.

---

## F-15 · Production keystore

**FOUNDER COMPLETE — present on the build machine** · **Blocks release? YES — 🔴**

`apps/mobile/android/key.properties` exists and points at a keystore file that is present on disk.
Both are gitignored and neither is in the repository — I verified no `.jks` and no service-account
JSON has ever been committed (`git log --diff-filter=A` across all history is clean).

The Gradle configuration is **fail-closed**: if the keystore is missing, a release build stops with
an explicit error rather than silently falling back to the debug key. Google rejects debug-signed
bundles, and a silent fallback would surface only at upload time.

### Your remaining responsibility

**Back up the keystore and its passwords somewhere you will still have in five years.** If Play App
Signing is enabled, losing the _upload_ key is recoverable through Google support; losing it without
noticing is not. Losing the _app signing_ key when Play App Signing is **not** enabled means you can
never update the app again.

---

## F-16 · Real-time Developer Notifications (optional — closes a refund gap)

**FOUNDER BLOCKED** · **Blocks release? NO** · ⚪

### What exists today, honestly stated

There is **no RTDN receiver in this codebase.** I checked; nothing listens for Google's Pub/Sub
push. Here is what that does and does not cost you:

| Lifecycle event         | Handled without RTDN?                                                                                                                                      |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purchase                | ✅ verified server-side at purchase time                                                                                                                   |
| Renewal                 | ✅ the next validate call moves `expiresAt` forward                                                                                                        |
| **Expiry**              | ✅ **entitlement is computed from `expiresAt` at read time** — an expired subscription simply stops appearing                                              |
| Cancellation            | ✅ access correctly continues until the paid period ends, then stops                                                                                       |
| **Refund / revocation** | ⚠️ **gap** — the entitlement persists until the client next re-validates. For the **lifetime** product (`expiresAt = null`) it would persist indefinitely. |

So expiry and cancellation are safe by design. **Refund abuse is the real gap**: someone can buy the
lifetime package, obtain a refund, and keep access.

### If you want to close it

1. **Google Cloud Console** → create a **Pub/Sub topic**, e.g. `play-rtdn`
2. Grant `google-play-developer-notifications@system.gserviceaccount.com` the
   **Pub/Sub Publisher** role on that topic
3. **Play Console → Monetise → Monetisation setup → Real-time developer notifications**
   ⚠️ _label may have changed_ → paste the topic name
4. Tell me, and I will build the receiving endpoint with signature verification and revocation
   handling.

**This is not a launch blocker.** Play does not require RTDN. It is recorded here so the gap is a
known, accepted risk rather than an unknown one.

---

## RevenueCat — not used, and why that is deliberate

**Do not configure RevenueCat.** It is not in the current architecture. This section exists because
`REVENUECAT_SETUP.md` and other historical documents in this repository describe it in detail, and
following them would waste your time and add a dependency the app does not have.

### What I verified

| Check                                 | Finding                                                                 |
| ------------------------------------- | ----------------------------------------------------------------------- |
| `apps/mobile/pubspec.yaml`            | Only `in_app_purchase: ^3.3.0`. **No `purchases_flutter`.**             |
| Billing gateway                       | `billingGatewayProvider` returns `PlayBillingGateway()` unconditionally |
| Historical `RevenueCatGateway`        | **Removed** (Premium Quality Programme, Phase 6)                        |
| Server webhook `/api/iap/revenuecat`  | Exists but is **dormant and fail-closed**                               |
| `REVENUECAT_WEBHOOK_SECRET` in Vercel | **not set** → the endpoint returns **503** (verified live, 11 Aug 2026) |
| `REVENUECAT_SECRET_KEY` in Vercel     | **set, but nothing in the codebase reads it** — a dead variable         |

The removal was measured, not assumed: the gateway was selected only when
`--dart-define=REVENUECAT_PUBLIC_KEY` was supplied, which **no build ever supplied** — so it never
ran. Meanwhile the released APK's `classes.dex` carried **3,114 RevenueCat symbols**, meaning every
user downloaded a payment SDK that never executed.

### Housekeeping you may do

`REVENUECAT_SECRET_KEY` can be deleted from Vercel. It is unread. I left it alone because deleting
a variable I did not create is your call.

### If you ever decide to migrate to RevenueCat

You would need: a RevenueCat project + Android app, the Play service-account JSON uploaded to
RevenueCat, products/entitlements/offerings mirrored there, the public SDK key supplied at build
time, and `REVENUECAT_WEBHOOK_SECRET` set so the existing webhook activates. **None of this is
needed for the current release**, and the webhook alone is not a migration — the mobile app would
have to adopt the SDK again.

---

## Server-side billing configuration — reference

For completeness; all of this is already correct.

| Item                    | State                                                                         |
| ----------------------- | ----------------------------------------------------------------------------- |
| `GOOGLE_PLAY_SA_JSON`   | Set in Production + Preview · service account **verified against Google**     |
| Verification endpoint   | `POST /api/iap/validate` — 401 unauthenticated, 503 unconfigured, 402 invalid |
| Products API            | `androidpublisher v3 purchases.products.get` (one-time)                       |
| Subscriptions API       | `androidpublisher v3 purchases.subscriptionsv2.get`                           |
| Product kind            | Read from the **server catalogue**, never from the client                     |
| Idempotency             | One row per (user, product); renewal moves `expiresAt` forward                |
| Entitlement read        | Expired subscriptions excluded at query time                                  |
| Web payments (separate) | Lemon Squeezy — unrelated to Play Billing; `/api/health` reports it           |

---

_Machine-checkable checklist: `FOUNDER_RELEASE_CHECKLIST.md`. Every declaration's code
justification: `PLAY_CONSOLE_DECLARATIONS_GUIDE.md`. Findings and evidence:
`PLAY_STORE_PREPRODUCTION_ROADMAP.md` and `FINAL_PRE_PRODUCTION_AUDIT.md`._
