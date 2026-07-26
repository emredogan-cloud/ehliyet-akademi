# Ortam değişkenleri — kesin rehber

**Beta Faz 13 · Denetim tarihi: 2026-07-27**
Bu belge, projenin ortam yapılandırması için **tek doğruluk kaynağıdır**. Depo baştan sona
tarandı: `.env` · `.env.example` · `process.env.*` · `String.fromEnvironment` (dart-define) ·
CI iş akışları · Vercel · Firebase · Play · RevenueCat.

> Bu belgede **hiçbir gizli değer yoktur** ve olmamalıdır.

---

## 1. Şu anda kullanılan tüm değişkenler

### 1.1 Web (`apps/web`, Vercel) — sunucu

| Değişken                                                                         | Nerede okunuyor            | İşlevi                                        |
| -------------------------------------------------------------------------------- | -------------------------- | --------------------------------------------- |
| `DATABASE_URL`                                                                   | `@ea/db`                   | Postgres (Neon) bağlantısı                    |
| `ANTHROPIC_API_KEY`                                                              | `lib/server/ai.ts`         | AI Koç yanıtları (akan + tek parça)           |
| `ANTHROPIC_MODEL`                                                                | `lib/server/ai.ts`         | Model kimliği (varsayılan `claude-haiku-4-5`) |
| `RESEND_API_KEY`                                                                 | `lib/server/email.ts`      | Doğrulama / sıfırlama e-postaları             |
| `EMAIL_FROM`                                                                     | `lib/server/email.ts`      | Gönderen adresi                               |
| `SUPPORT_EMAIL`                                                                  | destek yüzeyleri           | Kullanıcıya gösterilen destek adresi          |
| `GOOGLE_SERVER_CLIENT_ID`                                                        | `app/api/auth/google`      | **Mobil Google girişinin sunucu doğrulaması** |
| `GOOGLE_PLAY_SA_JSON`                                                            | `app/api/iap/validate`     | Play satın alma doğrulaması (servis hesabı)   |
| `LEMONSQUEEZY_API_KEY` · `LEMONSQUEEZY_STORE_ID` · `LEMONSQUEEZY_WEBHOOK_SECRET` | ödeme katmanı              | Web ödemesi                                   |
| `NEXT_PUBLIC_PAYMENT_PROVIDER`                                                   | istemci                    | Hangi ödeme sağlayıcısının gösterileceği      |
| `NEXT_PUBLIC_SITE_URL`                                                           | SEO · e-posta bağlantıları | Kanonik site adresi                           |
| `ADMIN_EMAILS` · `ADMIN_EMAIL_PATTERN`                                           | yetkilendirme              | Yönetici tanımı                               |
| `LOG_LEVEL`                                                                      | `lib/server/logger.ts`     | Günlük ayrıntısı                              |
| `SENTRY_DSN`                                                                     | hata izleme                | Opsiyonel                                     |

### 1.2 Web — yalnız test/CI

`PGLITE_DIR` · `RATE_LIMIT_DISABLED` · `IAP_DEV_ACCEPT` · `CI` · `NODE_ENV` · `VERCEL` ·
`NEXT_RUNTIME`

> `IAP_DEV_ACCEPT` ve `RATE_LIMIT_DISABLED` **üretimde ayarlanmamalıdır**; ikisi de güvenlik
> davranışını gevşetir.

### 1.3 Web — analitik / doğrulama (hepsi opsiyonel)

`NEXT_PUBLIC_GA_ID` · `NEXT_PUBLIC_POSTHOG_KEY` · `NEXT_PUBLIC_POSTHOG_HOST` ·
`NEXT_PUBLIC_CLARITY_ID` · `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION` ·
`NEXT_PUBLIC_BING_VERIFICATION` · `NEXT_PUBLIC_YANDEX_VERIFICATION` · `INDEXNOW_KEY` ·
`SEARCH_PROVIDER`

### 1.4 Mobil (`apps/mobile`) — **dart-define**, derleme zamanı

| Değişken                     | Varsayılan                      | İşlevi                                          |
| ---------------------------- | ------------------------------- | ----------------------------------------------- |
| `API_BASE_URL`               | `https://www.ehliyetegitim.com` | Arka uç adresi                                  |
| `GOOGLE_SERVER_CLIENT_ID`    | _(boş)_                         | Google girişi — **boşsa düğme HİÇ gösterilmez** |
| `REVENUECAT_PUBLIC_KEY`      | _(boş)_                         | Boşsa RevenueCat yolu hiç seçilmez              |
| `REVENUECAT_PROJECT_ID`      | _(boş)_                         | Yalnız teşhis/günlük                            |
| `REVENUECAT_ENTITLEMENT`     | `premium`                       | Uygulamanın sorduğu **tek** yetki               |
| `REVENUECAT_MONTHLY_PRODUCT` | _(boş)_                         | Aylık ürün kimliği                              |
| `REVENUECAT_YEARLY_PRODUCT`  | _(boş)_                         | Yıllık ürün kimliği                             |

