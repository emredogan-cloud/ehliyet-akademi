# Changelog

Tüm kayda değer değişiklikler bu dosyada tutulur. Biçim: [Keep a Changelog](https://keepachangelog.com/tr/) + SemVer.
Sürüm girdileri Changesets ile otomatik üretilir; faz-bazlı ilerleme için `STATUS.md`'ye bakın.

## [Yayınlanmamış]

### Eklendi

- **Sprint 5 — AI Platformu, Analitik & Güvenlik Sertleştirme:** sunucu-taraflı grounded AI (ADR-010: `/api/ai/ask` + halüsinasyon kapısı + model soyutlaması Mock/Anthropic + fallback + değerlendirme kümesi %100); rıza-kapılı analitik (ADR-011: GA4/Clarity/PostHog `enabledProviders`, gizlilik-öncelikli no-op); gözlemlenebilirlik (`/api/health`, `captureException` Sentry-hazır, instrumentation env/sır doğrulaması); güvenlik sertleştirme (CSP + tam güvenlik başlığı seti + CSRF same-origin middleware + secrets validation + `SECURITY_REVIEW.md` OWASP Top 10); performans (dynamic import code-split + streaming loading + cache başlıkları). 148 unit/integration + 41 e2e. Ayrıntı: `SPRINT_5_REPORT.md`.
- **Sprint 4 — Ticaret, Yasal & Üretim Servisleri:** gerçek tek-seferlik ödeme mimarisi (ADR-008 LemonSqueezy: `PaymentGateway` + webhook HMAC doğrulaması + makbuz + idempotency; mock varsayılan); e-posta platformu (ADR-009 Resend: `EmailProvider` + 5 şablon + doğrulama/reset/onay/destek akışları); yasal & uyum (Gizlilik/Kullanım/Çerez/KVKK taslak sayfaları + çerez rıza bannerı + rıza yönetimi + veri dışa aktarma + hesap silme); üretim sağlamlaştırma (yapısal logger + rate-limit + retry + hata sınırları); premium deneyim (`Lesson.premium` + entitlements + kilitli dersler + kilit açma + satın alma diyaloğu). 130 unit/integration + 37 e2e. Ayrıntı: `SPRINT_4_REPORT.md`.
- **Sprint 3 — İçerik Genişletme & Öğrenme Deneyimi:** soru bankası 53 → **198 özgün soru** (82 konu; zenginleştirilmiş metaveri whyWrong/objective/tags; yüklemede Zod parse); dersler 5 → **19** (Teorik Akademi 14 + Sürüş Akademisi 5; her ders tekrar kartları + alıştırma + hafıza/strateji/özet + görsel); görsel sistem 4 → **12 erişilebilir SVG**; **grounded AI öğrenme asistanı** (`lib/study.ts`: zayıf konu, çalışma planı, kişisel tekrar, yanlış-açıklama) + yeni `/calisma-plani` (ustalık radarı); şema geriye dönük uyumlu genişletme (Question/Lesson yeni alanlar + QuestionInput/LessonInput). 94 unit/integration + 32 e2e. Ayrıntı: `SPRINT_3_REPORT.md`.
- **Sprint 2 — CMS, Admin & İçerik Hattı:** şema-öncelikli özel CMS çekirdeği (ADR-007; `content_items`/`content_versions`/`media_assets`/`audit_logs`), yönetişimli içerik hattı (durum makinesi `draft→in_review→approved→published→retired`, sürüm geçmişi, denetim kaydı, arama indeksleme kancası), aynı SaaS kabuğunda admin panosu (`/admin`), medya kütüphanesi (svg/png/jpeg/webp/lottie + `/api/media/[id]`), takılabilir arama soyutlaması (`SearchProvider` + `LocalSearchProvider`), RBAC (user/editor/admin + rol bootstrap + öz-adminlik kilidi). ENV: `ADMIN_EMAILS`, `ADMIN_EMAIL_PATTERN`, `SEARCH_PROVIDER`. Ayrıntı: `SPRINT_2_REPORT.md`.
- **Sprint 1 — Auth, Veritabanı & Entitlements:** özel credentials auth (scrypt + DB oturum, çok-cihaz, forgot/reset), `@ea/db` çift sürücü (PGlite yerel / Postgres prod), sunucu-taraflı tek-seferlik entitlements + restore, cihazlar-arası ilerleme senkronu. ADR-004. Ayrıntı: `SPRINT_1_REPORT.md`.

## [0.1.0] — 2026-07-14

### Eklendi

- Faz 0: monorepo iskeleti (pnpm + turbo), kalite kapıları (ESLint, Prettier, TypeScript, Vitest/Playwright altyapısı), CI/CD (GitHub Actions: quality/e2e/gitleaks/commitlint/CodeQL), yönetişim dosyaları (LICENSE, SECURITY, CONTRIBUTING, CODEOWNERS, şablonlar), Dependabot, Changesets.
