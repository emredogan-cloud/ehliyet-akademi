# Phase 7 Implementation Report — Premium / IAP

**Ehliyet Akademi Mobile · Roadmap: `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`**
_Prepared: 2026-07-24 · Backend deployed + verified (incl. a security fix) · paywall + gating device-validated._

## Verdict: 🟢 GO (with a documented, honest store limitation)

The app now has a complete **premium monetization surface**: a paywall with the 5 one-time packs, an
entitlement model derived from the server (never a synced key), premium-lesson locking, free-tier AI/exam
quotas, and a Google-Play `in_app_purchase` flow validated by a new backend endpoint. Everything except
the **actual Play Store purchase round-trip** is built, tested, and device-validated — the purchase itself
requires a Play Console app + a signed AAB installed from Play (not possible on this Linux dev host), which
is documented honestly (like iOS-on-Linux and FCM).

---

## Completed work

### Backend (Next.js API — additive)

- **`POST /api/iap/validate`** (`app/api/iap/validate/route.ts`): Bearer-auth (`getSessionUser`), body
  `{ productId, purchaseToken, packageName }`. Verifies the product against the catalog (price integrity),
  **idempotently grants** into the `purchases` table (`provider: 'google_play'`, `externalRef=token`,
  unique(user,product)), returns `{ ok, owned[] }` — the same shape as `GET /api/purchases` (restore).
- **Security (fail-closed):** real Play token verification needs a Google service account (absent here).
  Grants without verification are allowed **only in test/dev** (`NODE_ENV!=production` or
  `IAP_DEV_ACCEPT=1`); **production returns 503** until verification is configured — mirroring the
  mock-payment `paymentConfigured` guard. (This closed a hole where any Bearer user could self-grant
  premium; verified live: production `/api/iap/validate` → **503**.)
- Integration test (`iap-validate.integration.test.ts`) — **6 passed**: grant + owned, idempotency,
  komple-b, unknown product → 404, missing token → 400, no session → 401, **production fail-closed → 503**.

### Mobile (Flutter)

- **Premium domain** (`domain/premium/products.dart`): Dart port of `products.ts` + `entitlements.ts` — 5
  one-time packs (premium-teori 249, premium-direksiyon 199, simulator-paketi 149, premium-soru-bankasi
  129, komple-b 449) + 5 capabilities, `capabilitiesOf`/`hasCapability`, `canAccessLesson`,
  `productForLesson`/`productForCapability`, and the store↔server id bridge.
- **Entitlements repo** (`data/premium/entitlements_repository.dart`): owned = distinct product ids from
  `GET /api/purchases` (never a synced key — the web P0), cached `ea:entitlements:v1` (SET, server wins);
  `validatePurchase` → `/api/iap/validate`.
- **Free-tier quotas** (`data/premium/quota_repository.dart`): 5 AI/day + 1 exam/day
  (`ea:aiQuota:v1`/`ea:examQuota:v1`, `{day,count}`), bypassed by `ai-sinirsiz`/`sinirsiz-deneme`.
- **IAP service** (`data/premium/iap_service.dart`): `in_app_purchase` — query products, `buyNonConsumable`,
  purchase-stream → validate → apply entitlements; restore.
- **UI**: a **paywall** (`features/premium/paywall_screen.dart` — catalog cards, buy/restore, honest
  "store unavailable" notice off-Play); **premium lessons locked** (list lock icon → paywall; detail shows
  a "Bu ileri ders premium" gate); **AI + exam quota gates** wired into the coach send + practice hub;
  Profil "Premium" row → paywall.

## Architecture (decisions, packages, structure)

- **Ownership derived from the server, never trusted from a synced key** (the web P0 — a synced
  entitlement could leak between users on a shared device). Mobile re-derives from `GET /api/purchases`.
- **Catalog price integrity + idempotency on the server**, exactly like the LemonSqueezy webhook; Google
  Play is a fourth provider path (`provider: 'google_play'`).
- **Fail-closed IAP validation** — no free grants in production without real verification.
- Package added: `in_app_purchase`.

## Tests executed

- `flutter analyze` — **0 issues**. `flutter test` — **76 passed** (products/capabilities, quotas,
  premium-lesson gating UI, plus all prior phases).
- Backend integration — **6 passed** (IAP validate incl. fail-closed). Web gates: prettier ✓, typecheck ✓
  (lesson: `vitest` doesn't run `tsc` — always run the typecheck gate), lint 0 errors (1 pre-existing
  warn), verify ✓.

## Build

- **Android debug APK builds** (`in_app_purchase` native compiles). **iOS N/A (no macOS)**. **Mobile CI**
  green.

## Device validation

- **Device:** Redmi M1908C3JGG, Android 11 (API 30), `AYXSUKIVJVPZ7HPZ` (USB), against **production**.
- **Deploy sanity (curl):** `/api/iap/validate` in dev-mode granted + `GET /api/purchases` returned it
  (restore works); after the security fix, production `/api/iap/validate` → **503 (fail-closed)**.
- **Exercised on-device:** Profil → **Premium** opens the paywall — all 5 packs with prices/features,
  Komple B highlighted "EN AVANTAJLI" (449 ₺), the honest **"Mağaza kullanılamıyor"** notice with disabled
  "Satın al" (debug build, not from Play), and "Geri yükle". Entitlement/lesson-lock/quota logic is
  unit + widget tested.
- **Evidence:** paywall screenshot.

## Known issues / limitations

- **Real Play Billing purchase cannot be tested on this host** (documented blocker): needs a Play Console
  app with the 5 managed products, a **signed AAB installed from a Play track**, and a Google **service
  account** for server-side token verification. The purchase round-trip + real receipt verification are
  gated on those; the flow, contract, gating, and quotas are built + tested. To go live: create the Play
  products (ids `premium_teori`/…/`komple_b`), add `GOOGLE_PLAY_SA_JSON` to the backend, ship a signed
  build.
- **iOS / App Store IAP: N/A (no macOS)** — same as prior iOS notes; StoreKit path unbuilt.
- During dev-mode testing (before the fail-closed fix), `premium-teori` was granted to a throwaway test
  account (`deploychk-…@ea.dev`) — harmless; note for a test-data cleanup pass.
- **Pre-existing 5px Home quick-actions overflow** (Phase 1) still logged for Phase 9.

## Next phase prerequisites (Phase 8 — Onboarding & Launch Prep)

- ✅ All core features + monetization in place.
- Phase 8 adds: premium onboarding, store assets/metadata, offline hardening, and a **release build**
  (needs a signing keystore — expect a documented partial like IAP if no keystore is available).

**Phase 7 is DONE per the Definition of Done: implementation complete (no placeholders/dead nav), mobile +
backend tests green, APK builds, backend deployed + verified + secured (fail-closed), and the paywall +
gating device-validated. The real store purchase is honestly documented as store-gated. Proceeding to
Phase 8 after CI is green.**
