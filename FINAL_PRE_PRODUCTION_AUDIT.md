# Final Pre-Production Audit — Ehliyet Akademi 1.0.0

**Date:** 10 August 2026 · **Branch:** `release/preproduction-1.0.0` · **Head:** see §7
**App version:** `1.0.0+5` (**not bumped** — see §6) · **Package:** `com.ehliyetegitim.ehliyet_akademi`

> Statuses are limited to **PASS · FAIL · BLOCKED · NOT APPLICABLE · NOT VERIFIED**.
> "Probably fixed" is not a status. Where I could not obtain evidence, the row says **NOT VERIFIED**
> and names what is missing.

---

## 0. VERDICT

```
PRODUCTION SUBMISSION READINESS
--------------------------------
Overall: BLOCKED

P0 blockers:      2 open  (both founder-dependent)
P1 blockers:      3 open  (all founder-dependent)
P2 remaining:     4
Founder blockers: 15
ASO assets:       FAIL  (not upload-ready — text and screenshots not composited)
Automated tests:  PASS  (1.096 mobile · 708 web · 77 packages)
CI:               PASS  (9/9 checks green)
Device E2E:       PARTIAL
Final AAB:        NOT BUILT
```

**The project is not ready to submit.** Every code-side blocker I could close is closed and
verified. What remains is (a) founder-owned legal/credential/Console work and (b) the ASO
compositing stage, which depends on a populated device state I did not finish generating.

---

## 1. Original 🔴 findings — `PLAY_STORE_REVIEW_AUDIT.md`

| ID   | Original issue                                                                                                                                                | Status                                                | Evidence                                                                                                                                                                                                                                                                                                                                                                    |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🔴-1 | Privacy/KVKK pages are draft templates with `[Şirket Ünvanı]` placeholders, describe a _web app_, omit Android data flows, contradict Data Safety on location | **PASS (code) · BLOCKED (live)**                      | Both pages rewritten against the real architecture; identity moved to env (`apps/web/lib/legal-entity.ts`); 40 regression tests forbid every placeholder string. Verified on a **local production server**: all three pages HTTP 200, zero forbidden strings. **Live site still serves the old page** — the branch is not merged/deployed, and F-01 env values are not set. |
| 🔴-2 | All five existing store assets unusable (iPhone frames, 4 fabricated nav bars, "10.000+ soru", 8 fabricated users)                                            | **PASS (superseded) · FAIL (replacement incomplete)** | Old assets are not used. New plates verified free of every one of those defects (`ASO_FINAL_VALIDATION_REPORT.md` §1). But the replacements are **not upload-ready**.                                                                                                                                                                                                       |
| 🔴-3 | `verifyPlayPurchase` returns `valid:true` for any token ≥ 4 chars                                                                                             | **PASS**                                              | Replaced with real Android Publisher v3 verification (`apps/web/lib/server/play-billing.ts`). 28 unit tests: cancelled/pending/expired states, short token rejected before network, wrong package, 401/403/404/500, network error, token cache. Ships **fail-closed**: unconfigured → 503 in production.                                                                    |
| 🔴-4 | No account-deletion URL; `/hesap-silme` 404                                                                                                                   | **PASS (code) · BLOCKED (live)**                      | Page built and rendering locally (HTTP 200, all four required sections). Live after merge + deploy.                                                                                                                                                                                                                                                                         |

### New 🔴 found during this work

| ID     | Issue                                                                                                                                                                                                                                                    | Status   | Evidence                                                                                                                                                                                                                                                                  |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **N1** | **Subscriptions returned 404** — mobile sells 3 products, server catalogue had 1. Users paid Google and received no entitlement.                                                                                                                         | **PASS** | All three added to `MOBILE_PRODUCTS`; integration test asserts each of the three validates and grants.                                                                                                                                                                    |
| **N4** | **Account deletion was broken for any user with a community avatar.** `media_assets.created_by` was `NOT NULL REFERENCES users(id)` with no `ON DELETE`; the avatar upload writes that row for _regular_ users. `DELETE FROM users` failed with `23503`. | **PASS** | Reproduced with a failing test (`constraint: media_assets_created_by_fkey`), then fixed: four attribution columns nullable + `ON DELETE SET NULL`; deletion route now removes the user's own avatar explicitly. Both tests green, plus the 9 pre-existing deletion tests. |

