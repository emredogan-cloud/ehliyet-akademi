# OPERASYON EL KİTABI

> 📘 **İlgili:** [`GOOGLE_PLAY_SIGNIN_PLAYBOOK.md`](GOOGLE_PLAY_SIGNIN_PLAYBOOK.md) — Google girişi arızası: belirtiden köke giden akış şeması, komut kütüphanesi ve önleme kontrol listesi.

**Ehliyet Akademi — sıfırdan üretime tek resmî dağıtım kaynağı**

|                |                                                                                                                                                                                                      |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sürüm          | 1.0 · 2026-07-27                                                                                                                                                                                     |
| Kapsam         | Web · Mobil · Backend · Play Console · Google Cloud · RevenueCat · Vercel · Veritabanı · E-posta · AI · Analitik                                                                                     |
| Yerine geçtiği | `ENV_SETUP_GUIDE.md` · `ENV_TEMPLATE.md` · `GOOGLE_AUTH_SETUP.md` · `REVENUECAT_SETUP.md` · `PLAY_CONSOLE_SETUP.md` · `RELEASE_CHECKLIST.md` · `FINAL_ENVIRONMENT_GUIDE.md` · `CLOSED_TEST_GUIDE.md` |
| Okur kitlesi   | Projeyi **hiç görmemiş** bir geliştirici                                                                                                                                                             |

> **Bu belgenin sözü:** buradaki adımları sırayla uygulayan bir geliştirici, tek bir soru sormadan
> projeyi sıfırdan üretime alabilir. Tahmin ettirmez, "ilgili ayarı bulun" demez; **her düğmeyi**
> adıyla yazar.

---

## 0. Bu el kitabı nasıl okunur

### 0.1 Aciliyetine göre giriş noktaları

