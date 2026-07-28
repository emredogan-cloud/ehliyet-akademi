# Google Play Sign-In Olay Kitabı (Playbook)

**Kalıcı mühendislik referansı · Sürüm 1.0 · 2026-07-28**

|            |                                                                     |
| ---------- | ------------------------------------------------------------------- |
| Olay       | Google girişi yalnız **Play'den kurulumda** başarısız oluyordu      |
| Süre       | ~3 gün, 4 ayrı soruşturma turu                                      |
| Kök neden  | Play App Signing sertifikası için **Android OAuth istemcisi yoktu** |
| Doğrulanma | Play imzalı yapıda giriş tamamlandı (§3.9)                          |
| Kapsam     | Android · Flutter · Google Sign-In · Play App Signing               |

> **Bu belgenin amacı:** yıllar sonra aynı sorunla karşılaşan bir mühendis, bu soruşturmayı
> tekrarlamadan **30 dakikada** çözebilsin. Anlatı değil, **kullanılabilir yöntem**.

---

## İÇİNDEKİLER

| §   | Konu                                                                   |
| --- | ---------------------------------------------------------------------- |
| 1   | [Problem özeti](#1-problem-özeti)                                      |
| 2   | [Soruşturma zaman çizelgesi](#2-soruşturma-zaman-çizelgesi)            |
| 3   | [Toplanan kanıtlar](#3-toplanan-kanıtlar)                              |
| 4   | [Kök neden](#4-kök-neden)                                              |
| 5   | [Firebase bulguları](#5-firebase-bulguları)                            |
| 6   | [Nihai düzeltme](#6-nihai-düzeltme)                                    |
| 7   | [Önleme kontrol listesi](#7-önleme-kontrol-listesi)                    |
| 8   | [Sık yapılan hatalar](#8-sık-yapılan-hatalar)                          |
| 9   | [Hata ayıklama akış şeması](#9-hata-ayıklama-akış-şeması)              |
| 10  | [Çıkarılan dersler](#10-çıkarılan-dersler)                             |
| 11  | [Yeniden kullanılabilir komutlar](#11-yeniden-kullanılabilir-komutlar) |
| 12  | [Gelecek projeler için otomasyon](#12-gelecek-projeler-için-otomasyon) |

---

## 1. Problem özeti

### 1.1 Belirtiler

| Ortam                            | Davranış         |
| -------------------------------- | ---------------- |
| `flutter run` (debug, USB)       | ✅ Çalışıyor     |
| Release APK, `adb install`       | ✅ Çalışıyor     |
| **Play Kapalı Test'ten kurulum** | ❌ **Başarısız** |

Başarısızlığın şekli — teşhisi zorlaştıran şey buydu:

```
Google hesap seçici açılıyor          ← normal
Kullanıcı hesabı seçiyor              ← normal
… sonra HİÇBİR ŞEY olmuyor
```

- **Çökme yok**
- **Backend hatası yok** (istek hiç gönderilmiyor)
- **Anlamlı hata mesajı yok**
- Uygulama giriş ekranında kalıyor

### 1.2 Neden bu kadar zor

| Etken                                          | Etkisi                                           |
| ---------------------------------------------- | ------------------------------------------------ |
| Geliştiricinin cihazında **çalışıyordu**       | "Bende çalışıyor" → sorun görünmez               |
| Hata mesajı jenerikti                          | Kullanıcı "hiçbir şey olmuyor" diye bildiriyordu |
| Uygulama **sürüm numarasını göstermiyordu**    | "Hangi yapıyı çalıştırıyorsun?" sorulamıyordu    |
| Ortamda **üç farklı Google projesi** izi vardı | Her biri makul bir suçlu gibi görünüyordu        |
| Google'ın hatası kodda **yutuluyordu**         | Asıl neden sürüm derlemesinde okunamıyordu       |

---

## 2. Soruşturma zaman çizelgesi

### Tur 1 — "Sunucu mu bozuk?"

| Adım              | Sonuç                                                                                                      |
| ----------------- | ---------------------------------------------------------------------------------------------------------- |
| Hipotez           | Backend ID token'ı reddediyor                                                                              |
| Deney             | `POST /api/auth/google` geçersiz token ile çağrıldı                                                        |
| Bulgu             | **HTTP 401** döndü                                                                                         |
| **Ret gerekçesi** | Sunucu yapılandırılmamış olsa **503** dönerdi. 401 → `GOOGLE_SERVER_CLIENT_ID` **ayarlı**. Backend elendi. |

### Tur 2 — "Uygulama kodunda sessiz bir yutma mı var?"

| Adım      | Sonuç                                                                                                      |
| --------- | ---------------------------------------------------------------------------------------------------------- |
| Hipotez   | `catch` bloğu hatayı yutuyor, akış sessizce ölüyor                                                         |
| Deney     | Zincirin **her adımına** geçici izleme eklendi, cihazda çalıştırıldı                                       |
| Bulgu     | `GoogleSignInException code=unknownError description=[28444] Developer console is not set up correctly`    |
| **Sonuç** | Hipotez **kısmen doğru**: kod hatayı gerçekten yutuyordu (düzeltildi), ama asıl neden Google tarafındaydı. |

> ⚠️ İlk gerçek ders: **`dart:developer.log` sürüm derlemesinde logcat'e düşmez.** Teşhis
> günlüğü `print()` / `debugPrint` olmalıdır.

### Tur 3 — "Play mi farklı davranıyor?"

| Hipotez                               | Deney                                                                                | Sonuç                                |
| ------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------ |
| Kodda flavor/`kReleaseMode` farkı var | `lib/` genelinde arama                                                               | ❌ Hiç yok                           |
| R8/ProGuard bir şey sıyırıyor         | `build.gradle.kts` incelendi                                                         | ❌ `minifyEnabled` ayarlı bile değil |
| AAB yanlış istemci kimliği taşıyor    | AAB'nin AOT anlık görüntüsünden `strings`                                            | ❌ Kimlik **doğru**                  |
| **Split APK teslimatı bozuyor**       | `bundletool` ile Play'in ürettiği split'ler **upload anahtarıyla** imzalanıp kuruldu | ❌ **Giriş çalıştı** → split elendi  |
| Play eski bir sürüm sunuyor           | _(o an ölçülemedi — uygulama sürüm göstermiyordu)_                                   | ⏸️ Açık kaldı                        |

> Bu turun kazancı: **kod, dart-define, AAB paketlemesi ve split teslimatı elendi.** Geriye tek
> değişken kaldı: **imzalayan sertifika**.

### Tur 4 — Kesin kanıt

| Adım                                                        | Sonuç                                                          |
| ----------------------------------------------------------- | -------------------------------------------------------------- |
| Test cihazının kapalı test kapsamında olduğu fark edildi    | 🔑 Dönüm noktası                                               |
| Yan yüklenen yapı kaldırıldı, uygulama **Play'den kuruldu** | Play imzalı yapı elde edildi                                   |
| Play APK'sı cihazdan çekildi, sertifikası okundu            | `CN=Android, O=Google Inc.` · SHA-1 `e200c3c3…`                |
| Play yapısında giriş denendi                                | `[GoogleSignIn_flowRunner] Flow failed` + `DEVELOPER_ERROR`    |
| Çalışan yapının ID token talepleri okundu                   | `azp` = upload anahtarının Android istemcisi                   |
| **Sonuç**                                                   | **Play App Signing SHA-1'i için Android OAuth istemcisi yok.** |

### Ölü sokaklar — ve neden

| Ölü sokak                   | Harcanan çaba | Neden yanlıştı                                    |
| --------------------------- | ------------- | ------------------------------------------------- |
| Firebase yapılandırması     | Yüksek        | Firebase projede **hiç kullanılmıyordu** (§5)     |
| `google-services.json`      | Orta          | Dosya hiç okunmuyordu **ve yanlış projeye aitti** |
| Backend / `aud` uyuşmazlığı | Düşük         | 401 vs 503 ayrımıyla bir komutta elendi           |
| Split APK teslimatı         | Orta          | `bundletool` deneyi kesin olarak eledi            |
| "Flutter/eklenti hatası"    | Düşük         | Google Play Services'in **kendi** hata kodu vardı |

---

## 3. Toplanan kanıtlar

### 3.1 Backend yapılandırma testi

```bash
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://<host>/api/auth/google \
  -H 'content-type: application/json' -d '{"idToken":"a.b.c"}'
```

| Kod     | Anlamı                                                                                |
| ------- | ------------------------------------------------------------------------------------- |
| **401** | Sunucuda `GOOGLE_SERVER_CLIENT_ID` **ayarlı** (token geçersiz olduğu için reddedildi) |
| **503** | Değişken **yok** ya da yeniden dağıtım yapılmamış                                     |

### 3.2 Uygulama içi izleme (geçici)

```dart
print('[SIGNIN] serverClientId=$_serverClientId');
…
print('[SIGNIN] HATA code=${e.code} description=${e.description}');
```

Yakalanan:

```
[SIGNIN] HATA GoogleSignInException code=unknownError
         description=[28444] Developer console is not set up correctly.
```

### 3.3 AAB'ye gömülü istemci kimliği

```bash
unzip -qo app-release.aab -d /tmp/aab
strings /tmp/aab/base/lib/arm64-v8a/libapp.so \
  | grep -oE "[0-9]+-[0-9a-z]+\.apps\.googleusercontent\.com"
```

> `--dart-define` değerleri AOT anlık görüntüsüne **sabit olarak gömülür** ve böyle okunabilir.
> Bu, "derlemeye doğru kimlik girdi mi?" sorusunun kesin cevabıdır.

### 3.4 Split APK kontrol deneyi (kritik)

```bash
bundletool build-apks --bundle=app-release.aab --output=play.apks \
  --ks=upload.jks --ks-pass=pass:… --ks-key-alias=upload --key-pass=pass:… \
  --connected-device --device-id=<SERIAL>

bundletool install-apks --apks=play.apks --device-id=<SERIAL>
adb shell pm path <package>     # base.apk + split_config.* → Play biçimi
```

**Sonuç: giriş çalıştı.** Bu tek deney şunları eledi: kod · dart-define · AAB paketlemesi ·
mimari/dil/yoğunluk split'leri.

### 3.5 Play'den kurulu yapının çıkarılması

```bash
adb uninstall <package>
adb shell am start -a android.intent.action.VIEW -d "market://details?id=<package>"
# → "Yükle" düğmesine dokun, kurulumu bekle

BASE=$(adb shell pm path <package> | grep base.apk | sed 's/package://' | tr -d '\r')
adb pull "$BASE" play_base.apk
```

> **Ön koşul:** cihazdaki Google hesabı kapalı test listesinde olmalı ve testçi bağlantısını
> kabul etmiş olmalıdır.

### 3.6 Play imzasının okunması

```bash
apksigner verify --print-certs --min-sdk-version 24 --max-sdk-version 36 play_base.apk
```

```
V3.0 Signer: certificate DN: CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US
V3.0 Signer: certificate SHA-1 digest: e200c3c3ed75215941c45c367c65cd81f8e8e1a5
```

> ⚠️ **`--max-sdk-version 36` şart.** Play artık **post-kuantum hibrit imza bloğu** (ML-DSA,
> minSdk 37+) ekliyor; JDK 17 bunu çözemez ve `apksigner` şu hatayla düşer:
> `Malformed public key: ML-DSA KeyFactory not available`.
>
> `CN=Android, O=Google Inc.` → Google'ın **ürettiği** App Signing sertifikasının imzasıdır.
> Sizin upload anahtarınızın DN'i kendi bilgilerinizi taşır.

### 3.7 Başarısızlığın cihaz günlüğü

```bash
adb logcat -c && <akışı çalıştır> && adb logcat -d | grep -aiE \
  "Auth.Api.Credentials|GoogleSignIn_flowRunner|DEVELOPER_ERROR"
```

**Başarısız (Play imzası):**

```
Auth.Api.Credentials: [GoogleSignIn_flowRunner] Flow failed.
Auth.Api.Credentials: chbm: [16] Account reauth failed.
GoogleApiManager: ConnectionResult{statusCode=DEVELOPER_ERROR}
```

**Başarılı (düzeltmeden sonra):**

```
Auth.Api.Credentials: [GoogleSignIn_flowRunner] Flow step completed
Auth.Api.Credentials: [FetchGoogleIdTokenCredentialOperation] Operation started
→ "Flow failed" satırı YOK
```

> ⚠️ **Gürültü tuzağı:** `FlagStore` / `Phenotype.API` kaynaklı `DEVELOPER_ERROR` satırları
> **ilgisizdir** ve her cihazda görülür. Yalnız **`Auth.Api.Credentials`** ve
> **`GoogleSignIn_flowRunner`** etiketli satırlar giriş akışına aittir.

### 3.8 ID token taleplerinin okunması

```dart
var p = idToken.split('.')[1];
p += '=' * ((4 - p.length % 4) % 4);
final claims = jsonDecode(utf8.decode(base64Url.decode(p)));
print('aud=${claims['aud']} azp=${claims['azp']}');
```

```
aud = 628233156307-nh8kv….apps.googleusercontent.com   ← Web istemcisi (serverClientId)
azp = 628233156307-q2a1arm5….apps.googleusercontent.com ← eşleşen ANDROID istemcisi
```

> **`azp` altın anahtardır:** hangi Android OAuth istemcisinin gerçekten eşleştiğini söyler.
> Bir imza için `azp` alabiliyorsanız o imzanın istemcisi kayıtlıdır.

### 3.9 Düzeltme sonrası doğrulama

| Kontrol                            | Sonuç                                                          |
| ---------------------------------- | -------------------------------------------------------------- |
| Kurulum kaynağı                    | Play Kapalı Test                                               |
| Kurulu imza                        | `CN=Android, O=Google Inc.` · `e200c3c3…`                      |
| `GoogleSignIn_flowRunner … failed` | **0 kez**                                                      |
| Giriş                              | ✅ **Tamamlandı** — oturum açıldı, profil kullanıcıyı gösterdi |

---

## 4. Kök neden

### 4.1 Tek cümle

> Google Cloud projesinde **upload anahtarı** için bir Android OAuth istemcisi vardı, ama Play'in
> uygulamayı yeniden imzalamakta kullandığı **App Signing anahtarı** için yoktu.

### 4.2 İki anahtar — neden ikisi de gerekli

```
        SEN                              GOOGLE PLAY                    KULLANICI
   ┌──────────┐                      ┌─────────────────┐            ┌────────────┐
   │  AAB     │  upload anahtarıyla  │  imzayı doğrular│            │   APK      │
   │ derlenir │─────imzalanır───────►│  ve KENDİ App   │───────────►│ Play App   │
   └──────────┘                      │  Signing anahtarıyla         │ Signing    │
                                     │  YENİDEN imzalar│            │ imzalı     │
                                     └─────────────────┘            └────────────┘
        ▲                                                                  ▲
        │                                                                  │
   Bu imza yalnız                                            Google Sign-In ÇALIŞMA
   Play'e YÜKLERKEN                                          ANINDA BUNA bakar
   ve sideload'da geçerli
```

| Kullanım                  | Çalışan imza         | Gereken Android OAuth istemcisi |
| ------------------------- | -------------------- | ------------------------------- |
| `flutter run`             | Debug anahtarı       | Debug SHA-1                     |
| `adb install` release APK | **Upload anahtarı**  | Upload SHA-1                    |
| **Play'den indirme**      | **Play App Signing** | **Play App Signing SHA-1**      |

> Üçü **farklı sertifikadır**. Kullanılacak her imza için **ayrı bir Android OAuth istemcisi**
> gerekir. Bu, Play App Signing kullanan **her** projede geçerlidir.

### 4.3 Google Sign-In eşleştirmeyi nasıl yapıyor

```
Uygulama: authenticate() çağırır
    │
    ▼
Google Play Services okur:
    · paket adı            (com.example.app)
    · ÇALIŞMA ANINDAKİ imza SHA-1
    │
    ▼
Projedeki ANDROID OAuth istemcileriyle karşılaştırır
    │
    ├── eşleşme VAR  → ID token üretilir
    │                   aud = serverClientId (Web istemcisi)
    │                   azp = eşleşen Android istemcisi
    │
    └── eşleşme YOK  → DEVELOPER_ERROR
                        [28444] Developer console is not set up correctly
```

### 4.4 Neden USB çalışıyordu, Play çalışmıyordu

|                     | USB                | Play                             |
| ------------------- | ------------------ | -------------------------------- |
| Kod                 | aynı               | aynı                             |
| dart-define         | aynı               | aynı                             |
| AAB / split         | aynı               | aynı                             |
| **İmza**            | Upload (`7E:1F:…`) | **Play App Signing (`E2:00:…`)** |
| **Kayıtlı istemci** | ✅ var             | ❌ **yok**                       |
| Sonuç               | Giriş çalışır      | **DEVELOPER_ERROR**              |

---

## 5. Firebase bulguları

### 5.1 Neden Firebase şüphelenildi

- Projede bir `google-services.json` duruyordu.
- Google Sign-In dokümantasyonunun çoğu Firebase üzerinden anlatır.
- `oauth_client: 0` içeriyordu → "yapılandırma eksik" gibi okundu.

### 5.2 Neden ilgisiz çıktı — CLI kanıtı

```bash
firebase projects:list
# → uygulamanın OAuth projesi bu listede YOK

firebase apps:list --project <uygulamanın-projesi>
# → Error: Failed to list Firebase apps.
```

> Uygulamanın OAuth istemcilerinin bulunduğu proje **saf bir Google Cloud projesiydi**;
> Firebase projesi bile değildi.

### 5.3 Ölü dosya nasıl teşhis edildi

| Kontrol                         | Komut                                   | Sonuç                                   |
| ------------------------------- | --------------------------------------- | --------------------------------------- |
| Gradle eklentisi uygulanıyor mu | `grep -r "com.google.gms" android/`     | **hiç yok** → dosya derlemede okunmuyor |
| Dart'ta kullanılıyor mu         | `grep -r "firebase" lib/`               | **hiç yok**                             |
| pubspec bağımlılığı             | `grep firebase pubspec.yaml`            | **yok**                                 |
| Hangi projeye ait               | `jq .project_info google-services.json` | **başka bir proje**                     |

### 5.4 Kaldırmanın etkisi

`google-services.json` **silindi** → uygulama yeniden derlendi → **giriş çalışmaya devam etti**.

> Bu, dosyanın ölü olduğunun **deneysel** kanıtıdır. Dosya sadece gereksiz değil, **aktif olarak
> zararlıydı**: yanlış bir projeyi gösterdiği için soruşturmayı saatlerce yanlış yöne çekti.

### 5.5 Kural

> **Firebase, Google Sign-In için ZORUNLU DEĞİLDİR.** Firebase yalnız OAuth istemcilerini
> oluşturmayı kolaylaştıran bir arayüzdür. İstemciler Google Cloud'da doğrudan da
> oluşturulabilir. Firebase SDK'sı kullanılmıyorsa `google-services.json` **projede
> bulunmamalıdır**.

---

## 6. Nihai düzeltme

### 6.1 Adım adım

```
console.cloud.google.com
  ↓
Proje seçici → DOĞRU projeyi seç
      (proje numarası, serverClientId'nin başındaki sayıyla AYNI olmalı)
  ↓
API'ler ve Hizmetler
  ↓
Kimlik bilgileri
  ↓
+ KİMLİK BİLGİLERİ OLUŞTUR
  ↓
OAuth istemci kimliği
  ↓
Uygulama türü: Android
  ↓
Ad        : <Uygulama> — Play App Signing
Paket adı : com.example.app                    ← applicationId ile BİREBİR aynı
SHA-1     : <Play App Signing sertifikasının SHA-1'i>
  ↓
OLUŞTUR
```

### 6.2 Play App Signing SHA-1'i nereden alınır

**Yol A — Play Console (hızlı):**

```
Play Console → Test ve yayınlama → Kurulum → Uygulama imzalama
  → "Uygulama imzalama anahtarı sertifikası" → SHA-1
```

> ⚠️ Bu ekranda **iki** sertifika vardır. **"Yükleme anahtarı sertifikası"** DEĞİL,
> **"Uygulama imzalama anahtarı sertifikası"** alınır. En sık yapılan hata budur.

**Yol B — Cihazdan doğrudan (kesin, konsola güvenmez):**

```bash
BASE=$(adb shell pm path <package> | grep base.apk | sed 's/package://' | tr -d '\r')
adb pull "$BASE" play_base.apk
apksigner verify --print-certs --min-sdk-version 24 --max-sdk-version 36 play_base.apk
```

> Yol B, konsolda yanlış bölümden kopyalama riskini tamamen ortadan kaldırır. Bu olayda
> kullanılan yol budur.

### 6.3 Yayılma gecikmesi

| Bekleme                                     | Gerekçe                                                                                            |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **~5 dakika**                               | Yeni OAuth istemcisinin Google altyapısına yayılması                                               |
| Uygulamayı **tamamen kapat**                | Google Play Services yapılandırmayı önbelleğe alır                                                 |
| Gerekirse Play Services önbelleğini temizle | `adb shell pm clear com.google.android.gms` _(agresif; cihazdaki tüm Google oturumlarını etkiler)_ |

> Hemen denemek yanıltıcıdır: doğru yapılandırma "hâlâ bozuk" gibi görünür ve doğru çözüm
> yanlışlıkla geri alınır.

### 6.4 Kaç istemci gerekir

```
Web istemcisi            ×1   → serverClientId (backend + Flutter, AYNI değer)
Android — debug          ×1   → her geliştirici makinesi için (debug.keystore farklıdır)
Android — upload         ×1   → sideload edilen release yapılar
Android — Play signing   ×1   → Play'den inen TÜM kullanıcılar   ◄── en sık atlanan
```

---

## 7. Önleme kontrol listesi

Her yeni Android/Flutter projesinde, **Google girişi ilk kez kurulurken** uygulanır.

### 7.1 Google Cloud

- [ ] Doğru proje seçili (proje numarası `serverClientId` önekiyle aynı)
- [ ] OAuth izin ekranı yapılandırıldı (uygulama adı, destek e-postası, yetkili alan adı)
- [ ] Kapsamlar yalnız `openid`, `email`, `profile` _(fazlası doğrulama süreci başlatır)_
- [ ] Yayınlama durumu **Üretim** — ya da tüm testçiler test kullanıcısı listesinde
- [ ] **Web** OAuth istemcisi oluşturuldu ve kimliği kopyalandı
- [ ] **Android — debug** istemcisi (her geliştirici makinesi için)
- [ ] **Android — upload** istemcisi
- [ ] **Android — Play App Signing** istemcisi ⚠️ _(AAB ilk yüklendikten SONRA)_
- [ ] Tüm Android istemcilerinin paket adı `applicationId` ile birebir aynı

### 7.2 Play Console

- [ ] Play App Signing etkin (varsayılan)
- [ ] İlk AAB yüklendi → App Signing sertifikası oluştu
- [ ] App Signing SHA-1 alındı _(Yükleme anahtarı sertifikasıyla karıştırılmadı)_
- [ ] Kapalı test listesi oluşturuldu, testçiler bağlantıyı kabul etti

### 7.3 Uygulama

- [ ] `serverClientId` = **Web** istemci kimliği _(Android DEĞİL)_
- [ ] `--dart-define` derleme komutunda gerçekten var
- [ ] Backend'deki `GOOGLE_SERVER_CLIENT_ID` ile **birebir aynı**
- [ ] `.env` güncel _(bayat değer, bir sonraki derlemeye sessizce sızar)_
- [ ] Uygulama **sürüm adı + derleme numarasını gösteriyor** ⚠️ _(teşhis altyapısı)_
- [ ] `versionCode` her Play yüklemesinde artıyor
- [ ] Firebase SDK kullanılmıyorsa `google-services.json` projede **yok**
- [ ] Google hatası **yutulmuyor**: `e.code` / `e.description` günlüğe yazılıyor

### 7.4 Doğrulama — her ikisi de zorunlu

- [ ] **USB release** kurulumda giriş test edildi
- [ ] **Play Kapalı Test** kurulumunda giriş test edildi ⚠️ _(birincisi ikincisini garanti etmez)_
- [ ] İki kurulumun imzaları karşılaştırıldı
- [ ] Başarılı bir girişte `azp` talebi okundu ve beklenen istemciyi gösteriyor

---

## 8. Sık yapılan hatalar

| #   | Hata                                                | Belirti                              | Önlem                                   |
| --- | --------------------------------------------------- | ------------------------------------ | --------------------------------------- |
| 1   | **Play App Signing istemcisi oluşturulmadı**        | USB ✅ / Play ❌                     | §7.1 son madde                          |
| 2   | Play Console'da **yanlış sertifika** kopyalandı     | Aynı belirti, "ama ben ekledim"      | §6.2 Yol B ile cihazdan oku             |
| 3   | `serverClientId` olarak **Android** kimliği verildi | `idToken` **null**                   | Türü "Web uygulaması" olmalı            |
| 4   | **Yanlış proje** — istemciler farklı projelerde     | Her şey doğru görünür, çalışmaz      | Proje numarası = `serverClientId` öneki |
| 5   | **Bayat `.env`**                                    | Sessizce yanlış kimlik gömülür       | CI'da doğrulama (§12)                   |
| 6   | Firebase'in gerekli olduğu varsayıldı               | Saatler kaybedilir                   | §5.5                                    |
| 7   | Ölü `google-services.json` bırakıldı                | Yanlış projeyi işaret eder, yanıltır | Kullanılmıyorsa sil                     |
| 8   | Split APK teslimatı suçlandı                        | Yanlış yöne saatler                  | `bundletool` deneyiyle ele (§3.4)       |
| 9   | "Flutter/eklenti hatası" varsayıldı                 | Yukarı akışta zaman kaybı            | Play Services'in kendi kodunu oku       |
| 10  | Backend suçlandı                                    | Yanlış yöne saatler                  | 401 vs 503 testi (§3.1)                 |
| 11  | Uygulama **sürüm göstermiyor**                      | "Hangi yapı?" sorusu yanıtsız        | §7.3                                    |
| 12  | `dart:developer.log` ile teşhis                     | Sürüm derlemesinde **çıktı yok**     | `print()` kullan                        |
| 13  | Değişiklikten hemen sonra test                      | "Düzelmedi" sanılır                  | 5 dk bekle (§6.3)                       |
| 14  | `Phenotype` `DEVELOPER_ERROR` gürültüsü             | Yanlış alarm                         | Yalnız `Auth.Api.Credentials` bak       |

---

## 9. Hata ayıklama akış şeması

```
                        ┌──────────────────────────┐
                        │  Google girişi çalışmıyor│
                        └────────────┬─────────────┘
                                     ▼
                    ┌────────────────────────────────┐
                    │ Google düğmesi görünüyor mu?   │
                    └────────┬───────────────┬───────┘
                         HAYIR│               │EVET
                              ▼               ▼
              ┌───────────────────────┐   ┌──────────────────────────┐
              │ --dart-define verildi │   │ Hesap seçici açılıyor mu?│
              │ mi? Değer boş mu?     │   └───────┬──────────────┬───┘
              │ → derleme komutunu    │       HAYIR│              │EVET
              │   düzelt              │           ▼              ▼
              └───────────────────────┘   ┌──────────────┐  ┌─────────────────┐
                                          │ Play Services│  │ Hesap seçilince │
                                          │ güncel mi?   │  │ ne oluyor?      │
                                          └──────────────┘  └────────┬────────┘
                                                                     ▼
                                    ┌────────────────────────────────────────┐
                                    │ adb logcat -d | grep -a                │
                                    │   "Auth.Api.Credentials"               │
                                    └───────────────┬────────────────────────┘
                                                    ▼
                    ┌───────────────────────────────────────────────────┐
                    │ "GoogleSignIn_flowRunner … Flow failed" var mı?    │
                    └──────┬────────────────────────────────┬───────────┘
                       EVET│                                │HAYIR
                           ▼                                ▼
              ┌────────────────────────┐        ┌──────────────────────────┐
              │ DEVELOPER_ERROR        │        │ idToken alındı →         │
              │ = paket adı + imza     │        │ sorun BACKEND'te         │
              │   eşleşmiyor           │        │ → 401? aud uyuşmazlığı   │
              └───────────┬────────────┘        │ → 503? env eksik         │
                          ▼                     └──────────────────────────┘
        ┌─────────────────────────────────────┐
        │ USB release kurulumda çalışıyor mu? │
        └────────┬────────────────────┬───────┘
             EVET│                    │HAYIR
                 ▼                    ▼
   ┌──────────────────────────┐  ┌────────────────────────────────┐
   │ SORUN PLAY İMZASINDA     │  │ Upload/debug SHA-1 kayıtlı mı? │
   │                          │  │ Paket adı doğru mu?            │
   │ 1. Play'den kur          │  │ Doğru projede misin?           │
   │ 2. base.apk'yı çek       │  │ (azp talebiyle doğrula)        │
   │ 3. apksigner ile SHA-1   │  └────────────────────────────────┘
   │ 4. Android OAuth         │
   │    istemcisi oluştur     │
   │ 5. 5 dk bekle, tekrar    │
   └──────────────────────────┘
```

### 9.1 Hızlı üçlü test (5 dakika)

| #   | Test                                        | Sonuç → anlam                                       |
| --- | ------------------------------------------- | --------------------------------------------------- |
| 1   | `curl POST /api/auth/google` geçersiz token | 401 → backend tamam · 503 → env eksik               |
| 2   | USB release kurulumda giriş                 | ✅ → kod tamam, sorun imzada · ❌ → SHA/paket/proje |
| 3   | `adb logcat \| grep Auth.Api.Credentials`   | `Flow failed` → istemci eşleşmiyor                  |

---

## 10. Çıkarılan dersler

### 10.1 İlk olarak her zaman kontrol edilmeli

1. **Uygulama hangi yapıyı çalıştırıyor?** Sürüm + derleme numarası görünmüyorsa, hiçbir saha
   raporu güvenilir değildir.
2. **Google'ın kendi hata kodu ne diyor?** Play Services zaten cevabı veriyordu
   (`Developer console is not set up correctly`) — kod onu yutuyordu.
3. **Hangi imzayla çalışıyor?** USB ve Play **farklı sertifikalardır**; bu ayrım her şeyi belirler.

### 10.2 En çok zaman kaybettirenler

| Sıra | Neden                                         | Kayıp                                                   |
| ---- | --------------------------------------------- | ------------------------------------------------------- |
| 1    | Hatanın kodda yutulması                       | Her tur, cihaza özel geçici günlük eklemeyi gerektirdi  |
| 2    | Uygulamanın sürüm göstermemesi                | "Play eski yapı mı sunuyor?" sorusu turlarca açık kaldı |
| 3    | Yanlış projeye ait ölü `google-services.json` | Firebase'i defalarca şüpheli hale getirdi               |
| 4    | Üç farklı proje numarasının ortalıkta olması  | Her biri makul bir hipotez üretti                       |

### 10.3 Belirleyici kanıtlar

| Kanıt                                            | Neyi kesinleştirdi                                |
| ------------------------------------------------ | ------------------------------------------------- |
| **`bundletool` split deneyi**                    | Kod/AAB/split masumdur → değişken yalnız imza     |
| **Play APK'sının cihazdan çekilmesi**            | Gerçek App Signing SHA-1'i konsola bakmadan verdi |
| **`Auth.Api.Credentials` + `DEVELOPER_ERROR`**   | Başarısızlığın kesin mekanizması                  |
| **`azp` talebi**                                 | Hangi Android istemcisinin eşleştiğini gösterdi   |
| **`google-services.json` silinip test edilmesi** | Ölü olduğunu deneysel olarak kanıtladı            |

### 10.4 Gelecekte nasıl kısaltılır

> Bu soruşturma **3 gün** sürdü. Aşağıdaki üç şey baştan olsaydı **30 dakika** sürerdi:

1. Uygulamada **sürüm + derleme numarası** görünür olsaydı
2. Google hatası **yutulmayıp günlüğe yazılsaydı**
3. Kurulumdan sonra **Play imzası bir kez** okunup istemci listesiyle karşılaştırılsaydı

**Altın kural:**

> **Bir imzayla test etmek, diğer imzayla çalışacağını GARANTİ ETMEZ.**
> Play App Signing kullanan her projede giriş **Play'den kurulumda** ayrıca test edilmelidir.

---

## 11. Yeniden kullanılabilir komutlar

### 11.1 Parmak izleri (keytool)

```bash
# Debug anahtarı
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA1

# Upload anahtarı
keytool -list -v -keystore upload.jks -alias upload | grep -E "SHA1|SHA256"

# Bir APK'yı imzalayan sertifika
unzip -p app.apk 'META-INF/*.RSA' | keytool -printcert | grep -E "Owner|SHA1"
```

### 11.2 İmza doğrulama (apksigner / jarsigner)

```bash
# APK — v2/v3 imza şeması
apksigner verify --print-certs app.apk

# APK — Play'in post-kuantum bloğu varsa
apksigner verify --print-certs --min-sdk-version 24 --max-sdk-version 36 app.apk

# AAB — apksigner ÇALIŞMAZ, jarsigner kullanılır
jarsigner -verify -verbose:summary app-release.aab      # beklenen: "jar verified."

# Debug anahtarıyla imzalanmadığını doğrula
unzip -p app-release.aab 'META-INF/*.RSA' | keytool -printcert | grep Owner
# "CN=Android Debug" GÖRMEMELİSİN
```

### 11.3 Cihaz (adb)

```bash
adb devices -l
adb shell pm path <package>                    # kurulu APK/split yolları
adb shell dumpsys package <package> | grep -E "versionCode|versionName"
adb pull "<yol>" local.apk
adb shell pm clear <package>                   # uygulama verisini sıfırla
adb uninstall <package>
adb logcat -c                                  # tamponu temizle
adb logcat -d | grep -aiE "Auth.Api.Credentials|GoogleSignIn_flowRunner|DEVELOPER_ERROR"
adb shell am start -a android.intent.action.VIEW -d "market://details?id=<package>"
adb reverse tcp:3000 tcp:3000                  # cihazdan yerel backend'e
```

### 11.4 Bundletool (Play'i taklit et)

```bash
bundletool build-apks --bundle=app-release.aab --output=play.apks \
  --ks=upload.jks --ks-pass=pass:<parola> \
  --ks-key-alias=upload --key-pass=pass:<parola> \
  --connected-device --device-id=<SERIAL>

bundletool install-apks --apks=play.apks --device-id=<SERIAL>
bundletool dump manifest --bundle=app-release.aab | grep -oE 'versionCode="[0-9]+"'
```

### 11.5 Google Cloud / Firebase (gcloud, firebase)

```bash
gcloud auth list
gcloud config list
gcloud projects list --format="table(projectId,projectNumber,name)"
gcloud projects describe <PROJECT_ID> --format="value(projectNumber)"
gcloud services list --enabled --project <PROJECT_ID>

firebase projects:list
firebase apps:list --project <PROJECT_ID>
firebase apps:android:sha:list <APP_ID>        # Firebase kullanılıyorsa SHA listesi
```

> ⚠️ **Genel OAuth 2.0 istemcileri gcloud ile LİSTELENEMEZ.** Public API yoktur
> (`gcloud iam oauth-clients` Workforce Identity içindir). Envanteri dolaylı kanıtla doğrulayın:
> `azp` talebi + `DEVELOPER_ERROR`.

### 11.6 Flutter

```bash
flutter clean && flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
flutter build appbundle --release --dart-define-from-file=defines.json
```

### 11.7 Derlenmiş artefaktı denetle

```bash
# dart-define gerçekten gömüldü mü
unzip -qo app-release.aab -d /tmp/aab
strings /tmp/aab/base/lib/arm64-v8a/libapp.so \
  | grep -oE "[0-9]+-[0-9a-z]+\.apps\.googleusercontent\.com"

# APK için
unzip -qo app-release.apk -d /tmp/apk
strings /tmp/apk/lib/arm64-v8a/libapp.so | grep googleusercontent
```

### 11.8 Backend

```bash
# Sunucuda GOOGLE_SERVER_CLIENT_ID ayarlı mı  (401 = evet, 503 = hayır)
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://<host>/api/auth/google \
  -H 'content-type: application/json' -d '{"idToken":"a.b.c"}'

# Bir idToken'ın audience'ını oku (yalnız teşhis; imza doğrulamaz)
python3 -c "
import base64,json,sys
p=sys.argv[1].split('.')[1]; p+='='*(-len(p)%4)
c=json.loads(base64.urlsafe_b64decode(p)); print('aud=',c['aud'],'azp=',c.get('azp'))
" <idToken>
```

---

## 12. Gelecek projeler için otomasyon

### 12.1 Uygulamada sürüm + derleme numarası _(en yüksek getiri)_

```dart
class AppVersion {
  final String name;   // 1.0.0
  final String build;  // 4   ← hangi AAB olduğunu KESİN söyler
  String get label => 'v$name ($build)';

  static Future<AppVersion> load() async {
    try {
      final i = await PackageInfo.fromPlatform();
      return AppVersion(name: i.version, build: i.buildNumber);
    } catch (_) {
      return unknown;                       // okunamazsa ÇÖKMEZ
    }
  }
}
```

Profil/Ayarlar ekranının altında gösterin. **Sabit dize kullanmayın.**

### 12.2 Hata yutmayı yasakla

```dart
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) return const Cancelled();

  final technical = 'code=${e.code} description=${e.description}';
  log('[auth/google] $technical');          // ham neden KAYBOLMAZ
  return SignInError(userMessageFor(e.description), technical: technical);
}
```

Ve mesajı **eyleme dönüştürün**: düzelmeyecek bir yapılandırma hatasında "tekrar dene" demeyin.

### 12.3 `scripts/doctor.mjs` — dağıtım teşhisi

Tek komutla tüm entegrasyonları ölçen, hiçbir şeyi değiştirmeyen, engelleyici bulguda `1`
koduyla çıkan bir betik. Örnek kontroller:

```
✅ Veritabanı          configured
✅ Google (sunucu)     GOOGLE_SERVER_CLIENT_ID ayarlı   (401 testi)
⚠️ Webhook             sır ayarlı değil
✅ Paket adı           com.example.app
✅ İmzalama anahtarı   upload (debug DEĞİL)
   └─ Android OAuth istemcisine girilecek SHA-1: 7E:1F:…
```

### 12.4 İmza doğrulama betiği

```bash
#!/usr/bin/env bash
# scripts/verify-signing.sh — yayın öncesi kapı
AAB="$1"
jarsigner -verify "$AAB" | grep -q "jar verified" || { echo "AAB imzasız"; exit 1; }
unzip -p "$AAB" 'META-INF/*.RSA' | keytool -printcert | grep -q "CN=Android Debug" \
  && { echo "HATA: debug anahtarıyla imzalanmış"; exit 1; }
echo "imza tamam"
```

### 12.5 Ortam doğrulama (CI)

```bash
# .env'deki istemci kimliğinin proje numarası, beklenen projeyle aynı mı
EXPECTED_PROJECT=628233156307
ACTUAL=$(grep -E "^GOOGLE_SERVER_CLIENT_ID=" .env | cut -d= -f2 | cut -d- -f1)
[ "$ACTUAL" = "$EXPECTED_PROJECT" ] || { echo "BAYAT .env: $ACTUAL"; exit 1; }
```

> Bu tek kontrol, bu olaydaki "bayat `.env`" tuzağını tamamen kapatır.

### 12.6 Yayın öncesi kapı: dart-define gerçekten gömüldü mü

```bash
strings build/app/outputs/bundle/release/base/lib/arm64-v8a/libapp.so \
  | grep -q "$EXPECTED_CLIENT_ID" || { echo "dart-define GÖMÜLMEMİŞ"; exit 1; }
```

### 12.7 Yayın sonrası doğrulama (elle ama zorunlu)

- [ ] Play'den kur, **Profil → sürüm satırını** oku → beklenen derleme numarası mı
- [ ] Google girişini **Play kurulumunda** dene
- [ ] `adb logcat | grep Auth.Api.Credentials` → `Flow failed` **yok**

### 12.8 Sır hijyeni

Bu olay sırasında depoda **iki servis hesabı özel anahtarı** bulundu; biri `git add -A` ile
commit'e girdi (push'tan önce yakalandı).

```gitignore
**/*service*account*.json
**/*playconsole*.json
android/app/*.json
*-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f].json
```

Ayrıca CI'da **gitleaks** çalıştırın. Konsoldan indirilen anahtarların adı öngörülemez;
desenleri **geniş** tutun.

---

## Ek — Tek sayfalık özet

> **Belirti:** USB'de çalışıyor, Play'den kurulumda çalışmıyor, hesap seçici açılıyor sonra
> hiçbir şey olmuyor.
>
> **İlk komut:**
> `adb logcat -d | grep -a "Auth.Api.Credentials"`
>
> **`Flow failed` + `DEVELOPER_ERROR` görürsen:** paket adı + çalışma anındaki imza, hiçbir
> Android OAuth istemcisiyle eşleşmiyor.
>
> **Sebep %90 ihtimalle:** Play App Signing sertifikası için Android OAuth istemcisi yok.
>
> **Çözüm:** Play'den kurulu APK'yı çek → `apksigner verify --print-certs --max-sdk-version 36`
> → çıkan SHA-1 ile Google Cloud'da **Android** OAuth istemcisi oluştur → 5 dakika bekle.
>
> **Unutma:** Upload anahtarı ≠ Play App Signing anahtarı. İkisi için de ayrı istemci gerekir.
