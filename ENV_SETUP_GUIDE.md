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
- **Production:** Neon connection string; `pnpm --filter @ea/db migrate:deploy`.

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

## Ödeme (ROADMAP Faz 16)

### `PAYMENT_PROVIDER` / `LEMONSQUEEZY_API_KEY` / `STRIPE_SECRET_KEY`

- **Ne:** Abonelik + kurs planı (web-first faturalama).
- **Zorunlu mu:** Hayır. `PAYMENT_PROVIDER=mock` (varsayılan) → sahte checkout + webhook simülasyonu.
- **Nasıl alınır:** [LemonSqueezy](https://lemonsqueezy.com) (tercih, MoR) / [Stripe](https://stripe.com).
- **Local:** mock ile satın-alma/iade akışları test edilir (gerçek para yok).
- **Production:** gerçek anahtar + webhook imza sırrı (`PAYMENT_WEBHOOK_SECRET`).

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

## Arama (ROADMAP Faz 28)

### `SEARCH_PROVIDER` / `MEILISEARCH_HOST` / `MEILISEARCH_KEY`

- **Zorunlu mu:** Hayır. Varsayılan `pg-fts` (Postgres/PGlite tam-metin) veya bellek-içi indeks.
- **Production ölçek:** Meilisearch/Typesense (self-host veya bulut).

---

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
