# Ehliyet Akademi — Mobile UI Redesign & Monetization Sprint: Report

**An update sprint on top of the completed Flutter app — new visual identity, personalization
onboarding, and a single-product premium strategy.**
_Prepared: 2026-07-24 · Built on the existing architecture (Riverpod · go_router · dio · drift) — no
new architecture introduced · device-validated on a real Android phone._

---

## 1. Executive summary — 🟢 GO

The redesign is **complete and device-validated**. The app now launches **dark-first** behind a new
adaptive launcher icon and branded splash, runs a **premium personalization onboarding**, presents every
screen in the supplied owl-mascot visual language, and monetizes through a **single "Komple Ehliyet
Paketi" (399 ₺)** with contextual, frequency-capped premium prompts.

All engineering standards were preserved: **`flutter analyze` 0 issues · `flutter test` 85 tests · web
`typecheck` 0 · web 336 tests** (backend change is additive/backward-compatible). Every screen was
exercised on the real device (Redmi, Android 11) and compared against the reference designs.

## 2. App icon, splash & default theme

- **New adaptive launcher icon** generated from `apps/assets/app_icon.png`: the emblem is background-keyed
  to a transparent foreground and placed on a navy background layer (`mipmap-anydpi-v26` adaptive icon +
  legacy square + round icons at all 5 densities). App label corrected to **"Ehliyet Akademi"**.
- **Branded splash**: navy (`#050B16`) window background + centered logo (both light & night resource
  sets, and `NormalTheme`) → **no white flash** on cold start. Device-verified.
- **Dark mode is now the default experience** (`ThemeModeController.build() → ThemeMode.dark`). The user
  can still switch to light from Profil; the choice persists across launches.

## 3. Onboarding — informational → personalization

Rebuilt as a 6-step premium flow (matching `001–006-onboarding`), collecting a persisted **`StudyProfile`**:

| Step | Question                    | Captured                                                      |
| ---- | --------------------------- | ------------------------------------------------------------- |
| 1    | Ehliyet türü                | licence category **B / A / D** (vehicle photos, "EN POPÜLER") |
| 2    | Daha önce sınava girdin mi? | **İlk Kez / Tekrar Giriyorum**                                |
| 3    | e-Sınav mı, Direksiyon mu?  | **e-Sınav / Direksiyon / İkisi** (multi-select)               |
| 4    | Sınava ne kadar kaldı?      | timeframe bucket → **study-plan intensity**                   |

Bookended by a welcome slide and an **AI Koç** intro. The profile **initializes the app**: the daily
study-plan **session size** (10 → 30 questions by timeframe, shown on Home + used by the SRS runner), the
**AI Coach context** (every answer is tailored to category/focus/timeframe/experience), and dashboard copy.
`Atla` (skip) saves an incomplete profile with sensible defaults. A step-segment progress bar + brand mark
appear on each step.

## 4. Screen redesign (all matched to references, device-validated)

| Screen          | Reference                       | Result                                                                                                                                                                   |
| --------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Home            | `home-page-1/2`                 | brand header + notification bell, readiness glow-card, **AI Koç owl hero** with nudge CTA, personalized "Bugünkü plan", colored quick-action tiles, İstatistiklerim card |
| Öğren hub       | `learning-page`                 | owl-reading hero + `HubRow` cards (Dersler 19 · İşaretler 121 · Araç 70 · Video 6)                                                                                       |
| Pratik hub      | `practice-exam-page`            | owl-teacher hero + 4 `HubRow`s (Akıllı Çalışma, Deneme, Koleksiyonlar, Geçmiş)                                                                                           |
| Koleksiyonlar   | `collections`                   | folder hero + tinted emoji circles + soru counts                                                                                                                         |
| Geçmiş Sınavlar | `past-exams-page`               | papers hero + year groups + document rows                                                                                                                                |
| Deneme Sınavı   | `practice-exam`                 | timer/answered **card**, circular **question-map pills**, İşaretle bookmark, "Sınavı Bitir" action, gradient Sonraki                                                     |
| Akıllı Çalışma  | `smart_work-1/2`                | subject badge, filled option badges + trailing radios, correct/wrong feedback + explanation, gradient "Sonraki soru"                                                     |
| Session result  | `smart-work-results`            | shared `SessionResultView` — target hero, animated **%success ring**, Doğru/Yanlış/Süre, gradient actions (exam + SRS)                                                   |
| AI Koç          | `AI-koç-menu`                   | owl intro card, assistant **owl avatars** in chat, gradient send button                                                                                                  |
| Profil          | `profil-page`                   | owl-shield hero card with Rozet/İlerleme/Gün, colored settings rows, brand promo card                                                                                    |
| Paywall         | `premium-return-pop-up` bg      | single gold-hero product, **₺399**, feature card, trust row, honest store-gated state                                                                                    |
| Premium popups  | `premium-incentive` / `-return` | gold-lock incentive + wheel-check success dialogs                                                                                                                        |

New reusable brand widgets (all token-driven, light+dark): `BrandMark` (steering-wheel CustomPainter),
`GradientPillButton` (teal + gold), `MascotImage`, `IconBadge`, `GlowCard`, `SegmentBar`, `BrandChip`,
`HubHeader`, `HubRow`; a shared `SessionResultView`; an enhanced `OptionTile`. Added one design token
(`purple`) for the personalization/stat accents. **No color or spacing is hand-picked outside the tokens.**

