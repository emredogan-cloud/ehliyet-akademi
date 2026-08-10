# Play Store Review Audit — Ehliyet Akademi

**Audit date:** 10 August 2026 · **Branch:** `main` @ `9ecc358` · **App version:** `1.0.0+5`
**Package:** `com.ehliyetegitim.ehliyet_akademi` · **Locale:** tr-TR (single locale)
**Method:** source-code inspection + live API/endpoint probing + inspection of every existing
store asset at full resolution. Two personas: **Google Play reviewer** and **first-time user**.

> **Reading rule.** Every finding below cites the file, line, live URL or measured value it came
> from. Nothing here is inferred from an older report. Where the repository cannot answer a
> question, the finding says **MANUAL VERIFICATION REQUIRED** rather than guessing.
>
> **CI is green on `main`. That is a statement about the code, not about the listing.** Six of the
> findings below sit entirely outside CI's reach — they are live web pages, store assets, and
> Console declarations.

---

## 0. Verdict

| Class                             | Count | Meaning                                                                                           |
| --------------------------------- | ----- | ------------------------------------------------------------------------------------------------- |
| 🔴 **DEFINITE REJECTION RISK**    | 4     | Submitting today is very likely to be rejected or, worse, to pass and later be enforced against.  |
| 🟠 **MUST FIX BEFORE SUBMISSION** | 7     | Not certain rejection, but each is a documented enforcement trigger or breaks an advertised flow. |
| 🟡 **SHOULD FIX**                 | 9     | Quality, conversion or robustness. None blocks submission.                                        |
| 🟢 **NO ISSUE**                   | 17    | Verified working / verified compliant. Recorded so the next audit does not re-litigate them.      |

**Bottom line: do not submit today.** The four 🔴 items are the privacy policy, the existing store
assets, the receipt-verification stub and the missing data-deletion URL. All four are outside the
Flutter codebase, which is why a green CI run says nothing about them.

---

## 1. Verified product facts (the baseline every claim is checked against)

These were measured on the audit date. Everything in §2–§6 is judged against this table.

| Fact                   | Value                                                                         | Evidence                                                                               |
| ---------------------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| App label              | `Ehliyet Akademi`                                                             | `apps/mobile/android/app/src/main/AndroidManifest.xml`                                 |
| Package / version      | `com.ehliyetegitim.ehliyet_akademi` · `1.0.0+5`                               | `android/app/build.gradle.kts:57`, `pubspec.yaml:19`                                   |
| Bottom navigation      | **Ana Sayfa · Öğren · Pratik · AI Koç · Topluluk · Profil** (6 tabs)          | `lib/app/shell.dart:22-33`                                                             |
| Question bank (live)   | **1.605 soru** · version `bd9b94049853b0fc`                                   | `GET /api/mobile/question-bank`, 2026-08-10 09:45 UTC                                  |
| Bank by subject        | trafik 396 · motor 329 · pratik 305 · ilkyardım 303 · adab 272                | same response                                                                          |
| Bank by difficulty     | kolay 557 · orta 767 · zor 281                                                | same response                                                                          |
| Exam blueprint         | **50 soru · 45 dakika · 35 doğru geçme** · 23/12/9/6                          | same response, `blueprint` key                                                         |
| Lessons (live)         | **29 ders**, 19 carry a figure, 3 premium                                     | `GET /api/mobile/content-snapshot`                                                     |
| Signs / parts / videos | **121 işaret · 112 araç parçası · 9 video (7 yayında, 2 planlandı)**          | same response, `counts`                                                                |
| Device-side catalogues | 121 sign · **60 ikaz ışığı** · **101 mekanik görsel**                         | `lib/core/dash_assets.dart`, `lib/core/mech_assets.dart`                               |
| Visual questions       | Generated **on the device** from those catalogues                             | `lib/domain/practice/visual_questions.dart:10-33`                                      |
| Licence classes        | **B (Otomobil) · A (Motosiklet) · D (Otobüs)**                                | `lib/domain/onboarding/study_profile.dart:11-15`                                       |
| Exam archive           | 6 categories, **first 3 exams free catalogue-wide**                           | `lib/domain/practice/exam_library.dart:25-44,119,144`                                  |
| Duel                   | 10 soru × 20 sn vs a **deterministic AI opponent**; 5 free/day                | `lib/domain/duel/duel.dart:57-116`, `duel_energy.dart:52`                              |
| AI Koç                 | Server-side `/api/ai/ask`; grounded flag + sources + disclaimer               | `lib/data/coach/coach_api.dart:68,84`; `lib/features/coach/coach_screen.dart:300`      |
| Coach insights/nudges  | **On-device heuristics, not an LLM**                                          | `lib/domain/coach/coach_insights.dart`, `nudge.dart`                                   |
| Auth                   | Email/password, Google Sign-In, guest. **"The app never gates on auth."**     | `lib/domain/auth/auth_controller.dart:29`                                              |
| Billing                | `in_app_purchase` → Play Billing; 3 packages; prices read from the store only | `lib/domain/premium/products.dart`, `lib/features/premium/paywall_screen.dart:87`      |
| Permissions (release)  | `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` only                           | `AndroidManifest.xml` (main)                                                           |
| Analytics              | First-party → `/api/analytics/collect`; random `anonId`, **no ad ID**         | `lib/core/analytics/analytics.dart:16-20`, `analytics_sink.dart:174`                   |
| Crash reporting        | First-party → own server. **No Crashlytics, no Sentry**                       | `lib/core/observability/error_reporter.dart:35-40`                                     |
| Account deletion       | In-app: Profil → Hesabımı sil → `DELETE /api/account`                         | `lib/features/profile/profile_screen.dart:164`, `apps/web/app/api/account/route.ts:91` |
| Automated tests        | 74 mobile test files; full suite green on `main`                              | `apps/mobile/test/`                                                                    |