> **N4 was mis-classified 🟡 in the original audit** on the assumption that `media_assets` was
> admin-only. It is not. Correcting my own finding is recorded here rather than quietly amended.

---

## 2. Original 🟠 findings

| ID   | Issue                                                              | Status                | Evidence                                                                                                                                                                                                                              |
| ---- | ------------------------------------------------------------------ | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🟠-1 | `assetlinks.json` returns `[]` → App Links verification fails      | **BLOCKED (founder)** | **Re-inspection corrected the original finding:** the route is already correct — it reads `ANDROID_SHA256_FINGERPRINTS`, validates the format and deliberately returns `[]` when unset. No code change needed. Founder task **F-07**. |
| 🟠-2 | No in-app privacy/KVKK link; `url_launcher` not a dependency       | **PASS**              | `url_launcher` promoted to a direct dependency; two rows added to Profil. **Verified on device**: both rows render, and tapping "Gizlilik Politikası" opens Chrome at `ehliyetegitim.com/gizlilik`.                                   |
| 🟠-3 | `INTERNET` reaches release builds only via a plugin manifest merge | **PASS**              | Declared explicitly in the main manifest. **Verified in the built APK**: `aapt2 dump permissions` lists it.                                                                                                                           |
| 🟠-4 | `STORE_LISTING.md` stale on 4 points                               | **PASS**              | Marked superseded with a table of each contradiction and its evidence.                                                                                                                                                                |
| 🟠-5 | Content rating must declare user-to-user communication             | **BLOCKED (founder)** | Answers prepared (`PLAY_CONSOLE_DECLARATIONS_GUIDE.md` §3); Console entry is F-09.                                                                                                                                                    |
| 🟠-6 | No in-app way to report an AI reply (Play GenAI policy)            | **PASS**              | "Bu yanıtı bildir" added to every assistant message, routed through the existing anonymous report queue with `source: 'ai-reply'`. 5 unit tests + a source-level guard test. **Not exercised on device** — see §4.                    |
| 🟠-7 | Docs say ₺399, store charges ₺479,99                               | **PASS**              | Corrected in the catalogue (it was in the DB write path, not just docs — finding N2) and in the superseded-listing banner.                                                                                                            |

---

## 3. Original 🟡 findings

| ID   | Issue                                              | Status                                    | Evidence                                                                                                                                                                                              |
| ---- | -------------------------------------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🟡-1 | 4 FKs to `users` lack `ON DELETE`                  | **PASS**                                  | Fixed — and re-classified P0 as N4 above.                                                                                                                                                             |
| 🟡-2 | `quick`/`random`/`adaptive` exam modes unreachable | **PASS (as designed)**                    | Left unexposed; no listing text or asset claims them.                                                                                                                                                 |
| 🟡-3 | `apps/assets/` screenshots stale (`Bugünküi plan`) | **PASS**                                  | **Verified on device**: the shipped string is `Bugünkü plan`. The typo exists only in the July capture, which is not used.                                                                            |
| 🟡-4 | Two videos are `status:"planned"`, `src:null`      | **NOT VERIFIED**                          | Live API confirms 7 available / 2 planned. Device rendering of the unavailable state was **not reached**.                                                                                             |
| 🟡-5 | Voice narration ships with no audio                | **PASS**                                  | Not mentioned in any listing text or asset.                                                                                                                                                           |
| 🟡-6 | 18 sign pictograms missing artwork                 | **NOT VERIFIED**                          | Affects only the gallery screenshot, which has not been captured yet.                                                                                                                                 |
| 🟡-7 | 347 questions flag the longest-option metric       | **PASS (scoped out)**                     | No listing copy claims a completed quality pass.                                                                                                                                                      |
| 🟡-8 | Web `LessonFigure` lags mobile                     | **NOT APPLICABLE**                        | Web-only; no Play impact.                                                                                                                                                                             |
| 🟡-9 | Icon pixel integrity unverified                    | **PASS (pixels) · NOT VERIFIED (design)** | Automated: no pure-white/black edge band, no stray alpha, 512×512 RGB ≤ 1 MB. Design checklist (48 px legibility, pre-rounded corners, text) **not audited** — `ASO_FINAL_VALIDATION_REPORT.md` F-A4. |

