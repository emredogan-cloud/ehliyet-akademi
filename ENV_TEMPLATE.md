# Ortam Değişkenleri — Şablon ve Rehber

> ## 🗄️ ARŞİV — bu belge artık resmî kaynak DEĞİLDİR
>
> Dağıtımın tek resmî kaynağı **[`OPERATIONS_MANUAL.md`](OPERATIONS_MANUAL.md)** oldu.
> Bu belgedeki içerik oraya taşındı: **§16 (Ortam değişkenleri — tam referans)**
>
> Burası tarihsel kayıt olarak duruyor. **Çelişki hâlinde el kitabı geçerlidir** — el kitabındaki
> her iddia ölçülerek doğrulanmıştır; bu belgedeki bazı ifadeler bayatlamıştır.

**Kural:** bu depoda **hiçbir gerçek gizli değer bulunmaz.** Depoda yalnız `.example` şablonları
durur; gerçek değerler `.env.local` (Git dışı), Vercel ortam değişkenleri ve CI secret'larında
tutulur. CI'daki **gitleaks** taraması bu kuralı zorlar.

> Aşağıdaki liste **koddan taranarak** çıkarıldı (`process.env.*`), tahminle değil.

---

## 1. Sunucu (Next.js / Vercel) — `apps/web/.env.local`

### 1.1 Zorunlu

| Değişken       | Ne işe yarar                      | Yoksa ne olur                                                           |
| -------------- | --------------------------------- | ----------------------------------------------------------------------- |
| `DATABASE_URL` | Postgres bağlantısı (Neon/Vercel) | Vercel'de hesap/satın alma uçları **503** döner; yerelde PGlite'a düşer |

### 1.2 Kimlik doğrulama (Faz 2'de eklenecek)

| Değişken                   | Ne işe yarar                                                      |
| -------------------------- | ----------------------------------------------------------------- |
| `GOOGLE_SERVER_CLIENT_ID`  | **En kritik olan.** ID token'ın `aud` doğrulaması bununla yapılır |
| `GOOGLE_WEB_CLIENT_ID`     | Web tarafı Google girişi kullanılacaksa                           |
| `GOOGLE_ANDROID_CLIENT_ID` | Kayıt amaçlı; sunucu doğrulamasında kullanılmaz                   |
| `GOOGLE_IOS_CLIENT_ID`     | İleride iOS eklenirse                                             |

> Android uygulaması `serverClientId` olarak **Web** istemci kimliğini verir. Ayrıntı:
> `GOOGLE_AUTH_SETUP.md` §4.

### 1.3 Ödeme

| Değişken                       | Ne işe yarar                                                |
| ------------------------------ | ----------------------------------------------------------- |
| `NEXT_PUBLIC_PAYMENT_PROVIDER` | `mock` \| `lemonsqueezy` — web ödeme sağlayıcısı            |
| `LEMONSQUEEZY_API_KEY`         | Web ödemesi (mevcut)                                        |
| `LEMONSQUEEZY_STORE_ID`        | Web ödemesi (mevcut)                                        |
| `LEMONSQUEEZY_WEBHOOK_SECRET`  | Webhook HMAC doğrulaması                                    |
| `GOOGLE_PLAY_SA_JSON`          | Play satın alma doğrulaması (servis hesabı JSON)            |
| `IAP_DEV_ACCEPT`               | **Yalnız geliştirme.** Üretimde **asla** ayarlanmaz         |
| `REVENUECAT_SECRET_KEY`        | (Faz 3) Sunucu → RevenueCat REST. **Asla istemciye gitmez** |

### 1.4 AI

| Değişken            | Ne işe yarar                                 |
| ------------------- | -------------------------------------------- |
| `ANTHROPIC_API_KEY` | AI Koç. Yoksa AI yüzeyi dürüstçe kapalı olur |
| `ANTHROPIC_MODEL`   | Model kimliği                                |

### 1.5 E-posta

| Değişken         | Ne işe yarar                                        |
| ---------------- | --------------------------------------------------- |
| `RESEND_API_KEY` | E-posta gönderimi. Yoksa konsola yazılır (devToken) |
| `EMAIL_FROM`     | Gönderen adresi                                     |
| `SUPPORT_EMAIL`  | Destek adresi                                       |

### 1.6 Yönetim ve işletim

| Değişken               | Ne işe yarar                           |
| ---------------------- | -------------------------------------- |
| `ADMIN_EMAILS`         | Yönetici erişimi (virgülle ayrık)      |
| `ADMIN_EMAIL_PATTERN`  | Yönetici e-posta deseni                |
| `LOG_LEVEL`            | Günlük ayrıntısı                       |
| `RATE_LIMIT_DISABLED`  | **Yalnız test.** Üretimde ayarlanmaz   |
| `SENTRY_DSN`           | Hata izleme (isteğe bağlı)             |
| `NEXT_PUBLIC_SITE_URL` | E-posta bağlantıları mutlak olsun diye |