---

## 2. 🔴 DEFINITE REJECTION RISK

### 🔴-1 · The live privacy policy is an unfinished template with placeholder identity

**Exact problem.** `https://www.ehliyetegitim.com/gizlilik` and `https://www.ehliyetegitim.com/kvkk`
both return HTTP 200 and both open with:

> _"**Taslak belge uyarısı.** Bu metin bir taslaktır (template) ve henüz kuruluşu tamamlanmamış bir
> ürün için hazırlanmıştır. Kamuya açık yayına alınmadan önce bir avukat tarafından gözden
> geçirilmelidir. Metindeki şirket ve iletişim bilgileri — **[Şirket Ünvanı]**, **[VKN]**,
> **[Adres]**, **[KEP adresi]**, **[destek e-postası]** — yalnızca yer tutucudur ve gerçek bir tüzel
> kişiliği temsil etmez."_

Four separate defects compound:

1. **No identifiable data controller and no contact address.** Google's User Data policy requires
   the privacy policy to name the developer and provide a working contact method. `[destek
e-postası]` is not a contact method.
2. **It describes the wrong product.** §1 reads _"Ehliyet Akademi … bir **web uygulamasıdır**"_ and
   §3 says progress is kept _"cihazınızda (tarayıcının **localStorage** alanında)"_. There is no
   mention of an Android app anywhere.
3. **It omits most of what the app actually collects.** Nothing about analytics events
   (`/api/analytics/collect`), crash reports, Google Sign-In, Play Billing purchase tokens, the AI
   Koç free-text question sent to `/api/ai/ask`, community display name/avatar, or local
   notifications.
4. **It contradicts the intended Data Safety answer.** The policy says technical data includes
   _"yaklaşık konum düzeyinde IP kaydı"_ (IP logging at approximate-location granularity), while
   `PLAY_DATA_SAFETY.md` §2 declares location **not collected** and states raw IP is never stored
   (salted SHA-256 only). Two incompatible statements about the same data flow, one of them
   public.

**Reproduction.** `curl -s https://www.ehliyetegitim.com/gizlilik | grep -o 'Taslak belge'` →
matches. Same for `/kvkk`.

**Why Google/user cares.** The privacy policy URL is a required Console field and is read by
review. A policy that (a) announces itself as non-final, (b) has bracketed placeholders instead of
a legal entity, (c) describes a different product and (d) contradicts the Data Safety form is the
textbook Data Safety / User Data mismatch. Per the FormAI lessons (§2.1, §12), a listing claim that
contradicts the Data Safety declaration puts two incompatible statements about user data on record
with Google.

**Recommended fix.** Rewrite both pages against the _current_ mobile+web architecture, remove the
draft banner, fill in the legal entity and a monitored support mailbox, add sections for analytics,
crash reporting, AI Koç, Google Sign-In, Play Billing, community data and notifications, and delete
or correct the IP/approximate-location sentence so it agrees with the Data Safety form.

**Ownership.** Content: **manual (owner + legal)**. Publishing: **code** (`apps/web/app/(marketing)/gizlilik`, `/kvkk`).

---

### 🔴-2 · Every existing store asset in `apps/ASO_IMAGE/` is unshippable

**Exact problem.** All five phone assets were inspected at full resolution. Each one reproduces
multiple failure classes documented in `PLAY_STORE_ASO_LESSONS_LEARNED.md`. **This is not a design
critique — every item below is a claim the app contradicts.**

