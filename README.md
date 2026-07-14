# 🚗 Ehliyet Akademi (monorepo)

Türkiye'nin B sınıfı ehliyet adayları için uçtan uca öğrenme platformu — **teorik e-Sınav ve direksiyon (pratik) sınavı** hazırlığı. Bu depo, üst dizindeki **ROADMAP.md**'yi tek doğru kaynak kabul eden v2+ monorepo'sudur; v1 (vanilla SPA) üst dizinde referans olarak durur.

## Hızlı başlangıç

```bash
pnpm install
pnpm dev          # apps/web (Faz 4 sonrası)
pnpm gates        # CI ile birebir kalite kapıları
```

## Yapı

```
apps/web          # Next.js App Router — ürün
packages/*        # ui, content-schema, question-bank, srs-engine, db, ...
docs/adr          # mimari kararlar (ADR)
.github/workflows # CI/CD
```

## Kurallar

- **ROADMAP.md tek doğru kaynak** — fazlar sırayla; kalite kapıları yeşil olmadan ilerleme yok.
- İçerik hukuku ve doğruluk: ROADMAP **BÖLÜM C.4 & E.6** bağlayıcıdır (özgün soru bankası; kopya içerik yasak; "Resmî Kural" yalnız doğrulanmış mevzuat).
- Ortam değişkenleri: `ENV_SETUP_GUIDE.md` (eksik ENV geliştirmeyi durdurmaz — mock/local provider kullanılır).

## Durum

Faz ilerlemesi: `STATUS.md` · Karar/bağlam: `MEMORY.md` · Sürümler: `CHANGELOG.md`
