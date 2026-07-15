# Changelog

Tüm kayda değer değişiklikler bu dosyada tutulur. Biçim: [Keep a Changelog](https://keepachangelog.com/tr/) + SemVer.
Sürüm girdileri Changesets ile otomatik üretilir; faz-bazlı ilerleme için `STATUS.md`'ye bakın.

## [Yayınlanmamış]

### Eklendi

- **Sprint 2 — CMS, Admin & İçerik Hattı:** şema-öncelikli özel CMS çekirdeği (ADR-007; `content_items`/`content_versions`/`media_assets`/`audit_logs`), yönetişimli içerik hattı (durum makinesi `draft→in_review→approved→published→retired`, sürüm geçmişi, denetim kaydı, arama indeksleme kancası), aynı SaaS kabuğunda admin panosu (`/admin`), medya kütüphanesi (svg/png/jpeg/webp/lottie + `/api/media/[id]`), takılabilir arama soyutlaması (`SearchProvider` + `LocalSearchProvider`), RBAC (user/editor/admin + rol bootstrap + öz-adminlik kilidi). ENV: `ADMIN_EMAILS`, `ADMIN_EMAIL_PATTERN`, `SEARCH_PROVIDER`. Ayrıntı: `SPRINT_2_REPORT.md`.
- **Sprint 1 — Auth, Veritabanı & Entitlements:** özel credentials auth (scrypt + DB oturum, çok-cihaz, forgot/reset), `@ea/db` çift sürücü (PGlite yerel / Postgres prod), sunucu-taraflı tek-seferlik entitlements + restore, cihazlar-arası ilerleme senkronu. ADR-004. Ayrıntı: `SPRINT_1_REPORT.md`.

## [0.1.0] — 2026-07-14

### Eklendi

- Faz 0: monorepo iskeleti (pnpm + turbo), kalite kapıları (ESLint, Prettier, TypeScript, Vitest/Playwright altyapısı), CI/CD (GitHub Actions: quality/e2e/gitleaks/commitlint/CodeQL), yönetişim dosyaları (LICENSE, SECURITY, CONTRIBUTING, CODEOWNERS, şablonlar), Dependabot, Changesets.
