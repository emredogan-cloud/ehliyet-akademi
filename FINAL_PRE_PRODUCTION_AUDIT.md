# Final Pre-Production Audit — Ehliyet Akademi 1.0.0

**Date:** 11 August 2026 · **Branch:** `release/preproduction-1.0.0` · **Head:** `0776b37` (this commit)
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

P0 blockers:      1 open  (founder-dependent: legal identity)
P1 blockers:      4 open  (all founder-dependent)
Founder blockers: 11 open · 3 CLOSED since 10 Aug (F-02 partial, F-04, F-15)
ASO assets:       FAIL   (real screenshots captured; overlay stage NOT done)
Automated tests:  PASS   (1.105 mobile · 734 web · 77 packages)
CI:               PASS   (9/9 green on the head commit)
Device E2E:       PARTIAL (substantially extended; 4 rows still open)
Final AAB:        NOT BUILT — deliberately, see §6
```

**The project is not ready to submit**, and the reason has narrowed. Every code-side blocker I can
close is closed and verified on hardware. What remains is (a) founder-owned legal/Console work and
(b) the ASO overlay stage.

**Eight new defects were found today**, six of which were only findable by running the app or
querying the live API. Three of those would have shipped as false statements to users or to Google.

---

## 1. What changed since the 10 August audit

| Area                  | 10 Aug                                  | 11 Aug                                                                     |
| --------------------- | --------------------------------------- | -------------------------------------------------------------------------- |
| Legal pages live      | BLOCKED — branch not deployed           | **PASS** — `/gizlilik`, `/kvkk`, `/hesap-silme` all 200, zero placeholders |
| Data retention        | undefined; analytics kept forever       | **PASS** — policy is data, published, and enforced daily                   |
| `GOOGLE_PLAY_SA_JSON` | assumed outstanding                     | **FOUNDER COMPLETE — verified against Google's API**                       |
| RevenueCat            | ambiguous across ~6 documents           | **Definitively excluded**, with evidence                                   |
| Android backup        | undeclared → guest data left the device | **PASS** — off, verified in the APK and on the device                      |
| AI report affordance  | NOT VERIFIED on device                  | **PASS** — badge, report link and report sheet all exercised               |
| `planned` videos      | NOT VERIFIED                            | **PASS** — render as YAKINDA + locked                                      |
| Offline               | NOT VERIFIED                            | **PASS** — full study session with WiFi and data off                       |
| Home progress card    | not examined                            | **was broken**, fixed, re-verified                                         |
| Listing numbers       | "verified" against the API              | **one was false in practice** — see N11                                    |

---

## 2. New findings (11 August)

| ID  | Sev | Finding                                                                                                  | Status | Evidence                                                        |
| --- | --- | -------------------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------- |
| N5  | P1  | `/hesap-silme` claimed purchase records are retained; the schema **cascades** them away                  | PASS   | `packages/db/src/schema.ts`; page + tests corrected             |
| N6  | P1  | Analytics/error rows survived deletion **with no upper bound** — indefinite retention                    | PASS   | `lib/retention.ts` + `/api/cron/retention` + 24 tests           |
| N7  | P1  | Support/sender fallbacks pointed at `ehliyetakademi.app` — **no DNS record**                             | PASS   | `getent hosts` empty; repointed to `ehliyetegitim.com`          |
| N8  | P1  | `allowBackup` undeclared → **true** → guest progress uploaded to Drive, contradicting the privacy policy | PASS   | `aapt2 dump` shows `allowBackup=false`; device `pkgFlags` clean |
| N9  | P1  | Paywall promised **"7 gün para iade garantisi"** — no refund code, Play allows 48 h, page says otherwise | PASS   | removed + `play_compliance_test.dart` guard                     |
| N10 | P1  | **Home froze at %0 after 90 solved questions**; progress screen simultaneously correct                   | PASS   | fixed; device re-test showed 95 soru with no restart            |
| N11 | P1  | **"29 ders"** — a number no user can ever see (B sees 19, A/D see 24)                                    | PASS   | copy corrected; lesson recorded as §16b                         |
| N12 | P2  | "112 araç parçası" is an unreproducible total (app shows 70 + 39)                                        | PASS   | reworded                                                        |

---

## 3. Original findings — carried forward

All 🔴 and 🟠 rows from `PLAY_STORE_REVIEW_AUDIT.md` retain the status recorded on 10 August, with
these upgrades:

| ID   | Was                       | Now      | Why                                                                              |
| ---- | ------------------------- | -------- | -------------------------------------------------------------------------------- |
| 🔴-1 | PASS (code) · BLOCKED     | **PASS** | The branch is deployed; the live pages carry no placeholder and no draft banner. |
| 🔴-4 | PASS (code) · BLOCKED     | **PASS** | `/hesap-silme` returns 200 live.                                                 |
| 🟠-6 | PASS (untested on device) | **PASS** | Report affordance and sheet exercised on hardware.                               |
| 🟡-4 | NOT VERIFIED              | **PASS** | Both `planned` videos render as YAKINDA with a lock+clock.                       |
| 🟠-1 | BLOCKED (founder)         | BLOCKED  | `assetlinks.json` still returns `[]`. Unchanged — F-07.                          |

---

## 4. Connected-device E2E

**Device:** Redmi Note 8 (2021) · `M1908C3JGG` · Android 11 (SDK 30) · 1080×2340 @440dpi (393×851 dp)
**Build:** clean install of a release APK from this branch (`installer=null`), built with the
`GOOGLE_SERVER_CLIENT_ID` dart-define.

> The preferred device (Redmi Note 11R) was not attached. This is the fallback "last connected
> Redmi", as authorised. **No 360 dp device is available**, so the small-width sweep stays open.

### Verified today

| Flow                         | Result   | Evidence                                                                     |
| ---------------------------- | -------- | ---------------------------------------------------------------------------- |
| Clean install                | **PASS** | `adb uninstall` then install; `versionCode=5`                                |
| `allowBackup` actually off   | **PASS** | `pkgFlags` no longer lists `ALLOW_BACKUP`                                    |
| First launch / onboarding    | **PASS** | 4 steps; B/A/D offered; summary shows daily goal 20                          |
| Guest flow                   | **PASS** | Everything below done **without an account**                                 |
| Coach-mark tour              | **PASS** | 9 steps, advances and skips                                                  |
| Bottom navigation            | **PASS** | Ana Sayfa · Öğren · Pratik · AI Koç · Topluluk · Profil                      |
| Question bank / study        | **PASS** | 2 × 20-question sessions, real answers, real explanations                    |
| **Full mock exam**           | **PASS** | 50 questions, timer, **passed %72 (36/50, threshold 35)**                    |
| Exam blueprint on screen     | **PASS** | `50 soru · 45 dk · MEB dağılımı (23/12/9/6)`                                 |
| Visual (on-device) questions | **PASS** | Generated from the sign/part catalogues, as documented                       |
| Progress screen              | **PASS** | Level 4 · 718 XP · radar · heatmap, all matching the session history         |
| **Home refresh after fix**   | **PASS** | 95 soru appeared **without restarting** (was frozen at 0 before the fix)     |
| AI Koç — real answer         | **PASS** | Live model answer, grounded badge, source line                               |
| **AI reply reporting**       | **PASS** | "Bu yanıtı bildir" opens a 4-reason sheet stating reports go to human review |
| Lessons / signs / parts      | **PASS** | Öğren shows 19 · 121 · 70 · 60 · 39 · 9 — the source of finding N11          |
| Planned videos               | **PASS** | YAKINDA badge + lock/clock, not playable                                     |
| **Offline**                  | **PASS** | WiFi and data disabled → app launches, home renders, study session runs      |
| Paywall / product display    | **PASS** | Upsell renders (and produced finding N9)                                     |

### Still NOT VERIFIED

| Flow                                   | Why                                                                            |
| -------------------------------------- | ------------------------------------------------------------------------------ |
| Purchase / restore / cross-device      | **Founder-only.** Held deliberately until the newest AAB is on closed testing. |
| Account deletion, end to end on device | Needs a throwaway account; server path is integration-tested                   |
| Community join / chat / report / block | Needs an account; not reached                                                  |
| Light theme sweep                      | Not reached                                                                    |
| 360 dp layout                          | No 360 dp device available                                                     |
| Referral deep link                     | Requires F-07 (`assetlinks.json` is still `[]`)                                |

---

## 5. Automated verification

| Suite                   | Result                                          |
| ----------------------- | ----------------------------------------------- |
| Mobile (`flutter test`) | **1.105 passed** (was 1.096; +9)                |
| `flutter analyze`       | **No issues found**                             |
| Web (`vitest`)          | **734 passed**, 89 files (was 708; +26)         |
| Packages                | **77 passed**                                   |
| `pnpm typecheck`        | clean                                           |
| `pnpm lint`             | clean (1 pre-existing warning in `packages/db`) |
| `pnpm format`           | clean repo-wide                                 |
| `pnpm build`            | success                                         |

**New tests today: 35** — 18 retention policy, 6 retention purge (both sides of the threshold),
6 progress-refresh, 2 store-claim guards, 1 backup guard, 2 legal-page guards.

### CI

**9/9 green** on PR #22 (verified per-commit): Lint·Typecheck·Test·Build · Analyze·Test·Build (Android) ·
E2E (Playwright) · CodeQL · Analyze (JS/TS) · Conventional Commits · gitleaks · Vercel ×2.

> CI only runs on `push` for `main` and on `pull_request`. PR #22 exists **as the CI gate** for this
> branch; without it no workflow runs at all. It is open, not merged.

---

## 6. Why the version was NOT bumped and the AAB was NOT built

The gate rule in the roadmap is explicit: **L and M cannot be entered while any P0 or P1 row is
not PASS.** They are not.

Open and founder-owned:

- **F-01** — four of five legal identity variables are still unset, so `/gizlilik` and `/kvkk`
  publish an honest "not yet published" notice instead of a data controller. This is a **P0**.
- **F-07** — `assetlinks.json` still returns `[]`.
- **F-08 / F-09 / F-10 / F-11 / F-12** — every Play Console declaration and the listing itself.
- **F-05** — the real purchase, which you asked me to hold until the newest AAB reaches closed
  testing.

Bumping to `1.0.0+6` and producing an AAB now would create an artefact that _looks_ like the
release candidate while five blocking rows are open. `1.0.0+5` stands.

**I can build it the moment the gate closes** — the production keystore and `key.properties` are
present on this machine and Gradle is fail-closed, so nothing technical is in the way.

### ⚠️ The stale AAB is still on disk

```
apps/mobile/build/app/outputs/bundle/release/app-release.aab
  built 1 August 2026 · 65,287,095 bytes