| Ne yapmak istiyorsun               | Git                                                                        |
| ---------------------------------- | -------------------------------------------------------------------------- |
| Her şeyi sıfırdan kurmak           | [§2 Zero → Production](#2-zero--production-yol-haritası)                   |
| Google girişini çalıştırmak        | [§17 Google Login](#17-google-login--uçtan-uca)                            |
| Satın almaları açmak               | [§18 Satın alma akışı](#18-satın-alma-akışı--uçtan-uca)                    |
| Bir değişkenin ne olduğunu anlamak | [§16 Ortam değişkenleri](#16-ortam-değişkenleri--tam-referans)             |
| Bir şey bozuldu, teşhis lazım      | [§19 Servis servis hata ayıklama](#19-servis-servis-hata-ayıklama-listesi) |
| Kapalı teste çıkmak                | [§20 Zero → Closed Testing](#20-zero--closed-testing)                      |
| Yeni sürüm yayınlamak              | [§21 Zero → Release](#21-zero--release)                                    |

### 0.2 Gösterim kuralları

- `Ekran → Menü → Düğme` biçimi **tıklama yoludur**; her ok bir tıklamadır.
- 🔴 **Yayın engelleyici** · 🟠 **Özellik engelleyici** · 🟡 **İsteğe bağlı** · ⚪ **Kozmetik**
- ✅ ölçülerek doğrulandı · ⚠️ ölçülmedi/varsayım · ❌ şu an bozuk

### 0.3 Bu belgenin yazıldığı andaki ÖLÇÜLMÜŞ durum

Aşağıdakiler tahmin değil; **2026-07-27'de üretime doğrudan istek atılarak** ölçüldü.

| Kontrol                 | Komut                                    | Sonuç                                                            | Anlamı                                                                                                                                           |
| ----------------------- | ---------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Sağlık                  | `GET /api/health`                        | `{"db":"configured","email":"resend","payments":"lemonsqueezy"}` | ✅ DB + e-posta + ödeme anahtarları Vercel'de ayarlı                                                                                             |
| Google doğrulama        | `POST /api/auth/google` (geçersiz token) | **401**                                                          | ✅ `GOOGLE_SERVER_CLIENT_ID` **sunucuda AYARLI** (ayarlı olmasa **503** dönerdi)                                                                 |
| Akan AI                 | `POST /api/ai/ask/stream`                | **200**                                                          | ✅ Dağıtıldı ve çalışıyor                                                                                                                        |
| RevenueCat webhook      | `POST /api/iap/revenuecat`               | **503**                                                          | ✅ Uç dağıtıldı, `REVENUECAT_WEBHOOK_SECRET` yok → **fail-closed** (doğru davranış)                                                              |
| Android OAuth istemcisi | Google Cloud → Kimlik bilgileri          | _(elle bakılır)_                                                 | ❌ **Android OAuth istemcisi YOK** → Google girişinin çalışmamasının sebebi budur ([§17.3-B](#belirti-b--hesap-seçici-açılıyor-hemen-kapanıyor)) |

> **Sonuç:** "Google girişi çalışmıyor" sorununun kaynağı **sunucu değil**. Sunucu doğru
> yapılandırılmış. Eksik olan **Google Cloud'daki Android OAuth istemcisidir** —
> kurulumu: [`GOOGLE_LOGIN_SETUP.md`](GOOGLE_LOGIN_SETUP.md) §3.

---

## 1. Servis haritası

### 1.1 Kim kiminle konuşuyor

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              KULLANICI CİHAZI                                │
│                                                                              │
│   ┌────────────────────────┐              ┌──────────────────────────────┐  │
│   │   Flutter Uygulaması   │              │   Google Play Store          │  │
│   │  com.ehliyetegitim.    │◄────────────►│   (Billing + Play Services)  │  │
│   │   ehliyet_akademi      │  satın alma  └───────────┬──────────────────┘  │
│   └───────┬────────────────┘                          │                     │
│           │                                           │                     │
│           │ HTTPS + Bearer                            │ ID token / fatura   │
└───────────┼───────────────────────────────────────────┼─────────────────────┘
            │                                           │
            ▼                                           ▼
┌───────────────────────────────┐         ┌──────────────────────────────────┐
│   VERCEL  (Next.js backend)   │         │   GOOGLE CLOUD                   │
│   www.ehliyetegitim.com       │         │   proje: ehliyet-akademi-3daa1   │
│                               │         │                                  │
│   /api/auth/google  ──────────┼────────►│   JWKS: oauth2/v3/certs          │
│   /api/iap/validate ──────────┼────────►│   androidpublisher (Play API)    │
│   /api/iap/revenuecat ◄───────┼──┐      │   OAuth istemcileri (Web+Android)│
│   /api/ai/ask[/stream] ───────┼┐ │      └──────────────────────────────────┘
│   /api/purchases              ││ │
└──────────┬────────────────────┘│ │
           │                     │ │
           ▼                     │ │      ┌──────────────────────────────────┐
┌───────────────────────────┐    │ └──────┤   REVENUECAT                     │
│   NEON  (PostgreSQL)      │    │        │   webhook → /api/iap/revenuecat  │
│   users · sessions ·      │    │        │   Play ile eşleşme (SA JSON)     │
│   purchases · community   │    │        └──────────────────────────────────┘
└───────────────────────────┘    │
                                 │        ┌──────────────────────────────────┐
           ┌─────────────────────┘        │   PLAY CONSOLE                   │
           ▼                              │   AAB · ürünler · kapalı test    │
┌───────────────────────────┐             │   App Signing sertifikası        │
│   ANTHROPIC API           │             └──────────────────────────────────┘
│   claude-haiku-4-5        │
│   (SSE akış destekli)     │             ┌──────────────────────────────────┐
└───────────────────────────┘             │   RESEND (e-posta)               │
                                          │   doğrulama · parola sıfırlama   │
                                          └──────────────────────────────────┘
```

### 1.2 Bağımlılık yönü — kim olmadan kim çalışmaz

| Servis           | Bunsuz çalışmayanlar                        | Bunsuz **çalışmaya devam edenler**            |
| ---------------- | ------------------------------------------- | --------------------------------------------- |
| **Neon (DB)**    | Hesap, ilerleme, topluluk, satın alma kaydı | Hiçbiri — 🔴 zorunlu                          |
| **Vercel**       | Tüm API                                     | Mobil uygulama açılır, yerel içerik çalışır   |
| **Google Cloud** | Google ile giriş                            | E-posta/parola girişi tam çalışır             |
| **Play Console** | Satın alma, dağıtım                         | Uygulamanın kendisi (sideload)                |
| **RevenueCat**   | _(hiçbiri)_                                 | Satın alma `in_app_purchase` yolundan çalışır |
| **Anthropic**    | AI Koç serbest yanıtları                    | İçerikten beslenen mock yanıtlar              |
| **Resend**       | Doğrulama + parola sıfırlama e-postası      | Giriş, kayıt (doğrulanmamış hesapla)          |

> **Mimari kural:** eksik anahtar **çökme üretmez**. Her entegrasyon bir `isConfigured` kapısıyla
> korunur; yapılandırılmamışsa yüzey **hiç gösterilmez** — çalışmayan düğme ölü gezinmedir.
> Bu kural kodda testlerle sabitlenmiştir.

### 1.3 Kimlik doğrulama sınırları (güven modeli)

| Sınır                | Kim kime güveniyor                | Nasıl doğrulanıyor                   |
| -------------------- | --------------------------------- | ------------------------------------ |
| Mobil → Backend      | Backend mobile **güvenmez**       | Bearer oturum jetonu, sunucuda saklı |
| Backend → Google     | Backend Google'a güvenir          | JWKS ile **RS256 imza doğrulaması**  |
| RevenueCat → Backend | Backend RevenueCat'e **güvenmez** | Paylaşılan sır / HMAC, sabit zamanlı |
| Play → Backend       | Backend Play'e güvenir            | `androidpublisher` servis hesabı     |
| Kullanıcı → Premium  | Sahiplik **istemcide tutulmaz**   | Her açılışta `GET /api/purchases`    |

---

## 2. Zero → Production yol haritası

Sıfırdan üretime giden **doğru sıra**. Sıra önemlidir: her adım bir öncekinin çıktısını kullanır.

```
 1. Depoyu klonla, araçları kur              (§3)
 2. Neon veritabanı oluştur                  (§12)
 3. Resend e-posta ayarla                    (§13)
 4. Anthropic anahtarı al                    (§14)
 5. Vercel projesi oluştur + değişkenleri gir (§11)
 6. İlk dağıtım → /api/health yeşil          (§11.6)
 7. Google Cloud projesi + OAuth izin ekranı (GOOGLE_LOGIN_SETUP §2)
 8. Android OAuth istemcileri (debug + upload) (GOOGLE_LOGIN_SETUP §3)
 9. Web OAuth istemcisi                      (GOOGLE_LOGIN_SETUP §2.3)
10. GOOGLE_SERVER_CLIENT_ID'yi Vercel'e gir  (§11.2)
11. Upload key üret, Gradle'a bağla          (§6.4)
12. AAB derle (dart-define ile)              (§6.6)
13. Play Console'da uygulama oluştur         (§7.2)
14. AAB'yi kapalı teste yükle                (§7.6)
15. Play App Signing SHA-1 → yeni Android OAuth istemcisi ← EN SIK ATLANAN ADIM
    (GOOGLE_LOGIN_SETUP §7.3)
16. AAB'yi yeniden derle + yükle             (§21)
17. Play ürünlerini oluştur                  (§7.5)
18. (İsteğe bağlı) RevenueCat kur            (§10)
19. 12 test kullanıcısını davet et           (§20)
```

**Toplam süre:** ilk kez yapan biri için ~4 saat; Play'in inceleme süreleri hariç.

### 2.1 En kritik üç bilgi

Bu üç şeyi bilmeyen herkes takılır:

1. **Google Sign-In için WEB istemci kimliği kullanılır**, Android istemcisi değil.
   Android istemcisi Google Cloud'da **var olmalıdır** ama koda **girilmez**.
2. **Play, AAB'nizi yeniden imzalar.** Kullanıcıya giden imza sizin upload key'iniz değil,
   Play'in **App Signing** sertifikasıdır. Google girişi için **her ikisinin de** SHA-1'i
   Google Cloud'da **ayrı birer Android OAuth istemcisi** olarak kayıtlı olmalıdır.
3. **Play Billing sideload edilmiş yapılarda çalışmaz.** "Mağaza kullanılamıyor" mesajının
   en sık sebebi budur; hata değildir.

---

## 3. Ön koşullar — geliştirme makinesi

### 3.1 Gerekli araçlar ve ölçülmüş sürümler

| Araç        | Sürüm                                 | Doğrulama komutu              |
| ----------- | ------------------------------------- | ----------------------------- |
| Node.js     | 24.13.1                               | `node -v`                     |
| pnpm        | (repo `packageManager` alanına bakar) | `pnpm -v`                     |
| Flutter     | 3.41.9 (stable)                       | `flutter --version`           |
| Dart        | 3.11.5                                | (Flutter ile gelir)           |
| JDK         | 17+                                   | `java -version`               |
| Android SDK | Platform 36 + Build-Tools             | `sdkmanager --list_installed` |
| Git         | herhangi                              | `git --version`               |

### 3.2 Depoyu hazırla

```bash
git clone <repo-url> ehliyet-akademi
cd ehliyet-akademi
pnpm install                      # monorepo bağımlılıkları
cd apps/mobile && flutter pub get # Flutter bağımlılıkları
```

### 3.3 Kurulumu doğrula

```bash
pnpm typecheck   # 9/9 paket geçmeli
pnpm test        # 559 test geçmeli
pnpm verify      # "Workspace doğrulaması TAMAM"
cd apps/mobile && flutter analyze   # "No issues found!"
cd apps/mobile && flutter test      # 395 test geçmeli
```

Bu beş komut geçmiyorsa **daha ileri gitme** — ortam kurulumunda bir sorun vardır.

---

## 4. BÖLÜM 1 — WEB (`apps/web`)

### 4.1 Ne olduğu

Next.js (App Router) uygulaması. Hem **pazarlama/öğrenme sitesi** hem **mobilin backend'i**.
Vercel'de barındırılır. Mobil uygulama bu uygulamanın `/api/*` uçlarını kullanır.

### 4.2 Dizin haritası

| Yol                    | İçerik                                                       |
| ---------------------- | ------------------------------------------------------------ |
| `apps/web/app/`        | Sayfalar ve API rotaları (App Router)                        |
| `apps/web/app/api/`    | Tüm backend uçları                                           |
| `apps/web/lib/server/` | Sunucu yardımcıları (auth, rate-limit, ai, email, logger)    |
| `apps/web/content/`    | Dersler, videolar, işaretler (kod içinde içerik)             |
| `apps/web/public/`     | Statik varlıklar (videolar, görseller)                       |
| `packages/db/`         | Drizzle şeması + çift sürücü (PGlite test / Postgres üretim) |

### 4.3 Yerel çalıştırma

```bash
# 1) Ortam dosyasını hazırla
cp apps/web/.env.example apps/web/.env.local
# 2) .env.local içindeki değerleri doldur (§15'e bak)
# 3) Çalıştır
pnpm --filter @ea/web dev      # http://localhost:3000
```

### 4.4 Yerel doğrulama

```bash
curl -s http://localhost:3000/api/health
# Beklenen: {"status":"ok","service":"ehliyet-akademi","db":"configured",...}
```

`db` alanı `configured` değilse → `DATABASE_URL` yanlış ya da eksik.

### 4.5 Testler

```bash
pnpm --filter @ea/web test           # tüm web testleri
pnpm --filter @ea/web test -- google # yalnız Google auth testleri
```

Testler **PGlite** (bellek içi Postgres) kullanır; gerçek veritabanına dokunmaz.

---

## 5. BÖLÜM 2 — MOBILE (`apps/mobile`)

### 5.1 Kimlik bilgileri (değiştirilemez olanlar)

| Alan                       | Değer                               | Not                               |
| -------------------------- | ----------------------------------- | --------------------------------- |
| Uygulama kimliği           | `com.ehliyetegitim.ehliyet_akademi` | **Yayından sonra DEĞİŞTİRİLEMEZ** |
| Sürüm                      | `1.0.0+1`                           | `pubspec.yaml`                    |
| `compileSdk` / `targetSdk` | 36                                  | `android/app/build.gradle.kts`    |
| `minSdk`                   | 24                                  | Android 7.0+                      |

### 5.2 Mimari kuralı — neden her şey arayüz

Platforma bağlı her şey (Google Sign-In, Play Billing, dosya seçici) **arayüz + uygulama**
olarak yazılır. Sebep pratiktir: `GoogleSignIn` ve `InAppPurchase` platform kanalına bağlıdır ve
widget testinde örneklenemez. Testler sahte uygulamalarla çalışır.

Sonuç: **hiçbir yapılandırma eksikliği çökme üretmez.** Servis `isConfigured` false döner,
arayüz o yüzeyi hiç göstermez.

### 5.3 Derleme zamanı yapılandırması — `--dart-define`

Mobil uygulamanın **`.env` dosyası yoktur**. Tüm yapılandırma derleme zamanında gömülür:

```bash
flutter build appbundle --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB-istemci-kimliği>.apps.googleusercontent.com \
  --dart-define=REVENUECAT_PUBLIC_KEY=goog_XXXXXXXX \
  --dart-define=REVENUECAT_MONTHLY_PRODUCT=premium_aylik \
  --dart-define=REVENUECAT_YEARLY_PRODUCT=premium_yillik
```

> ⚠️ **En sık hata:** `--dart-define` vermeyi unutmak. Uygulama **çalışır** ama Google düğmesi
> **hiç görünmez** ve RevenueCat devre dışı kalır. Hata mesajı yoktur — tasarım böyledir.
> Doğrulama: [§17.3 Belirti A](#belirti-a--google-düğmesi-hiç-görünmüyor).

### 5.4 Yerel çalıştırma

```bash
cd apps/mobile
flutter devices                     # cihazı gör
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

Yerel backend'e bağlanmak için:

```bash
adb reverse tcp:3000 tcp:3000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

### 5.5 Testler

```bash
flutter analyze                                  # 0 sorun olmalı
flutter test                                     # 395 test
flutter test test/google_auth_test.dart          # yalnız Google
flutter test test/premium_test.dart              # yalnız ödeme
```

### 5.6 İzinler — birleşik manifest (ölçüldü)

```
INTERNET · ACCESS_NETWORK_STATE · POST_NOTIFICATIONS · RECEIVE_BOOT_COMPLETED
VIBRATE · WAKE_LOCK · USE_BIOMETRIC · USE_FINGERPRINT
com.android.vending.BILLING
```

**Depolama izni YOKTUR.** Avatar seçimi izin gerektirmeyen sistem seçicisiyle yapılır — Play
incelemesinde en sık sorulan "neden depolama izni?" sorusu hiç doğmaz.

---

## 6. BÖLÜM 3 — BACKEND (API sözleşmesi)

### 6.1 Uçlar ve gereksinimleri

| Uç                    | Yöntem  | Kimlik         | Gereken değişken            | Yoksa              |
| --------------------- | ------- | -------------- | --------------------------- | ------------------ |
| `/api/health`         | GET     | —              | —                           | —                  |
| `/api/auth/register`  | POST    | —              | `DATABASE_URL`              | 500                |
| `/api/auth/login`     | POST    | —              | `DATABASE_URL`              | 500                |
| `/api/auth/me`        | GET     | Bearer         | `DATABASE_URL`              | 401                |
| `/api/auth/google`    | POST    | —              | `GOOGLE_SERVER_CLIENT_ID`   | **503**            |
| `/api/auth/forgot`    | POST    | —              | `RESEND_API_KEY`            | sessiz başarı      |
| `/api/purchases`      | GET     | Bearer         | `DATABASE_URL`              | 401                |
| `/api/iap/validate`   | POST    | Bearer         | `GOOGLE_PLAY_SA_JSON`       | **503** (üretimde) |
| `/api/iap/revenuecat` | POST    | Paylaşılan sır | `REVENUECAT_WEBHOOK_SECRET` | **503**            |
| `/api/ai/ask`         | POST    | —              | `ANTHROPIC_API_KEY`         | mock yanıt         |
| `/api/ai/ask/stream`  | POST    | —              | `ANTHROPIC_API_KEY`         | `streamed:false`   |
| `/api/community/*`    | çeşitli | Bearer         | `DATABASE_URL`              | 401                |

### 6.2 Hız sınırları

| Kova          | Sınır   | Uçlar                                                                        |
| ------------- | ------- | ---------------------------------------------------------------------------- |
| `auth-google` | 10 / dk | `/api/auth/google`                                                           |
| `ai`          | 20 / dk | `/api/ai/ask` **ve** `/api/ai/ask/stream` (aynı kova — akış sınırı atlatmaz) |
| `avatar`      | 6 / dk  | `/api/community/avatar`                                                      |

### 6.3 Oturum modeli

- Mobil: `Authorization: Bearer <token>`
- Web: `HttpOnly` çerez
- Jeton **sunucuda** saklanır (`sessions` tablosu) → uzaktan iptal edilebilir, çok cihaz destekli

### 6.4 Upload key üretimi (mobil imzalama)

Bu adım **backend değil mobil** ilgilendirir ama sıra burada gelir.

```bash
cd apps/mobile/android
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Sorulan bilgiler: ad, birim, kuruluş, şehir, il, ülke kodu (TR).

Sonra `apps/mobile/android/key.properties` dosyasını oluştur:

```properties
storePassword=<seçtiğin parola>
keyPassword=<seçtiğin parola>
keyAlias=upload
storeFile=upload-keystore.jks
```

> 🔴 **`key.properties` ve `.jks` dosyası ASLA depoya girmez.** `.gitignore` bunları kapsar.
> Kaybedersen **uygulamayı bir daha güncelleyemezsin** (Play App Signing kullanılıyorsa upload
> key sıfırlanabilir; yine de yedekle).

### 6.5 Parmak izlerini oku

```bash
keytool -list -v -keystore apps/mobile/android/upload-keystore.jks -alias upload
```

**Bu projede ölçülmüş değerler** (referans için):

| Anahtar              | SHA-1                                                         |
| -------------------- | ------------------------------------------------------------- |
| **Upload key**       | `7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57` |
| **Debug key**        | `20:AE:CA:91:98:1B:EE:12:3A:CD:0A:CE:54:9E:BA:7F:D0:A3:04:CF` |
| **Play App Signing** | _(Play Console'a ilk yüklemeden sonra görünür — §9.3.3)_      |

### 6.6 Derleme

```bash
cd apps/mobile
flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID=...
# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

### 6.7 İmzayı doğrula

```bash
jarsigner -verify -verbose:summary build/app/outputs/bundle/release/app-release.aab
```

Beklenen: **`jar verified.`**

> ⚠️ **`apksigner` bir AAB'yi doğrulayamaz.** AAB'ler v1/JAR imzalıdır; `apksigner` sessizce
> boş çıktı verir ve bu "imza yok" gibi okunur. AAB için **`jarsigner`**, APK için `apksigner`.
> Bu, Faz 4'te ölçülerek düzeltilmiş gerçek bir yanlış adımdır.
>
> `jarsigner`'ın "PKIX path building failed" uyarısı **beklenendir**: upload key kendinden
> imzalıdır.

---

## 7. BÖLÜM 4 — PLAY CONSOLE

### 7.1 Ön koşul

Google Play Console geliştirici hesabı (tek seferlik 25 USD). Hesap **doğrulanmış** olmalı;
2023 sonrası açılan bireysel hesaplarda kimlik doğrulama zorunludur ve **günler sürebilir**.

### 7.2 Uygulama oluşturma — düğme düğme

```
play.google.com/console
  → Tüm uygulamalar
  → Uygulama oluştur
      Uygulama adı:            Ehliyet Akademi
      Varsayılan dil:          Türkçe (tr-TR)
      Uygulama veya oyun:      Uygulama
      Ücretsiz veya ücretli:   Ücretsiz          ← uygulama-içi satın alma buna engel değildir
      Beyanlar:                ☑ Geliştirici Program Politikaları
                               ☑ ABD ihracat yasaları
  → Uygulama oluştur
```

### 7.3 Play App Signing — kritik kavram

```
  → Test ve yayınlama
  → Kurulum
  → Uygulama imzalama
```

Varsayılan olarak **Play App Signing açıktır** ve şunu yapar:

1. Sen AAB'yi **upload key** ile imzalarsın.
2. Play bu imzayı doğrular, sonra **kendi App Signing anahtarıyla yeniden imzalar**.
3. Kullanıcının cihazına giden APK, **Play'in anahtarıyla** imzalıdır.

> 🔴 **Bunun Google girişine etkisi:** Google Sign-In, uygulamanın **çalışma anındaki** imzasına
> bakar. Play'den inen yapı için bu **App Signing sertifikasıdır**, senin upload key'in değil.
> Bu SHA-1 için Google Cloud'da bir Android OAuth istemcisi yoksa
> **"debug'da çalışıyor, Play'den inende çalışmıyor"** durumu
> ortaya çıkar. → [§17.3 Belirti E](#belirti-e--debugda-çalışıyor-playden-inende-çalışmıyor)

**App Signing SHA-1'ini bulmak için** (ayrıntı: `GOOGLE_LOGIN_SETUP.md` §7.2):

```
  → Test ve yayınlama → Kurulum → Uygulama imzalama
  → "Uygulama imzalama anahtarı sertifikası" bölümü
  → SHA-1 sertifika parmak izi   ← bunu kopyala
```

> Bu ekran **ilk AAB yüklendikten sonra** dolar. Yani sıra zorunlu olarak şudur:
> AAB yükle → SHA-1'i al → **Google Cloud'da yeni Android OAuth istemcisi oluştur** →
> AAB'yi yeniden derle ve yükle.

### 7.4 Zorunlu beyanlar

```
  → Politika ve program
  → Uygulama içeriği
```

| Beyan                       | Bu projedeki cevap                                                   |
| --------------------------- | -------------------------------------------------------------------- |
| **Gizlilik politikası**     | `https://www.ehliyetegitim.com/gizlilik`                             |
| **Uygulama erişimi**        | "Tüm işlevler kısıtlama olmadan kullanılabilir" _(misafir modu var)_ |
| **Reklamlar**               | **Hayır**, uygulamada reklam yok                                     |
| **İçerik derecelendirmesi** | Anketi doldur → beklenen: **3+ / Everyone**                          |
| **Hedef kitle**             | 18+ (ehliyet yaşı) — çocuklara yönelik **değil**                     |
| **Veri Güvenliği**          | [§7.4.1](#741-veri-güvenliği-formu)                                  |
| **Yapay zekâ**              | Üretken AI **kullanılıyor** → beyan et                               |
| **Devlet uygulaması**       | **Hayır** — MEB/MTSK ile resmî bağ yoktur                            |

#### 7.4.1 Veri Güvenliği formu

| Soru                            | Cevap                                         | Gerekçe                 |
| ------------------------------- | --------------------------------------------- | ----------------------- |
| Veri topluyor musunuz?          | **Evet**                                      | E-posta, ad, ilerleme   |
| E-posta adresi                  | Toplanıyor · şifreli iletiliyor · silinebilir | Hesap için              |
| Ad                              | Toplanıyor · isteğe bağlı                     | Profil                  |
| Uygulama etkileşimleri          | Toplanıyor                                    | İlerleme ve öneriler    |
| Fotoğraflar                     | **Toplanıyor** (isteğe bağlı)                 | Yalnız topluluk avatarı |
| Konum                           | **Hayır**                                     |                         |
| Kişiler / SMS / Arama           | **Hayır**                                     |                         |
| Veriler şifreleniyor mu?        | **Evet** (HTTPS)                              |                         |
| Kullanıcı silme isteyebilir mi? | **Evet**                                      | `DELETE /api/account`   |

### 7.5 Uygulama-içi ürünler

```
  → Para kazanma
  → Ürünler
  → Uygulama içi ürünler        (tek seferlik satın almalar için)
  → Ürün oluştur
```

Ürün kimlikleri **koddaki katalogla birebir aynı** olmalıdır (`apps/web/lib/products.ts`):

| Ürün kimliği           | Başlık                    | Fiyat (₺) |
| ---------------------- | ------------------------- | --------- |
| `premium-teori`        | Premium Teori Paketi      | 249       |
| `premium-direksiyon`   | Premium Direksiyon Paketi | 199       |
| `simulator-paketi`     | Gelişmiş Simülatör Paketi | 149       |
| `premium-soru-bankasi` | Premium Soru Bankası      | —         |
| `komple-b`             | Komple B Paketi           | 449       |

> 🔴 **Kimlik uyuşmazlığı sessiz başarısızlık üretir:** Play'de `premium_teori` (alt çizgi)
> yazarsan, kod `premium-teori` (tire) arar, ürün bulunamaz ve paywall "Mağaza kullanılamıyor"
> gösterir. Kopyala-yapıştır yap, elle yazma.

Her ürün için:

```
  → Ürün kimliği:  premium-teori
  → Ad:            Premium Teori Paketi
  → Açıklama:      (mağazada görünür metin)
  → Fiyat ayarla → Türkiye → 249 TRY
  → Etkinleştir                    ← UNUTMA: oluşturmak yetmez, etkinleştirmek gerekir
```

### 7.6 AAB yükleme — kapalı test

```
  → Test ve yayınlama
  → Test
  → Kapalı test
  → Yeni sürüm oluştur
  → App bundle'ları
  → Yükle → app-release.aab
  → Sürüm adı:  1.0.0 (1)
  → Sürüm notları (tr-TR):
        İlk kapalı test sürümü.
  → Kaydet → Sürümü incele → Kapalı teste sun
```

### 7.7 Test kullanıcıları

```
  → Kapalı test → Test kullanıcıları sekmesi
  → E-posta listesi oluştur
  → Liste adı:  Beta 12
  → E-posta adreslerini yapıştır (virgülle veya satır satır)
  → Kaydet
  → Bağlantıyı kopyala            ← testçilere bu bağlantı gönderilir
```

> Test kullanıcısı bağlantıya tıklayıp **"Testçi ol"** demeden Play'de uygulamayı göremez.
> "Uygulama bulunamadı" şikâyetinin bir numaralı sebebi budur.

### 7.8 Lisans test hesapları (ücretsiz satın alma)

```
  → Play Console → Ayarlar (sol altta, dişli)
  → Lisans testi
  → Lisans testi yapan hesaplar: <test e-postaları>
  → Lisans yanıtı: RESPOND_NORMALLY
  → Kaydet
```

Bu hesaplar satın alma akışını **para ödemeden** uçtan uca test edebilir.

---

## 8. BÖLÜM 5 — GOOGLE GİRİŞİ ALTYAPISI (Firebase KULLANILMIYOR)

> **Bu proje Firebase kullanmaz.** Doğrulandı: `apps/mobile/android/` altındaki hiçbir Gradle
> dosyasında `com.google.gms.google-services` eklentisi uygulanmıyor; `google-services.json`
> derleme sırasında **hiç okunmuyor** ve silinebilir.
>
> Google girişi için gereken tek altyapı **Google Cloud Console**'dur.

### 8.1 Resmî kurulum belgesi

Google girişinin sıfırdan kurulumu ayrı ve **daha ayrıntılı** bir belgededir:

**→ [`GOOGLE_LOGIN_SETUP.md`](GOOGLE_LOGIN_SETUP.md)**

| Konu                                                                  | Orada hangi bölüm |
| --------------------------------------------------------------------- | ----------------- |
| Sorumluluk dağılımı (Cloud · Play · Flutter · Backend)                | §1                |
| OAuth izin ekranı · kapsamlar · yayınlama durumu · test kullanıcıları | §2                |
| **Web** OAuth istemcisi                                               | §2.3              |
| **Android** OAuth istemcisi · SHA-1 · hangi imza ne zaman             | §3                |
| Hangi istemci kimliği nereye gider (tablo)                            | §4                |
| Flutter `serverClientId` · dart-define · release/debug                | §5                |
| Backend doğrulaması · `aud` · oturum                                  | §6                |
| Play App Signing'in girişe etkisi                                     | §7                |
| Doğrulama kontrol listesi                                             | §8                |
| Sık yapılan hatalar (10 senaryo)                                      | §9                |

### 8.2 Bu el kitabındaki ilgili bölümler

- Google Cloud'un genel yapılandırması → [§9](#9-bölüm-6--google-cloud)
- Google giriş akışının uçtan uca izi ve sorun giderme → [§17](#17-google-login--uçtan-uca)
- `GOOGLE_SERVER_CLIENT_ID` değişkeninin tam referansı → [§16.3](#163--google_server_client_id)

## 9. BÖLÜM 6 — GOOGLE CLOUD

Google girişinin tüm kimlikleri burada yaşar. Sıfırdan kurulum için ayrıntılı belge:
[`GOOGLE_LOGIN_SETUP.md`](GOOGLE_LOGIN_SETUP.md).

### 9.1 OAuth onay ekranı (bir kez)

```
console.cloud.google.com
  → Proje seçici → ehliyet-akademi-3daa1
  → API'ler ve Hizmetler
  → OAuth izin ekranı
  → Kullanıcı türü:  Harici
  → Oluştur
      Uygulama adı:            Ehliyet Akademi
      Kullanıcı destek e-postası: <destek adresin>
      Uygulama logosu:         (isteğe bağlı)
      Uygulama ana sayfası:    https://www.ehliyetegitim.com
      Gizlilik politikası:     https://www.ehliyetegitim.com/gizlilik
      Kullanım şartları:       https://www.ehliyetegitim.com/kosullar
      Yetkili alan adları:     ehliyetegitim.com
      Geliştirici iletişim:    <e-postan>
  → Kaydet ve devam et
  → Kapsamlar: openid, email, profile   ← fazlasına GEREK YOK
  → Kaydet ve devam et
  → Test kullanıcıları: (yayınlanana kadar kendi hesabını ekle)
  → Kaydet ve devam et
```

> `openid`, `email`, `profile` dışında kapsam istersen Google **doğrulama süreci** başlatır ve
> bu haftalar sürebilir. Bu proje fazlasına ihtiyaç duymaz.

### 9.2 Web OAuth istemcisi 🔴 — sunucu doğrulamasının anahtarı

```
  → API'ler ve Hizmetler
  → Kimlik bilgileri
  → + KİMLİK BİLGİLERİ OLUŞTUR
  → OAuth istemci kimliği
  → Uygulama türü:  Web uygulaması
      Ad:  Ehliyet Akademi Web (sunucu doğrulama)
      Yetkili JavaScript kaynakları:
            https://www.ehliyetegitim.com
            http://localhost:3000              ← yerel geliştirme için
      Yetkili yönlendirme URI'leri:
            (BOŞ BIRAKILABİLİR — bu akışta yönlendirme kullanılmıyor)
  → Oluştur
  → "İstemci kimliği" değerini KOPYALA
        biçim: 430417XXXXXX-xxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

**Bu değer iki yere girilir:**

1. Vercel → `GOOGLE_SERVER_CLIENT_ID` (sunucu, ID token'ın `aud` alanını doğrular)
2. Flutter → `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` (istemci, `serverClientId` olarak)

> 🔴 **En sık yapılan hata:** buraya **Android** istemci kimliğini yazmak. Sonuç: `idToken`
> **null** döner ve giriş sessizce başarısız olur. Kod bunu yakalar ve
> _"Google kimliği alınamadı"_ mesajı gösterir.

### 9.3 Android OAuth istemcisi 🔴 — hesap seçicinin açılması için

Kullandığın **her imza için** bir tane oluşturulur (ayrıntı: `GOOGLE_LOGIN_SETUP.md` §3):

```
  → Kimlik bilgileri → + KİMLİK BİLGİLERİ OLUŞTUR → OAuth istemci kimliği
  → Uygulama türü:  Android
      Ad:                Ehliyet Akademi Android (upload)
      Paket adı:         com.ehliyetegitim.ehliyet_akademi
      SHA-1 sertifika parmak izi:  7E:1F:EA:...:73:57
  → Oluştur
```

**Kaç tane Android istemcisi gerekir?** Kullandığın **her imza için bir tane**:

| İmza             | Ne zaman gerekir                              |
| ---------------- | --------------------------------------------- |
| Debug            | `flutter run` ile test ederken                |
| Upload           | Sideload edilmiş release APK/AAB test ederken |
| Play App Signing | **Play'den inen tüm kullanıcılar için** 🔴    |

> Android istemci kimliği **hiçbir yere kopyalanmaz.** Varlığı yeterlidir; Google Play Services
> onu çalışma anında paket adı + imzaya bakarak bulur.

### 9.4 Play Android Developer API (satın alma doğrulaması için)

```
  → API'ler ve Hizmetler → Kütüphane
  → "Google Play Android Developer API" ara
  → Etkinleştir
```

### 9.5 Servis hesabı (`GOOGLE_PLAY_SA_JSON`)

```
  → IAM ve Yönetici → Hizmet hesapları
  → + HİZMET HESABI OLUŞTUR
      Ad:  play-purchase-verifier
  → Oluştur ve devam et → Rol: (boş bırakılabilir) → Bitti
  → Oluşturulan hesaba tıkla → Anahtarlar sekmesi
  → Anahtar ekle → Yeni anahtar oluştur → JSON → Oluştur
        (JSON dosyası indirilir — BİR KEZ indirilebilir, kaybetme)
```

Sonra Play Console'da yetkilendir:

```
Play Console → Ayarlar → API erişimi
  → Google Cloud projesini bağla:  ehliyet-akademi-3daa1
  → Hizmet hesapları listesinde play-purchase-verifier'ı bul
  → Erişim ver
  → İzinler:  ☑ Finansal verileri görüntüle
              ☑ Sipariş ve abonelikleri yönet
  → Kullanıcıyı davet et / Değişiklikleri kaydet
```

JSON'u **tek satıra sıkıştırıp** Vercel'e gir:

```bash
python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1]))))" indirilen.json
```

---

## 10. BÖLÜM 7 — REVENUECAT

> **RevenueCat İSTEĞE BAĞLIDIR.** Kurulmazsa uygulama `in_app_purchase` yolundan satın almayı
> destekler. Bu bölüm yalnız RevenueCat kullanacaksan gereklidir.

### 10.1 Neden ayrı bir sunucu köprüsü gerekiyor

RevenueCat'in Flutter SDK'sı ham Play `purchaseToken`'ını **sunmaz** — `StoreTransaction`
yalnız `transactionIdentifier` taşır. Bu yüzden RevenueCat yolu mevcut `/api/iap/validate`
ucunu **kullanamaz**. Doğru köprü **webhook**'tur: RevenueCat → bizim sunucumuz.

Bu, kodda `BillingServerBridge.revenueCatWebhook` olarak açıkça bildirilir.

### 10.2 Hesap ve proje

```
app.revenuecat.com
  → Sign up
  → Create new project
      Project name:  Ehliyet Akademi
  → Create project
```

### 10.3 Android uygulamasını ekle

```
  → Project settings → Apps
  → + New app
  → Platform:  Google Play Store
      App name:      Ehliyet Akademi
      Package name:  com.ehliyetegitim.ehliyet_akademi
  → Service Account credentials JSON:  <§9.5'te indirdiğin JSON'u yükle>
  → Save
```

> RevenueCat, Play ile konuşabilmek için **aynı servis hesabı JSON'unu** kullanır.
> "Play Store credentials not valid" hatası alıyorsan §9.5'teki izinleri kontrol et.

### 10.4 API anahtarı

```
  → Project settings → API keys
  → "Public app-specific API key"  (Google Play satırı)
  → Kopyala → biçim: goog_XXXXXXXXXXXXXXXX
```

Bu değer `--dart-define=REVENUECAT_PUBLIC_KEY=goog_...` olarak **derlemeye** girer.

> ⚠️ **Secret key'i ASLA uygulamaya koyma.** Public (`goog_`) anahtar istemci içindir;
> secret anahtar yalnız sunucu içindir ve bu projede kullanılmaz.

### 10.5 Entitlement — uygulamanın sorduğu TEK yetki

```
  → Product catalog → Entitlements
  → + New
      Identifier:   premium         ← koddaki varsayılanla AYNI olmalı
      Description:  Premium erişim
  → Add
```

> Kod `REVENUECAT_ENTITLEMENT` (varsayılan `premium`) adlı **tek** yetkiyi sorar. Ömür boyu
> paket de, aylık/yıllık abonelik de aynı yetkiyi açar; böylece ürün modeli değişse bile
> uygulama kodu değişmez.

### 10.6 Ürünleri bağla

```
  → Product catalog → Products
  → + New
      Store:        Play Store
      Identifier:   <Play Console'daki ürün kimliği>
  → Add
  → Ürüne tıkla → Attach to entitlement → premium
```

### 10.7 Offering (paketleme)

```
  → Product catalog → Offerings
  → + New
      Identifier:  default          ← SDK varsayılan olarak bunu ister
  → Add
  → Offering'e tıkla → + New package
      Identifier:  $rc_monthly   → ürünü seç
      Identifier:  $rc_annual    → ürünü seç
```

### 10.8 Webhook 🔴

```
  → Project settings → Integrations
  → + New → Webhooks
      Webhook URL:    https://www.ehliyetegitim.com/api/iap/revenuecat
      Authorization header value:  <güçlü rastgele bir sır üret>
      Event types:    ☑ Initial purchase
                      ☑ Renewal
                      ☑ Non renewing purchase
                      ☑ Product change
                      ☑ Uncancellation
  → Save
```

Sır üretmek için:

```bash
openssl rand -hex 32
```

Aynı değeri Vercel'e `REVENUECAT_WEBHOOK_SECRET` olarak gir.

### 10.9 Webhook güvenlik davranışı (kodda uygulanmış)

| Durum                           | Davranış                                        |
| ------------------------------- | ----------------------------------------------- |
| `REVENUECAT_WEBHOOK_SECRET` yok | **503** — hiçbir şey yazılmaz (**fail-closed**) |
| `Authorization` başlığı yok     | **401**                                         |
| Yanlış sır                      | **401** (sabit zamanlı karşılaştırma)           |
| `sha256=<hmac>` biçimi          | Kabul edilir, gövde üzerinden doğrulanır        |
| Aynı olay iki kez               | **Idempotent** — kopya sahiplik oluşmaz         |
| `CANCELLATION` / `EXPIRATION`   | Sahiplik üretmez ama **200** döner              |
| Bilinmeyen ürün / kullanıcı     | Yazmaz, **200** döner                           |

> **Neden "yok sayıldı" da 200 döner?** RevenueCat 2xx almazsa saatlerce yeniden dener.
> 4xx dönmek, bizim ilgilenmediğimiz bir olay için RevenueCat'i sonsuz döngüye sokardı.

### 10.10 Doğrulama

```bash
# 1) Sır ayarlı mı? (503 = ayarlı değil)
curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  https://www.ehliyetegitim.com/api/iap/revenuecat \
  -H 'content-type: application/json' -d '{}'

# 2) Sır ayarlıysa, yanlış sırla 401 dönmeli
curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  https://www.ehliyetegitim.com/api/iap/revenuecat \
  -H 'content-type: application/json' -H 'authorization: Bearer yanlis' -d '{}'
```

RevenueCat panosunda: `Integrations → Webhooks → Send test event` → **200** beklenir.

---

## 11. BÖLÜM 8 — VERCEL

### 11.1 Proje oluşturma

```
vercel.com
  → Add New → Project
  → Import Git Repository → <depo>
  → Framework Preset:   Next.js          (otomatik algılanır)
  → Root Directory:     apps/web         ← MONOREPO İÇİN ŞART
  → Build Command:      (varsayılan bırak)
  → Install Command:    pnpm install
  → Deploy
```

> 🔴 **Root Directory `apps/web` olmalı.** Depo kökü bırakılırsa Vercel Next.js'i bulamaz ve
> derleme "No Next.js version detected" ile başarısız olur.

### 11.2 Ortam değişkenlerini girme

```
  → Project → Settings → Environment Variables
  → Key:    DATABASE_URL
  → Value:  postgresql://...
  → Environments:  ☑ Production  ☑ Preview  ☑ Development
  → Save
```

Her değişken için tekrarla. Tam liste: [§16](#16-ortam-değişkenleri--tam-referans).

> ⚠️ **Değişken ekledikten sonra yeniden dağıtım gerekir.** Vercel ortam değişkenlerini
> derleme zamanında gömer; mevcut dağıtım eski değerlerle çalışmaya devam eder.
>
> ```
>   → Deployments → (en üstteki) → ⋯ → Redeploy
> ```

### 11.3 Alan adı

```
  → Project → Settings → Domains
  → Add → www.ehliyetegitim.com
  → DNS kayıtlarını alan adı sağlayıcında oluştur (Vercel gösterir)
  → ehliyetegitim.com → www'ye yönlendir (Redirect to www)
```

### 11.4 Otomatik dağıtım

`main` dalına her push → üretim dağıtımı. Bu projede doğrulandı: Faz 9/13 uçları push'tan
birkaç dakika sonra üretimde çalışır durumdaydı.

### 11.5 Günlükler

```
  → Project → Deployments → (dağıtıma tıkla) → Runtime Logs
```

Aranacak etiketler (kod bunları üretir):

| Etiket               | Anlamı                                        |
| -------------------- | --------------------------------------------- |
| `ai_model_fallback`  | Anthropic çağrısı başarısız, mock'a düşüldü   |
| `ai_stream_fallback` | Akış kurulamadı, tek parçaya düşüldü          |
| `ai_stream_broken`   | Akış ortada koptu                             |
| `ai_domain_fallback` | Kapsam dışı soru için model çağrısı başarısız |

### 11.6 Dağıtım doğrulaması

```bash
curl -s https://www.ehliyetegitim.com/api/health
```

| Alan       | Beklenen       | Değilse                        |
| ---------- | -------------- | ------------------------------ |
| `status`   | `ok`           | Dağıtım başarısız              |
| `db`       | `configured`   | `DATABASE_URL` eksik/yanlış    |
| `email`    | `resend`       | `RESEND_API_KEY` eksik         |
| `payments` | `lemonsqueezy` | LemonSqueezy anahtarları eksik |

---

## 12. BÖLÜM 9 — VERİTABANI (Neon PostgreSQL)

### 12.1 Proje oluşturma

```
console.neon.tech
  → New Project
      Project name:  ehliyet-akademi
      Postgres version:  16 (veya güncel)
      Region:  Europe (Frankfurt)     ← Türkiye kullanıcılarına en yakın
  → Create project
```

### 12.2 Bağlantı dizesini alma

```
  → Project → Dashboard → Connection Details
  → Connection string → "Pooled connection" seç
  → Kopyala
        postgresql://<user>:<pass>@<host>-pooler.<region>.aws.neon.tech/<db>?sslmode=require
```

> **Pooled** sürümü kullan. Vercel sunucusuz işlevleri her istekte yeni bağlantı açar;
> havuzsuz bağlantı hızla tükenir ("too many connections").

### 12.3 Şema

Şema `packages/db/src/schema.ts` içinde **Drizzle** ile tanımlıdır. Uygulama başlatıldığında
gerekli tablolar oluşturulur.

**Ölçülmüş tablo listesi (25):**

```
users · sessions · email_verification_tokens · password_reset_tokens
purchases · user_state · audit_logs
content_items · content_versions · media_assets
community_profiles · community_stats · community_achievements · community_blocks
community_reports · discussion_threads · discussion_posts · direct_messages
friendships · study_groups · study_group_members
challenges · challenge_progress · leaderboard_snapshots · question_reports
```

### 12.4 Yerel geliştirmede veritabanı

Testler **PGlite** (bellek içi) kullanır — gerçek bir veritabanı gerekmez:

```bash
pnpm test    # DATABASE_URL olmadan da çalışır
```

### 12.5 Üretim verisi hijyeni

Test/E2E artıkları zamanla birikir. Temizlik betiği **varsayılan olarak kuru çalıştırmadır**:

```bash
node scripts/db-cleanup.mjs                   # yalnız sayar, SİLMEZ
BACKUP_PATH=/güvenli/yol.json node scripts/db-cleanup.mjs --apply
```

> 🔴 **Betiğin dışlama kuralı bir tercih değil, zorunluluktur.** `content_items.created_by`,
> `content_versions.changed_by`, `media_assets.created_by` ve `audit_logs.user_id` yabancı
> anahtarları **`NO ACTION`**'dır. Bu referanslara sahip hesaplar silinemez — silinirse üretim
> içeriği ve denetim kayıtları öksüz kalır. Ayrıntı: `DATABASE_CLEANUP_REPORT.md`.

### 12.6 Yedekleme ve geri dönüş

Neon **point-in-time restore** sunar:

```
  → Project → Branches → main → Restore
  → Zaman noktası seç → Restore
```

Bu, uygulama seviyesindeki JSON yedeklerinden **daha güvenilirdir**.

---

## 13. BÖLÜM 10 — E-POSTA (Resend)

### 13.1 Hesap ve alan adı

```
resend.com
  → Sign up
  → Domains → Add Domain
      Domain:  ehliyetegitim.com
  → Gösterilen DNS kayıtlarını (SPF, DKIM) alan adı sağlayıcında oluştur
  → Verify
```

> Alan adı doğrulanmadan gönderim yapılamaz (yalnız Resend'in test adresine).

### 13.2 API anahtarı

```
  → API Keys → Create API Key
      Name:        ehliyet-akademi-prod
      Permission:  Sending access
      Domain:      ehliyetegitim.com
  → Add
  → Kopyala (biçim: re_XXXXXXXX)    ← BİR KEZ gösterilir
```

### 13.3 Değişkenler

| Değişken         | Örnek                                         |
| ---------------- | --------------------------------------------- |
| `RESEND_API_KEY` | `re_XXXXXXXX`                                 |
| `EMAIL_FROM`     | `Ehliyet Akademi <noreply@ehliyetegitim.com>` |

> `EMAIL_FROM` alan adı **doğrulanmış alan adıyla aynı** olmalıdır; farklıysa Resend 403 döner
> ve e-postalar sessizce gitmez.

### 13.4 Hangi e-postalar gönderiliyor

| Tetikleyici    | Uç                                          |
| -------------- | ------------------------------------------- |
| Kayıt          | `/api/auth/register` → doğrulama bağlantısı |
| Parola unuttum | `/api/auth/forgot` → sıfırlama bağlantısı   |
| Satın alma     | `/api/iap/validate` → onay e-postası        |

### 13.5 Doğrulama

```bash
curl -s https://www.ehliyetegitim.com/api/health | grep -o '"email":"[a-z]*"'
# Beklenen: "email":"resend"      ("email":"noop" → anahtar yok)
```

---

## 14. BÖLÜM 11 — AI (Anthropic)

### 14.1 Anahtar alma

```
console.anthropic.com
  → Settings → API Keys
  → Create Key
      Name:  ehliyet-akademi-prod
  → Kopyala (biçim: sk-ant-XXXXXXXX)
```

### 14.2 Değişkenler

| Değişken            | Varsayılan                  | Not                                |
| ------------------- | --------------------------- | ---------------------------------- |
| `ANTHROPIC_API_KEY` | —                           | Yoksa AI yalnız içerikten besteler |
| `ANTHROPIC_MODEL`   | `claude-haiku-4-5-20251001` | Değiştirmeye gerek yok             |

### 14.3 Mimari — halüsinasyon kapısı

1. **RETRIEVAL** — soru platformun kendi içeriğine eşlenir.
2. **KAPI** — eşleşme yoksa ve model yapılandırılmamışsa model **çağrılmaz**, dürüstçe reddedilir.
3. **MODEL** — sistem promptu modeli yalnız verilen bağlama zorlar.
4. **FALLBACK** — model hatası → mock kompozisyonu (asla kırılmaz).
5. **UYARI** — her yanıtın sonuna kalıcı MEB/MTSK uyarısı eklenir.

### 14.4 Akan (streaming) yanıt

`/api/ai/ask/stream` gerçek SSE akışı sağlar. **Sahte akış üretilmez**: yanıt tek parça
geldiyse olay `streamed: false` bildirir ve istemci metni olduğu gibi çizer.

**Ölçülmüş başarım:** 22 parça · ilk parça **0,64 s** · tam yanıt 4,94 s.

### 14.5 Doğrulama

```bash
curl -s -N -X POST https://www.ehliyetegitim.com/api/ai/ask/stream \
  -H 'content-type: application/json' \
  -d '{"question":"Kırmızı ışıkta ne yapmalıyım?"}' | head -5
```

| Görülen                                | Anlamı                                             |
| -------------------------------------- | -------------------------------------------------- |
| `"streamed":true` + çok sayıda `delta` | ✅ Gerçek akış çalışıyor                           |
| `"streamed":false` + tek `delta`       | ⚠️ `ANTHROPIC_API_KEY` yok ya da model hata verdi  |
| `"model":"gate"`                       | Soru içerikle eşleşmedi ve model yapılandırılmamış |

---

## 15. BÖLÜM 12 — ANALİTİK

Tamamı **isteğe bağlıdır**; hiçbiri kurulmasa uygulama tam çalışır.

| Değişken                                               | Servis             | Nereden                                                                    |
| ------------------------------------------------------ | ------------------ | -------------------------------------------------------------------------- |
| `NEXT_PUBLIC_GA_ID`                                    | Google Analytics 4 | analytics.google.com → Yönetici → Veri akışları → Ölçüm kimliği (`G-XXXX`) |
| `NEXT_PUBLIC_POSTHOG_KEY` · `NEXT_PUBLIC_POSTHOG_HOST` | PostHog            | app.posthog.com → Project settings → Project API Key                       |
| `NEXT_PUBLIC_CLARITY_ID`                               | Microsoft Clarity  | clarity.microsoft.com → Settings → Setup                                   |
| `SENTRY_DSN`                                           | Sentry             | sentry.io → Project → Settings → Client Keys (DSN)                         |
| `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION`                 | Search Console     | search.google.com/search-console → HTML etiketi yöntemi                    |
| `NEXT_PUBLIC_BING_VERIFICATION`                        | Bing Webmaster     | bing.com/webmasters                                                        |
| `NEXT_PUBLIC_YANDEX_VERIFICATION`                      | Yandex Webmaster   | webmaster.yandex.com                                                       |
| `INDEXNOW_KEY`                                         | IndexNow           | Rastgele üretilir; `/public` altına aynı adla dosya konur                  |

> `NEXT_PUBLIC_` öneki olan her değer **tarayıcıya gönderilir**. Gizli bir şey koyma.

---

## 16. ORTAM DEĞİŞKENLERİ — TAM REFERANS

> Bu bölüm liste değildir; her değişken **açıklanır**. Bir değişkeni anlamadan üretime girme.

### 16.1 Nasıl okunur

Her kayıt şu alanları içerir: amaç · zorunlu mu · servis · nereden alınır · tam ekran yolu ·
örnek · nerede saklanır · kim okur · ne zaman yüklenir · çalışma/derleme zamanı · nasıl
doğrulanır · nasıl döndürülür · yoksa ne olur · nasıl hata ayıklanır.

---

### 16.2 🔴 `DATABASE_URL`

| Alan                | Değer                                                                                                               |
| ------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Amaç**            | PostgreSQL bağlantısı — hesaplar, ilerleme, satın almalar, topluluk                                                 |
| **Zorunlu**         | 🔴 Evet — bunsuz hiçbir kalıcı özellik çalışmaz                                                                     |
| **Servis**          | Neon                                                                                                                |
| **Nereden**         | console.neon.tech → Project → Dashboard → Connection Details → **Pooled connection**                                |
| **Örnek**           | `postgresql://user:pass@ep-xxx-pooler.eu-central-1.aws.neon.tech/neondb?sslmode=require`                            |
| **Nerede saklanır** | Vercel (Production+Preview+Development) · yerelde `apps/web/.env.local`                                             |
| **Kim okur**        | `packages/db/src/index.ts` → `getDb()`                                                                              |
| **Ne zaman**        | İlk DB erişiminde (lazy)                                                                                            |
| **Zaman türü**      | **Çalışma zamanı**                                                                                                  |
| **Doğrulama**       | `curl .../api/health` → `"db":"configured"`                                                                         |
| **Döndürme**        | Neon → Roles → Reset password → yeni dizeyi Vercel'e gir → **Redeploy**                                             |
| **Yoksa**           | Tüm DB uçları 500; `/api/health` `"db":"missing"`                                                                   |
| **Hata ayıklama**   | Vercel Runtime Logs'ta `connection refused` / `too many connections` ara. İkincisi → **pooled** dize kullanmıyorsun |

---

### 16.3 🔴 `GOOGLE_SERVER_CLIENT_ID`

| Alan                | Değer                                                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Amaç**            | Google ID token'ının `aud` (audience) alanını doğrulamak; mobilde `serverClientId`                                                      |
| **Zorunlu**         | 🔴 Google girişi için evet                                                                                                              |
| **Servis**          | Google Cloud Console                                                                                                                    |
| **Nereden**         | console.cloud.google.com → API'ler ve Hizmetler → Kimlik bilgileri → OAuth 2.0 İstemci Kimlikleri → **Web istemcisi** → İstemci Kimliği |
| **Tam yol**         | `Kimlik bilgileri → + KİMLİK BİLGİLERİ OLUŞTUR → OAuth istemci kimliği → Uygulama türü: Web uygulaması → Oluştur`                       |
| **Örnek**           | `430417000000-abc123def456.apps.googleusercontent.com`                                                                                  |
| **Nerede saklanır** | **İKİ YERDE**: Vercel değişkeni **ve** Flutter `--dart-define`                                                                          |
| **Kim okur**        | Sunucu: `app/api/auth/google/route.ts` · Mobil: `GoogleSignInServiceImpl`                                                               |
| **Ne zaman**        | Sunucu: her istekte · Mobil: **derleme anında gömülür**                                                                                 |
| **Zaman türü**      | Sunucu **çalışma**, mobil **derleme**                                                                                                   |
| **Doğrulama**       | Sunucu: `POST /api/auth/google` geçersiz token → **401** (ayarlı) / **503** (ayarsız). Mobil: Google düğmesi görünüyorsa gömülmüş       |
| **Döndürme**        | Yeni Web istemcisi oluştur → her iki yeri güncelle → Vercel redeploy **+ yeni AAB derle**                                               |
| **Yoksa**           | Sunucu 503 · mobilde düğme **hiç görünmez** (çökme yok)                                                                                 |
| **Hata ayıklama**   | [§17.3](#173-sorun-giderme--belirtiden-nedene)                                                                                          |

> 🔴 **ANDROID istemci kimliğini buraya yazma.** Sonuç: `idToken` null döner, giriş sessizce
> başarısız olur. **Web** istemcisi kullanılır.

---

### 16.4 🔴 `RESEND_API_KEY` + `EMAIL_FROM`

| Alan                | Değer                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------- |
| **Amaç**            | Doğrulama ve parola sıfırlama e-postaları                                                            |
| **Zorunlu**         | 🔴 Evet (hesap doğrulama akışı için)                                                                 |
| **Servis**          | Resend                                                                                               |
| **Nereden**         | resend.com → API Keys → Create API Key → Sending access                                              |
| **Örnek**           | `re_ABC123...` · `Ehliyet Akademi <noreply@ehliyetegitim.com>`                                       |
| **Nerede saklanır** | Vercel                                                                                               |
| **Kim okur**        | `lib/server/email.ts` → `getEmailProvider()`                                                         |
| **Zaman türü**      | Çalışma zamanı                                                                                       |
| **Doğrulama**       | `/api/health` → `"email":"resend"`                                                                   |
| **Döndürme**        | Resend → API Keys → eskisini sil, yenisini oluştur → Vercel → Redeploy                               |
| **Yoksa**           | `"email":"noop"` — e-posta gönderilmez, akış **hata vermez** (kullanıcı doğrulama bağlantısı alamaz) |
| **Hata ayıklama**   | Resend → Logs → gönderim denemelerini gör. 403 → `EMAIL_FROM` alan adı doğrulanmamış                 |

---

### 16.5 🟠 `GOOGLE_PLAY_SA_JSON`

| Alan                | Değer                                                                                              |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| **Amaç**            | Play satın alma token'ını sunucuda doğrulamak (androidpublisher API)                               |
| **Zorunlu**         | 🟠 Üretimde satın alma için evet                                                                   |
| **Servis**          | Google Cloud + Play Console                                                                        |
| **Nereden**         | Google Cloud → IAM → Hizmet hesapları → Anahtarlar → JSON                                          |
| **Yetkilendirme**   | Play Console → Ayarlar → API erişimi → hizmet hesabına erişim ver                                  |
| **Örnek**           | `{"type":"service_account","project_id":"...",...}` (tek satır)                                    |
| **Nerede saklanır** | Vercel — **`NEXT_PUBLIC_` öneki ASLA verilmez**                                                    |
| **Kim okur**        | `app/api/iap/validate/route.ts`                                                                    |
| **Zaman türü**      | Çalışma zamanı                                                                                     |
| **Doğrulama**       | Oturumlu `POST /api/iap/validate` → 503 dönmüyorsa ayarlı                                          |
| **Döndürme**        | Yeni JSON anahtarı oluştur → Vercel → Redeploy → eski anahtarı sil                                 |
| **Yoksa**           | Üretimde grant **reddedilir** (fail-closed, 503). Geliştirmede `IAP_DEV_ACCEPT=1` ile kabul edilir |
| **Hata ayıklama**   | JSON tek satır mı? Satır sonları varsa `JSON.parse` patlar                                         |

---

### 16.6 🟡 `REVENUECAT_WEBHOOK_SECRET`

| Alan                | Değer                                                                                            |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| **Amaç**            | RevenueCat webhook'unun kimliğini doğrulamak                                                     |
| **Zorunlu**         | 🟡 Yalnız RevenueCat kullanılıyorsa                                                              |
| **Servis**          | RevenueCat                                                                                       |
| **Nereden**         | app.revenuecat.com → Project settings → Integrations → Webhooks → **Authorization header value** |
| **Üretme**          | `openssl rand -hex 32`                                                                           |
| **Nerede saklanır** | Vercel **ve** RevenueCat panosu (aynı değer)                                                     |
| **Kim okur**        | `app/api/iap/revenuecat/route.ts`                                                                |
| **Zaman türü**      | Çalışma zamanı                                                                                   |
| **Doğrulama**       | `POST /api/iap/revenuecat` → 503 (ayarsız) / 401 (ayarlı, yanlış sır)                            |
| **Döndürme**        | Yeni sır üret → önce Vercel'e gir + redeploy → sonra RevenueCat panosunu güncelle                |
| **Yoksa**           | Uç **503** döner ve **hiçbir sahiplik yazmaz** (bilinçli fail-closed)                            |
| **Hata ayıklama**   | RevenueCat → Integrations → Webhooks → **Delivery logs**                                         |

---

### 16.7 🟡 `REVENUECAT_PUBLIC_KEY`

| Alan                | Değer                                                                                |
| ------------------- | ------------------------------------------------------------------------------------ |
| **Amaç**            | RevenueCat SDK'sını başlatmak                                                        |
| **Zorunlu**         | 🟡 Hayır — verilmezse `in_app_purchase` yolu kullanılır                              |
| **Nereden**         | RevenueCat → Project settings → API keys → **Public app-specific key (Google Play)** |
| **Örnek**           | `goog_ABCDEFGHIJKLMNOP`                                                              |
| **Nerede saklanır** | Flutter `--dart-define`                                                              |
| **Zaman türü**      | **Derleme zamanı**                                                                   |
| **Doğrulama**       | Uygulamada satın alma ekranında ürünler görünüyorsa aktif                            |
| **Yoksa**           | `RevenueCatGateway.isConfigured` false → `PlayBillingGateway` seçilir                |
| **Hata ayıklama**   | RevenueCat → Customer history → cihaz görünüyor mu                                   |

> **Secret key'i (`sk_`) ASLA uygulamaya koyma.**

---

### 16.8 🟠 `ANTHROPIC_API_KEY` / ⚪ `ANTHROPIC_MODEL`

| Alan                | Değer                                                            |
| ------------------- | ---------------------------------------------------------------- |
| **Amaç**            | AI Koç serbest yanıtları ve akış                                 |
| **Zorunlu**         | 🟠 AI özelliği için                                              |
| **Nereden**         | console.anthropic.com → Settings → API Keys → Create Key         |
| **Örnek**           | `sk-ant-api03-...` · `claude-haiku-4-5-20251001`                 |
| **Nerede saklanır** | Vercel                                                           |
| **Kim okur**        | `lib/server/ai.ts`                                               |
| **Zaman türü**      | Çalışma zamanı                                                   |
| **Doğrulama**       | `/api/ai/ask/stream` → `"streamed":true`                         |
| **Döndürme**        | Console'dan yeni anahtar → Vercel → Redeploy → eskisini iptal et |
| **Yoksa**           | Yanıtlar mock kompozisyonuna düşer; akış `streamed:false`        |
| **Hata ayıklama**   | Vercel Runtime Logs → `ai_model_fallback` / `ai_stream_fallback` |

---

### 16.9 🔴 `NEXT_PUBLIC_SITE_URL`

| Alan           | Değer                                                                      |
| -------------- | -------------------------------------------------------------------------- |
| **Amaç**       | E-postadaki ve SEO'daki **mutlak** bağlantılar                             |
| **Zorunlu**    | 🔴 Evet                                                                    |
| **Örnek**      | `https://www.ehliyetegitim.com` — **sonda `/` YOK**                        |
| **Zaman türü** | **Derleme zamanı** (`NEXT_PUBLIC_` istemciye gömülür)                      |
| **Doğrulama**  | Doğrulama e-postasındaki bağlantıya tıkla; doğru alana gitmeli             |
| **Yoksa**      | E-posta bağlantıları `localhost`'a gider — kullanıcı hesabını doğrulayamaz |

---

### 16.10 🟠 LemonSqueezy üçlüsü

`LEMONSQUEEZY_API_KEY` · `LEMONSQUEEZY_STORE_ID` · `LEMONSQUEEZY_WEBHOOK_SECRET`

| Alan          | Değer                                                                           |
| ------------- | ------------------------------------------------------------------------------- |
| **Amaç**      | **Web** ödemesi (mobil değil)                                                   |
| **Nereden**   | app.lemonsqueezy.com → Settings → API                                           |
| **Webhook**   | Settings → Webhooks → `https://www.ehliyetegitim.com/api/webhooks/lemonsqueezy` |
| **Doğrulama** | `/api/health` → `"payments":"lemonsqueezy"`                                     |
| **Yoksa**     | Web'de ödeme yüzeyi kapanır; mobil satın alma etkilenmez                        |

---

### 16.11 ⚪ `ADMIN_EMAILS` / `ADMIN_EMAIL_PATTERN`

| Alan         | Değer                                                 |
| ------------ | ----------------------------------------------------- |
| **Amaç**     | Yönetim panelinin kime açık olduğu                    |
| **Örnek**    | `ADMIN_EMAILS=sahip@ornek.com,editor@ornek.com`       |
| **Yoksa**    | İlk kullanıcı yönetici sayılır (geliştirme kolaylığı) |
| **Güvenlik** | Üretimde **mutlaka açıkça ayarla**                    |

---

### 16.12 ⛔ Üretimde ASLA ayarlanmaması gerekenler

| Değişken                | Neden tehlikeli                                                |
| ----------------------- | -------------------------------------------------------------- |
| `IAP_DEV_ACCEPT=1`      | Play doğrulaması olmadan **herkes kendine premium verebilir**  |
| `RATE_LIMIT_DISABLED=1` | Kaba kuvvet ve maliyet saldırılarına kapıyı açar               |
| `PGLITE_DIR`            | Testler içindir; üretimde veritabanını yanlış yere yönlendirir |

---

### 16.13 Kullanılmayanlar (temizlenebilir)

`OPENAI_API_KEY` · `KIMI_API_KEY` · `NEON_AUTH_BASE_URL` · `VITE_NEON_AUTH_URL` ·
`NEON_PROJECT_ID` · `POSTGRES_*` · `PGHOST*` · `PGUSER` · `PGPASSWORD` ·
`DATABASE_URL_UNPOOLED` · `VERCEL_OIDC_TOKEN`

Kod bunların hiçbirini okumaz. Duran her gizli değer bir sızıntı yüzeyidir.

### 16.14 ⚠️ Ölçülmüş biçim tuzağı

`.env` ve `apps/web/.env.local` içinde iki anahtar **eşittirden önce boşlukla** yazılmış:

```
OPENAI_API_KEY ="sk-..."          ← DİKKAT: boşluk
GOOGLE_SERVER_CLIENT_ID ="4304..."
```

`dotenv` bunu tolere eder, ama `source .env` **etmez** ve değişken tanımsız kalır.
Doğrusu boşluksuzdur:

```
GOOGLE_SERVER_CLIENT_ID=4304...
```

---

## 17. GOOGLE LOGIN — UÇTAN UCA

### 17.1 Tam zincir

```
[1]  Kullanıcı "Google ile devam et" düğmesini görür
       ↑ KOŞUL: GoogleAuthService.isConfigured == true
       ↑ yani --dart-define=GOOGLE_SERVER_CLIENT_ID BOŞ DEĞİL
       ↓
[2]  Düğmeye dokunur → GoogleSignInServiceImpl.signIn()
       ↓
[3]  GoogleSignIn.instance.initialize(serverClientId: <WEB istemci kimliği>)
       ↑ BAĞIMLILIK: Google Play Services cihazda kurulu ve güncel
       ↓
[4]  supportsAuthenticate() kontrolü
       ↑ false → "Bu cihazda Google ile giriş desteklenmiyor."
       ↓
[5]  GoogleSignIn.instance.authenticate()  → hesap seçici açılır
       ↑ BAĞIMLILIK: Google Cloud'da ANDROID OAuth istemcisi VAR
       ↑            + paket adı eşleşiyor + çalışan imzanın SHA-1'i kayıtlı
       ↑ yoksa → hesap seçici açılır ve HEMEN kapanır (DEVELOPER_ERROR)
       ↓
[6]  account.authentication.idToken
       ↑ null ise → "Google kimliği alınamadı."
       ↑ EN SIK NEDEN: serverClientId olarak ANDROID istemci kimliği verilmiş
       ↓
[7]  POST /api/auth/google  { idToken }
       ↓
[8]  Sunucu: process.env.GOOGLE_SERVER_CLIENT_ID okunur
       ↑ boşsa → 503 "Google ile giriş bu sunucuda yapılandırılmadı."
       ↓
[9]  decodeJwtUnsafe(idToken) → header.kid + claims
       ↑ bozuksa → 401
       ↓
[10] GET https://www.googleapis.com/oauth2/v3/certs   (JWKS, 1 saat önbellekli)
       ↑ ulaşılamıyorsa → 503 (doğrulanmamış token ASLA kabul edilmez)
       ↓
[11] RS256 imza doğrulaması (kid ile eşleşen anahtar)
       ↓
[12] verifyGoogleClaims: iss · aud · exp · email_verified
       ↑ aud ≠ GOOGLE_SERVER_CLIENT_ID → 401
       ↑ email_verified false → 401
       ↓
[13] Kullanıcı arama (e-posta ile)
       ├─ VARSA  → HESAP BİRLEŞTİRME (aynı hesap, ilerleme korunur)
       └─ YOKSA  → yeni kullanıcı, passwordHash='google$no-password', emailVerified=true
       ↓
[14] createSession() → Bearer jetonu
       ↓
[15] Mobil jetonu saklar → oturum açık
```

### 17.2 Her adımın bağımlılıkları

| Adım | Bağımlılık                                 | Nerede yapılandırılır                                                             |
| ---- | ------------------------------------------ | --------------------------------------------------------------------------------- |
| 1    | `--dart-define=GOOGLE_SERVER_CLIENT_ID`    | Derleme komutu ([§5.3](#53-derleme-zamanı-yapılandırması----dart-define))         |
| 3    | Google Play Services                       | Cihaz                                                                             |
| 5    | Android OAuth istemcisi + SHA-1            | Google Cloud ([§9.3](#93-android-oauth-istemcisi--hesap-seçicinin-açılması-için)) |
| 6    | **Web** istemci kimliği kullanılmış olması | Derleme komutu                                                                    |
| 8    | `GOOGLE_SERVER_CLIENT_ID`                  | Vercel ([§11.2](#112-ortam-değişkenlerini-girme))                                 |
| 10   | Google'a giden ağ                          | Vercel çalışma zamanı                                                             |
| 12   | `aud` = aynı Web istemci kimliği           | İkisinin **aynı** olması                                                          |
| 13   | `DATABASE_URL`                             | Vercel                                                                            |

> 🔴 **Altın kural:** adım 6 ve adım 12'deki değer **birebir aynı Web istemci kimliği** olmalıdır.
> Farklıysa token üretilir ama sunucu `aud` uyuşmazlığı nedeniyle **401** döner.

### 17.3 SORUN GİDERME — belirtiden nedene

#### Belirti A — Google düğmesi hiç görünmüyor

```
Google düğmesi yok
  ↓
Kontrol A1: Derlemede dart-define verildi mi?
      flutter build ... --dart-define=GOOGLE_SERVER_CLIENT_ID=...
      → Verilmediyse: SEBEP BUDUR. Yeniden derle.
  ↓
Kontrol A2: Değer boş string mi?
      --dart-define=GOOGLE_SERVER_CLIENT_ID=""  → isConfigured false
      → Kabuk değişkeni boş olabilir:  echo "${GID}" ile doğrula
  ↓
Kontrol A3: Doğru yapıyı mı çalıştırıyorsun?
      adb uninstall com.ehliyetegitim.ehliyet_akademi
      adb install -r build/app/outputs/flutter-apk/app-release.apk
      → Eski yapı cihazda kalmış olabilir
  ↓
Kontrol A4: Kodda kapı doğru mu?
      grep -n "googleReady" apps/mobile/lib/features/auth/auth_screen.dart
      → `isConfigured` bekleniyor; testle korunuyor
```

> Bu **tasarlanmış** davranıştır: çalışmayan bir düğme göstermek yerine hiç göstermemek.

#### Belirti B — Hesap seçici açılıyor, hemen kapanıyor

Bu klasik `DEVELOPER_ERROR` (kod 10) belirtisidir.

```
Seçici açılıp kapanıyor
  ↓
Kontrol B1: Google Cloud'da bu imza için ANDROID istemcisi var mı?
      Google Cloud → Kimlik bilgileri → OAuth 2.0 İstemci Kimlikleri
      → Yoksa: SEBEP BUDUR → GOOGLE_LOGIN_SETUP.md §3.2
  ↓
Kontrol B2: Çalışan yapının imzası kayıtlı mı?
      Debug yapı  → debug.keystore SHA-1 kayıtlı olmalı
      Sideload    → upload key SHA-1 kayıtlı olmalı
      Play'den    → App Signing SHA-1 kayıtlı olmalı
  ↓
Kontrol B3: Paket adı birebir aynı mı?
      Google Cloud'daki: com.ehliyetegitim.ehliyet_akademi
      Uygulamadaki:   grep applicationId apps/mobile/android/app/build.gradle.kts
      → Tek harf farkı bile yeter
  ↓
Kontrol B4: Değişiklikten sonra Google'ın yayması 5 dakika sürebilir
      → Bekle, uygulamayı tamamen kapat, tekrar dene
  ↓
Kontrol B5: Cihaz logu
      adb logcat | grep -iE "GoogleSignIn|DEVELOPER_ERROR|ApiException"
      → "ApiException: 10" görürsen kesin SHA/paket uyuşmazlığı
```

#### Belirti C — "Google kimliği alınamadı" (idToken null)

```
idToken null
  ↓
Kontrol C1: serverClientId WEB istemcisi mi?
      Değer ...apps.googleusercontent.com ile bitmeli VE
      Google Cloud → Kimlik bilgileri'nde türü "Web uygulaması" olmalı
      → Android istemcisi verilmişse SEBEP BUDUR (en sık hata)
  ↓
Kontrol C2: Web istemcisi silinmiş olabilir mi?
      Google Cloud → Kimlik bilgileri → listede duruyor mu
  ↓
Kontrol C3: OAuth onay ekranı yapılandırıldı mı?
      Yapılandırılmamışsa Google token üretmez
```

#### Belirti D — Sunucu token'ı reddediyor

```
POST /api/auth/google başarısız
  ↓
HTTP kodu nedir?
  ├─ 503 "yapılandırılmadı"
  │     → Vercel'de GOOGLE_SERVER_CLIENT_ID YOK
  │     → Ekle + Redeploy (ekleme tek başına yetmez!)
  │
  ├─ 503 "doğrulama servisine ulaşılamadı"
  │     → Vercel'den Google JWKS'e ağ sorunu; geçicidir, tekrar dene
  │
  ├─ 401 "Google kimliği doğrulanamadı"
  │     → Kontrol D1: aud uyuşmazlığı — mobildeki ve Vercel'deki
  │                   GOOGLE_SERVER_CLIENT_ID AYNI mı?
  │     → Kontrol D2: token süresi dolmuş (saat kayması)
  │     → Kontrol D3: email_verified false — Google hesabı doğrulanmamış
  │
  ├─ 429
  │     → Hız sınırı (10/dk). Bir dakika bekle.
  │
  └─ 500
        → Vercel Runtime Logs'a bak; muhtemelen DATABASE_URL
```

**`aud` uyuşmazlığını kesin teşhis etmek:**

```bash
# Cihazdan yakalanan idToken'ın audience'ını oku (imza doğrulamadan):
python3 -c "
import base64,json,sys
p=sys.argv[1].split('.')[1]; p+='='*(-len(p)%4)
print(json.loads(base64.urlsafe_b64decode(p))['aud'])
" <idToken>
```

Çıkan değer Vercel'deki `GOOGLE_SERVER_CLIENT_ID` ile **birebir aynı** olmalı.

#### Belirti E — Debug'da çalışıyor, Play'den inende çalışmıyor 🔴

Bu **en sık ve en kafa karıştırıcı** senaryodur.

```
Debug ✅ / Play ❌
  ↓
SEBEP (neredeyse her zaman):
      Play, AAB'nizi KENDİ App Signing anahtarıyla YENİDEN İMZALAR.
      Kullanıcının cihazındaki imza sizin upload key'iniz DEĞİLDİR.
      O SHA-1 için Google Cloud'da Android istemcisi yoksa giriş yalnız Play
      yapılarında bozulur.
  ↓
ÇÖZÜM:
  1. Play Console → Test ve yayınlama → Kurulum → Uygulama imzalama
  2. "Uygulama imzalama anahtarı sertifikası" → SHA-1'i kopyala
  3. Google Cloud → Kimlik bilgileri → OAuth istemci kimliği → Android →
     paket adı + bu SHA-1 ile YENİ istemci oluştur
  4. google-services.json'ı yeniden indir (oauth_client sayısı artmalı)
  5. 5 dakika bekle (Google yayılımı)
  6. Uygulamayı Play'den yeniden indir
  ↓
NOT: Bu adım için AAB'nin ÖNCE yüklenmiş olması gerekir — App Signing
     sertifikası ilk yüklemeden önce mevcut değildir.
```

#### Belirti F — Kullanıcı seçiciyi kapattı

Bu **hata değildir**. Kod `GoogleSignInCancelled` döner ve **hiçbir mesaj göstermez**.
Kullanıcı fikrini değiştirmiştir.

#### Belirti G — Google ile giriş yeni hesap açtı, ilerlemem kayboldu

Olmaması gereken bir durumdur; kod **hesap birleştirme** yapar (adım 13).

```
Kontrol G1: E-posta adresleri gerçekten aynı mı?
      ornek@gmail.com  vs  ornek+test@gmail.com  → FARKLI hesaplardır
Kontrol G2: Veritabanında iki kayıt var mı?
      select email, created_at from users where email ilike '%<parça>%';
```

### 17.4 Doğrulama betiği (kopyala-çalıştır)

```bash
# 1) Sunucu yapılandırılmış mı? 401 = evet, 503 = hayır
curl -s -o /dev/null -w "auth/google: %{http_code}\n" \
  -X POST https://www.ehliyetegitim.com/api/auth/google \
  -H 'content-type: application/json' -d '{"idToken":"a.b.c"}'

# 2) google-services.json'da OAuth istemcisi var mı?
python3 -c "
import json;d=json.load(open('apps/mobile/android/app/google-services.json'))
print('oauth_client:', len(d['client'][0].get('oauth_client',[])))"

# 3) Upload key SHA-1 (Android OAuth istemcisine girilecek)
keytool -list -v -keystore apps/mobile/android/upload-keystore.jks -alias upload | grep SHA1

# 4) Debug key SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
  -storepass android -keypass android | grep SHA1
```

---

## 18. SATIN ALMA AKIŞI — UÇTAN UCA

### 18.1 İki ayrı yol

Kod **iki** ödeme yolunu destekler ve derleme zamanında seçer:

```
REVENUECAT_PUBLIC_KEY verildi mi?
  ├─ EVET → RevenueCatGateway     → sunucu köprüsü: WEBHOOK
  └─ HAYIR → PlayBillingGateway   → sunucu köprüsü: İSTEMCİ MAKBUZU
```

### 18.2 Yol A — `in_app_purchase` (varsayılan)

```
[1]  Kullanıcı paywall'ı açar
       ↓
[2]  _billing.available()  → InAppPurchase.isAvailable()
       ↑ false → "Mağaza kullanılamıyor" kartı, satın alma düğmesi PASİF
       ↓
[3]  products(ids) → Play'den ürün ayrıntıları
       ↑ boş dönerse → yine "Mağaza kullanılamıyor"
       ↑ SEBEP: ürün Play'de yok / etkin değil / kimlik uyuşmuyor
       ↓
[4]  Kullanıcı "Satın Al" → InAppPurchase.buyNonConsumable()
       ↓
[5]  Google Play ödeme sayfası (sistem tarafından çizilir)
       ↓
[6]  Akış ASENKRONDUR: sonuç purchaseStream'den gelir
       ↓
[7]  POST /api/iap/validate  { productId, purchaseToken, packageName }  + Bearer
       ↓
[8]  Sunucu: GOOGLE_PLAY_SA_JSON var mı?
       ├─ YOK + üretim → 503 (FAIL-CLOSED, grant reddedilir)
       └─ VAR → androidpublisher ile token doğrulanır
       ↓
[9]  purchases tablosuna INSERT  (unique(user,product) → idempotent)
       ↓
[10] Onay e-postası (Resend)
       ↓
[11] Yanıt: { ok: true, owned: [...] }
       ↓
[12] Uygulama sahipliği SUNUCUDAN okur (GET /api/purchases)
       ↑ sahiplik istemcide TUTULMAZ — kurcalanamaz
       ↓
[13] Premium yüzeyler açılır (dersler, AI kotası, simülatör)
```

### 18.3 Yol B — RevenueCat

```
[1-6] Aynı (RevenueCat SDK Play Billing'i sarar)
       ↓
[7]  Play → RevenueCat'e satın almayı bildirir
       ↓
[8]  RevenueCat → POST /api/iap/revenuecat  (webhook)
       Authorization: <REVENUECAT_WEBHOOK_SECRET>  veya  sha256=<hmac>
       ↓
[9]  Sunucu: sır yoksa → 503, HİÇBİR ŞEY YAZILMAZ
       Sır yanlışsa → 401
       ↓
[10] event.type GRANTING kümesinde mi?
       (INITIAL_PURCHASE · RENEWAL · NON_RENEWING_PURCHASE ·
        PRODUCT_CHANGE · UNCANCELLATION)
       ↓
[11] event.app_user_id → bizim kullanıcı kimliğimiz
       ↑ $RCAnonymousID:... ise → yok sayılır (200)
       ↓
[12] purchases INSERT (idempotent)
       ↓
[13] Uygulama GET /api/purchases ile sahipliği görür
```

> **Neden RevenueCat `/api/iap/validate` kullanamıyor?** RevenueCat SDK'sı ham Play
> `purchaseToken`'ını **sunmaz**. Bu yüzden köprü webhook olmak zorundadır. Bu, kodda
> `BillingServerBridge` enum'uyla açıkça bildirilir — gizli bir varsayım değildir.

### 18.4 SORUN GİDERME

#### Belirti A — "Mağaza kullanılamıyor" 🔴 (en sık şikâyet)

```
"Mağaza kullanılamıyor"
  ↓
Kontrol A1: Uygulama Play'DEN mi kuruldu?
      → sideload/debug yapıda Play Billing ÇALIŞMAZ.
      → Bu bir hata DEĞİLDİR. Kapalı test kanalından indir.
  ↓
Kontrol A2: Google hesabı test kullanıcısı mı?
      Play Console → Kapalı test → Test kullanıcıları → e-posta listede mi
      → Testçi bağlantısını kabul etti mi ("Testçi ol")
  ↓
Kontrol A3: Ürünler Play'de ETKİN mi?
      Play Console → Para kazanma → Ürünler → Uygulama içi ürünler
      → Durum "Etkin" olmalı. Sadece oluşturmak YETMEZ.
  ↓
Kontrol A4: Ürün kimlikleri BİREBİR eşleşiyor mu?
      Koddaki:  premium-teori   (tire)
      Play'deki: premium-teori  (tire)
      → premium_teori (alt çizgi) yazıldıysa SEBEP BUDUR
      grep -n "id: '" apps/web/lib/products.ts
  ↓
Kontrol A5: Uygulama en az bir kanalda YAYINLANDI mı?
      → Play, hiç yayınlanmamış uygulamada faturalandırmayı etkinleştirmez
      → İlk yükleme sonrası birkaç saat gecikme normaldir
  ↓
Kontrol A6: Cihaz logu
      adb logcat | grep -iE "BillingClient|IabHelper|in_app_purchase"
      → "BILLING_UNAVAILABLE" → hesap/ülke sorunu
      → "ITEM_UNAVAILABLE"   → ürün kimliği veya etkinleştirme sorunu
```

#### Belirti B — Satın alma tamamlandı ama premium açılmadı

```
Ödeme alındı, premium yok
  ↓
Kontrol B1: Sunucu doğrulaması yapılandırılmış mı?
      curl -s -o /dev/null -w "%{http_code}\n" -X POST \
        https://www.ehliyetegitim.com/api/iap/validate \
        -H 'content-type: application/json' -d '{}'
      → 401 (oturum yok) beklenir. 503 görürsen GOOGLE_PLAY_SA_JSON YOK
        → FAIL-CLOSED devrede: grant bilinçli olarak reddediliyor
  ↓
Kontrol B2: (RevenueCat yolunda) webhook ulaşıyor mu?
      RevenueCat → Integrations → Webhooks → Delivery logs
      → 503 → REVENUECAT_WEBHOOK_SECRET Vercel'de yok
      → 401 → sır iki tarafta FARKLI
      → 200 → webhook tamam, sorun başka yerde
  ↓
Kontrol B3: Veritabanında kayıt var mı?
      select * from purchases where user_id = '<kullanıcı>';
  ↓
Kontrol B4: app_user_id doğru mu? (RevenueCat)
      → $RCAnonymousID: ile başlıyorsa uygulama kullanıcıyı RevenueCat'e
        tanıtmamış demektir → sahiplik hiçbir hesaba yazılamaz
  ↓
Kontrol B5: Uygulama sahipliği yeniden okudu mu?
      → Uygulamayı tamamen kapat/aç (GET /api/purchases yeniden çağrılır)
```

#### Belirti C — Geri yükleme çalışmıyor

```
Kontrol C1: Aynı Google hesabı mı?
Kontrol C2: Aynı uygulama hesabı (e-posta) ile mi giriş yapıldı?
      → Sahiplik BİZİM kullanıcımıza bağlıdır, Google hesabına değil
Kontrol C3: GET /api/purchases ne dönüyor?
      curl -H "authorization: Bearer <token>" .../api/purchases
```

#### Belirti D — Test satın alması para kesti

```
→ Lisans test hesabı ayarlanmamış.
   Play Console → Ayarlar → Lisans testi → hesabı ekle → RESPOND_NORMALLY
→ Ayarlandıktan sonra satın almalar ücretsizdir ve "Test kartı" görünür.
```

#### Belirti E — Webhook 401 dönüyor ama sır doğru görünüyor

```
Kontrol E1: Baştaki/sondaki boşluk
      RevenueCat panosuna yapıştırırken boşluk girmiş olabilir
Kontrol E2: "Bearer " öneki
      Kod hem "Bearer <sır>" hem düz "<sır>" kabul eder — bu sorun değil
Kontrol E3: Vercel'e girildi ama REDEPLOY yapılmadı
      → En sık sebep budur
Kontrol E4: HMAC bekleniyor ama düz sır gönderiliyor (veya tersi)
      → Kod ikisini de kabul eder; sorun değerdedir
```

### 18.5 Satın alma testleri (kodda mevcut)

```bash
# Sunucu tarafı
pnpm --filter @ea/web test -- iap-validate       # 7 test
pnpm --filter @ea/web test -- revenuecat         # 11 test

# Mobil taraf
cd apps/mobile && flutter test test/premium_test.dart
```

RevenueCat webhook testlerinin çoğu **"kim yazamaz"** sorusunu ölçer: sır yoksa yazamaz,
yanlış sırla yazamaz, bozuk HMAC ile yazamaz, bilinmeyen kullanıcı için yazamaz.

### 18.6 Neden uçtan uca ölçülemiyor — dürüst sınır

Gerçek bir satın alma akışı **Play imzalı yapı + Play Console + gerçek cihaz** gerektirir.
Geliştirme ortamında (sideload) bu **mümkün değildir** ve hiçbir yapılandırma bunu değiştirmez.

Bu yüzden proje şunu yapar: **grant ve idempotency mantığı testlerle tam kapsanır**, gerçek
Play etkileşimi **kapalı testin ilk işi** olarak işaretlenir.

---

## 19. SERVİS SERVİS HATA AYIKLAMA LİSTESİ

Her servis için: **Sağlık kontrolü → Beklenen sonuç → Bozukluk belirtileri → Düzeltme → Doğrulama**

### 19.1 Vercel / Backend

|                     |                                                                                                             |
| ------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | `curl -s https://www.ehliyetegitim.com/api/health`                                                          |
| **Beklenen**        | `{"status":"ok","db":"configured","email":"resend","payments":"lemonsqueezy"}`                              |
| **Belirtiler**      | 404 → dağıtım yok/Root Directory yanlış · 500 → çalışma zamanı hatası · `"db":"missing"` → DB değişkeni yok |
| **Düzeltme**        | Vercel → Deployments → son dağıtım → Build Logs / Runtime Logs                                              |
| **Doğrulama**       | Sağlık kontrolünü tekrarla; dört alan da beklenen değerde olmalı                                            |

### 19.2 Neon / Veritabanı

|                     |                                                                                                       |
| ------------------- | ----------------------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | `/api/health` → `"db":"configured"` · Neon panosu → Monitoring                                        |
| **Beklenen**        | Bağlantı açık, aktif bağlantı sayısı havuz sınırının altında                                          |
| **Belirtiler**      | `too many connections` → **pooled** dize kullanılmıyor · `password authentication failed` → dize eski |
| **Düzeltme**        | Pooled bağlantı dizesini kullan; parola döndüyse Vercel'i güncelle + **Redeploy**                     |
| **Doğrulama**       | `node scripts/db-cleanup.mjs` (kuru çalıştırma) tablo sayılarını yazdırabiliyorsa bağlantı sağlam     |

### 19.3 Google Cloud / OAuth

|                     |                                                                                                          |
| ------------------- | -------------------------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | `POST /api/auth/google` geçersiz token → **401** · `google-services.json` → `oauth_client ≥ 2`           |
| **Beklenen**        | 401 (sunucu ayarlı) + Android ve Web istemcileri mevcut                                                  |
| **Belirtiler**      | 503 → sunucuda değişken yok · `oauth_client: 0` → SHA eklenmemiş · `ApiException: 10` → imza uyuşmazlığı |
| **Düzeltme**        | [§17.3](#173-sorun-giderme--belirtiden-nedene)                                                           |
| **Doğrulama**       | Gerçek cihazda giriş yap; `/api/auth/me` kullanıcıyı dönmeli                                             |

### 19.4 Play Console / Billing

|                     |                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | Uygulamada paywall'ı aç → ürünler ve fiyat görünüyor mu                                |
| **Beklenen**        | Ürün adı + TRY fiyat + aktif "Satın Al" düğmesi                                        |
| **Belirtiler**      | "Mağaza kullanılamıyor" → [§18.4-A](#belirti-a--mağaza-kullanılamıyor--en-sık-şikâyet) |
| **Düzeltme**        | Ürünleri etkinleştir · kimlikleri eşle · Play'den kur · testçi listesine ekle          |
| **Doğrulama**       | Lisans test hesabıyla ücretsiz satın alma → premium açılmalı                           |

### 19.5 RevenueCat

|                     |                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | `POST /api/iap/revenuecat` → 503 (sır yok) / 401 (yanlış sır) · pano → Send test event |
| **Beklenen**        | Test olayı **200** almalı                                                              |
| **Belirtiler**      | 503 → Vercel'de sır yok · 401 → sırlar farklı · 404 → uç dağıtılmamış                  |
| **Düzeltme**        | Sırrı iki tarafta eşitle, **Vercel'i redeploy et**                                     |
| **Doğrulama**       | Delivery logs'ta 200 · gerçek satın almada `purchases` satırı oluşmalı                 |

### 19.6 Anthropic / AI

|                     |                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------ |
| **Sağlık kontrolü** | `/api/ai/ask/stream` çıktısında `"streamed":true`                                                      |
| **Beklenen**        | `meta` → çok sayıda `delta` → `done`                                                                   |
| **Belirtiler**      | `streamed:false` → anahtar yok/hata · `model:"gate"` → içerik eşleşmedi + model yok · 429 → hız sınırı |
| **Düzeltme**        | Anahtarı Vercel'e gir + Redeploy; Runtime Logs'ta `ai_*_fallback` ara                                  |
| **Doğrulama**       | Uygulamada AI Koç'a soru sor; yanıt **parça parça** yazılmalı                                          |

### 19.7 Resend / E-posta

|                     |                                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Sağlık kontrolü** | `/api/health` → `"email":"resend"`                                                                           |
| **Beklenen**        | Kayıt sonrası doğrulama e-postası dakikalar içinde                                                           |
| **Belirtiler**      | `"email":"noop"` → anahtar yok · Resend Logs'ta 403 → alan adı doğrulanmamış · spam klasörü → SPF/DKIM eksik |
| **Düzeltme**        | Alan adını doğrula, `EMAIL_FROM`'u doğrulanmış alan adıyla eşle                                              |
| **Doğrulama**       | Yeni hesap aç, e-postanın geldiğini gör                                                                      |

### 19.8 Google Cloud OAuth istemcileri

|                     |                                                                                                                         |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | Google Cloud → API'ler ve Hizmetler → Kimlik bilgileri → OAuth 2.0 İstemci Kimlikleri listesi                           |
| **Beklenen**        | 1 adet **Web** istemcisi + kullandığın **her imza için** birer **Android** istemcisi                                    |
| **Belirtiler**      | Hesap seçici açılıp kapanıyor → Android istemcisi yok/SHA yanlış · `idToken` null → Web yerine Android kimliği verilmiş |
| **Düzeltme**        | `GOOGLE_LOGIN_SETUP.md` §3 (Android) · §2.3 (Web) · §9 (sık hatalar)                                                    |
| **Doğrulama**       | `pnpm doctor` → paket adı + SHA-1 yazdırır; gerçek cihazda giriş dener                                                  |

### 19.9 CI / GitHub Actions

|                     |                                                                                                                                           |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Sağlık kontrolü** | `gh run list --limit 5`                                                                                                                   |
| **Beklenen**        | CI ✅ · Mobile CI ✅ · CodeQL ✅                                                                                                          |
| **Belirtiler**      | Mobile CI çalışmadı → yalnız `apps/mobile/**` değişince tetiklenir (**beklenen davranış**) · gitleaks kırmızı → depoya gizli değer girmiş |
| **Düzeltme**        | gitleaks bulgusunu **hemen** temizle ve anahtarı **döndür**                                                                               |
| **Doğrulama**       | `gh run list` üç iş akışının da yeşil olduğunu göstermeli                                                                                 |

### 19.10 Tek komutta tam sağlık taraması

Bu bölümün **çalıştırılabilir hâli** depoda mevcuttur:

```bash
pnpm doctor                              # üretimi ölçer
node scripts/doctor.mjs --base http://localhost:3000   # yereli ölçer
```

Araç hiçbir şeyi değiştirmez; her bulguyu bu el kitabının ilgili bölümüne yönlendirir ve
**yayın engelleyici bir sorun varsa 1 koduyla çıkar** (CI'da kullanılabilir).

Örnek çıktı (2026-07-27, üretim):

```
✅ Veritabanı                configured                    → §19.2
✅ E-posta                   resend                        → §19.7
✅ Web ödemesi               lemonsqueezy                  → §16.10
✅ Google (sunucu)           GOOGLE_SERVER_CLIENT_ID ayarlı → §17.1
⚠️ RevenueCat webhook        REVENUECAT_WEBHOOK_SECRET yok  → §16.6
✅ Akan AI                   gerçek akış çalışıyor          → §14.4
✅ Paket adı                 com.ehliyetegitim.ehliyet_akademi → GOOGLE_LOGIN_SETUP §3.3
✅ İmzalama anahtarı         upload · SHA1 7E:1F:EA:D9:20:BE…→ §6.5

Yayın engelleyici bulgu yok.
```

Ham komutlarla yapmak istersen:

```bash
#!/usr/bin/env bash
BASE=https://www.ehliyetegitim.com
echo "── sağlık ──";           curl -s $BASE/api/health
echo; echo "── google (401 bekleniyor) ──"
curl -s -o /dev/null -w "%{http_code}\n" -X POST $BASE/api/auth/google \
  -H 'content-type: application/json' -d '{"idToken":"a.b.c"}'
echo "── revenuecat (503=sır yok, 401=sır var) ──"
curl -s -o /dev/null -w "%{http_code}\n" -X POST $BASE/api/iap/revenuecat \
  -H 'content-type: application/json' -d '{}'
echo "── akan AI ──"
curl -s -X POST $BASE/api/ai/ask/stream -H 'content-type: application/json' \
  -d '{"question":"Kırmızı ışıkta ne yapmalıyım?"}' | head -c 160
echo; echo "── oauth_client ──"
python3 -c "
import json;d=json.load(open('apps/mobile/android/app/google-services.json'))
print(len(d['client'][0].get('oauth_client',[])))"
```

---

## 20. ZERO → CLOSED TESTING

### 20.1 Ön koşullar

- [ ] AAB imzalanmış ve `jarsigner` doğrulamış ([§6.7](#67-i̇mzayı-doğrula))
- [ ] Play Console'da uygulama oluşturulmuş ([§7.2](#72-uygulama-oluşturma--düğme-düğme))
- [ ] Tüm zorunlu beyanlar tamamlanmış ([§7.4](#74-zorunlu-beyanlar))
- [ ] Mağaza listesi (başlık, açıklama, ekran görüntüleri, ikon 512², öne çıkan 1024×500)

### 20.2 Adımlar

```
1. Kapalı test sürümü oluştur ve AAB'yi yükle       (§7.6)
2. Play App Signing SHA-1'i → yeni Android OAuth istemcisi  ← ZORUNLU
   (GOOGLE_LOGIN_SETUP.md §7.3)
3. AAB'yi YENİDEN derle ve YENİ sürüm olarak yükle  (§6.6)
4. Test kullanıcısı listesi oluştur                 (§7.7)
5. Lisans test hesaplarını ayarla                   (§7.8)
6. Katılım bağlantısını 12 kişiye gönder
7. Her testçi: bağlantı → "Testçi ol" → Play'den indir
```

> **2–3 arası neden zorunlu?** İlk yüklemeden önce App Signing sertifikası yoktur. O SHA-1
> için Google Cloud'da bir Android OAuth istemcisi oluşturulmadan Google girişi
> **Play'den inen yapıda çalışmaz**.

### 20.3 Testçilere gönderilecek metin (şablon)

```
Merhaba,

Ehliyet Akademi'nin kapalı testine davetlisin. Adımlar:

1. Bu bağlantıya tıkla: <PLAY_TEST_LINK>
2. "Testçi ol" düğmesine bas.
3. Aynı sayfadaki Play Store bağlantısından uygulamayı indir.

ÖNEMLİ: Play Store'a giriş yaptığın hesap, bize verdiğin e-posta ile aynı olmalı.

Lütfen şunları dene:
· Tanıtım ekranlarını geç, ana sayfaya in
· Hesap aç (e-posta veya Google ile)
· Bir ders oku, bir deneme sınavı çöz
· AI Koç'a bir soru sor
· Premium ekranını aç (satın alma ücretsizdir, test hesabısın)

Takıldığın yeri ekran görüntüsüyle bize yaz. Teşekkürler!
```

### 20.4 Testçilerin sınaması istenen akışlar

| #   | Akış                             | Beklenen                                            |
| --- | -------------------------------- | --------------------------------------------------- |
| 1   | İlk açılış → tanıtım             | 5 sayfa, kaydırma gerekmez, boş alan yok            |
| 2   | Ana sayfa → AI karşılama popup'ı | Bir kez açılır, kapanır, **bir daha açılmaz**       |
| 3   | E-posta ile kayıt                | Doğrulama e-postası gelir                           |
| 4   | **Google ile giriş**             | Hesap seçici açılır, giriş tamamlanır               |
| 5   | Parola sıfırlama                 | E-posta gelir                                       |
| 6   | Ders okuma                       | Hero, süre, zorluk, okuma çubuğu görünür            |
| 7   | Deneme sınavı                    | Süre, sonuç, yanlış analizi                         |
| 8   | AI Koç                           | Yanıt **parça parça** yazılır                       |
| 9   | **Premium satın alma**           | Ürün görünür, satın alma tamamlanır, premium açılır |
| 10  | Uygulamayı kapat/aç              | Premium **hâlâ açık** (sunucudan okunur)            |
| 11  | Çevrimdışı                       | Uygulama açılır, dürüst uyarı gösterilir            |
| 12  | Topluluk                         | Katılım isteğe bağlı, avatar yüklenebilir           |

### 20.5 Çıkış ölçütleri

- [ ] 12 testçinin en az 8'i uygulamayı kurup kullanmış
- [ ] Google girişi en az 5 farklı cihazda çalışmış
- [ ] En az 1 gerçek satın alma uçtan uca tamamlanmış
- [ ] Çökme raporu **yok** (Play Console → Kalite → Android vitals)
- [ ] ANR oranı %0,47'nin altında

---

## 21. ZERO → RELEASE

### 21.1 Yayın öncesi kapılar (tamamı otomatik)

```bash
# Web
pnpm lint && pnpm typecheck && pnpm format && pnpm verify && pnpm test

# Mobil
cd apps/mobile
flutter analyze          # 0 sorun
flutter test             # tüm testler geçmeli

# CI
gh run list --limit 3    # CI · Mobile CI · CodeQL hepsi ✅
```

Bu kapıların **hepsi** geçmeden yayın yapılmaz.

### 21.2 Sürüm numarası

`apps/mobile/pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ^^^^^ ^
#        adı   derleme numarası — Play'e her yüklemede ARTMALI
```

> Aynı derleme numarasıyla ikinci kez yükleyemezsin. Play "Sürüm kodu zaten kullanılmış" der.

### 21.3 Derleme

```bash
cd apps/mobile
flutter clean
flutter pub get
flutter build appbundle --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-istemci-kimliği>
```

### 21.4 İmza doğrulaması

```bash
jarsigner -verify -verbose:summary \
  build/app/outputs/bundle/release/app-release.aab
# Beklenen: "jar verified."
```

Sertifika sahibini de kontrol et (yanlışlıkla debug anahtarıyla imzalanmadığından emin ol):

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab 'META-INF/*.RSA' \
  | keytool -printcert | grep Owner
# "CN=Android Debug" GÖRMEMELİSİN
```

### 21.5 Yükleme

```
Play Console → Test ve yayınlama → Kapalı test → Yeni sürüm oluştur
  → AAB'yi yükle
  → Sürüm notları (tr-TR) yaz
  → Kaydet → İncele → Kapalı teste sun
```

### 21.6 Yayın sonrası doğrulama

```bash
# Üretim uçları hâlâ sağlıklı mı
curl -s https://www.ehliyetegitim.com/api/health
```

- [ ] Play Console → Yayın panosu → sürüm "Kullanılabilir"
- [ ] Gerçek cihazda Play'den indirilip açılıyor
- [ ] **Google girişi Play yapısında çalışıyor** ([§17.3-E](#belirti-e--debugda-çalışıyor-playden-inende-çalışmıyor-))
- [ ] Satın alma test hesabıyla çalışıyor
- [ ] Android vitals'ta çökme yok

### 21.7 Geri alma (rollback)

Play'de yayınlanmış bir sürüm **silinemez**, ama:

```
Play Console → Sürüm → Yayını durdur (Halt rollout)
→ sonra düzeltilmiş yeni sürüm yükle (derleme numarası artırılmış)
```

Backend için Vercel:

```
Vercel → Deployments → önceki başarılı dağıtım → ⋯ → Promote to Production
```

---

## 22. EKLER

### 22.1 Bu projeye özgü sabit değerler

| Alan                       | Değer                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------- |
| Uygulama kimliği           | `com.ehliyetegitim.ehliyet_akademi`                                                               |
| Üretim alan adı            | `https://www.ehliyetegitim.com`                                                                   |
| Google Cloud proje kimliği | `ehliyet-akademi-3daa1`                                                                           |
| Sürüm                      | `1.0.0+1`                                                                                         |
| Upload key SHA-1           | `7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57`                                     |
| Upload key SHA-256         | `46:B2:DF:CE:2F:78:BD:A0:EB:C6:A0:19:FE:4F:14:98:C0:52:37:42:19:94:68:C5:47:D0:4F:68:6F:06:07:D3` |
| Debug key SHA-1            | `20:AE:CA:91:98:1B:EE:12:3A:CD:0A:CE:54:9E:BA:7F:D0:A3:04:CF`                                     |
| Upload key geçerlilik      | 2026-07-26 → 2053-12-11                                                                           |

### 22.2 Sık kullanılan komutlar

```bash
# Tüm kapılar
pnpm lint && pnpm typecheck && pnpm format && pnpm verify && pnpm test
cd apps/mobile && flutter analyze && flutter test

# Üretim AAB
flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID=...

# Cihaza kur ve izle
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=...
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep -iE "flutter|GoogleSignIn|BillingClient"

# Parmak izleri
keytool -list -v -keystore apps/mobile/android/upload-keystore.jks -alias upload
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android

# Dağıtım teşhisi (hiçbir şeyi değiştirmez)
pnpm doctor

# Veritabanı (kuru çalıştırma)
node scripts/db-cleanup.mjs

# CI durumu
gh run list --limit 5
```

### 22.3 Bu el kitabının yerine geçtiği belgeler

| Belge                        | Durum                                                                  |
| ---------------------------- | ---------------------------------------------------------------------- |
| `ENV_SETUP_GUIDE.md`         | 🗄️ Arşiv — içeriği §16'da                                              |
| `ENV_TEMPLATE.md`            | 🗄️ Arşiv — içeriği §16'da                                              |
| `GOOGLE_AUTH_SETUP.md`       | 🗄️ Arşiv — içeriği §8, §9, §17'de                                      |
| `REVENUECAT_SETUP.md`        | 🗄️ Arşiv — içeriği §10, §18'de                                         |
| `PLAY_CONSOLE_SETUP.md`      | 🗄️ Arşiv — içeriği §7, §20, §21'de                                     |
| `RELEASE_CHECKLIST.md`       | 🗄️ Arşiv — içeriği §21'de                                              |
| `FINAL_ENVIRONMENT_GUIDE.md` | 🗄️ Arşiv — içeriği §16'da                                              |
| `CLOSED_TEST_GUIDE.md`       | 🗄️ Arşiv — içeriği §20'de                                              |
| `GOOGLE_LOGIN_SETUP.md`      | ✅ **Geçerli** — Google girişinin resmî kurulum belgesi (Firebase'siz) |
| `DATABASE_CLEANUP_REPORT.md` | ✅ **Geçerli** — ölçüm raporu, §12.5'ten atıf yapılır                  |
| `RELEASE_AUDIT_REPORT.md`    | ✅ **Geçerli** — denetim kaydı                                         |
| `MOBILE_PROJECT_MEMORY.md`   | ✅ **Geçerli** — mühendislik kararları ve tuzaklar                     |

### 22.4 Çözülen çelişkiler

Belgeler birleştirilirken üç gerçek çelişki bulundu ve **ölçümle** çözüldü:

| Çelişki                                    | Eski belgeler                                    | Ölçülen gerçek                                           |
| ------------------------------------------ | ------------------------------------------------ | -------------------------------------------------------- |
| `GOOGLE_SERVER_CLIENT_ID` sunucuda var mı? | `GOOGLE_AUTH_SETUP.md` §9.5 "henüz mevcut değil" | ✅ **Vercel'de AYARLI** — üretim 401 dönüyor (503 değil) |
| AAB imzası nasıl doğrulanır?               | Bazı yerlerde `apksigner`                        | ❌ `apksigner` AAB'yi doğrulayamaz → **`jarsigner`**     |
| RevenueCat webhook ucu var mı?             | `REVENUECAT_SETUP.md` uç varmış gibi anlatıyordu | Faz 13'e kadar **yoktu** (404); şimdi var ve fail-closed |

### 22.5 Bakım

Bu el kitabı **tek resmî dağıtım kaynağıdır**. Bir yapılandırma değiştiğinde:

1. Önce burayı güncelle.
2. Değişikliği **ölçerek** doğrula (curl / keytool / test).
3. Ölçüm çıktısını belgeye yaz — "çalışıyor" yazma, **kanıtı** yaz.

> Bu belgedeki her "✅ ölçüldü" işareti gerçek bir komut çıktısına dayanır. Bu alışkanlık
> bozulursa el kitabı, güvenilemeyecek bir belgeye dönüşür.
