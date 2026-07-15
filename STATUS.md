# STATUS

> Tek doğru kaynak: üst dizindeki `ROADMAP.md` (v3.1, Faz 0–35).

_Son güncelleme: 2026-07-15 · SPRINT 5 (AI platformu + analitik + gözlemlenebilirlik + güvenlik) sonrası_

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

### Yaptım (SPRINT 3) ✅ — içerik & öğrenme deneyimi

- **Soru bankası 53 → 198 özgün soru** (trafik 63 · ilkyardim 42 · motor 39 · adab 26 · pratik 28; 82 konu); zenginleştirilmiş metaveri (whyWrong/objective/tags); banka yüklemede Zod parse (bozuk içerik build kırar). 5 ayrı dosya `questions-{trafik,ilkyardim,motor,adab,pratik}.ts`.
- **Dersler 5 → 19** (Teorik Akademi 14 + Sürüş Akademisi 5). Her ders: kazanımlar, rozetli bölümler, hatalar, hafıza teknikleri, sınav stratejisi, özet, tekrar kartları (çevrilir), alıştırma soruları (anında geri bildirim), görsel, AI giriş noktası. `content/{lessons,theory-lessons,driving-lessons}.ts`.
- **Görsel sistem:** LessonFigure 4 → 12 erişilebilir SVG (takip mesafesi, sollama, yaya, TYD, araç, rampa, park, dönel kavşak) — figureId ile eşlenir.
- **AI öğrenme asistanı (grounded):** `lib/study.ts` (weakTopics, buildStudyPlan, personalizedReview, explainWrongAnswer, nextStudySuggestion) — kullanıcının kendi verisinden. AI Koç'a 3 aksiyon + yeni `/calisma-plani` (adımlar + ustalık radarı).
- **Şema (geriye dönük uyumlu):** Question +whyWrong/objective/tags; Lesson +memoryTips/examStrategy/keyTakeaways/reviewCards/practiceQuestionIds/figureId; QuestionInput/LessonInput yazım tipleri.
- **Kalite:** 94 unit/integration (+11 study, +2 bank) + 32 e2e (+4) + typecheck + build (23 sayfa) + CI yeşil + prod deploy + **canlı tarayıcı doğrulaması** (ders/alıştırma/plan/AI/görsel — konsol 0 hata).
- Ayrıntı: `SPRINT_3_REPORT.md`.

### Yaptım (SPRINT 4) ✅ — ticaret, yasal & üretim servisleri

- **Ödeme (ADR-008 LemonSqueezy MoR):** `PaymentGateway` soyutlaması + MockGateway (varsayılan) + LemonSqueezyGateway (ENV); `/api/checkout` + `/api/webhooks/lemonsqueezy` (HMAC imza + makbuz doğrulaması + idempotent grant + external_ref). Fiyat sunucuda doğrulanır. Abonelik yok.
- **E-posta (ADR-009 Resend):** `EmailProvider` soyutlaması + Console (varsayılan)/Resend (retry) + 5 saf şablon; kayıt→hoş geldin+doğrulama, forgot→reset, `/api/auth/verify`+`/dogrula`, `/sifirla`, `/api/support`. `users.email_verified` + doğrulama tablosu.
- **Yasal:** /gizlilik, /kullanim-kosullari, /cerez-politikasi, /kvkk (taslak, yer-tutucu, hukukçu-inceleme notlu) + çerez rıza bannerı + rıza yönetimi + veri dışa aktarma + hesap silme (`DELETE /api/account`).
- **Üretim sağlamlaştırma:** yapısal logger (sır redaksiyonu) + rate-limit + withRetry + error.tsx/not-found.tsx + guarded 503.
- **Premium:** Lesson.premium + entitlements (canAccessLesson) + PremiumBadge + PremiumLessonGate + PurchaseDialog + checkoutClient; 3 ileri ders premium (güvenlik/ilk yardım ASLA kilitlenmez).
- **Kalite:** 130 unit/integration (+35) + 37 e2e (+5) + CI yeşil + CodeQL yeşil + prod deploy + **canlı tarayıcı** (premium unlock/çerez/yasal/API kapıları).
- Ayrıntı: `SPRINT_4_REPORT.md` · ADR-008/009.