```

It predates every fix in this branch. **Delete it before any release work:**

```bash
rm apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

---

## 7. ASO — FAIL, and precisely why

| Stage                                      | State                                                                      |
| ------------------------------------------ | -------------------------------------------------------------------------- |
| Raw plates (`NEW/`)                        | ✅ 8 plates + icon + feature graphic, verified free of every banned defect |
| Normalisation (`NORMALIZED/`)              | ✅ 1080×1920 sRGB, deterministic                                           |
| **Real device screenshots**                | ✅ **12 captured today** — `apps/ASO_IMAGE/SCREENS/`, with `PROVENANCE.md` |
| **Overlay** (screens + Turkish typography) | ❌ **NOT DONE**                                                            |
| Validation / `PLAY_READY/`                 | ❌ not produced — **deliberately**                                         |

The hard, non-fabricable half is done: the screenshots are real, from a real device, with a real
95-question study history (%67 accuracy, level 4) built by actually answering questions. There is
no zero state and no invented UI anywhere in them.

What is missing is the mechanical half: perspective-mapping each screenshot into the plate's phone
screen and typesetting the Turkish copy into the measured card boxes — roughly 9 text blocks × 8
plates, then OCR verification of every string.

**I did not produce `PLAY_READY/`.** A folder with that name is an instruction to upload, and
producing one before the overlay stage would be exactly the "fake ready artefact" this project has
already been bitten by.