## 5. Assets replaced & optimized (WebP)

- The **21 supplied interface illustrations** (`apps/assets/interface-assets/`, ~40 MB PNG) were
  **background-keyed to transparency** (corner flood-fill preserving the neon glow) and converted to
  optimized **WebP** (lossy q86, capped dimensions) → **1.6 MB total** bundled under
  `apps/mobile/assets/img/`, catalogued in `lib/core/assets.dart`. They composite seamlessly on the dark
  surfaces (residual dark glow blends invisibly).
- Transparency is preserved (alpha WebP) so mascots/vehicles/illustrations float on any surface.
- The large design-reference PNGs + PDFs are **git-ignored** (references, not shipped).

## 6. Premium strategy

- **Single product**: previous 5 packs removed → **"Komple Ehliyet Paketi" @ 399 TL** (tek-seferlik /
  ömür boyu), granting every capability. Mobile `products.dart` rewritten; store id `komple_ehliyet`.
- **Backend (additive, backward-compatible)**: `MOBILE_PRODUCTS` + `anyProductById()` added to
  `apps/web/lib/products.ts`; `/api/iap/validate` now recognizes the mobile product. The web `PRODUCTS`
  array, web paywall, and all existing web tests are **unchanged**; a new integration test covers
  `komple-ehliyet`. Fail-closed IAP verification preserved.
- **Revised free tier** (keeps the app useful, creates clear premium value): free daily AI-coach quota,
  free daily deneme quota, **video lessons premium** (first video is a free preview, rest locked),
  premium advanced lessons — all bypassed by the pack.
- **Contextual, frequency-capped prompts** (`premium_prompt.dart`, pure + tested): never shown to premium
  users, 24 h cooldown, lifetime cap. Wired to real moments — first completed exam, session engagement,
  AI/exam quota exhaustion, and video/lesson lock taps. Device-verified: the gold incentive popup fired
  after a completed study session and matched the design.

## 7. Testing & CI

- **Mobile**: `flutter analyze` **0 issues** · `flutter test` **85 tests** (unit + widget), including new
  coverage for the single-product model, video gating, and the premium-prompt frequency cap.
- **Backend**: `pnpm --filter @ea/web typecheck` **0 errors** · **336 web tests** green (incl. the new
  `komple-ehliyet` IAP-validate case).
- **CI**: pushed to `main`; **Web CI · Mobile CI · CodeQL** run on every commit (see the sprint's final
  commit for the green status). Generated codegen files remain committed (Mobile CI has no build_runner).
- Debug APK builds clean (~205 MB debug; release tree-shakes to ~66 MB as before).

## 8. Real-device validation (Redmi M1908C3JGG · Android 11 · USB)

Every screen was installed and screenshotted against the redesign, in dark mode:

- Adaptive launcher icon + branded navy splash + dark-default launch.
- Full onboarding: welcome → licence (B, keyed car/moto/bus photos) → experience → e-Sınav/Direksiyon
  dual-select → timeframe → AI Koç → Home. Profile persisted; Home showed the personalized **"20 soru"**
  plan (from the weekToMonth choice).
- Home, Öğren (counts 19/121/70/6), Pratik, Koleksiyonlar, AI Koç, Profil, Bildirimler.
- Akıllı Çalışma: question + **correct/wrong feedback** + explanation; completing a session → the
  `SessionResultView` (**%10 Başarı oranı**, 2 Doğru / 18 Yanlış / 05:31) — and the **premium incentive
  popup** fired (engagement) matching `premium-incentive`.
- Deneme Sınavı runner: timer card (44:55), circular question pills, subject badge, İşaretle, gradient
  Sonraki, "Sınavı Bitir".
- Paywall: "Komple Ehliyet Paketi · ₺399 · tek seferlik", 5-feature card, honest "Mağaza kullanılamıyor".
- Videolar: first video free (İZLE), second **PREMIUM** with the gold lock overlay.

No visual regressions or overflows were observed. Minor first-load latency while the content/question
snapshots warm the cache (counts/questions appear a moment after entering a screen) — expected offline-first
behavior.

## 9. Remaining limitations (honest, infrastructure-gated)

- **Real Google Play purchase remains store-gated** (as before): a sideloaded debug build cannot complete
  an in-app purchase, so the **success popup** (`premium-return-pop-up`) was verified by design + code +
  the flow, not by a live purchase. Needs Play Console + the managed product `komple_ehliyet` @ 399 +
  `GOOGLE_PLAY_SA_JSON` for server verification.
- **iOS build N/A** (no macOS on this Linux host) — `ios/` config valid, never built.
- The `smart_work-1` reference shows an owl + "İpucu" hint beside the question; the question data model has
  **no hint field**, so the SRS question view keeps the clean subject-badge layout rather than inventing
  hint text (per "do not invent missing assets").
- FCM push remains N/A (local notifications are the working lane), unchanged from the prior program.

## 10. GO / NO-GO

**🟢 GO.** The UI redesign, personalization onboarding, single-product premium strategy, and asset
optimization are implemented to the supplied designs, preserve the existing architecture and all
engineering/testing discipline, and are validated end-to-end on the real device. Remaining items are the
same infrastructure gates documented since the original build (real Play IAP, iOS, FCM) — none block the
redesign itself.
