# Play Console Declarations Guide — Ehliyet Akademi

**Written:** 10 August 2026 · **Branch:** `main` @ `9ecc358` · **App version:** `1.0.0+5`
**Package:** `com.ehliyetegitim.ehliyet_akademi`

Every answer below was derived from the **current** implementation on the date above — the Flutter
app in `apps/mobile/`, the Next.js API in `apps/web/`, the schema in `packages/db/`, and live
probes of the deployed endpoints. Nothing was copied from an older report without re-verification.

**How to read each entry**

1. **SELECT** — the literal value to choose in the Console.
2. **WHY** — the reason that answer is correct.
3. **EVIDENCE** — the file, line or live response that proves it.
4. **REVIEWER SEES** — what a Google reviewer will encounter that corresponds to this answer.
5. **MISMATCH RISK** — what would make this answer look false.

Where the repository cannot settle a question, the entry says **⚠️ MANUAL VERIFICATION REQUIRED**
and states who can answer it.

> **Prerequisite.** Four blockers in `PLAY_STORE_REVIEW_AUDIT.md` must be closed before these
> answers become truthful: the draft privacy policy (🔴-1), the missing data-deletion URL (🔴-4),
> the receipt-verification stub (🔴-3) and the existing store assets (🔴-2). Several answers below
> depend on them and are marked **BLOCKED BY**.

---

## Table of contents