### Yaptım (SPRINT 5) ✅ — AI platformu, analitik, gözlemlenebilirlik, güvenlik, performans

- **AI (ADR-010):** sunucu grounded yanıtlama `/api/ai/ask` — retrieval + halüsinasyon kapısı (eşleşme yoksa reddet) + model soyutlaması (Mock varsayılan / Anthropic ENV) + prompt orkestrasyonu + fallback; önek-duyarlı Türkçe eşleşme; değerlendirme kümesi + %100 skor. AICoach sunucu rotasını kullanır (yerel fallback) + sınav hazırlığı aksiyonu.
- **Analitik (ADR-011):** rıza-kapılı sağlayıcı katmanı (GA4/Clarity/PostHog); `enabledProviders` saf+testli; AnalyticsLoader yalnız rıza+ENV varsa yükler; genişletilmiş olay sözlüğü. No-op varsayılan (gizlilik-öncelikli).
- **Gözlemlenebilirlik:** `/api/health` + observability lib (Sentry-hazır) + instrumentation (açılışta env/sır doğrulaması) + yapısal logger.
- **Güvenlik:** CSP + tam güvenlik başlığı seti (next.config, SSG-uyumlu) + CSRF same-origin middleware (webhook muaf) + secrets validation + `SECURITY_REVIEW.md` (OWASP Top 10).
- **Performans:** PurchaseDialog dynamic import (code-split) + loading.tsx streaming + cache başlıkları. CSP render'ı kırmadı.
- **Kalite:** 148 unit/integration (+18) + 41 e2e (+4) + CI yeşil + CodeQL yeşil + prod deploy + **canlı doğrulama** (güvenlik başlıkları/health/CSRF 403/grounded AI, 0 CSP ihlali).
- Ayrıntı: `SPRINT_5_REPORT.md` · ADR-010/011 · `SECURITY_REVIEW.md`.

### Yapıyorum

- Sprint 5 kapanışı (rapor + dokümantasyon). **DUR: Sprint 6 başlatılmadı** (direktif).

### Yapacağım (ROADMAP sırası — sonraki sorumlu nokta)

- **Faz 17 ASO** (mağaza — retention kanıtı sonrası) · **Faz 19** diğer sınıflar (altyapı hazır: `licence` kolonu).
- **Faz 22–35 kurumsal:** AI platformu (mock→gerçek), Analitik (GA4/PostHog), gerçek tahsilat adaptörü, Güvenlik sertleştirme (CSP/pen-test/KVKK), Gözlemlenebilirlik (Sentry), Topluluk, Habit-loop derinleştirme, Platform Zekası. **(Faz 24 CMS · 25 Admin · 28 Arama çekirdekleri Sprint 2'de tamamlandı; 34 seri/streak canlıda.)**

### Engeller / Notlar

- ~~Actions faturalandırma kilidi~~ → **çözüldü** (repo public; CI ücretsiz ve yeşil).
- Dependabot PR'ları (9 adet, major sürümler) bekliyor — ayrı hijyen turunda ele alınacak.
- Ödeme mimarisi **hazır** (ADR-008 LemonSqueezy adaptörü + webhook + makbuz); gerçek tahsilat için `LEMONSQUEEZY_*` ENV (kullanıcı aksiyonu). O gelene dek satın alma **demo modda** (etiketli).
- İçerik: **198 soru (82 konu) / 19 ders** (Sprint 3); hedef konu başına 100+ (uzman onaylı) — üretim hattı hazır, sürüyor. İlk yardım içeriği uzman onayı bekliyor (review: draft).
