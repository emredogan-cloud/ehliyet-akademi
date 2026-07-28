# Google Kimlik Doğrulama — Nihai Kök Neden Raporu

**2026-07-28 · Cihaz: AYXSUKIVJVPZ7HPZ (Android 11) · Tüm bulgular CLI çıktısı, cihaz günlüğü veya derlenmiş artefakt ile kanıtlanmıştır.**

> Bu raporda **hiçbir varsayım yoktur.** Play'den kurulu gerçek yapı cihaza indirildi, sertifikası
> çıkarıldı ve başarısız akış birebir yeniden üretildi.

---

## 1. Kök neden

**Google Cloud projesi `628233156307` içinde, uygulamanın Play App Signing sertifikasına karşılık
gelen bir Android OAuth istemcisi YOKTUR.**

Yalnız **upload anahtarının** istemcisi kayıtlıdır. Play, uygulamayı kullanıcıya dağıtırken kendi
App Signing anahtarıyla **yeniden imzaladığı** için, Play'den inen yapının imzası hiçbir kayıtlı
istemciyle eşleşmez ve Google Play Services `DEVELOPER_ERROR` döndürür.

|                      | SHA-1                                                             | Kayıtlı mı                     | Sonuç               |
| -------------------- | ----------------------------------------------------------------- | ------------------------------ | ------------------- |
| Upload anahtarı      | `7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57`     | ✅ Evet (`azp` ile kanıtlandı) | Giriş **çalışıyor** |
| **Play App Signing** | **`E2:00:C3:C3:ED:75:21:59:41:C4:5C:36:7C:65:CD:81:F8:E8:E1:A5`** | ❌ **Hayır**                   | **DEVELOPER_ERROR** |

---

## 2. Kanıtlar

### 2.1 Play'den kurulu gerçek yapının sertifikası

Cihaz kapalı test kapsamında olduğu için uygulama **Play üzerinden kuruldu** ve APK cihazdan
çekildi:

```
$ adb shell pm path com.ehliyetegitim.ehliyet_akademi
package:/data/app/~~PjHqZzLIqVsJXEyVAvavYQ==/…/base.apk
package:/data/app/~~PjHqZzLIqVsJXEyVAvavYQ==/…/split_config.arm64_v8a.apk
package:/data/app/~~PjHqZzLIqVsJXEyVAvavYQ==/…/split_config.tr.apk
package:/data/app/~~PjHqZzLIqVsJXEyVAvavYQ==/…/split_config.xxhdpi.apk

$ apksigner verify --print-certs --min-sdk-version 24 --max-sdk-version 36 base.apk
V3.0 Signer: certificate DN: CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US
V3.0 Signer: certificate SHA-1 digest:   e200c3c3ed75215941c45c367c65cd81f8e8e1a5
V3.0 Signer: certificate SHA-256 digest: 32d23e34775b4c56dac1d73b35be340153aff0319ca7c9f75e35ceeb44a8e5d6
```

> `CN=Android, O=Google Inc.` — Play'in **kendi ürettiği** App Signing sertifikasının ayırt edici
> ayrıntısıdır. Upload anahtarının DN'i `CN=Emre Dogan`'dır; ikisi farklı sertifikadır.
>
> Not: `apksigner` önce başarısız oldu çünkü Play artık **post-kuantum hibrit imza bloğu**
> (`ML-DSA`, minSdk 37+) ekliyor ve JDK 17 bunu çözemiyor. `--max-sdk-version 36` ile v3.0
> imzacısı okundu.

### 2.2 Play yapısında başarısızlık — cihaz günlüğü

Aynı cihazda, Play'den kurulu yapıyla Google girişi denendi:

```
ActivityTaskManager: START … SignInCredentialChooserActivity        ← hesap seçici açıldı
Auth.Api.Credentials: [AccountReauth_flowRunner] Flow failed.
Auth.Api.Credentials: [GoogleSignIn_flowRunner] Flow failed.
Auth.Api.Credentials: chbm: [16] Account reauth failed.
GoogleApiManager: ConnectionResult{statusCode=DEVELOPER_ERROR, resolution=null}
```

