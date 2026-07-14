# STATUS

> Her ~3 fazda bir güncellenir. Tek doğru kaynak: üst dizindeki `ROADMAP.md` (v3.1, Faz 0–35).

_Son güncelleme: 2026-07-15 · Faz 4 sonu_

### Yaptım

- **Faz 0 — Mühendislik Temeli ✅** monorepo (pnpm+turbo), kalite kapıları (`pnpm gates`), CI/CD (Actions), yönetişim, private repo + push.
- **Faz 1–3 — Strateji & Mimari ✅** 6 ADR (Next.js, monorepo, Postgres/Drizzle+PGlite, auth, içerik modeli, stil) + `ENV_SETUP_GUIDE.md`.
- **Faz 4 — Next.js + çekirdek ✅ (test edildi)**
  - Paketler: `@ea/content-schema` (Zod), `@ea/srs-engine` (SM-2 + hazırlık skoru/trafik ışığı), `@ea/question-bank` (22 özgün soru).
  - Web (Next 15 App Router, SSG): aktivasyon akışı **tanı denemesi → hazırlık skoru**; /dersler (+SSG detay), /e-sinav, /hazirlik-skorum; sitemap+robots+metadata; güvenlik başlıkları.
  - **Kalite: verify + lint + typecheck + 30 unit + 4 e2e (gerçek tarayıcı) + build(13 sayfa) — HEPSİ YEŞİL.**
- **Faz 5–8 (temel) ~** tasarım tokenları (globals.css), BİM rotaları, UI bileşenleri, frontend CWV-dostu SSG hazır.
- **Faz 9–14 (temel) ~** SRS motoru + hazırlık skoru entegre; 3 ders (4 dersin tümüne genişletilecek); soru bankası hattı; PWA manifest.

### Yapıyorum

- Faz 5–14 derinleştirme (daha çok özgün soru + e-Sınav simülatörü + quiz pratiği) ve FINAL raporları.

### Yapacağım (ROADMAP sırası)

- Faz 15–21: SEO schema, monetizasyon (mock), ASO, PWA/mobil cila, QA regresyon, yayın.
- Faz 22–35: kurumsal katmanlar (AI mock, analitik mock, CMS, admin, arama, güvenlik sertleştirme, DevOps/gözlemlenebilirlik, topluluk, habit loop, platform zekası) — soyutlama + mock provider ile başlanır, gerçek servisler ENV ile takılır.

### Engeller / Riskler

- ⛔ **GitHub Actions faturalandırma kilidi (dış engel):** private repo'da hosted CI başlamıyor (billing). Yerel `pnpm gates` + e2e CI'ın birebir muadili olarak her faz çalıştırılıyor; workflow'lar hazır. Çözüm sahibi kullanıcı: Billing düzelt **veya** repo'yu public yap.
- Branch protection: GitHub Pro/public ister (free+private'ta API 403) — trunk disiplini + yerel kapılarla ilerleniyor.
- **Kapsam gerçekliği:** 36 kurumsal fazın tamamı tek oturumda üretime alınamaz; çekirdek ürün (Faz 0–4) tam, test edilmiş ve deploy'a hazır; Faz 5–35 için sağlam temel + mock/soyutlama kurulu, gerçek servisler ENV ile takılır. Ayrıntı: FINAL raporları.