---

## 8. What must happen next, in order

1. **Founder works `FOUNDER_RELEASE_CHECKLIST.md`** — 11 open tasks. F-01 is the P0.
2. **Merge PR #22** so the retention job and the corrected pages go live.
3. **Finish the ASO overlay stage**, then validate, then create `PLAY_READY/`.
4. **Close the remaining device rows** — account deletion, community, light theme, 360 dp.
5. **Then** bump to `1.0.0+6`, build the AAB, and re-issue this audit.

**Until step 5, the answer to "is it ready to submit?" is no — and it is BLOCKED, not FAIL.**

---

## 9. Reproducing

```bash
git checkout release/preproduction-1.0.0
pnpm install --frozen-lockfile
pnpm typecheck && pnpm lint && pnpm test && pnpm build
cd apps/mobile && flutter analyze && flutter test
```

Live checks:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://www.ehliyetegitim.com/hesap-silme   # 200
curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "Taslak belge"              # 0
curl -s https://www.ehliyetegitim.com/gizlilik | grep -c "henüz yayımlanmadı"        # 1 → 0 after F-01
curl -s https://www.ehliyetegitim.com/.well-known/assetlinks.json                    # [] → populated after F-07
curl -s -X POST https://www.ehliyetegitim.com/api/iap/revenuecat -d '{}'             # 503 (dormant, fail-closed)
```