`DEVELOPER_ERROR`, Google Sign-In'de tek bir anlama gelir: **çağıran uygulamanın paket adı +
çalışma anındaki imza SHA-1'i, projedeki hiçbir Android OAuth istemcisiyle eşleşmiyor.**

### 2.3 Aynı AAB, aynı split teslimat, farklı imza → çalışıyor

Kontrol deneyi. **Aynı AAB**, `bundletool` ile Play'in ürettiği split APK'lara dönüştürüldü ve
**upload anahtarıyla** imzalanıp kuruldu:

```
$ adb shell pm path com.ehliyetegitim.ehliyet_akademi
base.apk · split_config.arm64_v8a.apk · split_config.tr.apk · split_config.xxhdpi.apk
```

**Sonuç: giriş BAŞARILI** (Profil "Murat Dogan · muratdogan010114@gmail.com" gösterdi).

> Bu deney tek başına **kodu, dart-define'ı, AAB paketlemesini ve split teslimatını** şüpheli
> olmaktan çıkarır. Play kurulumundan tek farkı imzalayan sertifikadır.

### 2.4 Hangi Android istemcisinin eşleştiği — token talebiyle kanıt

Çalışan (upload anahtarlı) yapıda ID token'ın talepleri okundu (**token yazılmadı**, yalnız
talepler):

```
[CLAIMS] aud=628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21.apps.googleusercontent.com
[CLAIMS] azp=628233156307-q2a1arm5guv9qa0pqp4s0ql5bdoarrrg.apps.googleusercontent.com
[CLAIMS] iss=https://accounts.google.com email_verified=true
```

- `aud` = **Web istemcisi** (serverClientId) — doğru, proje `628233156307`
- `azp` = **Android istemcisi** — token'ı yetkilendiren istemci; upload anahtarına karşılık gelir

Yani projede **bir** Android istemcisi vardır ve o upload anahtarınındır. Play imzası için
ikinci bir istemci gereklidir; §2.2 onun bulunmadığını gösterir.

### 2.5 Play yapısı doğru istemci kimliğini taşıyor

Play'den çekilen APK'nın AOT anlık görüntüsünden:

```
$ strings lib/arm64-v8a/libapp.so | grep googleusercontent
628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21.apps.googleusercontent.com
```

`versionCode=4` · `versionName=1.0.0` — Play güncel yapıyı sunuyor.

> **Bu, önceki raporda açık bırakılan "A olasılığını" (Play eski yapı sunuyor) kesin olarak
> ELER.** Play doğru sürümü, doğru istemci kimliğiyle sunuyor. Geriye yalnız imza kalır.

---

## 3. Firebase denetimi

**Sonuç: Firebase kimlik doğrulamaya HİÇ katılmıyor. Tek kalıntı yanlış projeye ait ölü bir
dosyaydı ve kaldırıldı.**

### 3.1 CLI kanıtı

```
$ firebase projects:list
┌──────────────────────┬───────────────────────┬────────────────┐
│ ehliyet-akademi      │ ehliyet-akademi-3daa1 │ 648053691908   │
│ kindredPaws          │ kindredpaws-2c49e     │ 121717013179   │
└──────────────────────┴───────────────────────┴────────────────┘
2 project(s) total.

$ firebase apps:list --project ehliyet-akademi-sinav-2026
Error: Failed to list Firebase apps.
```

> Uygulamanın OAuth istemcilerinin bulunduğu proje (`ehliyet-akademi-sinav-2026`) **bir Firebase
> projesi değildir.** Firebase CLI onu tanımıyor.

### 3.2 Depo kanıtı

| Arama                                                                      | Sonuç                                                                     |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `firebase_core` / `firebase_auth` (pubspec)                                | **yok**                                                                   |
| `Firebase.initializeApp` / `FirebaseApp` / `DefaultFirebaseOptions` (Dart) | **yok**                                                                   |
| `firebase_options.dart`                                                    | **yok**                                                                   |
| `com.google.gms.google-services` (Gradle)                                  | **uygulanmıyor**                                                          |
| `google-services.json`                                                     | vardı — **ait olduğu proje `648053691908`**, uygulamanınki `628233156307` |

