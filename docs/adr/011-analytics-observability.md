# ADR-011 — Analitik & Gözlemlenebilirlik: rıza-kapılı sağlayıcılar + Sentry-hazır

**Statü:** Kabul edildi · Sprint 5 (2026-07-15) · ROADMAP Faz 23/31

## Bağlam

Üretim analitiği (GA4/Clarity/PostHog) ve gözlemlenebilirlik (Sentry) gerekir; ancak KVKK/ePrivacy
uyumu için analitik YALNIZCA açık rıza ile çalışmalı. Anahtar yoksa akış no-op olmalı.

## Karar

**Analitik** (`lib/analytics.ts` + `AnalyticsLoader`):

- Tipli olay sözlüğü (funnel/retention/soru/drop-off/özellik olayları) — PII gönderilmez.
- `enabledProviders(consent, cfg)` **saf ve test edilebilir**: sağlayıcı YALNIZCA (a) rıza + (b)
  ilgili `NEXT_PUBLIC_*` anahtarı varsa etkin. Rıza yoksa boş liste → hiçbir izleyici yüklenmez.
- `AnalyticsLoader` istemcide rıza + ENV varsa GA4/Clarity/PostHog script'lerini yükler; oturum
  tekrarı (Clarity/PostHog) rızaya bağlıdır. **Bizim dağıtımımızda ENV yok → tümüyle no-op.**
- CSP: analitik alan adları YALNIZCA ilgili ENV build'de set edildiğinde eklenir.

**Gözlemlenebilirlik** (`lib/server/observability.ts` + `/api/health` + `instrumentation.ts`):

- `captureException/captureMessage` — sağlayıcı-agnostik; varsayılan yapısal logger (sır redaksiyonu),
  `SENTRY_DSN` gelince Sentry adaptörü tek noktadan takılır.
- `/api/health` — izleme/uptime probu (db/email/payments yapılandırma durumu).
- `instrumentation.register()` — açılışta ortam/sır doğrulaması (`checkEnv`) loglanır.

## Sonuçlar

- (+) Gizlilik-öncelikli: rızasız hiçbir üçüncü-taraf izleyici yüklenmez.
- (+) Anahtar/DSN olmadan tam no-op; ENV ile üretimde tek adım açılır.
- (−) Gerçek Sentry SDK ve gösterge panoları ayrı kurulum (ENV + hesap) gerektirir.