1. [App access](#1-app-access)
2. [Ads](#2-ads)
3. [Content rating](#3-content-rating)
4. [Target audience and content](#4-target-audience-and-content)
5. [News apps](#5-news-apps)
6. [Data safety — the collection matrix](#6-data-safety--the-collection-matrix)
7. [Data safety — per-category answers](#7-data-safety--per-category-answers)
8. [Data safety — security practices](#8-data-safety--security-practices)
9. [Privacy policy](#9-privacy-policy)
10. [Account deletion](#10-account-deletion)
11. [Government apps, financial features, health](#11-government-apps-financial-features-health)
12. [Generative AI declaration](#12-generative-ai-declaration)
13. [User-generated content and moderation](#13-user-generated-content-and-moderation)
14. [Photos and media](#14-photos-and-media)
15. [Notifications](#15-notifications)
16. [Referral / deep links](#16-referral--deep-links)
17. [Monetisation and in-app purchases](#17-monetisation-and-in-app-purchases)
18. [Permissions declaration](#18-permissions-declaration)
19. [Store listing metadata](#19-store-listing-metadata)
20. [Pre-submission manual checklist](#20-pre-submission-manual-checklist)

---

## 1. App access

**Console path:** App content → App access

**SELECT: "All functionality is available without special access"**

**WHY.** The app is deliberately usable end to end without an account. The auth controller states
it in one line: _"The app never gates on auth — guests use everything; auth adds identity + sync."_
A guest can onboard, study all 29 lessons, answer all 1.605 questions, sit full exams, use the
exam archive's free tier, play Duel, ask the AI Koç and buy premium.

**EVIDENCE.** `apps/mobile/lib/domain/auth/auth_controller.dart:29`.
Guest is a first-class state: `enum AuthStatus { unknown, guest, authenticated }` (line 14), and
`AuthState.guest` is the default after startup (lines 44, 52).

**REVIEWER SEES.** App opens to a welcome screen → 4-step onboarding → home. No login wall appears
at any point. The Profil tab offers _"Giriş yap / Kayıt ol"_ as an option, not a requirement.

**MISMATCH RISK.** One surface **does** require an account: the Topluluk (community) tab shows
_"Katılmak için hesabınla giriş yapmış olman gerekir."_ (`community_screen.dart:135`), and the
referral code only exists for signed-in users (`referral_screen.dart:54-55`).

**This does not change the answer** — Play's "special access" question is about credentials the
reviewer could not obtain themselves, not about optional sign-in. Registration is open, requires no
invite, and creates a session immediately (`apps/web/app/api/auth/register/route.ts:71-72`), so a
reviewer can reach community and referral unaided.

**RECOMMENDED ANYWAY.** Provide reviewer notes describing the two account-gated surfaces, so the
reviewer does not conclude a feature is broken. Optionally supply a demo account with premium
already granted — see §20 M2.

**⚠️ MANUAL VERIFICATION REQUIRED:** confirm on a clean install that no login prompt appears before
the home screen.

---

## 2. Ads

**Console path:** App content → Ads

**SELECT: "No, my app does not contain ads"**

**WHY.** There is no ad SDK, no ad unit, no ad placement, and no advertising identifier read
anywhere in the app.

**EVIDENCE.**

- `apps/mobile/pubspec.yaml` — 23 runtime dependencies, none of them an ads SDK (no
  `google_mobile_ads`, no AppLovin, no Unity Ads, no `applovin_max`).
- `AndroidManifest.xml` declares no `com.google.android.gms.permission.AD_ID`.
- `lib/core/analytics/analytics.dart:16-20` documents the anonymous ID explicitly:
  _"cihaz başına bir kez üretilen rastgele bir dize; kişiyi tanımlamaz, **reklam kimliği DEĞİLDİR**
  ve hiçbir yerden satın alınmamıştır."_

**REVIEWER SEES.** No banners, no interstitials, no rewarded video, no sponsored content anywhere.
The only monetisation surface is the premium paywall.

**MISMATCH RISK.** None identified. If an ads SDK is ever added, this answer and the Data Safety
form must change together.

---

## 3. Content rating

**Console path:** App content → Content rating (IARC questionnaire)

### 3.1 The single most important answer

**Question: "Does the app allow users to interact or exchange content with other users?"**

**SELECT: YES.**

**WHY.** The app ships free-text user-to-user communication in four places:

| Surface            | File                                                   | What users can send                              |
| ------------------ | ------------------------------------------------------ | ------------------------------------------------ |
| Direct chat        | `lib/features/community/chat_screen.dart`              | Free-text messages                               |
| Discussion threads | `lib/features/community/discussion_thread_screen.dart` | Free-text posts and replies                      |
| Groups             | `lib/features/community/group_detail_screen.dart`      | Group membership + content                       |
| Profile / avatar   | `lib/features/community/avatar_editor_screen.dart`     | Chosen display name and an image from the device |

**⚠️ `STORE_LISTING.md` currently says "no user-to-user content". That statement is false and must
not be carried into the questionnaire.** See `PLAY_STORE_REVIEW_AUDIT.md` 🟠-4 and 🟠-5.

**REVIEWER SEES.** Topluluk tab → sign in → join → discussions, chat, groups, friends,
leaderboards.

**MISMATCH RISK.** Declaring "no user interaction" while shipping a chat screen is a content-rating
misdeclaration and an enforcement category on its own. The community feature is discoverable from
the persistent bottom bar — a reviewer will find it in seconds.

### 3.2 The rest of the questionnaire

| IARC question                                 | SELECT                                                                                         | Evidence                                                                                                                                                                                                                                                                                                   |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Violence, blood, gore                         | **No**                                                                                         | Educational content only: traffic rules, first aid, vehicle mechanics                                                                                                                                                                                                                                      |
| Sexual content, nudity                        | **No**                                                                                         | None                                                                                                                                                                                                                                                                                                       |
| Profanity / crude humour                      | **No** in app-authored content. User-generated text is covered by 3.1                          | Question and lesson text is first-party and reviewed                                                                                                                                                                                                                                                       |
| Controlled substances                         | **⚠️ Read carefully.** The curriculum covers **alcohol and driving** as a traffic-safety topic | `packages/question-bank` — trafik/adab subjects include alcohol limits. This is legally-required educational content about a prohibited behaviour, not promotion. Answer per the questionnaire's own wording; if it asks about _references to_ alcohol, answer **Yes** and explain the educational context |
| Gambling / simulated gambling                 | **No**                                                                                         | Duel is a knowledge quiz with no wagering and no virtual currency purchase                                                                                                                                                                                                                                 |
| Users can share their location                | **No**                                                                                         | No location permission, no geolocation code anywhere                                                                                                                                                                                                                                                       |
| Users can purchase digital goods              | **Yes**                                                                                        | `in_app_purchase` → Play Billing; 3 packages                                                                                                                                                                                                                                                               |
| Shares personal info with third parties       | **No**                                                                                         | See §6 — no data sharing                                                                                                                                                                                                                                                                                   |
| Shares user-provided content with other users | **Yes**                                                                                        | Community surfaces per 3.1                                                                                                                                                                                                                                                                                 |
| Unrestricted internet access (browser)        | **No**                                                                                         | No in-app browser; `url_launcher` is not even a dependency                                                                                                                                                                                                                                                 |
| Digital purchases                             | **Yes**                                                                                        | as above                                                                                                                                                                                                                                                                                                   |

**Expected outcome.** With user-to-user communication declared, the rating will land above
"Everyone / 3+". That is correct and expected — do not try to engineer a lower rating by
under-declaring.

**MITIGATING FACTS to include in any free-text explanation** (all verifiable):

- Community participation is **opt-in with explicit consent**; nothing is shared until the user
  joins (`join_community_screen.dart:17`).
- Only display name, avatar and study statistics are shared —
  _"e-posta ve gerçek adın **asla** görünmez"_ (`join_community_screen.dart:91`).
- Reporting exists and is honest about its scope: _"Bildirimler insan incelemesine gider. Otomatik
  bir filtre yoktur."_ (`report_sheet.dart:33`).
- Blocking plus an unblock-management screen exist (`blocked_users_screen.dart`).

---

## 4. Target audience and content

**Console path:** App content → Target audience and content

**SELECT — Target age groups: 18 and over.**

**WHY.** The product prepares candidates for the Turkish driving-licence examination. The minimum
age for a B-class licence in Turkey is 18. `PLAY_DATA_SAFETY.md` §4 already records the intended
answer as _"Hedef kitle 18+ (sürücü belgesi adayları)"_.

**Note on A-class:** the app also covers A (motorcycle), where some sub-classes start at 16. The
Console asks for target age _groups_ and allows multiple selections. Selecting **18 and over**
only is the defensible answer because the app's own description and onboarding are written for
licence candidates generally, and because selecting a 13–17 band would pull the app into
**Families policy**, which brings ad-content, data and design requirements this app is not built
for.

**SELECT — "Do children under 13 use your app?": No.**
**SELECT — Play Families Policy applies: No.**

**REVIEWER SEES.** Onboarding asks which licence class the user is pursuing and how long until the
exam. No child-directed design, no cartoon-for-children framing (the owl mascot is a brand device
in an adult education context, not a children's character).

**MISMATCH RISK.** If any store asset or description is written to appeal to under-18s, the
appeal-to-children assessment could pull the app into Families. **The screenshot plan in
`ASO_PROMPT_LIBRARY.html` deliberately keeps the mascot secondary and the tone adult.**

**⚠️ MANUAL VERIFICATION REQUIRED:** the owner should confirm the marketing tone decision, since
"appeals to children" is assessed on the store listing as a whole, not on code.

---

## 5. News apps

**Console path:** App content → News apps

**SELECT: "No, my app is not a news app"**

**WHY.** Educational exam-preparation content. No journalism, no editorial feed, no current-affairs
reporting. The daily "Sınav Arşivi" entries are _date-seeded practice exams generated
deterministically from the existing bank_ — not news.

**EVIDENCE.** `lib/domain/practice/exam_library.dart:125-139` — `libraryExams()` builds a list by
subtracting days from today and seeding generation from the date.

**MISMATCH RISK.** The archive labels exams _"10 Ağustos 2026 Sınav Soruları"_, which reads like
dated content. It is generated, not published, and the description must not imply that real exam
papers are being republished daily.

---

## 6. Data safety — the collection matrix

**Console path:** App content → Data safety

**SELECT: "Does your app collect or share any of the required user data types?" → YES.**

This supersedes any earlier "no collection" position. The app began collecting analytics and crash
reports in Beta Phase 3–4; shipping with a no-collection declaration would be a false statement.

### The matrix

| Play data type                   | Collected | Shared | Required     | Purpose                                                  | Evidence                                                                      |
| -------------------------------- | --------- | ------ | ------------ | -------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **Email address**                | Yes       | No     | **Optional** | Account management                                       | `apps/web/app/api/auth/register/route.ts:29,71`                               |
| **Name**                         | Yes       | No     | **Optional** | Account management                                       | same (`name` column)                                                          |
| **User IDs**                     | Yes       | No     | Optional     | Account management, app functionality                    | `users.id`, session bearer tokens                                             |
| **Purchase history**             | Yes       | No     | **Required** | App functionality (premium entitlement)                  | `lib/data/premium/entitlements_repository.dart:63-69` → `/api/iap/validate`   |
| **App interactions**             | Yes       | No     | Optional     | Analytics, app functionality                             | `lib/core/analytics/*` → `/api/analytics/collect`                             |
| **Crash logs**                   | Yes       | No     | Optional     | Diagnostics                                              | `lib/core/observability/error_reporter.dart`                                  |
| **Other user-generated content** | Yes       | No     | Optional     | App functionality (AI Koç questions; community messages) | `lib/data/coach/coach_api.dart:68`; `lib/features/community/chat_screen.dart` |
| **Photos**                       | Yes       | No     | Optional     | App functionality (avatar)                               | `lib/data/community/avatar_service.dart`                                      |

**"Required" vs "Optional" — get this right.** Only **purchase history** is required, and only for
users who buy. Email and name are optional because **the app works fully without an account**
(§1). Analytics and crash logs are optional because they are not needed for the app to function.

### Explicitly NOT collected

| Category                                 | Why not                                                           | Evidence                                                     |
| ---------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------ |
| **Location** (approximate or precise)    | No location permission; no geolocation API used                   | `AndroidManifest.xml`; no `geolocator`/`location` dependency |
| **Contacts**                             | No permission, no API                                             | `AndroidManifest.xml`                                        |
| **Calendar, SMS, call logs**             | No permission                                                     | `AndroidManifest.xml`                                        |
| **Microphone / audio**                   | No permission                                                     | `AndroidManifest.xml`                                        |
| **Health and fitness**                   | Not applicable                                                    | —                                                            |
| **Financial info (payment details)**     | Payment is entirely inside Google Play; the app never sees a card | `in_app_purchase`; only a purchase token reaches the server  |
| **Device or other IDs (advertising ID)** | AAID/GAID never read; no ads SDK                                  | `analytics.dart:16-20`                                       |
| **Files and docs**                       | No storage permission, no file access                             | `AndroidManifest.xml`                                        |
| **Web browsing history**                 | No browser                                                        | `url_launcher` absent                                        |
| **Installed apps**                       | Not queried                                                       | manifest `<queries>` covers only `ACTION_PROCESS_TEXT`       |

### Data sharing: NO, for every category

**WHY.** "Sharing" in Play's definition means transferring data to a **third party**. Every
endpoint this app talks to is first-party, in the same Vercel deployment as the web app:
`/api/analytics/collect`, `/api/errors/report`, `/api/ai/ask`, `/api/iap/validate`, `/api/account`,
`/api/auth/*`, `/api/mobile/*`.

The `error_reporter.dart:35-40` header records this as a deliberate decision:

> _"Crashlytics/Sentry taşımak, KVKK açısından ayrı bir karar (üçüncü tarafa veri aktarımı) ve
> uygulamaya ek bir yerel bağımlılık demek. Raporlar kendi sunucumuza gider."_

**⚠️ MANUAL VERIFICATION REQUIRED — three sub-processor questions the repo cannot answer:**

1. **Anthropic (Claude Haiku 4.5)** receives the free-text question a user types into AI Koç, via
   the server. Under Play's definition this is a **service provider**, not "sharing", _provided_
   the processing is limited to serving the request. Confirm the contractual position and disclose
   it in the privacy policy.
2. **Neon (PostgreSQL)** and **Vercel** are infrastructure processors — again service providers,
   not sharing, but they belong in the privacy policy's sub-processor list.
3. **The email provider** used by `apps/web/lib/server/email.ts` receives the user's address to
   send verification/welcome mail. Same treatment.

None of these changes the Data Safety "shared" answer to Yes. **All three must appear in the
privacy policy** or the policy will be incomplete — which is part of 🔴-1.

---

## 7. Data safety — per-category answers

### 7.1 Personal info → Email address

- **Collected:** Yes · **Shared:** No · **Ephemeral:** No · **Required:** No (optional)
- **Purposes:** Account management
- **EVIDENCE:** `apps/web/app/api/auth/register/route.ts:29,33,71`; also Google Sign-In returns an
  email (`lib/data/auth/google_auth_service.dart`).
- **REVIEWER SEES:** Profil → Giriş yap / Kayıt ol → email + password form, and a Google button
  **if the build carried `GOOGLE_SERVER_CLIENT_ID`** (see §20 M1).
- **MISMATCH RISK:** If the uploaded AAB omits that dart-define, the Google button vanishes and the
  listing would advertise a sign-in method the binary does not contain.

### 7.2 Personal info → Name

- **Collected:** Yes · **Shared:** No · **Required:** No
- **Purposes:** Account management, app functionality
- **Note:** the community **display name** is user-chosen and separate from the account name; the
  join screen states the real name is never shown (`join_community_screen.dart:91`).

### 7.3 Personal info → User IDs

- **Collected:** Yes · **Shared:** No · **Required:** No
- **Purposes:** Account management, app functionality, analytics
- **EVIDENCE:** `users.id`; sessions table with bearer tokens; analytics context carries an optional
  `userId` (`analytics.dart:19-30`).
- **Important nuance for the form:** the analytics `anonId` is **not** a device ID. It is a random
  string generated once per install, is not the advertising ID, and disappears on uninstall
  (`analytics.dart:16-20`). Declare it under **App interactions**, not under "Device or other IDs".
  `PLAY_DATA_SAFETY.md` §3 reaches the same conclusion.

### 7.4 Financial info → Purchase history

- **Collected:** Yes · **Shared:** No · **Required:** **Yes** (for purchasers)
- **Purposes:** App functionality
- **EVIDENCE:** `entitlements_repository.dart:63-69` posts `{productId, purchaseToken, packageName}`
  to `/api/iap/validate`.
- **Explicitly NOT collected:** payment method, card number, billing address. Google Play handles
  payment; only an opaque purchase token reaches the server.
- **BLOCKED BY 🔴-3:** the verification endpoint is a stub. This does not change the declaration —
  the token _is_ transmitted and stored — but it does mean the stated purpose ("entitlement
  verification") is not yet genuinely performed.

### 7.5 App activity → App interactions

- **Collected:** Yes · **Shared:** No · **Required:** No
- **Purposes:** Analytics, app functionality
- **EVIDENCE:** `lib/core/analytics/analytics_sink.dart:173-174` → `POST /api/analytics/collect`.
- **What is in an event:** the event dictionary header is explicit —
  _"`props` içine **kişisel veri konmaz** — e-posta, ad, serbest metin, soru cevabı yok. Yalnız
  sayılar, kısa kimlikler ve numaralandırılmış değerler."_ (`analytics_event.dart`). A test enforces
  it (`test/analytics_test.dart`).
- **Server-side hardening worth citing:** the client-supplied `userId` is ignored; the event is
  bound to the server session (`apps/web/lib/server/telemetry.ts`), so nobody can write events
  against another identity.

### 7.6 App info and performance → Crash logs

- **Collected:** Yes · **Shared:** No · **Required:** No
- **Purposes:** Diagnostics
- **EVIDENCE:** `lib/core/observability/error_reporter.dart` → own server. Queue capped at 50
  reports with fingerprint-based deduplication.
- **No third-party crash SDK.** Do not tick any Crashlytics/Sentry-related option.

### 7.7 Messages / Other user-generated content

- **Collected:** Yes · **Shared:** No · **Required:** No
- **Purposes:** App functionality
- **Two distinct flows:**
  1. **AI Koç question text** → `POST /api/ai/ask` (`coach_api.dart:68`). The route responds
     `cache-control: no-store` (`apps/web/app/api/ai/ask/route.ts:29`) and the request body is not
     written to a persistent table. Declare it as collected — it is transmitted — and describe the
     retention honestly in the privacy policy.
  2. **Community messages, discussion posts and group content** → stored, because other users must
     be able to read them, and because reports need something to review.
- **MISMATCH RISK:** `PLAY_DATA_SAFETY.md` §1 footnote 3 currently mentions only the AI Koç flow.
  **Community UGC must be added** — it is the larger of the two and it is persisted.

### 7.8 Photos and videos → Photos

- **Collected:** Yes · **Shared:** No · **Required:** No
- **Purposes:** App functionality (community avatar)
- **EVIDENCE:** `lib/data/community/avatar_service.dart` uses `image_picker`.
- **Important:** the code notes that on modern Android this opens the **system photo picker**, which
  requires **no permission** and grants access only to the single image the user chose
  (`avatar_service.dart:18-20`). The app never scans the gallery.
- **MISMATCH RISK:** `PLAY_DATA_SAFETY.md` §2 lists "Fotoğraf / video" under _not collected_, with
  the reasoning that it is only for avatars and only on user action. **That is the wrong line for
  the Play form.** A user-selected image that is uploaded to the server _is_ collected. Declare
  **Photos: collected, optional, app functionality**.
  ⚠️ **MANUAL VERIFICATION REQUIRED:** confirm whether the chosen avatar image is uploaded to the
  server or only processed on device. If it never leaves the device, declare **not collected** and
  record why. Check `avatar_service.dart` upload path and the community API.

---

## 8. Data safety — security practices

| Console question                   | SELECT                                                                                                                                                          | Evidence                                                                                                                                |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Is data encrypted in transit?      | **Yes**                                                                                                                                                         | All endpoints are HTTPS (`AppConfig.apiBaseUrl` = `https://www.ehliyetegitim.com`); no cleartext traffic configuration in the manifest  |
| Can users request data deletion?   | **Yes**                                                                                                                                                         | In-app: Profil → Hesabımı sil → `DELETE /api/account` → `db.delete(users)` with 29 `ON DELETE CASCADE` FKs (`packages/db/src/index.ts`) |
| Committed to Play Families Policy? | **No**                                                                                                                                                          | Target audience 18+ (§4)                                                                                                                |
| Independent security review        | **⚠️ MANUAL** — only tick if one was genuinely commissioned. `SECURITY_REVIEW.md` in this repo is an internal review, which is **not** what this question means |

**Deletion caveat to record internally** (not a Console field): four foreign keys to `users` have no
`ON DELETE` clause — `content_items.created_by` (:132), `content_versions.changed_by` (:146),
`media_assets.created_by` (:335), `audit_logs.user_id` (:342). All four are admin/CMS tables written
only from `apps/web/lib/server/cms.ts`, so a normal user's deletion cascades cleanly. **Deleting an
admin account would fail with a foreign-key violation.** See `PLAY_STORE_REVIEW_AUDIT.md` 🟡-1.

---

## 9. Privacy policy

**Console path:** App content → Privacy policy

**ENTER: `https://www.ehliyetegitim.com/gizlilik`**

**🔴 BLOCKED BY 🔴-1 — DO NOT SUBMIT WITH THE CURRENT PAGE.**

The live page returns HTTP 200 but opens with a draft-document warning and carries `[Şirket
Ünvanı]`, `[VKN]`, `[Adres]`, `[KEP adresi]` and `[destek e-postası]` as placeholders. It also
describes the product as _"bir web uygulamasıdır"_ and says progress lives in the browser's
`localStorage` — neither is true of the Android app.

**What the rewritten policy must contain to match this guide:**

- [ ] A named legal entity and a monitored contact email (replacing all five placeholders)
- [ ] Removal of the "Taslak belge uyarısı" banner
- [ ] Explicit coverage of the **Android app**, not only the web app
- [ ] Analytics event collection and its anonymous-ID design
- [ ] Crash/error reporting to first-party servers
- [ ] Google Sign-In as an authentication method
- [ ] Play Billing purchase tokens and what is stored
- [ ] AI Koç: that typed questions are sent to a server, processed by a third-party model provider,
      and what the retention is
- [ ] Community: display name, avatar, study statistics; that email and real name are never shown
- [ ] Local notifications
- [ ] Sub-processors: Anthropic, Vercel, Neon, the email provider (§6)
- [ ] Correction or removal of the _"yaklaşık konum düzeyinde IP kaydı"_ sentence, which currently
      contradicts the Data Safety answer of "location: not collected"
- [ ] Retention periods and the deletion route (§10)

`/kvkk` carries the same draft banner and the same placeholders and needs the same treatment.

---

## 10. Account deletion

**Console path:** App content → Data safety → Data deletion

**SELECT: "Users can request that their data is deleted"** and provide **both** paths.

| Path        | Value                                            | Status                                                                       |
| ----------- | ------------------------------------------------ | ---------------------------------------------------------------------------- |
| **In-app**  | Profil → Hesabımı sil                            | ✅ Implemented (`profile_screen.dart:164-165`, `delete_account_dialog.dart`) |
| **Web URL** | e.g. `https://www.ehliyetegitim.com/hesap-silme` | 🔴 **DOES NOT EXIST — all candidates return 404**                            |

**🔴 BLOCKED BY 🔴-4.** Play requires a web-accessible deletion route for account-based apps, so a
user who has uninstalled the app can still request deletion. Verified 404 on `/hesap-silme`,
`/veri-silme`, `/hesabimi-sil`, `/delete-account`, `/hesap-sil`.

**What the page must say:**

- How to delete from inside the app (the primary route)
- What is deleted: account, progress, entitlement records, community profile and messages
- What is retained and why (e.g. purchase/invoice records for statutory accounting periods)
- The retention window before permanent deletion
- An email route for users without the app installed

**In-app flow detail worth knowing.** The dialog does not delete on first confirmation — _"'Evet,
hesabımı sil' doğrudan silmez; sunucunun bildirdiği koşula göre ikinci bir onay alır"_
(`delete_account_dialog.dart:18`). Password re-entry is enforced server-side
(`apps/web/app/api/account/route.ts:86`).

**⚠️ MANUAL VERIFICATION REQUIRED (M3):** register a throwaway account, generate progress, delete
it, and confirm the rows are actually gone. Cascade is declared in SQL; that it executes is
unverified.

---

## 11. Government apps, financial features, health

| Console section        | SELECT | Why                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Government apps**    | **No** | ⚠️ **Read this carefully.** The app prepares users for a state examination but is **not** developed by, on behalf of, or in partnership with any government body. **No asset or description may claim MEB affiliation, endorsement or approval.** Two existing assets carry _"MEB Uyumlu"_ / _"MEB Müfredatına %100 Uygun"_ — both must be removed (`PLAY_STORE_REVIEW_AUDIT.md` 🔴-2). |
| **Financial features** | **No** | No lending, no investment, no payments beyond Play Billing, no crypto                                                                                                                                                                                                                                                                                                                   |
| **Health apps**        | **No** | The first-aid curriculum (303 questions, 2 lessons) is **exam preparation**, not health guidance. It must never be framed as medical instruction, and no asset may present it as first-aid _advice_.                                                                                                                                                                                    |

**Recommended safe phrasing for MEB.** Describe **format compliance**, never affiliation:

> _"e-Sınav biçiminde: 50 soru, 45 dakika, 23/12/9/6 dağılım."_

That is a factual statement about the exam format the app reproduces
(live `blueprint`: `{totalQuestions:50, passCorrect:35, durationMinutes:45,
distribution:{trafik:23, ilkyardim:12, motor:9, adab:6}}`). It claims nothing about MEB's opinion of
the app.

---

## 12. Generative AI declaration

**Console path:** App content → (Generative AI, where surfaced for the account)

**SELECT: the app contains generative-AI features.**

### What the app actually does

| Component                                | Implementation                                                                                | Is it AI?                                                  |
| ---------------------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **AI Koç chat**                          | `POST /api/ai/ask`, `/api/ai/ask/stream` → **Anthropic Claude Haiku 4.5**, server-side        | **Yes — a real LLM**                                       |
| **Grounding gate**                       | Server refuses ungrounded questions; response carries `grounded` + `sources`                  | Yes, part of the AI pipeline                               |
| **Coach insights / nudges / 7-day plan** | `lib/domain/coach/coach_insights.dart`, `nudge.dart` — **deterministic on-device heuristics** | **No.** Must not be marketed as AI                         |
| **Duel opponent**                        | `AiOpponent` — a deterministic accuracy curve, not a model                                    | **No.** Named "AI" in code; must not be marketed as an LLM |
| **Visual questions**                     | Generated on device from bundled catalogues                                                   | **No** — templated generation, not a model                 |

**Marketing consequence.** Only the chat is genuinely an LLM. The prompt library confines the AI
claim to the chat screen and describes the coach cards as _"çalışma planı"_, not as AI output.

### Safeguards already shipped — cite these in the declaration

| Requirement                       | Status         | Evidence                                                                                                                                 |
| --------------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| AI presence disclosed in-app      | ✅             | Standing disclaimer: _"AI yanıtları platform içeriğine dayanır; kesin ve güncel kural için MEB/MTSK esastır."_ (`coach_screen.dart:300`) |
| Per-response provenance           | ✅             | Badge shows `İçeriğe dayalı` (green, verified icon) or `AI` (`coach_screen.dart:429-438`)                                                |
| Sources surfaced                  | ✅             | `sources` array rendered with the answer (`coach_api.dart:76`)                                                                           |
| AI visibly synthetic, not human   | ✅             | Cartoon owl mascot; never a photorealistic person                                                                                        |
| Grounding / hallucination gate    | ✅             | Server refuses ungrounded answers; offline mock composer as fallback                                                                     |
| **In-app reporting of AI output** | ❌ **MISSING** | No report affordance on assistant messages — see 🟠-6                                                                                    |

**🟠 ACTION REQUIRED.** Play's generative-AI policy expects users to be able to report offensive
AI-generated content **without leaving the app**. The app already contains the exact widget needed
(`lib/features/community/report_sheet.dart`); wire it into AI Koç messages before submitting.

### AI-related data handling

- The user's typed question is transmitted to the first-party API and then to the model provider.
- The route sets `cache-control: no-store` and the body is not persisted
  (`apps/web/app/api/ai/ask/route.ts:29`).
- **Declare under Data Safety as "Other user-generated content"** (§7.7).
- **The privacy policy must state that questions are processed by a third-party model provider.**
  It currently does not — part of 🔴-1.
- **Never claim the model learns from user data.** If false it is misrepresentation; if true it is
  an undeclared Data Safety item. Nothing in the repo suggests any training use.

---

## 13. User-generated content and moderation

Play expects apps with UGC to have a moderation strategy, a reporting mechanism and a way for users
to block others. **All three ship.**

| Requirement                      | Status | Evidence                                                                                                                                     |
| -------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Report content                   | ✅     | `lib/features/community/report_sheet.dart`; `chat_screen.dart:349-362` → `reportContent()`                                                   |
| Report acknowledgement to user   | ✅     | _"Bildirimin alındı. İnceleyeceğiz."_ (`chat_screen.dart:362`)                                                                               |
| Honest description of moderation | ✅     | _"Bildirimler insan incelemesine gider. Otomatik bir filtre yoktur."_ (`report_sheet.dart:33`)                                               |
| Block a user                     | ✅     | `communityApi.block()`; entry point on every surface — _"Rahatsız eden birini her ekrandan engelleyebilirsin"_ (`community_screen.dart:104`) |
| Unblock / manage blocks          | ✅     | `blocked_users_screen.dart`                                                                                                                  |
| Server-side storage of reports   | ✅     | `question_reports` and community report tables in `packages/db/src/index.ts:199-210`                                                         |
| Opt-in before any sharing        | ✅     | `join_community_screen.dart:17,89-91`                                                                                                        |

**⚠️ MANUAL VERIFICATION REQUIRED:** a moderation _process_ must exist behind the reports — someone
who reads the queue and acts. The code promises human review; the Console answer and the app's own
string both depend on that promise being kept.

---

## 14. Photos and media

**Permission model: none required.**

`image_picker` on modern Android opens the **system photo picker**, which returns a single
user-chosen image without any runtime permission. The manifest's permission list is only
`POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`, which the code comments call out explicitly
(`avatar_service.dart:18-20`).

- **No `READ_MEDIA_IMAGES`, no `READ_EXTERNAL_STORAGE`.** Do not add them.
- **No gallery scanning.** Only the selected image is accessible.
- **Declaration:** see §7.8 — declare **Photos** as collected/optional, subject to the manual check
  on whether the avatar is uploaded.

---

## 15. Notifications

- **Permission:** `POST_NOTIFICATIONS` (Android 13+) declared in the manifest.
- **Also declared:** `RECEIVE_BOOT_COMPLETED`, so scheduled reminders survive a reboot
  (`ScheduledNotificationBootReceiver` in the manifest).
- **Type:** **local only.** `flutter_local_notifications` + `timezone`. **There is no FCM, no push
  server, no remote message path.** The service header states it:
  _"Yerel bildirim servisi (flutter_local_notifications). Çevrimdışı; zamanı-tabanlı hatırlatmalar"_
  (`lib/data/coach/notification_service.dart:9`).
- **Permission timing:** requested from the notification-preferences flow, not at cold start
  (`lib/domain/coach/notification_prefs.dart:154`). Good practice; the reviewer will not be
  ambushed at launch.
- **User control:** a dedicated settings screen with per-type toggles and a master switch; turning a
  type off cancels already-scheduled notifications (`notification_service.dart:97-98`).
- **Data safety impact:** none. No token is collected, nothing is transmitted.
- **Console:** no separate notifications declaration is required. Do **not** declare push messaging.

---

## 16. Referral / deep links

- **Web link:** `https://www.ehliyetegitim.com/davet/<KOD>` — `android:autoVerify="true"`
- **Custom scheme:** `ehliyetakademi://app/davet/<KOD>` — always works if installed
- **Reward integrity:** an invite counts only after the invited friend verifies their email; the
  screen deliberately shows "invited" and "counted" as separate numbers so users do not think a
  reward is missing (`referral_screen.dart:17-19,125`).
- **Data:** invite codes are bound to an account. Raw IP is **not** stored — only a salted SHA-256
  for fraud detection (`apps/web/lib/server/referrals.ts` → `hashIp`).

**🟠 BLOCKED BY 🟠-1.** `https://www.ehliyetegitim.com/.well-known/assetlinks.json` currently returns
**`[]`**, so App Links verification will fail and https invite links will open in the browser.
Publish the **Play App Signing** SHA-256 fingerprint (from Play Console → App integrity), not the
upload key.

**Console impact:** none directly, but the listing must not promise one-tap app opening until this
is fixed.

---

## 17. Monetisation and in-app purchases

**Console path:** Monetise → Products

| Product  | Type                           | Store ID            | Notes                                                                                                                                    |
| -------- | ------------------------------ | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Lifetime | **One-time (managed product)** | `komple_ehliyet`    | Server ID is `komple-ehliyet`; the `_`↔`-` bridge is deliberate and test-locked (`entitlements_repository.dart:173`, `products.dart:85`) |
| Weekly   | **Subscription**               | see `products.dart` | `BillingPeriod.weekly`, suffix `/hafta`                                                                                                  |
| Monthly  | **Subscription**               | see `products.dart` | `BillingPeriod.monthly`, suffix `/ay`                                                                                                    |

**Answers:**

- **"Does your app contain in-app purchases?" → Yes.**
- **Billing library:** Google Play Billing via `in_app_purchase` ^3.3.0. **RevenueCat was removed**
  — do not configure it, and leave `REVENUECAT_PUBLIC_KEY` unset (supplying it switches the app onto
  a gateway whose webhook bridge is not configured).

**Critical warnings:**

1. **🔴 BLOCKED BY 🔴-3.** Server-side receipt verification is a stub. **Do not set
   `GOOGLE_PLAY_SA_JSON` until the real `androidpublisher` check exists** — the env var currently
   acts as the only fail-closed guard, and setting it would let any authenticated user self-grant
   lifetime premium.
2. **`STORE_LISTING.md` says one product at 399 TL.** There are three, and the lifetime price at the
   store is **479,99 TL**. Screens are safe (prices are read from the store only,
   `paywall_screen.dart:83-89`), but **no listing text or asset may state a price**.
3. **No trial claims.** Nothing in the repo configures a free trial. Do not write "ücretsiz deneme"
   anywhere unless a live SKU carries one, and if it does, the terms and price must accompany it.

**⚠️ MANUAL VERIFICATION REQUIRED (M2):** one real purchase and one restore, on a device, with a
licence tester account. No automated check covers this.

---

## 18. Permissions declaration

**Declared in the release manifest:**

| Permission               | Why                                             | Sensitive-permission declaration needed? |
| ------------------------ | ----------------------------------------------- | ---------------------------------------- |
| `POST_NOTIFICATIONS`     | Local study reminders                           | No                                       |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule reminders after reboot              | No                                       |
| `VIBRATE`                | Merged in by `flutter_local_notifications`      | No                                       |
| `INTERNET`               | **Merged in only via `google_sign_in_android`** | No — but see below                       |

**No sensitive-permission declaration forms are required.** The app requests no location, camera,
microphone, contacts, SMS, call log, `QUERY_ALL_PACKAGES`, `MANAGE_EXTERNAL_STORAGE`, accessibility
service, or exact-alarm permission.

**🟠 Action (🟠-3):** `INTERNET` is declared only in `android/app/src/debug/` and
`android/app/src/profile/`. The release build gets it by accident, through the `google_sign_in_android`
plugin manifest merge. Add it explicitly to `android/app/src/main/AndroidManifest.xml` — one line,
no behaviour change today, removes a latent silent-failure mode.

---

## 19. Store listing metadata

The full proposed copy lives in **`ASO_PROMPT_LIBRARY.html` → "Play Store Listing Metni"**. What
belongs _here_ is the compliance frame:

| Field             | Limit       | Rule                                                                                    |
| ----------------- | ----------- | --------------------------------------------------------------------------------------- |
| App name          | 30 chars    | Must match `android:label` conceptually. `android:label` is `Ehliyet Akademi`.          |
| Short description | 80 chars    | Count characters, not bytes — Turkish is multi-byte.                                    |
| Full description  | 4.000 chars | Google Play **has no keyword field**; keywords must sit naturally inside readable copy. |

**Claim rules that apply to the text exactly as they apply to screenshots:**

- **Never claim MEB affiliation, endorsement or approval.** Format compliance only (§11).
- **Never promise exam success, passing, or a licence.** Duration and content volume are facts;
  outcomes are not.
- **Never state a user count, rating, download figure or ranking.**
- **Never state a price or a trial.** (§17)
- **Never use privacy absolutes** — no "%100 güvenli", "hiçbir veri gönderilmez", "tamamen".
  Scope every privacy sentence to the data it is actually true of.
- **Question count is 1.605** (live-verified). Not 10.000+. Not "binlerce" without a basis.
- **Lesson count is 29.** Nineteen is the number that carry a drawn figure.
- **Video count is 7 available** (2 more are `planned`), each 10–14 seconds. They are short
  manoeuvre clips, not "HD video dersler".
- **Duel is against a deterministic AI opponent**, not live multiplayer.
- **Voice narration does not exist yet** — the abstraction ships with no audio. Do not mention it.

---

## 20. Pre-submission manual checklist

Nothing below can be settled from the repository. Each needs a person, a device, or the Console.

| #       | Task                                                                                                                                              | Owner       | Blocks submission?                          |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------- |
| **M1**  | Verify the uploaded AAB carries `GOOGLE_SERVER_CLIENT_ID`:<br>`unzip -p <aab> base/lib/arm64-v8a/libapp.so \| grep -a apps.googleusercontent.com` | Engineering | **Yes** if the listing shows Google Sign-In |
| **M2**  | One real purchase + one restore on a device with a licence tester                                                                                 | Owner       | **Yes**                                     |
| **M3**  | Account deletion end to end on a throwaway account; confirm cascaded rows are gone                                                                | Owner       | **Yes**                                     |
| **M4**  | Airplane-mode first launch (no cache yet)                                                                                                         | Engineering | No — but a bad first impression             |
| **M5**  | 360 dp layout sweep (six-tab bar, overflow)                                                                                                       | Engineering | No                                          |
| **M6**  | Light-theme sweep across every screen                                                                                                             | Engineering | No                                          |
| **M7**  | Confirm the two `planned` videos render as unavailable, not as broken players                                                                     | Engineering | No                                          |
| **M8**  | After fixing `assetlinks.json`, confirm the deep link opens the app                                                                               | Engineering | No                                          |
| **M9**  | A monitored support mailbox exists and is in the privacy policy                                                                                   | Owner       | **Yes** (part of 🔴-1)                      |
| **M10** | Closed-testing tester count and continuous-day requirement met                                                                                    | Owner       | **Yes**, if the account is subject to them  |
| **M11** | Confirm whether the community avatar image is uploaded to the server (§7.8)                                                                       | Engineering | **Yes** — determines a Data Safety answer   |
| **M12** | Confirm the sub-processor list (Anthropic, Vercel, Neon, email provider) for the privacy policy                                                   | Owner       | **Yes** (part of 🔴-1)                      |
| **M13** | Confirm a human moderation process exists behind community reports (§13)                                                                          | Owner       | No — but the app promises it                |
| **M14** | Decide and record the alcohol-content answer in the IARC questionnaire (§3.2)                                                                     | Owner       | **Yes**                                     |
| **M15** | Confirm no independent security review is being claimed in Data Safety (§8)                                                                       | Owner       | **Yes**                                     |

---

## Cross-check before you press Submit

Run this last. Every row must agree with every other row.

| Claim               | Screenshot              | Listing text              | Data Safety                 | Privacy policy                    | App           |
| ------------------- | ----------------------- | ------------------------- | --------------------------- | --------------------------------- | ------------- |
| 1.605 soru          | ✅ must say 1.605       | ✅ 1.605                  | —                           | —                                 | ✅ live API   |
| No ads              | no ad imagery           | no ad mention             | Ad ID: not collected        | no ad section                     | no SDK        |
| Account optional    | no forced-login imagery | "hesapsız kullanılabilir" | Email: **optional**         | must say so                       | guest mode    |
| AI is a real LLM    | AI disclosure visible   | AI disclosed + limits     | UGC collected               | **must name the provider**        | `/api/ai/ask` |
| Community is opt-in | no fabricated users     | opt-in stated             | UGC collected               | **must cover it**                 | join gate     |
| No location         | no map imagery          | no location mention       | Location: **not collected** | **must not say "yaklaşık konum"** | no permission |
| Purchases exist     | no price shown          | no price stated           | Purchase history: required  | must cover it                     | Play Billing  |
| Data can be deleted | —                       | —                         | Yes + **URL**               | must document it                  | in-app flow   |

Any row where one column disagrees with another is a finding, not a formatting issue. The FormAI
precedent is unambiguous: a privacy claim in an asset that contradicts the Data Safety form puts two
incompatible statements about user data on record with Google.

---

_Companion documents: `PLAY_STORE_REVIEW_AUDIT.md` (findings and evidence) and
`ASO_PROMPT_LIBRARY.html` (asset specifications, listing copy, and the post-generation validation
pipeline). Supersedes the collection matrix in `PLAY_DATA_SAFETY.md` where the two differ — that
file predates the current community/UGC surface and mis-classifies Photos._
