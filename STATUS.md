# STATUS

> Tek doğru kaynak: üst dizindeki `ROADMAP.md` (v3.1, Faz 0–35).

_Son güncelleme: 2026-07-15 · Kabuk redesign + kurumsal fazlar sonrası_

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

### Yapıyorum

- Kapanış dokümantasyonu (FINAL raporları v3).

### Yapacağım (ROADMAP sırası — sonraki sorumlu nokta)

- **Faz 17 ASO** (mağaza — retention kanıtı sonrası) · **Faz 19** diğer sınıflar.
- **Faz 22–35 kurumsal:** AI platformu (mock→gerçek), Analitik (GA4/PostHog), CMS (Payload), Admin, API/DB sunucu kalıcılığı (auth), Arama, Güvenlik sertleştirme (CSP/pen-test), Gözlemlenebilirlik (Sentry), Topluluk, Habit-loop derinleştirme, Platform Zekası. (Faz 34'ün seri/streak çekirdeği canlıda.)

### Engeller / Notlar

- ~~Actions faturalandırma kilidi~~ → **çözüldü** (repo public; CI ücretsiz ve yeşil).
- Dependabot PR'ları (9 adet, major sürümler) bekliyor — ayrı hijyen turunda ele alınacak.
- Ödeme **demo modda** (gerçek tahsilat yok) — üretim tahsilatı için LemonSqueezy/Stripe one-time adaptörü + webhook (Faz 16 kalan iş).
- İçerik: 53 soru/5 ders = sağlam çekirdek; hedef konu başına 100+ (uzman onaylı) — üretim hattı hazır.
