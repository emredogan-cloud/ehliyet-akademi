# ADR-003 — Veritabanı: Postgres + Drizzle (yerelde PGlite)

**Statü:** Kabul edildi (ROADMAP Faz 27)

## Bağlam

İlişkisel veri (kullanıcı, ilerleme, soru, SRS kartı, oturum, abonelik, kurs/koltuk),
migrasyon disiplini ve tip güvenliği gerekli. Geliştirmenin harici bir DB servisine
bağımlı olmaması istenir (ENV/mock politikası: eksik servis geliştirmeyi durdurmaz).

## Karar

- **Postgres** (üretim: Neon/Vercel) + **Drizzle ORM** (tipli şema + Drizzle Kit migrasyon).
- **Yerel geliştirme/test:** **PGlite** (WASM Postgres) — sıfır kurulum, dosya/bellek içi;
  aynı Drizzle şeması. `DATABASE_URL` yoksa otomatik PGlite'a düşülür (feature-flag/dummy).
- Repository deseni ile veri erişimi soyutlanır (Clean Architecture) → sağlayıcı değişimi ucuz.

## Sonuçlar

- (+) Harici servis olmadan tam çalışan, testlenebilir veri katmanı.
- (+) Üretime geçişte yalnız `DATABASE_URL` set edilir; kod değişmez.
- (−) PGlite ile Postgres arasında nadir uç-durum farkları → CI'da (ileride) gerçek PG matrisi.
