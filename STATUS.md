# STATUS

> Tek doğru kaynak: üst dizindeki `ROADMAP.md` (v3.1, Faz 0–35).

_Son güncelleme: 2026-07-15 · SPRINT 2 (CMS+Admin+içerik hattı+medya+arama soyutlaması) sonrası_

### Yaptım

- **Faz 0–4 ✅** mühendislik temeli, ADR'ler, Next.js + çekirdek paketler (önceki oturum).
- **Gerçek CI aktif ✅** — repo PUBLIC; GitHub Actions **yeşil** (quality + E2E + gitleaks + **CodeQL**); her faz push'unda izlendi; kırmızı görüldüğünde düzeltilip yeşile çekildi. Branch protection (force-push/deletion yasak, linear history) kuruldu.
- **Faz 9–14 ✅** SM-2 **SRS pratik döngüsü** (/calis, seri/streak ile — Faz 34 temeli) · soru bankası **53 özgün soruya** çıktı → **tam e-Sınav dağılımı (23/12/9/6) karşılanıyor** (test kapısı) · **e-Sınav simülatörü** (/deneme-sinavi: 50 soru · 45dk geri sayım · soru haritası · ders bazlı sonuç) · +2 ders (kavşak, trafik adabı → 4 dersin tümü) · 4 inline SVG ders görseli.
- **Faz 15 ✅** JSON-LD: Organization+WebSite / LearningResource+Course / Quiz — production'da doğrulandı.
- **Faz 16 ✅ (PİVOT)** — **abonelik KALDIRILDI** (kullanıcı direktifi): tek-seferlik paketler (Premium Teori 249₺, Direksiyon 199₺, Simülatör 149₺, Soru Bankası 129₺, **Komple B/Lifetime 449₺**); PaymentProvider soyutlaması + mock; entitlement + günde-1-deneme kotası → paket = sınırsız. ROADMAP Faz 16 güncellendi.
- **Faz 18 ✅** PWA: service worker (offline) + manifest — **production'da kayıtlı olduğu doğrulandı**.
- **Faz 20 ✅ (çekirdek)** 43 birim testi + **10 Playwright E2E** — CI'da ve yerelde yeşil.
- **Faz 21 ✅ DEPLOY** — **Vercel production: https://ehliyet-akademi-nine.vercel.app** (rootDirectory=apps/web monorepo; NEXT_PUBLIC_SITE_URL env). **Gerçek tarayıcıyla production doğrulandı:** landing, tanı→hazırlık skoru, dersler+SVG+schema, deneme (45:00 sayaç, 50 soru), fiyatlandırma+mock satın alma+sahiplik, SW kaydı, koyu tema, konsol 0 hata.

### Yaptım (bu tur — kabuk + kurumsal)

