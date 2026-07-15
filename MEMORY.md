# MEMORY — proje sürdürme bağlamı

> Ani kesinti sonrası devam için. Tek doğru kaynak: üst dizin `ROADMAP.md` (v3.1, 36 faz).
> Ayrıntı: `STATUS.md` · GO/NO-GO: `FINAL_RELEASE_READINESS_REPORT.md`.

_Son güncelleme: 2026-07-15 · SPRINT 2 sonrası_

## Kilit durum

- **PRODUCTION CANLI:** https://ehliyet-akademi-nine.vercel.app (Vercel, proje `ehliyet-akademi`, rootDirectory=`apps/web`, NEXT_PUBLIC_SITE_URL env set). Deploy: `vercel deploy --prod --yes` (kökten).
- **CI GERÇEK ve YEŞİL:** repo PUBLIC; Actions (quality/E2E/gitleaks/CodeQL) her push'ta; branch protection açık.
- **MONETIZASYON PİVOTU (bağlayıcı):** abonelik YOK → **tek-seferlik paketler** (5 paket; Komple B = lifetime). ROADMAP Faz 16 güncellendi. Ödeme mock (demo); üretim tahsilatı = LemonSqueezy/Stripe one-time adaptörü kalan iş.

## SPRINT 2 (en güncel tur) — CMS/Admin/İçerik hattı/Medya/Arama

- **CMS (ADR-007):** şema-öncelikli özel çekirdek (Payload'a açık kapı). `packages/db/src/cms.ts` = content_items/content_versions/media_assets/audit_logs (JSONB payload, Zod doğrulama). Türler: lesson/question/article/seo_page/kb; `locale`+`licence` kolonları (gelecekteki sınıflar).
- **İçerik hattı:** `@ea/content-schema` WORKFLOW state machine `draft→in_review→approved→published→retired` + `canTransition`/`validatePayload`. `lib/server/cms.ts` = createContent/updateContent(sürüm+1)/transitionContent(sunucuda zorlar + audit + arama kancası)/list/get/listPublished/upload/list/getMedia/listUsers/setUserRole/listAudit/adminStats.
- **RBAC:** `users.role` user/editor/admin; `requireRole()` (401/403); rol bootstrap `api/auth/register` (ADMIN_EMAILS → ADMIN_EMAIL_PATTERN regex → yönetici-yoksa-ilk-kullanıcı-admin); öz-adminlik düşürme kilidi.
- **Admin UI:** `app/(app)/admin/*` (layout client-guard `admin-denied` + 6 sayfa) **aynı SaaS kabuğunda**; Sidebar `isAdmin`→Yönetim linki. API: `app/api/admin/{content,content/[id],media,users,audit,stats}` + `app/api/media/[id]` (hepsi `guarded()`+`requireRole`).
- **Medya:** base64 DB'de (2MB cap; svg/png/jpeg/webp/lottie), servis `/api/media/[id]` (immutable cache). Blob/S3 adaptör kapısı.
- **Arama:** `lib/search.ts` SearchProvider arayüzü + LocalSearchProvider (TR-normalize, published registry); `getSearchProvider()` + `SEARCH_PROVIDER` env → Meili/Typesense/Algolia takılır. `/arama` yeniden yazıldı (`data-testid=search-results/search-empty`).
- **ENV yeni:** `ADMIN_EMAILS`, `ADMIN_EMAIL_PATTERN` (e2e: `^admin-e2e-` playwright webServer'da), `SEARCH_PROVIDER`.
- **Canlı doğrulandı:** /arama sonuç veriyor · /admin misafirde admin-denied · /api/admin/content oturumsuz 401.

## SPRINT 1

- **@ea/db**: users/sessions/password_reset_tokens/user_state/purchases; getDb() çift sürücü; `webpackIgnore` native-import (PGlite ESM bundling fix); testte memory://, devde .pglite/.
- **Auth**: lib/server/auth.ts (scrypt, token-hash oturum, guarded() 503); api/auth/* + api/state + api/purchases; lib/authClient.ts (syncSet/fullSync/restore/serverPurchase).
- **Playwright prod-build'e koşuyor** (webServer: build && start).
- **Prod DATABASE_URL bekleniyor** — Neon şartlar linki SPRINT_1_REPORT.md'de; kabul→`vercel integration add neon`→redeploy.

## Önceki tur

- **(app)/(marketing) route grupları** — uygulama kalıcı SOL SIDEBAR kabuğunda (components/Sidebar.tsx); /panel dashboard (components/Dashboard.tsx).
- AI Koç mock/grounded: lib/ai.ts (retrieval, testli) + /ai-koc. Analitik: lib/analytics.ts (tipli olaylar). Başarılar: lib/achievements.ts + /basarilar. Arama: /arama. Ayarlar/tema: /ayarlar (ea:theme, FOUC-safe kök script).
- Vitest alias: '@' → apps/web kökü (vitest.config.ts).

## Tamamlanan fazlar

0–4 ✅ · 5–8 ✅ · **9–16, 18, 20(çekirdek), 21 ✅** · **24 CMS · 25 Admin · 28 Arama ✅ (Sprint 2)** · 26/27 auth-DB ✅ (Sprint 1) · 34 streak çekirdeği ✅.
**Kalan:** 17 (ASO), 19 (sınıf genişleme — altyapı hazır), 22 (gerçek AI), 23 (gerçek analitik), gerçek tahsilat, 30 (güvenlik sertleştirme), 31 (gözlemlenebilirlik), 32/33 (topluluk), 35 (platform zekâsı).

## Mimari hatırlatmalar

- Banka **53 özgün soru** → tam sınav dağılımı (23/12/9/6); test kapısı `question-bank/index.test.ts`.
- SRS: `@ea/srs-engine` (SM-2) + `apps/web/lib/progress.ts` (kart/cevap/seri localStorage).
- Ödeme/entitlement: `apps/web/lib/{products,payments}.ts` — kota: günde 1 deneme; `sinirsiz-deneme` yeteneği → sınırsız.
- SW: `public/sw.js` (yalnız prod'da kayıt). JSON-LD: `components/JsonLd.tsx`.
- Vercel token: CLI keyring (`~/.local/share/com.vercel.cli/auth.json`) — proje ayarı API ile PATCH edildi.

## Komutlar

`pnpm gates` · `pnpm --filter @ea/web e2e` · deploy: yukarıda · CI izleme: `gh run watch $(gh run list --workflow CI --branch main --limit 1 --json databaseId -q '.[0].databaseId')`

## Son durum

- **Testler:** 81 unit/integration (48 web + 33 paket) + 28 e2e ✅ · build 22 sayfa + 15 API rotası ✅ · CI ✅ · **prod tarayıcı doğrulaması ✅** (konsol 0 hata).
- **DUR:** Sprint 2 sonrası durdu; Sprint 3 direktif olmadan başlatılmaz.
- Dependabot 9 PR bekliyor (major bump'lar) — hijyen turu.
