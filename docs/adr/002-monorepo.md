# ADR-002 — Monorepo (pnpm + turbo)

**Statü:** Kabul edildi (ROADMAP Faz 0, E.5)

## Bağlam

Platform; web, admin, cms, mobile uygulamaları ve paylaşılan paketler (ui, içerik, srs,
db, ai, analytics) içerecek. Ortak tipler ve tek CI hattı gerekli.

## Karar

**pnpm workspace + Turborepo.** `apps/*` (çalıştırılabilir), `packages/*` (paylaşılan lib).
Paket ad alanı: `@ea/*`.

**Konum kararı (önemli):** Monorepo, `other_report/ehliyet-akademi/` altındadır ve git
kökü buradadır. Üst dizindeki ilgisiz/özel dosyalar (pazar raporları, **gerçek
`OPENAI_API_KEY` içeren `.env`**, v1 vanilla uygulaması) **repo dışında** kalır — asla
commit/push edilmez. v1, referans olarak üst dizinde durur.

## Sonuçlar

- (+) Sır sızıntısı riski yapısal olarak engellenir; temiz geçmiş.
- (+) Tek `pnpm gates` hattı tüm workspace'i doğrular.
- (−) Turbo/pnpm öğrenme; kabul edilebilir.
