# MEMORY — proje sürdürme bağlamı

> Ani kesinti sonrası kaldığı yerden devam için. Tek doğru kaynak: üst dizin `ROADMAP.md` (v3.1, 36 faz).
> Her ~3 fazda güncellenir. Ayrıntılı ilerleme: `STATUS.md`.

_Son güncelleme: 2026-07-14 · Faz 0 sonu_

## Tamamlanan fazlar

- **Faz 0** — Mühendislik temeli: monorepo (pnpm+turbo), kalite kapıları (`pnpm gates`), GitHub Actions (CI/CodeQL/gitleaks/commitlint), yönetişim dosyaları, Dependabot, Changesets, private repo + push.

## Mimari kararlar (kısa ADR özeti)

1. **Monorepo konumu:** `other_report/ehliyet-akademi/` — üst dizindeki ilgisiz/özel dosyalar (raporlar, gerçek `OPENAI_API_KEY` içeren `.env`) repo DIŞINDA kalır; asla commit edilmez.
2. **Trunk-based** + Conventional Commits + Changesets (SemVer).
3. **Dependabot** (Renovate yerine — native, sıfır kurulum; ROADMAP "Renovate tercih / Dependabot" izin veriyor).
4. **CodeQL** yalnız repo public olduğunda (private'ta Advanced Security istiyor) — workflow'da görünürlük koşulu.
5. Kullanıcıya görünen her şey Türkçe; içerik hukuku ROADMAP C.4/E.6 bağlayıcı.

## Açık işler

- Faz 1–3 ADR'leri → sonra Faz 4 (Next.js + auth + DB).
- Dependabot PR'ları (actions sürüm yükseltmeleri) CI koşamadığı için bekliyor.
- Branch protection henüz kurulmadı (private+free plan kısıtı denenecek).

## Riskler

- **GitHub Actions faturalandırma kilidi** (dış engel — detay STATUS.md). Yerel kapılar CI'ın birebir muadili olarak çalıştırılıyor.

## Son durum bilgisi

- **Son commit:** `b1132d0` chore: Faz 0 — mühendislik temeli (+ bu dosyalarla yeni commit gelecek)
- **Remote:** https://github.com/emredogan-cloud/ehliyet-akademi (private)
- **Son test/CI/build:** `pnpm gates` yerelde ✅ · hosted CI ⛔ faturalandırma · build (turbo) ✅ (henüz paket yok)