### 3.3 Ölü olduğunun deneysel kanıtı

`google-services.json` silindi, uygulama yeniden derlendi ve **giriş yine çalıştı**. Dosya
derlemede hiç okunmuyordu; üstelik **yanlış projeyi** gösterdiği için teşhiste aktif olarak
yanıltıcıydı.

---

## 4. Google Cloud denetimi

```
$ gcloud auth list
ACTIVE  ACCOUNT
*       emre30283@gmail.com

$ gcloud config list
project = ehliyet-akademi-sinav-2026

$ gcloud projects list
PROJECT_ID                  PROJECT_NUMBER
ehliyet-akademi-3daa1       648053691908      ← Firebase projesi (KULLANILMIYOR)
ehliyet-akademi-sinav-2026  628233156307      ← uygulamanın OAuth projesi
…
```

### 4.1 Üç proje numarası karışıklığı — çözüldü

| Numara           | Nerede geçiyor                        | Durum                                                      |
| ---------------- | ------------------------------------- | ---------------------------------------------------------- |
| **628233156307** | AAB'ye gömülü istemci · `aud` · `azp` | ✅ **Doğru ve etkin proje**                                |
| 648053691908     | `google-services.json`                | ❌ İlgisiz Firebase projesi — dosya kaldırıldı             |
| 430417323295     | depodaki `.env`                       | ❌ **Hesabın hiçbir projesine ait değil** — bayat/geçersiz |

### 4.2 Etkin API'ler (628233156307)

`androidpublisher` · `bigquery*` · `datastore` · `logging` · `monitoring` · `pubsub` …
Google Sign-In için ek API gerekmez; `identitytoolkit`/`firebase` **etkin değil** ve gerekmiyor.

### 4.3 OAuth istemcileri neden CLI ile listelenemedi