### 1.7 Analitik / doğrulama (hepsi isteğe bağlı)

`NEXT_PUBLIC_GA_ID` · `NEXT_PUBLIC_POSTHOG_KEY` · `NEXT_PUBLIC_POSTHOG_HOST` ·
`NEXT_PUBLIC_CLARITY_ID` · `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION` ·
`NEXT_PUBLIC_BING_VERIFICATION` · `NEXT_PUBLIC_YANDEX_VERIFICATION` · `INDEXNOW_KEY` ·
`SEARCH_PROVIDER`

> **Veri Güvenliği uyarısı:** analitik açarsanız Play'deki Veri Güvenliği formu güncellenmelidir
> (`PLAY_CONSOLE_SETUP.md` §5.6). Kapalı test için kapalı tutmak beyan yükünü azaltır.

---

## 2. Mobil (Flutter) — derleme zamanı

Flutter'da `.env` dosyası çalışma zamanında okunmaz; değerler **derleme zamanında** verilir:

```bash
flutter build appbundle --release \
  --dart-define=REVENUECAT_PUBLIC_KEY=... \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

| Değişken                     | Ne işe yarar                                       |
| ---------------------------- | -------------------------------------------------- |
| `GOOGLE_SERVER_CLIENT_ID`    | `google_sign_in`'a `serverClientId` olarak verilir |
| `REVENUECAT_PUBLIC_KEY`      | RevenueCat SDK (Android public key)                |
| `REVENUECAT_PROJECT_ID`      | Kayıt/teşhis amaçlı                                |
| `REVENUECAT_ENTITLEMENT`     | Varsayılan `premium`                               |
| `REVENUECAT_MONTHLY_PRODUCT` | Aylık abonelik ürün kimliği (kullanılırsa)         |
| `REVENUECAT_YEARLY_PRODUCT`  | Yıllık abonelik ürün kimliği (kullanılırsa)        |

**Kural:** bu değerlerin hiçbiri **zorunlu değildir**. Verilmezse uygulama çökmez; ilgili yüzey
dürüst bir "yapılandırılmadı" durumu gösterir. Bu davranış Faz 2 ve Faz 3'te **testle** korunur.

Ayrıca `google-services.json` bir **dosya**dır, ortam değişkeni değil:
`apps/mobile/android/app/google-services.json`. CI'da base64 secret olarak verilip derleme
öncesi yazılır.

---

## 3. Oluşturulacak şablon dosyaları

| Dosya                                         | Ne zaman | Durum                                                |
| --------------------------------------------- | -------- | ---------------------------------------------------- |
| `apps/web/.env.example`                       | Faz 2    | ✅ **depoda** (Faz 3'te `.gitignore` düzeltildi)     |
| `apps/mobile/.env.example`                    | Faz 3    | ✅ **depoda** — mobil derleme değişkenleri, değersiz |
| `android/release-keystore.properties.example` | Faz 4    | ⬜ İmzalama şablonu                                  |

> ⚠️ **`.gitignore` tuzağı (Faz 3'te bulundu):** kök `.gitignore` ve `apps/web/.gitignore`
> içindeki `.env*` kalıbı, daha önceki `!.env.example` istisnasını **geçersiz kılıyordu** (son
> eşleşen kalıp kazanır). Bu yüzden Faz 2'nin `.env.example`'ı depoya **hiç girmemişti**.
> Düzeltildi. **Yeni şablon dosyası eklerken `git check-ignore -v <dosya>` ile doğrula** —
> "dosyayı yazdım" ile "dosya depoda" aynı şey değildir.

Şablon biçimi — **örnek değer bile yazılmaz**, yalnız açıklama:

```dotenv
# Google ID token doğrulaması için WEB istemci kimliği (Android istemci DEĞİL).
# Firebase → Proje ayarları → Android uygulaması → OAuth istemcileri
GOOGLE_SERVER_CLIENT_ID=
```

> Gerçekçi görünen sahte değerler bile yazılmaz: gitleaks bunları sır sanıp CI'ı kırabilir
> (E9'da bir test parolası yüzünden tam olarak bu yaşandı).

---

## 4. Gizli değer sızarsa ne yapılır

1. Anahtarı **hemen** sağlayıcı panosundan iptal edin (rotate).
2. Yeni anahtarı Vercel/CI secret'ına girin.
3. Depodan silmek **yetmez** — Git geçmişinde kalır; anahtar zaten iptal edilmiş olmalıdır.
4. Sızıntının hangi commit'te girdiğini `gitleaks detect` ile kayda geçirin ve
   `MOBILE_PROJECT_MEMORY.md`'ye ekleyin.
