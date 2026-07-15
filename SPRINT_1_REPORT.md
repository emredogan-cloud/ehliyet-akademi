# SPRINT 1 TAMAMLAMA RAPORU — Auth, Veritabanı, Entitlements, Senkron

_Tarih: 2026-07-15 · Tek doğru kaynak: `ROADMAP.md` (Faz 4-auth, 26, 27, 16-entitlement)_

---

## Sonuç: ✅ TAMAMLANDI (tek kalan dış aksiyon: production DATABASE_URL — aşağıda)

| Sprint kriteri               | Durum                                                                                                                 |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Authentication çalışıyor     | ✅ Kayıt/giriş/çıkış/unuttum/reset/oturum-kalıcılığı/korumalı-rota/profil/çok-cihaz — kod + testler + gerçek tarayıcı |
| Veritabanı kalıcı            | ✅ Drizzle şema (users/sessions/reset/user_state/purchases); PGlite yerel · Postgres(Neon) prod-hazır                 |
| Progress sync çalışıyor      | ✅ Cihaz A→B senkron e2e ile kanıtlı (cevaplar/kartlar/seri/hazırlık/tema/kota/paketler)                              |
| Lifetime entitlements        | ✅ Sunucu-taraflı tek-seferlik satın alma (fiyat sunucuda katalogtan) + restore purchases                             |
| CI yeşil                     | ✅ GitHub Actions (quality + E2E-prod-build + gitleaks + CodeQL)                                                      |
| Production deploy doğrulandı | ✅ Misafir akışları canlı; auth uçları DATABASE_URL gelene dek **tasarlanmış dostane 503**                            |
| Tarayıcı doğrulaması         | ✅ 23 Playwright e2e (5'i Sprint-1 akışları) — production build üzerinde                                              |

## Epic Özetleri

### Epic 1 — Authentication (ADR-004 güncellendi)

Karşılaştırma yapıldı (Clerk / Auth.js / Supabase / Firebase / özel) → **özel credentials**
seçildi: sıfır harici bağımlılık, otonom kurulabilir, tam kontrol; adaptör kapısı açık.

- scrypt (N=16384) parola · oturum: 256-bit rastgele token, DB'de yalnız SHA-256 hash'i,
  httpOnly + SameSite=Lax çerez, 30 gün, **çok-cihaz** (oturum başına satır).
- Uçlar: `register · login · logout · me · forgot · reset` — reset sonrası **tüm oturumlar düşer**.
- E-posta servisi yokken forgot **dürüst devToken** modunda (RESEND_API_KEY gelince gerçek gönderim).
- UI: `/giris` (4 mod), `/profil` (**korumalı**), Sidebar dinamik hesap bölümü.

### Epic 2 — Database (Faz 26/27; ADR-003 doğrulandı)

- `@ea/db`: Drizzle ORM Postgres-lehçe şema; **çift sürücü** — `DATABASE_URL`→node-postgres,
  yoksa **PGlite** (dev: `.pglite/`, test: bellek-içi). İdempotent bootstrap DDL.
- Kritik mühendislik çözümü: PGlite ESM-only olduğundan Next onu bundle'lıyordu
  (`ERR_INVALID_ARG_TYPE`) → `webpackIgnore` native-import + web'e doğrudan bağımlılık.
- Playwright artık **production build + next start** üzerinde koşuyor (CI-birebir gerçeklik).

### Epic 3 — Entitlements (tek-seferlik, abonelik YOK)

- `POST /api/purchases`: fiyat **sunucuda** katalogtan (fiyat-bütünlüğü), idempotent
  (unique user+product), kalıcı satır = ömür boyu sahiplik.
- `GET /api/purchases` + `/profil` "Satın almaları geri yükle" → her cihazda restore.
- Pricing girişliyken sunucuya yazar; girişsiz yerel demo + bilgilendirme.

### Epic 4 — Progress Sync

- `syncSet` katmanı: tüm yazımlar (cevaplar, SRS kartları, seri, hazırlık, kota, paketler,
  tema) yerel + girişliyse **debounce'lu sunucu PUT** (izin-listeli anahtarlar, boyut sınırı).
- Girişte `fullSync`: sunucu-öncelikli birleşme; yalnız-yerel anahtarlar sunucuya itilir.
- Sidebar açılışta oturum varsa cihaz senkronu — **çerez duruyor, localStorage boş** senaryosu dahil.

## Test Kanıtı

- **39 unit/integration** (yeni: 4 DB CRUD + **8'li API entegrasyon paketi** — kayıt→409/400 →
  me→çok-cihaz→state-izinlist→purchase-idempotent→restore→forgot/reset-oturum-düşürme→logout).
- **23 e2e** (yeni 5: kayıt+kalıcılık, korumalı profil, **cihaz A→B ilerleme senkronu**,
  **satın alma→başka cihazda restore**, çıkış). Hepsi CI'da, production build üzerinde.

## Production Durumu ve TEK Kalan Dış Aksiyon

Kod production'da; misafir deneyimi tam. Auth'un canlıda aktifleşmesi için **Postgres**
gerekiyor. Neon entegrasyonu CLI'dan başlatıldı; **marketplace şartlarının kabulü** kullanıcı
onayı gerektirdiğinden (hukuki sözleşme — otonom kabul edilmedi) tek adım kaldı:

1. Aç ve kabul et: https://vercel.com/emre30283-4955s-projects/~/integrations/accept-terms/neon?source=cli
2. `vercel integration add neon` (DATABASE_URL otomatik bağlanır)
3. `vercel deploy --prod --yes`

Şema ilk bağlantıda kendini kurar; başka hiçbir değişiklik gerekmez. Şartlar kabul edilene
dek auth uçları üretimde **bilinçli 503** döner (canlıda doğrulandı) ve uygulamanın hesapsız
akışları tam çalışır.

## Sprint 2 Adaylığı (ROADMAP sırası — başlatılmadı)

Gerçek tahsilat adaptörü (LemonSqueezy/Stripe one-time + webhook) · RESEND e-posta ·
içerik derinleştirme (100+/konu + uzman onayı) · Faz 24 CMS / 25 Admin · güvenlik sertleştirme.
