# Katkı Rehberi

Bu depo **ROADMAP.md'yi (üst dizinde) tek doğru kaynak** kabul eder. Her katkı bir
ROADMAP fazına bağlanır.

## Akış (trunk-based)

1. `main`'den kısa ömürlü dal aç: `feat/faz4-auth`, `fix/quiz-scoring` …
2. Küçük, odaklı PR'lar; her PR şablondaki kontrol listesini doldurur.
3. CI (lint · format · typecheck · test · build · e2e · gitleaks · commitlint) **yeşil olmadan merge yok**.
4. Merge sonrası dal silinir.

## Commit mesajları — Conventional Commits

```
feat(web): tanı denemesi ve hazırlık skoru akışı
fix(srs): erken tekrar aralığı hesabı
docs(adr): veritabanı seçimi ADR-003
chore(ci): lighthouse eşiği
```

Tipler: `feat` `fix` `docs` `style` `refactor` `perf` `test` `chore` `ci` `content`.
`content(...)` — ders/soru bankası değişiklikleri (uzman onayı gerektirir).

## Yerel komutlar

```bash
pnpm install
pnpm gates        # verify + lint + typecheck + test + build (CI ile birebir)
pnpm e2e          # Playwright (apps/web)
```

## Kod standartları

- TypeScript strict; `any` kaçışına gerekçe yorumu.
- Kullanıcıya görünen her metin **Türkçe**; erişilebilirlik (klavye/odak/aria) korunur.
- İçerikte placeholder/TODO yasak (CI `verify` kapısı bunu tarar).
- "Resmî Kural" rozetli bilgi yalnız doğrulanmış mevzuata dayanır (bkz. ROADMAP E.6).

## Sürümleme

Changesets kullanılır: `pnpm changeset` → sürüm PR'ı → otomatik CHANGELOG.