Genel OAuth 2.0 istemci kimlikleri **hiçbir public API/gcloud komutuyla listelenemez**
(`gcloud iam oauth-clients` Workforce Identity içindir, `iap oauth-brands` yalnız IAP içindir ve
2026-03'te kapatılıyor). Bu yüzden istemci envanteri **dolaylı ama kesin** yolla kanıtlandı:
`azp` talebi (§2.4) + `DEVELOPER_ERROR` (§2.2).

---

## 5. Bağımlılık grafiği

```
Google Play Services (cihaz)
   │  paket adı + ÇALIŞMA ANINDAKİ imza SHA-1
   ▼
Android OAuth istemcisi   ← ✅ upload anahtarı için VAR
   │                        ❌ Play App Signing için YOK   ◄── KIRILMA NOKTASI
   ▼
Google OAuth (accounts.google.com)
   │  ID token üretir · aud = Web istemcisi · azp = Android istemcisi
   ▼
Web OAuth istemcisi (serverClientId)  ← ✅ 628233156307-nh8kv…
   │
   ▼
Backend  POST /api/auth/google
   │  JWKS ile RS256 imza · iss/aud/exp/email_verified doğrulaması
   ▼
Oturum (Bearer jetonu, sunucuda saklı)
   │
   ▼
TokenStore → Navigation → Ana Sayfa

Firebase: bu zincirin HİÇBİR adımında yer almıyor.
```

---

## 6. Kod değişiklikleri ve kaldırılan bileşenler

| Öge                                            | İşlem                             | Gerekçe                                                                                                                                |
| ---------------------------------------------- | --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `apps/mobile/android/app/google-services.json` | **Silindi**                       | Gradle eklentisi uygulanmıyor → hiç okunmuyordu; üstelik **yanlış projeye** aitti. Silindikten sonra giriş çalışmaya devam etti (§3.3) |
| `.gitignore`                                   | Açıklama eklendi                  | Dosyanın neden istenmediği yazıldı                                                                                                     |
| `google_auth_service.dart`                     | Geçici teşhis kodu **kaldırıldı** | `[SIGNIN]` / `[CLAIMS]` izleri yalnız soruşturma içindi                                                                                |

**Kaldırılmayanlar ve nedeni:** `firebase_*` paketi, `firebase_options.dart`, Gradle eklentisi
zaten **hiç yoktu** — kaldıracak bir şey bulunmadı.

---

## 7. Derleme doğrulaması

```
flutter clean && flutter pub get      → tamam
flutter analyze                       → 0 sorun
flutter test                          → 404 test geçti
flutter build apk --release           → 79,9 MB
flutter build appbundle --release     → 64,4 MB
jarsigner -verify                     → jar verified.
versionCode                           → 4
gömülü istemci kimliği                → 628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21…
google-services.json AAB içinde       → yok ✓
```

**Nihai AAB:**

```
/home/emre/Downloads/OTHER-RESEARCH/other_report/ehliyet-akademi/apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

---

## 8. Google girişi doğrulaması

| Senaryo                                       | İmza                 | Sonuç                  | Kanıt                                                        |
| --------------------------------------------- | -------------------- | ---------------------- | ------------------------------------------------------------ |
| USB, monolitik APK                            | Upload               | ✅ **Başarılı**        | Profil "Murat Dogan" · `Auth.Api.Credentials` hatası **yok** |
| Split kurulum (Play biçimi)                   | Upload               | ✅ **Başarılı**        | Profil "Murat Dogan"                                         |
| **Play Kapalı Test**                          | **Play App Signing** | ❌ **DEVELOPER_ERROR** | `GoogleSignIn_flowRunner: Flow failed`                       |
| USB, `google-services.json` silindikten sonra | Upload               | ✅ **Başarılı**        | Dosyanın ölü olduğunu kanıtlar                               |

---

## 9. Sonuç ve tek yapılacak iş

Uygulama kodu, AAB, dart-define, split teslimat ve backend **tamamen doğrudur ve kanıtlanmıştır**.
Eksik olan tek şey bir konsol kaydıdır.

### Yapılacak (kod değil — Google Cloud Console)

```
console.cloud.google.com
  ↓
Proje seçici → Ehliyet Akademi Sinav 2026   (proje numarası 628233156307)
  ↓
API'ler ve Hizmetler → Kimlik bilgileri
  ↓
+ KİMLİK BİLGİLERİ OLUŞTUR → OAuth istemci kimliği
  ↓
Uygulama türü: Android
   Ad        : Ehliyet Akademi — Play App Signing
   Paket adı : com.ehliyetegitim.ehliyet_akademi
   SHA-1     : E2:00:C3:C3:ED:75:21:59:41:C4:5C:36:7C:65:CD:81:F8:E8:E1:A5
  ↓
OLUŞTUR → 5 dakika bekle → Play'den kurulu uygulamayı yeniden dene
```

> ⚠️ **En sık hata:** Play Console'daki **"Yükleme anahtarı sertifikası"** SHA-1'ini kopyalamak.
> Doğrusu **"Uygulama imzalama anahtarı sertifikası"**dır. Yukarıdaki değer, Play'in cihaza
> gerçekten dağıttığı APK'dan **doğrudan okunmuştur** — Play Console'a bakmaya gerek yoktur.

### Ayrıca düzeltilmesi gereken (yayın engelleyici değil)

Depodaki `.env` içindeki `GOOGLE_SERVER_CLIENT_ID` hâlâ `430417323295-…` — **hiçbir projeye ait
olmayan** bayat bir değer. Bu değerle derlenen her yapı Google girişinde başarısız olur.
Doğrusu:

```
GOOGLE_SERVER_CLIENT_ID=628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21.apps.googleusercontent.com
```

### Neden bu adımı ben yapamadım

Genel OAuth 2.0 istemcisi oluşturmak için **public API yoktur**; `gcloud` bu işlemi
desteklemez (§4.3). Konsol dışında bir yolu bulunmamaktadır.
