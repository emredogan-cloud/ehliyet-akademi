# MEMORY — proje sürdürme bağlamı

> Ani kesinti sonrası devam için. Tek doğru kaynak: üst dizin `ROADMAP.md` (v3.1, 36 faz).
> Ayrıntı: `STATUS.md` · GO/NO-GO: `FINAL_RELEASE_READINESS_REPORT.md`.

_Son güncelleme: 2026-07-15 · SPRINT 1 sonrası_

## Kilit durum

- **PRODUCTION CANLI:** https://ehliyet-akademi-nine.vercel.app (Vercel, proje `ehliyet-akademi`, rootDirectory=`apps/web`, NEXT_PUBLIC_SITE_URL env set). Deploy: `vercel deploy --prod --yes` (kökten).
- **CI GERÇEK ve YEŞİL:** repo PUBLIC; Actions (quality/E2E/gitleaks/CodeQL) her push'ta; branch protection açık.
- **MONETIZASYON PİVOTU (bağlayıcı):** abonelik YOK → **tek-seferlik paketler** (5 paket; Komple B = lifetime). ROADMAP Faz 16 güncellendi. Ödeme mock (demo); üretim tahsilatı = LemonSqueezy/Stripe one-time adaptörü kalan iş.

## SPRINT 1 (en güncel tur)

- **@ea/db**: users/sessions/password_reset_tokens/user_state/purchases; getDb() çift sürücü; `webpackIgnore` native-import (PGlite ESM bundling fix); testte memory://, devde .pglite/.
- **Auth**: lib/server/auth.ts (scrypt, token-hash oturum, guarded() 503); api/auth/* + api/state + api/purchases; lib/authClient.ts (syncSet/fullSync/restore/serverPurchase).
- **Playwright prod-build'e koşuyor** (webServer: build && start).
- **Prod DATABASE_URL bekleniyor** — Neon şartlar linki SPRINT_1_REPORT.md'de; kabul→`vercel integration add neon`→redeploy.

## Önceki tur

- **(app)/(marketing) route grupları** — uygulama kalıcı SOL SIDEBAR kabuğunda (components/Sidebar.tsx); /panel dashboard (components/Dashboard.tsx).
- AI Koç mock/grounded: lib/ai.ts (retrieval, testli) + /ai-koc. Analitik: lib/analytics.ts (tipli olaylar). Başarılar: lib/achievements.ts + /basarilar. Arama: /arama. Ayarlar/tema: /ayarlar (ea:theme, FOUC-safe kök script).
- Vitest alias: '@' → apps/web kökü (vitest.config.ts).

## Tamamlanan fazlar

0–4 ✅ (önceki oturum) · **9–16, 18, 20(çekirdek), 21 ✅** (bu oturum) · 5–8 ✅ · 34'ün streak çekirdeği ✅.
**Kalan:** 17 (ASO), 19 (sınıf genişleme), 22–35 kurumsal (AI/analitik/CMS/admin/auth-DB kalıcılığı/arama/güvenlik-sertleştirme/gözlemlenebilirlik/topluluk/zekâ).

## Mimari hatırlatmalar

- Banka **53 özgün soru** → tam sınav dağılımı (23/12/9/6); test kapısı `question-bank/index.test.ts`.
- SRS: `@ea/srs-engine` (SM-2) + `apps/web/lib/progress.ts` (kart/cevap/seri localStorage).
- Ödeme/entitlement: `apps/web/lib/{products,payments}.ts` — kota: günde 1 deneme; `sinirsiz-deneme` yeteneği → sınırsız.
- SW: `public/sw.js` (yalnız prod'da kayıt). JSON-LD: `components/JsonLd.tsx`.
- Vercel token: CLI keyring (`~/.local/share/com.vercel.cli/auth.json`) — proje ayarı API ile PATCH edildi.

## Komutlar

`pnpm gates` · `pnpm --filter @ea/web e2e` · deploy: yukarıda · CI izleme: `gh run watch $(gh run list --workflow CI --branch main --limit 1 --json databaseId -q '.[0].databaseId')`

## Son durum

- **Testler:** 43 unit + 10 e2e ✅ · build 19 sayfa ✅ · CI ✅ · **prod tarayıcı doğrulaması ✅** (konsol 0 hata).
- Dependabot 9 PR bekliyor (major bump'lar) — hijyen turu.