---

## 4. Connected-device E2E — PARTIAL

**Device:** Redmi Note 8 (2021) · `M1908C3JGG` · Android 11 (SDK 30) · 1080×2340 @440dpi (393×851 dp)
**Build:** clean install of a release APK from this branch, built with the `GOOGLE_SERVER_CLIENT_ID`
dart-define (verified present inside `libapp.so`).

### Verified

| Flow                          | Result              | Evidence                                                                                                                                                                                        |
| ----------------------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Clean install                 | **PASS**            | Prior build uninstalled; `versionCode=5` installed                                                                                                                                              |
| First launch / welcome        | **PASS**            | Renders; states `50 soru · 45 dakika · 35 doğru` — matches the live blueprint                                                                                                                   |
| Onboarding (4 steps)          | **PASS**            | Licence class **B / A / D** offered; summary shows daily goal 20 (`kDailyQuestionTarget`)                                                                                                       |
| No login wall                 | **PASS**            | Whole flow completed as a guest                                                                                                                                                                 |
| Coach-mark tour               | **PASS**            | 9 steps, skippable                                                                                                                                                                              |
| Bottom navigation             | **PASS**            | Exactly **Ana Sayfa · Öğren · Pratik · AI Koç · Topluluk · Profil** — confirms the old assets' four nav bars were fabricated                                                                    |
| Home screen                   | **PASS**            | Renders; `Bugünkü plan` spelled correctly                                                                                                                                                       |
| Pratik screen                 | **PASS**            | `50 soru · 45 dk · MEB dağılımı (23/12/9/6)`; "e-Sınav B, A ve D için aynıdır"                                                                                                                  |
| **Profil legal links (R-09)** | **PASS**            | Both rows render; privacy link opens Chrome at the correct URL                                                                                                                                  |
| Live privacy page content     | **FAIL (expected)** | Still the old draft — branch not deployed. Confirms the fix is _not yet live_.                                                                                                                  |
| Release APK permissions       | **PASS**            | `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `BILLING`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `USE_BIOMETRIC`, `USE_FINGERPRINT`. No location/camera/contacts/storage. |

### NOT VERIFIED

| Flow                                   | Why                                                                                                                  |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| AI Koç report button (R-10)            | Ran out of reliable interaction budget; covered by 5 unit tests + a source guard, but **not seen working on device** |
| Purchase / restore / cross-device      | Requires F-04 + F-05 (founder)                                                                                       |
| Account deletion end to end            | Not reached on device (server-side path is integration-tested)                                                       |
| Community join / chat / report / block | Not reached                                                                                                          |
| Offline / airplane mode                | Not reached                                                                                                          |
| Light theme sweep                      | Not reached                                                                                                          |
| 360 dp layout                          | Device is 393 dp; no 360 dp device available                                                                         |
| Referral deep link                     | Requires F-07                                                                                                        |
| The two `planned` videos               | Not reached                                                                                                          |

> **`USE_BIOMETRIC` / `USE_FINGERPRINT`** enter via a plugin's manifest. They are _normal_
> permissions (no runtime prompt, no Data Safety implication), but they were not in the source
> manifest and are recorded here so the Console answers are not surprised by them.

---

## 5. Automated verification

| Suite                                                    | Result                                                     |
| -------------------------------------------------------- | ---------------------------------------------------------- |
| Mobile (`flutter test`)                                  | **1.096 passed**                                           |
| `flutter analyze`                                        | **No issues found**                                        |
| Web (`vitest`)                                           | **708 passed** (87 files)                                  |
| Packages (content-schema, question-bank, srs-engine, db) | **77 passed**                                              |
| `pnpm typecheck`                                         | **clean**                                                  |
| `pnpm lint`                                              | clean (1 pre-existing warning in `packages/db`, unrelated) |
| `pnpm format`                                            | clean repo-wide                                            |
| `pnpm build`                                             | success                                                    |
| ASO validator (`--stage final`)                          | **94/94**                                                  |
| Pipeline determinism                                     | byte-identical across two runs                             |

**New tests added this session: 45** — 28 Play-billing unit, 5 IAP integration, 2 account-deletion,
5 AI-report, 5 Play-compliance guards (plus 40 legal-page/identity tests).

### CI

All **9 checks green** on the final commit: Lint·Typecheck·Test·Build · Analyze·Test·Build (Android)
· E2E (Playwright) · CodeQL · Analyze (JS/TS) · Conventional Commits · gitleaks · Vercel ×2.

One CodeQL alert (`js/insufficient-password-hash`, #6) was **dismissed as a false positive** with a
recorded justification: `createSign('RSA-SHA256')` performs a digital signature, not password
hashing; RS256 is mandatory in Google's OAuth2 service-account flow (RFC 7523). The reasoning is
also written into the source so the next reader does not re-ask.

---

## 6. Why the version was NOT bumped and the AAB was NOT built

The instruction was explicit: bump only after **all** gates pass. They do not.

- 2 P0 and 3 P1 rows are BLOCKED on founder actions (F-01…F-15)
- ASO assets are **FAIL** — not upload-ready
- Device E2E is **PARTIAL**

Bumping the version now would make the release look finished while five blocking rows are open.
`1.0.0+5` stands.

**When the gates close**, the sequence is: bump to `1.0.0+6` → re-run all suites → commit → CI green
→ build the AAB with the `GOOGLE_SERVER_CLIENT_ID` dart-define → verify package/version/signing/
client-ID inside the artefact → write `FINAL_RELEASE_AAB_REPORT.md`.

A release APK **was** built and verified this session (client ID embedded, `INTERNET` present), but
it is a **verification artefact, not a submission artefact** — it is unsigned by the production
keystore (F-15) and carries the un-bumped version.

### ⚠️ A STALE AAB IS SITTING IN THE BUILD DIRECTORY — DO NOT UPLOAD IT

```
apps/mobile/build/app/outputs/bundle/release/app-release.aab
  built    1 August 2026        (nine days before this work)
  size     65,287,095 bytes
  sha256   18a2953b5c5824918cb0a3ee3a2680cc…