---

## 2. Zorunlu değişkenler

| #   | Değişken                        | Neden zorunlu                                             |
| --- | ------------------------------- | --------------------------------------------------------- |
| 1   | `DATABASE_URL`                  | Onsuz hiçbir hesap, ilerleme veya topluluk çalışmaz       |
| 2   | `ANTHROPIC_API_KEY`             | Onsuz AI Koç yalnız içerikten besteler; akış hiç kurulmaz |
| 3   | `RESEND_API_KEY` + `EMAIL_FROM` | Doğrulama ve parola sıfırlama e-postaları                 |
| 4   | `NEXT_PUBLIC_SITE_URL`          | E-postadaki ve SEO'daki mutlak bağlantılar                |
| 5   | `GOOGLE_SERVER_CLIENT_ID`       | **Mobil Google girişi** — sunucu tarafı doğrulama         |
| 6   | `GOOGLE_PLAY_SA_JSON`           | Play satın almalarının sunucuda doğrulanması              |

---

## 3. Opsiyonel değişkenler

`SENTRY_DSN` · `LOG_LEVEL` · tüm `NEXT_PUBLIC_*` analitik/doğrulama anahtarları ·
`ANTHROPIC_MODEL` · `SUPPORT_EMAIL` · tüm `REVENUECAT_*` (verilmezse uygulama mevcut
`in_app_purchase` yolunda çalışır).

---

## 4. Kullanımdan kalkmış / kullanılmayanlar

| Değişken                                                                     | Durum                                                          |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `OPENAI_API_KEY`                                                             | `.env` içinde **var ama kodda hiç okunmuyor** — kaldırılabilir |
| `KIMI_API_KEY`                                                               | `apps/web/.env.local` içinde var, kodda yok — kaldırılabilir   |
| `NEON_AUTH_BASE_URL` · `VITE_NEON_AUTH_URL` · `NEON_PROJECT_ID`              | Neon panelinin otomatik eklediği; uygulama kullanmıyor         |
| `POSTGRES_*` · `PGHOST*` · `PGUSER` · `PGPASSWORD` · `DATABASE_URL_UNPOOLED` | Neon'un türev kopyaları; kod yalnız `DATABASE_URL` okur        |
| `VERCEL_OIDC_TOKEN`                                                          | Vercel CLI'ın yerel oturum jetonu; kalıcı değildir             |

> Bunlar zarar vermiyor ama `.env`'i şişiriyor ve "hangi anahtar gerçekten gerekli" sorusunu
> bulanıklaştırıyor.

---

## 5. Zaten yapılandırılmış olanlar

Üretim sağlık ucu **doğrudan sorgulandı**:

```
GET https://www.ehliyetegitim.com/api/health
{"status":"ok","service":"ehliyet-akademi","db":"configured",
 "email":"resend","payments":"lemonsqueezy"}
```

Bu çıktı şunları **kanıtlar**: `DATABASE_URL` ✅ · `RESEND_API_KEY` ✅ ·
LemonSqueezy anahtarları ✅ (Vercel üretim ortamında ayarlı).

Ayrıca:

| Öge                                      | Durum                             |
| ---------------------------------------- | --------------------------------- |
| Firebase SHA-1 / SHA-256 parmak izleri   | ✅ eklendi (kullanıcı tarafından) |
| Google Cloud **Web** OAuth istemcisi     | ✅ oluşturuldu                    |
| `GOOGLE_SERVER_CLIENT_ID` (yerel `.env`) | ✅ var                            |
| Play Console yapılandırması              | ✅ hazır                          |
| Kapalı Test altyapısı                    | ✅ hazır                          |

---

## 6. Hâlâ eksik olanlar

| #   | Değişken                                                   | Nerede          | Etki                                                                        |
| --- | ---------------------------------------------------------- | --------------- | --------------------------------------------------------------------------- |
| 1   | `GOOGLE_SERVER_CLIENT_ID` — **mobil derlemede**            | `--dart-define` | Verilmezse Google düğmesi uygulamada **hiç görünmez** (bilinçli tasarım)    |
| 2   | `REVENUECAT_PUBLIC_KEY`                                    | `--dart-define` | Verilmezse RevenueCat devre dışı; uygulama `in_app_purchase` ile çalışır    |
| 3   | `REVENUECAT_MONTHLY_PRODUCT` · `REVENUECAT_YEARLY_PRODUCT` | `--dart-define` | Abonelik ürünleri listelenemez                                              |
| 4   | `GOOGLE_PLAY_SA_JSON`                                      | Vercel          | Play satın almaları **sunucuda doğrulanamaz**                               |
| 5   | `ANTHROPIC_API_KEY` (Vercel üretim)                        | Vercel          | Sağlık ucu doğrulamıyor; AI yanıtları üretimde **ölçülerek** teyit edilmeli |

