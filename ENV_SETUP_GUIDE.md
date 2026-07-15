# ENV_SETUP_GUIDE — Ortam Değişkenleri

> **İlke (ROADMAP mock politikası):** Eksik ENV geliştirmeyi **durdurmaz**. Her harici
> bağımlılığın yerel/mock alternatifi vardır; ENV set edilmezse otomatik olarak ona düşülür.
> Bu rehber, üretim kurulumu için yeterlidir.

Yerel geliştirme için `apps/web/.env.example` → `apps/web/.env.local` kopyalayın (opsiyonel).
`.env*` dosyaları git'e **girmez** (gitignore + gitleaks kapısı).

---

## Çekirdek

### `DATABASE_URL`

- **Ne:** Postgres bağlantısı (kullanıcı, ilerleme, SRS, abonelik…).
- **Zorunlu mu:** Hayır (yerelde). Set edilmezse **PGlite** (gömülü WASM Postgres) kullanılır.
- **Nasıl alınır:** [Neon](https://neon.tech) / [Vercel Postgres](https://vercel.com/storage/postgres) — ücretsiz kademe var.
- **Local:** boş bırak → PGlite (`.pglite/` altında dosya). Migrasyon: `pnpm --filter @ea/db migrate`.
- **Production:** Neon connection string. **Tek kullanıcı aksiyonu bekleniyor:** Vercel-Neon
  entegrasyonu CLI'dan başlatıldı; marketplace şartlarını kabul etmek gerekiyor →
  https://vercel.com/emre30283-4955s-projects/~/integrations/accept-terms/neon?source=cli
  Kabul sonrası: `vercel integration add neon` yeniden çalıştırılır, DATABASE_URL otomatik
  bağlanır ve `vercel deploy --prod --yes` ile auth canlıda aktifleşir (kod hazır; şema
  ilk bağlantıda idempotent bootstrap ile kurulur). Şartlar kabul edilene dek auth uçları
  üretimde dostane 503 döner; uygulamanın hesapsız akışları tam çalışır.

### `RESEND_API_KEY` / `EMAIL_FROM` (e-posta platformu — Sprint 4 · ADR-009)

- **Ne:** İşlemsel e-postalar (doğrulama, parola sıfırlama, satın alma onayı, hoş geldin, destek).
- **Zorunlu mu:** Hayır. Yoksa **ConsoleEmailProvider** (e-posta gitmez, loglanır); doğrulama/sıfırlama **devToken** modunda (token yanıt içinde).
- **Nasıl alınır:** https://resend.com — ücretsiz kademe; `EMAIL_FROM` için doğrulanmış gönderen alan adı.
- **Production:** `RESEND_API_KEY` girilince gerçek gönderim (`ResendEmailProvider`, yeniden-denemeli) otomatik etkinleşir; kod değişmez.
- **İlgili:** `SUPPORT_EMAIL` (destek talebi kutusu; varsayılan `destek@ehliyetakademi.app`).

### `AUTH_SECRET`

- **Ne:** Oturum çerezi/JWT imzalama sırrı.
- **Zorunlu mu:** Üretimde evet. Yerelde yoksa sabit geliştirme-anahtarı (yalnız non-prod) kullanılır.
- **Nasıl alınır:** `openssl rand -base64 32`.
- **Production:** Güçlü rastgele değer; Vercel env.

### `AUTH_PROVIDER`

- **Ne:** `credentials` (varsayılan, yerel) | `clerk` | `authjs`.
- **Zorunlu mu:** Hayır. Varsayılan `credentials` — harici servis gerektirmez.
- **Ücretsiz alternatif:** `credentials` her zaman çalışır. Clerk ücretsiz kademe sunar.

---

## AI (ROADMAP Faz 22)

### `AI_PROVIDER` / `ANTHROPIC_API_KEY` / `OPENAI_API_KEY`

- **Ne:** AI koç/açıklama/soru-taslak üretimi ve görsel üretimi.
- **Zorunlu mu:** Hayır. `AI_PROVIDER=mock` (varsayılan) → **deterministik mock yanıtlar** (grounded, banka/müfredattan).
- **Nasıl alınır:** [console.anthropic.com](https://console.anthropic.com) / [platform.openai.com](https://platform.openai.com).
- **Local:** `mock` ile tam akış test edilir (halüsinasyon = 0, maliyet = 0).
- **Production:** gerçek anahtar **yalnız sunucu ortam değişkeni**; asla istemci koduna/repoya girmez. Görsel üretim yalnız build/script aşamasında.
- **Güvenlik:** üst dizindeki `.env`'de bulunan gerçek `OPENAI_API_KEY` bu repoya **taşınmaz**; ihtiyaç olursa CI/Vercel secret olarak girilir.

---

## Ödeme (ROADMAP Faz 16 · Sprint 4 · ADR-008)

**Model: TEK-SEFERLİK satın alma (abonelik YOK).** Sağlayıcı: **LemonSqueezy (Merchant of Record)**.

### `LEMONSQUEEZY_API_KEY` / `LEMONSQUEEZY_STORE_ID` / `LEMONSQUEEZY_WEBHOOK_SECRET` / `LEMONSQUEEZY_VARIANT_<PRODUCT>`

- **Ne:** Gerçek tek-seferlik tahsilat (hosted checkout + HMAC imzalı webhook + makbuz doğrulaması).
- **Zorunlu mu:** Hayır. Üçü de yoksa **MockGateway** (gerçek para yok; tam akış demo). Üçü de girilince `LemonSqueezyGateway` otomatik devreye girer.
- **Variant eşlemesi:** her ürün için `LEMONSQUEEZY_VARIANT_PREMIUM_TEORI`, `..._KOMPLE_B` vb. (ürün id'si BÜYÜK_SNAKE).
- **Nasıl alınır:** [LemonSqueezy](https://lemonsqueezy.com) — mağaza + ürün/variant + webhook (URL: `/api/webhooks/lemonsqueezy`, secret).
- **Local/Prod:** mock ile satın-alma akışları test edilir; anahtarlar girilince gerçek tahsilat. **Fiyat her zaman sunucuda katalogdan doğrulanır.**

---

## Analitik & Gözlemlenebilirlik (ROADMAP Faz 23/31)

| ENV                       | Ne                   | Zorunlu | Local                 | Alternatif              |
| ------------------------- | -------------------- | ------- | --------------------- | ----------------------- |
| `NEXT_PUBLIC_POSTHOG_KEY` | Ürün analitiği/deney | Hayır   | `mock` → konsola olay | PostHog ücretsiz kademe |
| `NEXT_PUBLIC_GA_ID`       | GA4                  | Hayır   | kapalı                | ücretsiz                |
| `NEXT_PUBLIC_CLARITY_ID`  | Isı/oturum           | Hayır   | kapalı                | ücretsiz                |
| `SENTRY_DSN`              | Hata izleme          | Hayır   | konsola               | Sentry ücretsiz kademe  |

Analitik ENV yoksa **no-op/console** sink kullanılır — olay sözlüğü yine çalışır.

---

## Admin / RBAC (ROADMAP Faz 25 · Sprint 2)

Roller `users.role` kolonunda: `user | editor | admin`. İlk yöneticiyi **kayıt anında** belirlemek
için (aşağıdaki sıra ile) bootstrap kuralları çalışır. `/admin` ve `/api/admin/*` yalnız editor/admin'e açıktır.

### `ADMIN_EMAILS`

- **Ne:** Virgülle ayrılmış e-posta listesi; bu adreslerle kayıt olan kullanıcı otomatik **admin** olur.
- **Zorunlu mu:** Hayır. Örn: `ADMIN_EMAILS=kurucu@ea.dev,editor@ea.dev`.
- **Production:** ilk yöneticiyi güvenle atamak için önerilir.

### `ADMIN_EMAIL_PATTERN`

- **Ne:** Regex; eşleşen e-posta ile kayıt olan **admin** olur (esnek alan/desen tabanlı atama).
- **Zorunlu mu:** Hayır. E2E'de `^admin-e2e-` olarak Playwright webServer'da set edilir.
- **Not:** Geçersiz regex sessizce yok sayılır (try/catch).

### Fallback — ilk kullanıcı

- Yukarıdakiler eşleşmez **ve** sistemde hiç admin yoksa, **ilk kayıt olan kullanıcı admin** olur.
  Sonraki kullanıcılar `user` olur. (Otonom/sıfırdan kurulum için güvenli varsayılan.)

---

## Arama (ROADMAP Faz 28 · Sprint 2)

### `SEARCH_PROVIDER` / `MEILISEARCH_HOST` / `MEILISEARCH_KEY`

- **Ne:** Arama sağlayıcısı. Kod `SearchProvider` **soyutlaması** üzerinden çalışır (`lib/search.ts`).
- **Zorunlu mu:** Hayır. Varsayılan `local` → `LocalSearchProvider` (TR-normalize, bellek-içi yayınlanmış-içerik indeksi).
- **Production ölçek:** `SEARCH_PROVIDER=meilisearch` (veya typesense/algolia) → aynı arayüz;
  `getSearchProvider()` fabrikasına adaptör eklenir, **uygulama/UI kodu değişmez** (yeniden-yazımsız takılır).

---

## Üretim sağlamlaştırma (ROADMAP Faz 30/31 · Sprint 4)

| ENV                    | Ne                                        | Zorunlu      | Varsayılan                       |
| ---------------------- | ----------------------------------------- | ------------ | -------------------------------- |
| `LOG_LEVEL`            | Yapısal log eşiği (debug/info/warn/error) | Hayır        | prod: `info`, dev: `debug`       |
| `RATE_LIMIT_DISABLED`  | Hız sınırını kapat (yalnız test/e2e)      | Hayır        | kapalı (sınır aktif); e2e'de `1` |
| `SUPPORT_EMAIL`        | Destek talebi alıcı kutusu                | Hayır        | `destek@ehliyetakademi.app`      |
| `NEXT_PUBLIC_SITE_URL` | E-posta bağlantı tabanı (doğrula/sıfırla) | Prod'da evet | prod URL                         |

- Hız sınırlama bellek-içidir (serverless'te örnek-başına); ölçekte Upstash/Redis adaptörü aynı arayüzle takılır.
- Loglar üretimde tek-satır JSON; bilinen sır anahtarları (key/secret/token/…) redakte edilir.

## Deploy (Vercel — ROADMAP Faz 21) ✅ KURULU

### Platform kararı

**Vercel** seçildi (Netlify'a karşı): Next.js'in native platformu, sıfır-config App Router/ISR desteği, CLI yetkili. Proje: `ehliyet-akademi` · rootDirectory=`apps/web` (monorepo).

### `NEXT_PUBLIC_SITE_URL` ✅ set edildi

- **Ne:** Kanonik site URL'i (sitemap, JSON-LD, OG).
- **Değer (production):** `https://ehliyet-akademi-nine.vercel.app`
- **Nasıl:** `vercel env add NEXT_PUBLIC_SITE_URL production` (özel domain alınırsa güncellenir).

### Deploy komutları

```bash
vercel deploy --yes        # preview
vercel deploy --prod --yes # production
```

## Özet

Hiçbir ENV olmadan `pnpm dev` çalışır: PGlite + credentials-auth + mock AI/ödeme/analitik/arama.
Üretim için yalnızca gerçek servislerin anahtarları girilir; **kod değişmez** (Clean Architecture / DI).