```

It is **gitignored**, so it is not in the repository — but it is on disk and it is the only `.aab`
present, which makes it exactly the file someone would reach for.

**It predates every fix in this branch.** Uploading it would ship:

- the **purchase-verification stub** (any 4-character token grants lifetime premium once
  `GOOGLE_PLAY_SA_JSON` is set)
- **subscriptions that 404** server-side
- **broken account deletion** for any user with a community avatar
- **no in-app privacy/KVKK links** and **no AI-reply reporting**
- `INTERNET` only via the plugin manifest merge — the one occurrence inside it comes from
  `google_sign_in_android`, not from an explicit declaration

**Delete it before any release work**, so the production AAB cannot be confused with it:

```bash
rm apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

The real production AAB does not exist yet and must be built from the final verified commit after
the gates in §8 close.

---

## 7. Reproducing

```bash
git checkout release/preproduction-1.0.0
pnpm install --frozen-lockfile
pnpm typecheck && pnpm lint && pnpm test && pnpm build
cd apps/mobile && flutter analyze && flutter test
python3 scripts/aso/build_play_assets.py
python3 scripts/aso/validate_play_assets.py --dir apps/ASO_IMAGE/NORMALIZED --stage final
```

Live checks (should change once the branch is deployed):

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://www.ehliyetegitim.com/hesap-silme      # 404 → 200
curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "Taslak belge"                 # 1 → 0
curl -s https://www.ehliyetegitim.com/.well-known/assetlinks.json                       # [] → populated
```

---

## 8. What must happen next, in order

1. **Merge and deploy this branch** — without it, none of the web fixes are live and three of the
   four original 🔴 rows stay BLOCKED.
2. **Founder works `FOUNDER_RELEASE_CHECKLIST.md`** — 15 tasks, F-01 through F-15.
3. **Finish ASO compositing** — populate a device study state, capture screens, typeset Turkish,
   OCR-verify, then create `PLAY_READY/`.
4. **Complete device E2E** — the nine NOT VERIFIED flows in §4.
5. **Then** bump the version, build the AAB, and re-issue this audit with the BLOCKED rows resolved.

**Until step 5, the answer to "is it ready to submit?" is no.**