---

## 7. Her değeri hangi servis verir

| Değişken                  | Servis                                                                          |
| ------------------------- | ------------------------------------------------------------------------------- |
| `DATABASE_URL`            | **Neon** → Project → Connection string                                          |
| `ANTHROPIC_API_KEY`       | **Anthropic Console** → API Keys                                                |
| `RESEND_API_KEY`          | **Resend** → API Keys                                                           |
| `GOOGLE_SERVER_CLIENT_ID` | **Google Cloud Console** → APIs & Services → Credentials → OAuth **Web** client |
| `GOOGLE_PLAY_SA_JSON`     | **Google Cloud** servis hesabı + **Play Console** → API access                  |
| `LEMONSQUEEZY_*`          | **Lemon Squeezy** → Settings → API                                              |
| `REVENUECAT_PUBLIC_KEY`   | **RevenueCat** → Project → API keys → **Public SDK key (Android)**              |
| `REVENUECAT_PROJECT_ID`   | **RevenueCat** → Project settings                                               |
| `REVENUECAT_*_PRODUCT`    | **Play Console** → Monetize → Subscriptions (ürün kimlikleri)                   |
| `SENTRY_DSN`              | **Sentry** → Project settings → Client keys                                     |

---

## 8. Eksik değerler tam olarak nasıl alınır

### 8.1 `GOOGLE_SERVER_CLIENT_ID` (mobil derleme)

Zaten var; derlemeye **aktarılması** gerekiyor:

```bash
flutter build appbundle --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-istemci-kimliği>.apps.googleusercontent.com
```

