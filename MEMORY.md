# MEMORY — proje sürdürme bağlamı

> Ani kesinti sonrası kaldığı yerden devam için. Tek doğru kaynak: üst dizin `ROADMAP.md` (v3.1, 36 faz).
> Ayrıntılı ilerleme: `STATUS.md`. Faz durumu + GO/NO-GO: `FINAL_*` raporları.

_Son güncelleme: 2026-07-15 · Faz 4 sonu_

## Tamamlanan fazlar

- **Faz 0** ✅ mühendislik temeli (monorepo, gates, CI/CD, repo+push).
- **Faz 1–3** ✅ 6 ADR + ENV rehberi.
- **Faz 4** ✅ Next.js app + 3 çekirdek paket; 30 unit + 4 e2e + build yeşil; çekirdek akış tarayıcıda doğrulandı.
- **Faz 5–14** temel kuruldu (tokenlar, rotalar, SRS, içerik, PWA).

## Mimari kararlar

Bkz. `docs/adr/`: Next.js App Router · monorepo (`@ea/*`) · Postgres/Drizzle + yerel PGlite ·
sağlayıcı-agnostik auth (yerel credentials) · tipli içerik + özgün soru bankası · CSS tokenları.
**Mock politikası:** DB/auth/AI/ödeme/analitik/arama harici servissiz çalışır (ENV_SETUP_GUIDE.md).

## Komutlar

- `pnpm gates` = verify + lint + typecheck + test + build (CI muadili).
- `pnpm --filter @ea/web e2e` = Playwright (dev sunucu 3100).
- `pnpm --filter @ea/web dev` = yerel geliştirme.

## Açık işler

- Daha fazla özgün soru (konu başına 100+ hedefi), 4 dersin tümü, e-Sınav simülatörü, quiz pratiği.
- Faz 15–35: SEO schema, monetizasyon (mock), analitik (mock), CMS, admin, arama (Meili), güvenlik sertleştirme, gözlemlenebilirlik, topluluk, habit loop, platform zekası.

## Riskler / engeller

- **GitHub Actions billing kilidi** (dış) — yerel gates ile telafi. Branch protection Pro/public ister.
- Kapsam: 36 faz tek oturumda tam üretime alınamaz — çekirdek tam+test edilmiş; gerisi temel+mock.

## Son durum

- **Son commit:** Faz 4 (`feat(web): Next.js + çekirdek paketler`), pushed.
- **Remote:** https://github.com/emredogan-cloud/ehliyet-akademi (private)
- **Testler:** 30 unit + 4 e2e ✅ · build 13 sayfa ✅ · hosted CI ⛔ billing (yerel gates ✅)