- **UYGULAMA KABUĞU REDESIGN ✅ (direktif)** — (marketing)/(app) ayrımı; **kalıcı sol sidebar** (gruplu nav, aktif durum, streak), mobil çekmece+scrim; **/panel dashboard** (stat kartları, ustalık barları, skeleton, hızlı aksiyonlar). Production'da doğrulandı.
- **Faz 22 AI Koç ✅ (mock/grounded)** — /ai-koc: yanıtlar YALNIZ içerikten (retrieval, halüsinasyon=0), uyarı etiketli; 6 unit test; canlıda doğrulandı.
- **Faz 23 Analitik ✅ (temel)** — tipli olay sözlüğü + console sink; 5 kritik olay bağlandı (PostHog ENV ile takılır).
- **Faz 34 Başarılar ✅** — 8 rozet + panel entegrasyonu (4 unit test).
- **Faz 28 Arama ✅ (hafif)** — /arama TR-normalize anlık arama.
- **Ayarlar ✅** — tema (sistem/açık/koyu, FOUC'suz kalıcı — e2e) + veri dışa aktar/sıfırla.
- Kapılar: **27 unit + 18 e2e** + build (24 sayfa) + **CI yeşil** + prod deploy + canlı doğrulama.

### Yaptım (SPRINT 1) ✅

- **Auth:** özel credentials (scrypt + DB oturum, çok-cihaz, forgot/reset) — /giris, /profil (korumalı), dinamik Sidebar. ADR-004 güncellendi.
- **DB (Faz 26/27):** @ea/db — Drizzle şema + çift sürücü (PGlite yerel / Postgres prod); idempotent bootstrap; PGlite-Next bundling sorunu webpackIgnore ile çözüldü.
- **Entitlements:** sunucu-taraflı tek-seferlik satın alma (fiyat sunucuda) + restore; Pricing entegre.
- **Senkron:** syncSet + fullSync — cihaz A→B ilerleme/paket senkronu e2e ile kanıtlı.
- **Kalite:** 39 unit/integration + 23 e2e (production build üstünde) + CI yeşil + prod deploy.
- **Tek dış aksiyon:** production DATABASE_URL → Neon marketplace şartları kullanıcı kabulü bekliyor (SPRINT_1_REPORT.md'de link). O gelene dek prod auth uçları bilinçli 503.

### Yaptım (SPRINT 2) ✅

- **CMS (Faz 24 · ADR-007):** değerlendirme (Payload/Sanity/Contentful/Strapi/özel) → **şema-öncelikli özel çekirdek**; `content_items/content_versions/media_assets/audit_logs` (JSONB payload + Zod doğrulama); türler `lesson/question/article/seo_page/kb`, `locale`+`licence` ile gelecekteki sınıflara açık. Payload'a açık kapı (JSONB birebir taşınır).
- **İçerik hattı:** durum makinesi `draft→in_review→approved→published→retired` (sunucuda zorlanır; onaysız yayın reddedilir); her değişiklik = sürüm satırı + denetim satırı; yayın/emeklilik → arama indeksleme kancası.
- **Admin (Faz 25):** `/admin` **aynı SaaS kabuğunda** (Genel Bakış/İçerik/Medya/Kullanıcılar/Denetim); istemci koruması (admin-denied) + sunucu koruması (`requireRole` her `/api/admin/*` ucunda); JSON payload editörü + NEXT geçiş düğmeleri + sürüm geçmişi.
- **Medya (Faz 14 altyapı):** svg/png/jpeg/webp/lottie yükleme (2MB sınır, desteklenmeyen mime reddi) + halka açık servis `/api/media/[id]` (doğru mime, değişmez cache); Blob/S3 adaptör kapısı.
- **Arama soyutlaması (Faz 28):** `SearchProvider` arayüzü + `LocalSearchProvider`; `getSearchProvider()` + `SEARCH_PROVIDER` env → Meili/Typesense/Algolia **yeniden-yazımsız** takılır; /arama bu soyutlamayı kullanıyor.
- **RBAC:** `users.role` user/editor/admin; rol bootstrap (`ADMIN_EMAILS` → `ADMIN_EMAIL_PATTERN` → yönetici-yoksa-ilk-kullanıcı); oturumsuz 401 / yetkisiz 403; öz-adminlik düşürme kilidi; tam denetim kaydı.
- **Kalite:** 81 unit/integration + 28 e2e (production build) + CI yeşil + prod deploy + **canlı tarayıcı doğrulaması** (arama sonuç veriyor · /admin misafirde RBAC reddi · admin API oturumsuz 401).
- Ayrıntı: `SPRINT_2_REPORT.md` · karar: `docs/adr/007-cms.md`.

### Yapıyorum

- Sprint 2 kapanışı (rapor + dokümantasyon). **DUR: Sprint 3 başlatılmadı** (direktif).

### Yapacağım (ROADMAP sırası — sonraki sorumlu nokta)

- **Faz 17 ASO** (mağaza — retention kanıtı sonrası) · **Faz 19** diğer sınıflar (altyapı hazır: `licence` kolonu).
- **Faz 22–35 kurumsal:** AI platformu (mock→gerçek), Analitik (GA4/PostHog), gerçek tahsilat adaptörü, Güvenlik sertleştirme (CSP/pen-test/KVKK), Gözlemlenebilirlik (Sentry), Topluluk, Habit-loop derinleştirme, Platform Zekası. **(Faz 24 CMS · 25 Admin · 28 Arama çekirdekleri Sprint 2'de tamamlandı; 34 seri/streak canlıda.)**

### Engeller / Notlar

- ~~Actions faturalandırma kilidi~~ → **çözüldü** (repo public; CI ücretsiz ve yeşil).
- Dependabot PR'ları (9 adet, major sürümler) bekliyor — ayrı hijyen turunda ele alınacak.
- Ödeme **demo modda** (gerçek tahsilat yok) — üretim tahsilatı için LemonSqueezy/Stripe one-time adaptörü + webhook (Faz 16 kalan iş).
- İçerik: 53 soru/5 ders = sağlam çekirdek; hedef konu başına 100+ (uzman onaylı) — üretim hattı hazır.