| Asset       | Findings                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **001.png** | iPhone frame with **Dynamic Island** + iOS status bar `9:41`; nav rendered `Ana Sayfa / Testler / **AI Asistan** / İstatistik / Profil` (the app's nav is `Ana Sayfa / Öğren / Pratik / AI Koç / Topluluk / Profil`); **"%100 Güvenli — Verilerin korunur"** (privacy absolute, contradicts the analytics/crash/AI data flow); **"MEB Uyumlu — Güncel müfredata tam uyum"**; **"Daha Yüksek Başarı"** (outcome claim); **"7/24 Destek"** (no support channel ships)                                                                                          |
| **002.png** | iPhone + Dynamic Island + `9:41`; nav `Ana Sayfa / Testler / Dersler / İstatistik / Profil` (second, different fabricated nav); greeting **"Merhaba, Emre!"** — a real personal name presented as a user; **stale in-app date "10 Mayıs 2024"** on a 2026 submission; invented metrics **"Genel Başarı Puanın 98 ★ MÜKEMMEL"**, **"124 Çözülen Test"**, **"%98 Doğru Oranı"**, **"🔥15 Aktif Seri"**, **"%23 daha iyisin"** — the real home screen shows _Hazırlık %_, _soru_, _doğruluk %_, _Lv_, and no "Genel Başarı Puanı" exists                        |
| **003.png** | iPhone + Dynamic Island + `9:41`; third fabricated nav; **"10.000+ Güncel Sınav Sorusu"** — the live bank is **1.605**, a 6.2× overstatement; **"MEB Müfredatına %100 Uygun"** (absolute + affiliation-adjacent)                                                                                                                                                                                                                                                                                                                                             |
| **004.png** | iPhone + Dynamic Island + `9:41`; fourth fabricated nav; **"3D Motor Görselleri"** (no 3D anywhere); **"Yüksek Kaliteli Video Dersler — HD videolarla"** with a **12:18 runtime and a chaptered playlist (03:15 / 04:27 / 02:36 / 02:50)** — the app ships **7 clips of 10–14 seconds** with no chapters; **a photorealistic instructor face named "Ahmet Yıldız · 10+ Yıl Sürücü Eğitmeni" with a "Takip Et" button** — fabricated identity + a follow feature that does not exist; **"Çevrimdışı İzle — İndir"** (no video download); **"Uzman Anlatımı"** |
| **005.png** | iPhone + Dynamic Island + `9:41`; fifth fabricated nav; **eight photorealistic human faces presented as named users** (Zeynep A., Emre Y., Kerem D., Merve Ç., Ahmet K., Berkay T., Elif S., Seda Y.); **"Binlerce sürücü adayıyla yarış"** and **"Binlerce kullanıcıyla etkileşimde kal"** — fabricated scale for a closed-beta app; **"Online Arkadaşlar · Çevrimiçi"** presence indicators; fabricated engagement counts **"125 beğeni · 23 Yorum"**; fabricated leaderboard point totals                                                                 |

**Technical defects on top of the content defects** (measured with Pillow):

| File                            | Size         | Mode     | Ratio  | Problem                                                                                                                           |
| ------------------------------- | ------------ | -------- | ------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `001.png`–`005.png`             | **941×1672** | **RGBA** | 1.7768 | **Alpha channel → Play rejects at upload.** Short side 941 < 1080 → loses promo/featuring eligibility. Not exactly 9:16 (1.7778). |
| `özellik-grafiği(OLD).png`      | 1794×876     | RGBA     | —      | Wrong dimensions for a feature graphic (must be 1024×500)                                                                         |
| `PlayStore-özellik-grafiği.png` | 1024×500     | RGB      | —      | Correct format — content not audited; superseded by the new plan                                                                  |
| `PlayStore-APP-ICON.png`        | 512×512      | RGB      | —      | Correct format — content not audited; see 🟡-9                                                                                    |

**Why Google/user cares.** Misrepresentation (features and layouts the app does not render),
Deceptive Behavior (fabricated users, fabricated scale, fabricated engagement counts), device
misrepresentation (Apple hardware in an Android listing), and a privacy absolute that contradicts
the Data Safety form. The reviewer has the app; four different fabricated navigation bars across
five assets is the specific thing review is designed to catch.

**Recommended fix.** **Do not upload any file from `apps/ASO_IMAGE/`.** Regenerate the full set
from `ASO_PROMPT_LIBRARY.html`, which specifies the real nav, the real numbers, an Android
punch-hole device, and forbids every string listed above.

**Ownership.** **Code/asset work** (regeneration + the post-generation CLI pipeline).

---

### 🔴-3 · Server-side Play receipt verification is a stub that grants premium for any 4-character string

**Exact problem.** `verifyPlayPurchase` in `apps/web/app/api/iap/validate/route.ts:33` returns
`valid: true` for any token of length ≥ 4. There is no `googleapis` dependency and no
`androidpublisher` call anywhere in the repository.

Production is currently safe **only** because `GOOGLE_PLAY_SA_JSON` is unset, which makes the route
return 503. **Setting that env var removes the fail-closed guard and activates the stub** — any
authenticated user could then self-grant lifetime premium by POSTing a four-character string.

**Reproduction.** Read `apps/web/app/api/iap/validate/route.ts:33`. Then
`grep -rn "androidpublisher\|googleapis" apps/web` → no matches.

**Why Google/user cares.** Two things. First, it is an unmetered revenue leak the moment the env
var is set. Second, and more relevant to review: **entitlements do not sync across devices** until
verification is real, so a reviewer who purchases on one device and restores on another may see
the restore fail — an advertised flow that does not complete.

**Danger note.** Several older documents in this repo list _"set `GOOGLE_PLAY_SA_JSON`"_ as the fix
for this blocker. **That advice is actively unsafe.** Implement the real
`purchases.products.get` / `purchaseState == 0` check and set the env var in the same change,
never separately.

**Recommended fix.** Add `googleapis`, implement the real verification, then set the variable.

**Ownership.** **Code** (`apps/web/app/api/iap/validate/route.ts`) + **Console/env** (service account).

---

### 🔴-4 · No account-deletion URL exists, and Play requires one

**Exact problem.** Play requires apps that let users create an account to provide a **web URL**
where deletion can be requested, in addition to the in-app path. Every plausible route 404s:

```
/hesap-silme      HTTP 404
/veri-silme       HTTP 404
/hesabimi-sil     HTTP 404
/delete-account   HTTP 404
/hesap-sil        HTTP 404
```

The in-app path **does** exist and works (Profil → Hesabımı sil → `DELETE /api/account` →
`db.delete(users)` with 29 `ON DELETE CASCADE` foreign keys). The gap is the _external URL_ the
Data Safety form asks for.

**Why Google/user cares.** The "Data deletion" field in the App content section is mandatory for
account-based apps. Leaving it blank blocks submission; pointing it at a 404 is worse.

**Recommended fix.** Publish a page (e.g. `https://www.ehliyetegitim.com/hesap-silme`) that
explains the in-app path, states what is deleted and the retention window, and offers an email
route for users who no longer have the app installed. `PLAY_DATA_SAFETY.md` §6 already records this
as open item #2.

**Ownership.** **Code** (new web route) + **Console** (paste the URL).

---

## 3. 🟠 MUST FIX BEFORE SUBMISSION

### 🟠-1 · `assetlinks.json` is an empty array — App Links verification will fail

`https://www.ehliyetegitim.com/.well-known/assetlinks.json` returns **`[]`** (HTTP 200,
`application/json`). The manifest declares `android:autoVerify="true"` for
`https://www.ehliyetegitim.com/davet/*` and `https://ehliyetegitim.com/davet/*`
(`AndroidManifest.xml`), so Android will attempt verification at install time and fail.

**Consequence:** referral links open in the browser instead of the app. The custom scheme
`ehliyetakademi://app/davet/<KOD>` still works, so the flow is degraded rather than broken — but
the referral screen advertises the https link (`lib/features/referral/referral_screen.dart:91`).

**Fix:** publish the Play App Signing SHA-256 fingerprint into
`apps/web/app/.well-known/assetlinks.json/route.ts`. **Use the Play App Signing key, not the upload
key** — locally signed builds cannot pass verification either way.

**Ownership:** **Code + Console** (fingerprint comes from Play Console → App integrity).

---

### 🟠-2 · No in-app link to the privacy policy, and the app cannot open one

The Profile menu contains: Koyu tema · Ehliyet sınıfı · Topluluk profilim · Bildirimler · Premium ·
Arkadaşını davet et · Uygulamayı puanla · Hakkında · Çıkış yap · Hesabımı sil
(`lib/features/profile/profile_screen.dart:78-165`). **There is no privacy-policy or KVKK entry.**

`url_launcher` is **not** a dependency (`pubspec.yaml`), so the app has no mechanism to open a web
URL at all. `Hakkında` is a plain `showAboutDialog` (`profile_screen.dart:237`).

**Why it matters.** Google's User Data policy requires the privacy policy to be linked both on the
store listing **and** within the app for apps that access personal or sensitive data. This app
collects email, name, purchase history and free-text AI questions.

**Fix:** add `url_launcher`, add a "Gizlilik Politikası" and "KVKK Aydınlatma Metni" row to the
Profile list pointing at the two live URLs. Blocked by 🔴-1 — do not link to a page that says it is
a draft.

**Ownership:** **Code**.

---

### 🟠-3 · Release builds get `INTERNET` only by accident, via a plugin manifest merge

`android/app/src/main/AndroidManifest.xml` declares only `POST_NOTIFICATIONS` and
`RECEIVE_BOOT_COMPLETED`. `INTERNET` is declared **only** in `android/app/src/debug/` and
`android/app/src/profile/`.

The release build works today because `google_sign_in_android` declares `INTERNET` in its own
manifest and the merger pulls it in (verified: `~/.pub-cache/hosted/pub.dev/google_sign_in_android-7.2.11/android/src/main/AndroidManifest.xml`).

**Why it matters.** The app is entirely API-driven — questions, lessons, AI, auth, entitlements.
If `google_sign_in` is ever removed or replaced, the release build silently loses network access
with no compile error. This is the same silent-degradation class as the `GOOGLE_SERVER_CLIENT_ID`
dart-define trap already documented in project memory.

**Fix:** add `<uses-permission android:name="android.permission.INTERNET"/>` to the **main**
manifest explicitly. One line, zero behaviour change today, removes a latent production outage.

**Ownership:** **Code**.

---

### 🟠-4 · `STORE_LISTING.md` is stale and contradicts the app on four points

If this file is used to fill the Console, four wrong values reach the listing:

| `STORE_LISTING.md` says                                       | Reality                                                | Evidence                                                                                   |
| ------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| "Content rating: Everyone / 3+ … **no user-to-user content**" | The app ships chat, discussions, groups and messaging  | `lib/features/community/chat_screen.dart`, `discussions_screen.dart`, `groups_screen.dart` |
| One product, `komple_ehliyet`, **399 TL**                     | Three packages; lifetime is **479,99 TL** at the store | `lib/domain/premium/products.dart`; PROJECT_STATUS §5 P1-4                                 |
| "**19** detaylı ders"                                         | **29 lessons**; 19 is the count that carry a _figure_  | live `content-snapshot`: `counts.lessons = 29`, 19 with `figureId`                         |
| App name "Ehliyet Akademi — **B Sınıfı** Sınav"               | A, B and D are all supported                           | `study_profile.dart:11-15`                                                                 |

**Fix:** treat `ASO_PROMPT_LIBRARY.html` §Listing copy as the source of truth and mark
`STORE_LISTING.md` superseded.

**Ownership:** **Docs + Console**.

---

### 🟠-5 · Content rating questionnaire must declare user-to-user communication

The community feature ships free-text chat (`chat_screen.dart`), discussion threads
(`discussion_thread_screen.dart`), groups (`group_detail_screen.dart`) and user profiles with
uploaded avatars (`avatar_editor_screen.dart` via `image_picker`).

Answering "no user interaction" — which `STORE_LISTING.md` currently implies — is a **false
declaration**, and content rating misdeclaration is an enforcement category in its own right.

**Mitigating facts that belong in the answer** (all real, all verifiable):

- Community is **opt-in with explicit consent**; nothing is shared until the user joins
  (`join_community_screen.dart:17,89-91`).
- Only display name, avatar and study statistics are shared — _"e-posta ve gerçek adın **asla**
  görünmez"_ (`join_community_screen.dart:91`).
- Reporting exists and is honest about its limits: _"Bildirimler insan incelemesine gider. Otomatik
  bir filtre yoktur."_ (`report_sheet.dart:33`).
- Blocking + an unblock management screen exist (`blocked_users_screen.dart`).

**Fix:** answer the questionnaire truthfully (see `PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §7) and
expect a rating above 3+.

**Ownership:** **Console (manual)**.

---

### 🟠-6 · No in-app way to report an AI reply

`lib/features/coach/coach_screen.dart` renders a grounding badge (`İçeriğe dayalı` / `AI`,
lines 429–438) and a standing disclaimer (line 300):

> _"AI yanıtları platform içeriğine dayanır; kesin ve güncel kural için MEB/MTSK esastır."_

That disclosure is good and should be kept. But a grep across `lib/features/coach/` and
`lib/domain/feedback/` finds **no report/flag affordance for a generated reply**. The community
surfaces have one (`report_sheet.dart`); the AI surface does not.

**Why it matters.** Play's Generative AI policy expects an in-app mechanism for users to report or
flag offensive AI-generated content, without leaving the app. The app already contains the exact
widget needed — `ReportSheet` — so this is a wiring job, not a new feature.

**Fix:** add a long-press / overflow "Bu yanıtı bildir" action on assistant messages that opens the
existing report sheet.

**Ownership:** **Code**.

---

### 🟠-7 · Price documentation and store price disagree

`PROJECT_STATUS.md` §5 P1-4 records that the docs and catalogue say **₺399** while the store
charges **₺479,99**. The screens are safe — `paywall_screen.dart` reads prices from the store
product only (`_storeProduct`, line 87) and never from the catalogue — but any listing text or
screenshot carrying "399 TL" would be a false price claim.

**Fix:** reconcile the documents; put **no price in any store asset** (the prompt library forbids
it), and let the Console's own price display do the work.

**Ownership:** **Docs + Console (manual)**.

---

## 4. 🟡 SHOULD FIX

| #    | Finding                                                                                                                                                                                                                                                                        | Evidence                                                         | Why it matters                                                                                                                                                                                                               |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🟡-1 | **Deleting an admin/CMS account fails.** Four FKs to `users` have no `ON DELETE` clause: `content_items.created_by` (:132), `content_versions.changed_by` (:146), `media_assets.created_by` (:335), `audit_logs.user_id` (:342). Default `NO ACTION` blocks the parent delete. | `packages/db/src/index.ts`                                       | Regular users are unaffected (`audit_logs` is written only from `apps/web/lib/server/cms.ts:29`), so this is not a reviewer-facing break. But "delete my account" failing for _any_ account class is a bad look under a DSR. |
| 🟡-2 | **`quick` / `random` / `adaptive` exam modes have no UI entry point.**                                                                                                                                                                                                         | `lib/domain/practice/exam_v2.dart:23-38`; PROJECT_STATUS §5 P2-9 | Dead capability. Must not appear in any screenshot or description — the prompt library omits them.                                                                                                                           |
| 🟡-3 | **App screenshots in `apps/assets/` are from 24 July and predate current UI.** e.g. `home-page-1.png` renders `Bugünküi plan`; the shipped string is `Bugünkü plan` (`home_screen.dart:218`).                                                                                  | file mtimes vs source                                            | Compositing a July capture into a 2026 store asset would ship a typo the app has already fixed. **Capture fresh screens from the `1.0.0+5` build.**                                                                          |
| 🟡-4 | **Two of nine videos are `status: "planned"` with `src: null`.**                                                                                                                                                                                                               | live `content-snapshot`                                          | The Learn UI must render them as unavailable, not as broken players. No asset or description may imply nine watchable videos. **MANUAL VERIFICATION REQUIRED** on device.                                                    |
| 🟡-5 | **Voice narration ships as a UI abstraction with no audio files.**                                                                                                                                                                                                             | PROJECT_STATUS §5 P2-6                                           | Correctly renders nothing today. Must not be mentioned in the listing.                                                                                                                                                       |
| 🟡-6 | **18 sign pictograms are still missing real artwork.**                                                                                                                                                                                                                         | PROJECT_STATUS §5 P2-7                                           | A screenshot of the sign gallery must be captured from a region that renders complete artwork.                                                                                                                               |
| 🟡-7 | **347 questions still flag on the longest-option metric.**                                                                                                                                                                                                                     | PROJECT_STATUS §5 P2-5                                           | Below the 25% random baseline, so not exploitable — but do not make a quality _claim_ in the listing that implies a completed pass. The prompt library phrases this as a process, not a guarantee.                           |
| 🟡-8 | **Web `LessonFigure` lags mobile** (12 SVGs vs 18 mobile figures; unknown IDs render nothing).                                                                                                                                                                                 | PROJECT_STATUS §6                                                | Web-only. Irrelevant to the Play listing; recorded so it is not re-discovered.                                                                                                                                               |
| 🟡-9 | **App icon pixel integrity unverified.** `PlayStore-APP-ICON.png` is 512×512 RGB, but no edge/corner scan has been run.                                                                                                                                                        | measured                                                         | FormAI shipped an icon with a 12-row pure-white band nobody saw. The post-generation pipeline (§11 of the prompt library) includes this check.                                                                               |

---

## 5. 🟢 NO ISSUE — verified, do not re-litigate

| Area                                 | Verified state                                                                                                                                                                      | Evidence                                                                                   |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **App access / login**               | No login required. _"The app never gates on auth — guests use everything; auth adds identity + sync."_ A reviewer can use the whole app without an account.                         | `lib/domain/auth/auth_controller.dart:29`                                                  |
| **Reviewer registration**            | Registration creates a session **immediately**; email verification is not required to log in (it only gates referral rewards). A reviewer will not be stuck at a verification wall. | `apps/web/app/api/auth/register/route.ts:71-72`                                            |
| **Permissions**                      | Only `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`. No location, camera, contacts, storage, microphone.                                                                           | `AndroidManifest.xml`                                                                      |
| **Notification permission timing**   | Requested from the notification-settings flow, not at cold start.                                                                                                                   | `lib/domain/coach/notification_prefs.dart:154`                                             |
| **Photo access**                     | Avatar picking uses the Android **system photo picker**, which requires no permission and exposes no gallery scan.                                                                  | `lib/data/community/avatar_service.dart:18-20`                                             |
| **Advertising ID**                   | Not read. No ads SDK, no ads. `anonId` is a random per-install string, explicitly _"reklam kimliği DEĞİLDİR"_.                                                                      | `lib/core/analytics/analytics.dart:16-20`                                                  |
| **Third-party analytics/crash SDKs** | None. Both go to first-party endpoints; the code documents this as a deliberate KVKK decision.                                                                                      | `lib/core/observability/error_reporter.dart:35-40`                                         |
| **Analytics payload hygiene**        | Event props carry only numbers, flags and short IDs — no email, name, free text or answers. Enforced by a test.                                                                     | `lib/core/analytics/analytics_event.dart` header; `test/analytics_test.dart`               |
| **AI data retention**                | `/api/ai/ask` responds `cache-control: no-store` and the request body is not written to a persistent table.                                                                         | `apps/web/app/api/ai/ask/route.ts:29`                                                      |
| **AI disclosure**                    | Standing disclaimer + per-message grounded/AI badge. Exceeds what most competitors ship.                                                                                            | `coach_screen.dart:300,429-438`                                                            |
| **AI is visibly synthetic**          | The coach avatar is a cartoon owl mascot, never a photorealistic human.                                                                                                             | `lib/design/living_mascot.dart`, `AppImages.owlWave`                                       |
| **Community privacy posture**        | Opt-in with explicit consent; email and real name never shared; block + report + unblock all implemented; reporting honestly states there is no automatic filter.                   | `join_community_screen.dart:17,89-91`; `report_sheet.dart:33`; `blocked_users_screen.dart` |
| **Restore purchase**                 | Implemented and documented as fixed, including the guest case where the server returns 401.                                                                                         | `paywall_screen.dart:311-332`                                                              |
| **Prices on screen**                 | Read from the Play product only, never from the catalogue — so a stale catalogue price cannot reach the user.                                                                       | `paywall_screen.dart:83-89`                                                                |
| **In-app review**                    | Uses `in_app_review`; the code explicitly refuses the banned "route happy users to the store, unhappy users to a form" pattern.                                                     | `lib/data/feedback/store_review_service.dart:12`                                           |
| **Duel honesty**                     | The opponent is named `AiOpponent` in code and capped at 85% accuracy deliberately. Nothing claims live multiplayer.                                                                | `lib/domain/duel/duel.dart:57-89`                                                          |
| **Exam archive honesty**             | The code comment refuses to call visual questions "animated": _"elimizde animasyon YOK, görsel var. Olmayan bir şeyi vaat etmiyoruz."_                                              | `exam_library.dart:33-35`                                                                  |

---

## 6. Persona walkthroughs

### 6.1 Persona A — Google Play reviewer

| Step                         | Expected reviewer experience                                                                         | Verdict                                                       |
| ---------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Install from Play            | Signed AAB, closed beta already live                                                                 | 🟢                                                            |
| Launch                       | Welcome → onboarding, no login wall                                                                  | 🟢                                                            |
| Onboarding                   | 4 steps: licence class → prior attempt → exam focus → time remaining                                 | 🟢 `onboarding_screen.dart:94-145`                            |
| Licence selection            | A / B / D offered and persisted                                                                      | 🟢                                                            |
| Login / guest                | **Can skip entirely.** Google button present **only if the build carried `GOOGLE_SERVER_CLIENT_ID`** | 🟠 build-config risk — see §7                                 |
| Home                         | Readiness ring, AI Koç card, today's plan, quick actions                                             | 🟢                                                            |
| Coach marks                  | Product tour wraps the shell including the bottom bar                                                | 🟢 `shell.dart:46-56`                                         |
| Lessons                      | 29 lessons, 19 with drawn figures                                                                    | 🟢                                                            |
| Questions / visual questions | 1.605 text + device-generated visual                                                                 | 🟢                                                            |
| Exam                         | 50 soru / 45 dk / 35 doğru                                                                           | 🟢                                                            |
| Exam archive                 | 6 categories; **3 free, rest paywalled**                                                             | 🟢 — but see §7 on paywall expectations                       |
| Duel                         | vs AI opponent, 5/day free                                                                           | 🟢                                                            |
| AI Koç                       | Grounded answers, sources, disclaimer                                                                | 🟠 no report affordance (🟠-6)                                |
| Progress / profile           | Readiness, streak, level, badges                                                                     | 🟢                                                            |
| Community                    | Opt-in gate; **requires an account** (`community_screen.dart:135`)                                   | 🟢 — reviewer can register freely                             |
| Premium / purchase           | Live Play pricing; three packages                                                                    | 🟠 entitlement will not sync cross-device until 🔴-3 is fixed |
| Restore                      | Implemented                                                                                          | 🟢                                                            |
| Logout                       | Implemented                                                                                          | 🟢                                                            |
| Account deletion             | In-app, works, cascades                                                                              | 🟢 in-app / 🔴 missing external URL (🔴-4)                    |
| Referral                     | Deep link advertised                                                                                 | 🟠 App Links unverified (🟠-1)                                |
| Privacy policy               | **Draft template with placeholders; no in-app link**                                                 | 🔴-1 / 🟠-2                                                   |

### 6.2 Persona B — first-time user

**What works well.** The app is usable immediately with no account, no permission prompt at
startup and no paywall in the first session. Onboarding is four short questions that visibly change
the plan. Offline-first means a user on a bad connection still gets content from cache
(`lib/data/content/content_repository.dart:12`).

**Where a first-time user hits friction:**

1. **Empty first-run dashboard.** The home screen shows `%0 Hazırlık · 0 soru · %0 doğruluk · Lv 1`.
   The copy handles it (_"Çözmeye başla — ilerlemen ve zayıf konuların burada belirir."_), so this
   is 🟢 — recorded because it is what a reviewer's screenshot will look like, and **no store asset
   may show a zero state**.
2. **Community tab is visible but requires an account** (`community_screen.dart:135`). A guest tapping
   the 5th tab hits a login requirement. Acceptable, but the tab gives no advance signal. 🟡
3. **Network failure paths — MANUAL VERIFICATION REQUIRED.** Airplane-mode behaviour on first launch
   (before any cache exists) was not verified on device in this audit. The code is offline-first with
   a local store, but the _first-ever_ launch has nothing cached.
4. **Overflow at 360 dp — MANUAL VERIFICATION REQUIRED.** The narrowest device in the fleet (Huawei
   ANE-LX1, 360 dp) is documented as physically unusable. The 6-tab bar was specifically rebuilt to
   survive 360 dp (`shell.dart:9-14`), but that fix is unverified on real 360 dp hardware.
5. **Dark/light theme.** Both palettes are fully defined (`tokens.dart:56-98`). Light-theme
   verification on device: **MANUAL VERIFICATION REQUIRED**.

---

## 7. Items that must be verified by hand before submission

No amount of repository reading can settle these. Each needs a person and a device.

| #   | Check                                                                   | How                                                                                              | Why it cannot be inferred                                                                                                                              |
| --- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| M1  | **The uploaded AAB carries `GOOGLE_SERVER_CLIENT_ID`**                  | `unzip -p <aab> base/lib/arm64-v8a/libapp.so \| grep -a apps.googleusercontent.com`              | Omitting the dart-define hides the Google button with **no build error**. A listing that shows Google Sign-In while the binary lacks it is a mismatch. |
| M2  | **One real purchase + one restore, on a device, with a licence tester** | Manual                                                                                           | No automated check covers Play Billing end to end. Until 🔴-3 is fixed, cross-device restore is expected to fail.                                      |
| M3  | **Account deletion end to end on a throwaway account**                  | Register → use → delete → confirm rows gone                                                      | Cascade is declared in SQL; that it _executes_ is unverified.                                                                                          |
| M4  | **Airplane-mode first launch**                                          | Fresh install, no network, launch                                                                | The first launch has no cache.                                                                                                                         |
| M5  | **360 dp layout**                                                       | Any 360 dp device                                                                                | Fleet's 360 dp device is unusable; the 6-tab bar fix is untested there.                                                                                |
| M6  | **Light theme sweep**                                                   | Toggle Koyu tema off, walk every screen                                                          | Tokens exist; rendering is unverified.                                                                                                                 |
| M7  | **The two `planned` videos render as unavailable**                      | Öğren → Videolar                                                                                 | Live data says `src: null`.                                                                                                                            |
| M8  | **Deep link opens the app after `assetlinks.json` is fixed**            | `adb shell am start -a android.intent.action.VIEW -d "https://www.ehliyetegitim.com/davet/TEST"` | Verification is an install-time OS behaviour.                                                                                                          |
| M9  | **A monitored support mailbox exists**                                  | —                                                                                                | DSR requests land on a statutory clock. The privacy policy currently has `[destek e-postası]`.                                                         |
| M10 | **Closed-testing requirements met** (tester count + continuous days)    | Play Console                                                                                     | Account-specific; not visible from the repo.                                                                                                           |

> `PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §20 carries this same M1–M10 list plus five Console-specific
> items: **M11** (is the community avatar uploaded to the server — it decides a Data Safety answer),
> **M12** (the sub-processor list the privacy policy must name), **M13** (a human moderation process
> behind community reports), **M14** (the alcohol answer in the IARC questionnaire) and **M15** (that
> no independent security review is being claimed). Work from that list when filling the Console;
> work from this one when testing the build.

---

## 8. Recommended fix order

1. **🔴-1** Rewrite and republish the privacy policy + KVKK pages (unblocks 🟠-2 and the Data Safety form).
2. **🔴-4** Publish the account-deletion URL.
3. **🔴-3** Implement real Play receipt verification, _then_ set `GOOGLE_PLAY_SA_JSON`.
4. **🟠-1** Publish the Play App Signing SHA-256 into `assetlinks.json`.
5. **🟠-3** Add `INTERNET` to the main manifest (one line).
6. **🟠-2** Add `url_launcher` + in-app legal links.
7. **🟠-6** Wire `ReportSheet` into AI Koç messages.
8. **🔴-2** Regenerate the store assets from `ASO_PROMPT_LIBRARY.html`; run the post-generation
   validation pipeline; **do not upload anything from `apps/ASO_IMAGE/` as it stands today**.
9. **🟠-4 / 🟠-5 / 🟠-7** Console text, content rating, price reconciliation.
10. Work the manual list — M1–M10 here, plus M11–M15 in `PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §20.

---

## 9. The submission rule

> Do not submit merely because the app builds.
> Do not submit merely because CI is green.
> Do not submit merely because the screenshots look premium.
>
> Submit only when the **app**, the **screenshots**, the **listing text**, the **privacy policy**,
> the **Data Safety form** and **real-device behaviour** all tell the same truth.

At the time of this audit they do not: the listing assets claim 10.000+ questions against a live
bank of 1.605, show an iPhone for an Android app, and depict eight fabricated users — while the
privacy policy tells the reader it is a draft for a company that does not yet exist.

---

_Companion documents: `ASO_PROMPT_LIBRARY.html` (asset specifications and the post-generation
validation pipeline) and `PLAY_CONSOLE_DECLARATIONS_GUIDE.md` (every Console answer with its
code-level justification)._