> **Web** istemci kimliği kullanılır, Android istemcisi değil. Sunucu, mobilin gönderdiği
> `idToken`'ı bu kimliğe göre doğrular.
>
> `google-services.json` içindeki `oauth_client: []` boş olması **sorun değildir**: Google
> Services Gradle eklentisi projede **uygulanmıyor**; kimlik yalnız dart-define'dan okunur
> (Faz 2'de ölçüldü).

### 8.2 RevenueCat (üç değer)

1. **RevenueCat** hesabı aç → yeni **Project**.
2. **Apps** → Android uygulaması ekle: paket adı `com.ehliyetegitim.ehliyet_akademi`.
3. Play Console servis hesabı JSON'unu RevenueCat'e yükle (Play ile eşleşme için).
4. **API keys** → `Public SDK key (Android)` → `REVENUECAT_PUBLIC_KEY`.
5. **Entitlements** → `premium` adında bir yetki oluştur (uygulama **tam olarak bunu** sorar).
6. **Products** → Play'deki abonelik kimliklerini bağla → aylık ve yıllık ürün kimlikleri.
7. **Integrations → Webhooks** → hedef: `POST https://www.ehliyetegitim.com/api/iap/revenuecat`

8. **Vercel** → `REVENUECAT_WEBHOOK_SECRET` = RevenueCat panosundaki `Authorization` değeri.

> ✅ **Webhook ucu Faz 13'te yazıldı** (`app/api/iap/revenuecat/route.ts`, 11 test).
> Denetim sırasında üretimde `404` döndüğü ölçülmüştü; Faz 3'ün "sunucu köprüsü webhook'tur"
> kararının kapanışı budur.
>
> Uç **fail-closed**'dur: `REVENUECAT_WEBHOOK_SECRET` ayarlı değilse 503 döner ve **hiçbir şey
> yazmaz** — aksi hâlde internetteki herkes kendine premium verebilirdi. Düz paylaşılan sır ve
> `sha256=<hmac>` imzası kabul edilir; karşılaştırma sabit zamanlıdır. Aynı olay iki kez gelirse
> kopya sahiplik oluşmaz.

### 8.3 `GOOGLE_PLAY_SA_JSON`

1. Google Cloud → IAM → Service Accounts → yeni hesap → JSON anahtar indir.
2. Play Console → Setup → API access → hesabı bağla → **View financial data** izni ver.
3. JSON'un **tamamını tek satıra** sıkıştırıp Vercel'e ortam değişkeni olarak gir.

---

## 9. Kritik / opsiyonel ayrımı

| Kritiklik                  | Değişkenler                                                                           | Yoksa ne olur                                        |
| -------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 🔴 **Yayın engelleyici**   | `DATABASE_URL` · `RESEND_API_KEY` · `NEXT_PUBLIC_SITE_URL`                            | Hesap ve e-posta akışı çalışmaz                      |
| 🟠 **Özellik engelleyici** | `GOOGLE_SERVER_CLIENT_ID` (dart-define) · `GOOGLE_PLAY_SA_JSON` · `ANTHROPIC_API_KEY` | İlgili özellik **dürüstçe kapanır**, uygulama çökmez |
| 🟡 **İsteğe bağlı**        | `REVENUECAT_*`                                                                        | Mevcut `in_app_purchase` yolu çalışmaya devam eder   |
| ⚪ **Kozmetik**            | analitik / doğrulama anahtarları                                                      | Ölçüm toplanmaz                                      |

> Projenin mimari kuralı: **eksik anahtar çökme üretmez.** Her entegrasyon
> `isConfigured` kapısıyla korunur ve yapılandırılmamışsa yüzey **hiç gösterilmez** —
> çalışmayan düğme ölü gezinmedir.

---

## 10. Güvenlik önerileri

1. **`.env` asla depoya girmez.** `.gitignore` bunu kapsar; CI'da ayrıca `gitleaks` çalışır.
   Depoda yalnız `.env.example` **şablonları** bulunur (gizli değer içermez).
2. **Biçim uyarısı — ölçüldü:** `.env` ve `apps/web/.env.local` içinde iki anahtar
   `AD =değer` biçiminde, yani **eşittirden önce boşlukla** yazılmış
   (`OPENAI_API_KEY` ve `GOOGLE_SERVER_CLIENT_ID`). `dotenv` bunu tolere eder ama kabuk
   (`source .env`) **etmez**. Boşluklar temizlenmelidir.
3. **Kullanılmayan anahtarları sil** (§4). Duran her gizli değer bir sızıntı yüzeyidir.
4. `IAP_DEV_ACCEPT` ve `RATE_LIMIT_DISABLED` üretimde **asla** ayarlanmamalıdır.
5. `GOOGLE_PLAY_SA_JSON` bir **servis hesabı özel anahtarıdır**; yalnız Vercel'in sunucu
   ortamında bulunmalı, `NEXT_PUBLIC_` öneki **asla** verilmemelidir.
6. Anahtar döndürme (rotation): Anthropic ve Resend anahtarları panolarından tek tıkla
   yenilenebilir; yenileme sonrası Vercel değişkeni güncellenmeli ve yeniden dağıtım yapılmalıdır.
7. Yerel veritabanı yedekleri (ör. temizlik yedeği) **e-posta ve parola özeti içerir** →
   depo dışına yazılır.

---

## 11. Dağıtım kontrol listesi

- [ ] Vercel → Production ortamında §2'deki **altı zorunlu** değişken ayarlı
- [ ] `NEXT_PUBLIC_SITE_URL` = `https://www.ehliyetegitim.com` (sonda `/` yok)
- [ ] `ADMIN_EMAILS` yalnız gerçek yöneticileri içeriyor
- [ ] `IAP_DEV_ACCEPT` ve `RATE_LIMIT_DISABLED` üretimde **yok**
- [ ] `/api/health` `db: configured` · `email: resend` döndürüyor
- [ ] AAB, `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` ile derlendi
- [x] RevenueCat webhook ucu **yazıldı** (`/api/iap/revenuecat`, fail-closed, 11 test)
- [ ] (RevenueCat kullanılacaksa) pano dolduruldu + `REVENUECAT_WEBHOOK_SECRET` Vercel'e girildi
- [ ] `pnpm verify` temiz (placeholder/sır kalıntısı yok)
- [ ] `gitleaks` CI adımı yeşil

---

## 12. Üretime hazırlık kontrol listesi

- [x] Mobil: `flutter analyze` 0 · `flutter test` 395 · sürüm derlemesi başarılı
- [x] Web: `pnpm test` 548 · `lint` · `typecheck` · `format` · `verify` temiz
- [x] CI · Mobile CI · CodeQL · gitleaks yeşil
- [x] Sürüm imzalama `key.properties` üzerinden bağlı; AAB `jarsigner` ile doğrulanıyor
- [x] `targetSdk` 36 · `minSdk` 24 · sürüm `1.0.0+1`
- [x] Google girişi uçtan uca (sunucu doğrulamalı) — kimlik derlemeye verilince açılır
- [x] Eksik anahtarlarda **çökme yok**, yüzey dürüstçe kapanıyor
- [ ] RevenueCat panosu + `REVENUECAT_WEBHOOK_SECRET` (yayın engelleyici **değil**)
- [ ] Üretim veritabanı temizliği (`DATABASE_CLEANUP_REPORT.md` §7 — onay bekliyor)
- [ ] Play Console'a nihai AAB yüklemesi (elle)
