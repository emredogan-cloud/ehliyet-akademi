# Google ile Giriş — Sıfırdan Kurulum (Firebase YOK)

**Ehliyet Akademi · 2026-07-27**

Bu belge Google Sign-In'i **Firebase kullanmadan** sıfırdan kurar. Gereken tek altyapı
Google Cloud Console'dur; Firebase yalnız bir kolaylık katmanıdır ve bu projede **hiç
kullanılmamaktadır**.

|                  |                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------- |
| Uygulama kimliği | `com.ehliyetegitim.ehliyet_akademi`                                                         |
| Backend          | `https://www.ehliyetegitim.com`                                                             |
| Flutter paketi   | `google_sign_in: ^7.2.0`                                                                    |
| Kapsam           | **Yalnız Google ile giriş.** Ödeme, faturalandırma, RevenueCat bu belgenin konusu değildir. |

> **Bu projede Firebase gerçekten kullanılmıyor.** Doğrulandı: `apps/mobile/android/` altındaki
> hiçbir Gradle dosyasında `com.google.gms.google-services` eklentisi uygulanmıyor. Yani
> `google-services.json` dosyası **derleme sırasında hiç okunmuyor** ve silinebilir. Google
> kimliği yalnızca `--dart-define` üzerinden koda girer.

---

## BÖLÜM 1 — Gerçekte ne gerekiyor

Google girişi dört ayrı yerin **birlikte** doğru olmasını gerektirir. Her biri farklı bir şeyden
sorumludur ve biri eksikse giriş sessizce başarısız olur.

### 1.1 Sorumluluk dağılımı

| Bileşen                  | Neyi sağlar                                                                                                  | Bunsuz ne olur                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| **Google Cloud Console** | OAuth istemcilerini ve izin ekranını barındırır. Google'ın "bu uygulama kimdir?" sorusunun cevabı buradadır. | Hesap seçici açılmaz ya da token üretilmez                     |
| **Google Play Console**  | Uygulamayı kullanıcıya **dağıtırken kullanılan imzayı** belirler (Play App Signing).                         | Play'den inen yapıda giriş çalışmaz (sideload'da çalışsa bile) |
| **Flutter (mobil)**      | Hesap seçiciyi açar, Google'dan **ID token** alır, backend'e gönderir.                                       | Düğme hiç görünmez veya token null döner                       |
| **Backend**              | ID token'ı Google'ın açık anahtarlarıyla **doğrular** ve kendi oturumuna çevirir.                            | Giriş 401/503 ile reddedilir                                   |

### 1.2 Her bileşenin tam görevi

**Google Cloud Console**

- OAuth **izin ekranı** (kullanıcının gördüğü "… hesabınıza erişmek istiyor" penceresi)
- **Web OAuth istemcisi** → ID token'ın hedefi (`aud`). Hem Flutter hem backend bunu kullanır.
- **Android OAuth istemcisi** → paket adı + imza parmak izi eşleşmesi. Kodda **hiç geçmez**,
  ama var olmak zorundadır.

**Google Play Console**

- Yalnız **tek bir şey** için gereklidir: uygulamayı Play üzerinden dağıtırken Play, AAB'yi
  **kendi anahtarıyla yeniden imzalar**. O imzanın SHA-1'i Google Cloud'daki Android istemcisine
  eklenmezse Play'den inen yapıda giriş çalışmaz.

**Flutter**

- `serverClientId` olarak **Web** istemci kimliğini alır (derleme zamanında gömülür).
- Hesap seçiciyi açar, `idToken` alır, `POST /api/auth/google` ile backend'e gönderir.

**Backend**

- `GOOGLE_SERVER_CLIENT_ID` ortam değişkenini okur.
- Google'ın JWKS uç noktasından açık anahtarları çeker, **RS256 imzasını** doğrular.
- `iss` · `aud` · `exp` · `email_verified` iddialarını denetler.
- Kullanıcıyı bulur ya da oluşturur, kendi **Bearer oturumunu** döner.

### 1.3 Akışın tek bakışta özeti

```
Flutter                Google Play Services        Google                Backend
  │                            │                      │                     │
  ├─ initialize(               │                      │                     │
  │    serverClientId = WEB)   │                      │                     │
  ├─ authenticate() ──────────►│                      │                     │
  │                            ├─ paket adı + imza ──►│                     │
  │                            │   (ANDROID istemcisi │                     │
  │                            │    ile eşleşmeli)    │                     │
  │                            │◄──── hesap seçici ───┤                     │
  │◄──── idToken (aud = WEB) ──┤                      │                     │
  ├─ POST /api/auth/google ──────────────────────────────────────────────►  │
  │                            │                      │◄─ JWKS isteği ──────┤
  │                            │                      ├─ açık anahtarlar ──►│
  │                            │                      │                     ├─ imza + aud doğrula
  │◄────────────── Bearer oturum jetonu ───────────────────────────────────┤
```

> **Kritik nokta:** hesap seçicinin **açılması** Android istemcisine bağlıdır; token'ın
> **kabul edilmesi** Web istemcisine bağlıdır. İkisi farklı işler yapar ve ikisi de gereklidir.

---

## BÖLÜM 2 — Google Cloud Console

### 2.1 Proje seçimi veya oluşturma

```
console.cloud.google.com
  ↓
Üst çubuktaki proje seçici (logonun sağındaki açılır liste)
  ↓
YENİ PROJE            (yoksa)
  ↓
Proje adı:      ehliyet-akademi
Kuruluş:        (kişisel hesapta "Kuruluş yok")
  ↓
OLUŞTUR
  ↓
Proje seçicide yeni projeyi SEÇ
```

> ⚠️ Bundan sonraki her adımda **doğru projede** olduğundan emin ol. Üst çubuktaki proje adı
> her sayfada görünür. Yanlış projede oluşturulan istemci hiçbir işe yaramaz ve teşhisi
> zordur (§9.5).

### 2.2 OAuth izin ekranı

Google bu bölümü 2025'te yeniden adlandırdı. Konsolun sürümüne göre iki yoldan biri geçerlidir:

**Yeni arayüz:**

```
Sol menü → API'ler ve Hizmetler → OAuth izin ekranı
  (veya doğrudan sol menüde "Google Auth Platform")
  ↓
BAŞLAYIN / YAPILANDIR
```

**Eski arayüz:**

```
Sol menü → API'ler ve Hizmetler → OAuth izin ekranı
```

#### 2.2.1 Kullanıcı türü

```
Kullanıcı türü:
   ○ Dahili   (yalnız Google Workspace kuruluşundaki hesaplar)
   ● Harici   ← BUNU SEÇ
  ↓
OLUŞTUR
```

> **Neden Harici?** Uygulama herkese açık; kullanıcılar kişisel Gmail hesaplarıyla girecek.
> "Dahili" yalnız Workspace kuruluşu içindir ve kişisel hesaplarda seçenek olarak çıkmaz.

#### 2.2.2 Uygulama bilgileri

```
Uygulama adı:                Ehliyet Akademi
Kullanıcı destek e-postası:  <destek adresin>
Uygulama logosu:             (isteğe bağlı — yüklersen Google DOĞRULAMA ister, bkz. §2.2.6)
```

#### 2.2.3 Uygulama alan adı

```
Uygulama ana sayfası:        https://www.ehliyetegitim.com
Gizlilik politikası:         https://www.ehliyetegitim.com/gizlilik
Kullanım şartları:           https://www.ehliyetegitim.com/kosullar
```

#### 2.2.4 Yetkili alan adları

```
Yetkili alan adları
  ↓
ALAN ADI EKLE
  ↓
ehliyetegitim.com          ← "www." YAZILMAZ, yalnız kök alan adı
```

**Kuralları:**

- Yalnız **kök alan adı** girilir (`ehliyetegitim.com`), alt alan adı değil.
- `http://` veya `https://` **yazılmaz**.
- Yukarıdaki ana sayfa / gizlilik / şartlar bağlantılarının alan adı burada **kayıtlı olmalıdır**;
  değilse Google kaydetmeye izin vermez.
- `localhost` buraya **eklenemez** ve eklenmesine gerek de yoktur.

#### 2.2.5 Kapsamlar (scopes)

```
KAPSAMLARI EKLE VEYA KALDIR
  ↓
Şu üçünü işaretle:
   ☑ openid
   ☑ .../auth/userinfo.email
   ☑ .../auth/userinfo.profile
  ↓
GÜNCELLE → KAYDET VE DEVAM ET
```

| Kapsam             | Ne getirir                          | Bu projede kullanımı                          |
| ------------------ | ----------------------------------- | --------------------------------------------- |
| `openid`           | ID token üretilmesini sağlar        | **Zorunlu** — token'ın kendisi buna bağlı     |
| `userinfo.email`   | `email`, `email_verified` iddiaları | **Zorunlu** — backend hesabı e-postayla eşler |
| `userinfo.profile` | `name`, `picture` iddiaları         | Görünen adı üretmek için                      |

> 🔴 **Bu üçünden fazlasını isteme.** Bu üçü "hassas olmayan" kapsamlardır ve Google
> **doğrulama süreci istemez**. Takvim, Drive, kişiler gibi bir kapsam eklersen Google
> güvenlik incelemesi başlatır; bu **haftalar** sürebilir ve uygulama o süre boyunca
> 100 kullanıcı sınırına takılır. Bu proje o kapsamların hiçbirine ihtiyaç duymaz.

#### 2.2.6 Yayınlama durumu (publishing status)

```
OAuth izin ekranı → Hedef Kitle (veya "Yayınlama durumu")
```

| Durum      | Kim giriş yapabilir                                          | Ne zaman kullanılır       |
| ---------- | ------------------------------------------------------------ | ------------------------- |
| **Test**   | Yalnız açıkça eklenmiş **test kullanıcıları** (en fazla 100) | Geliştirme ve kapalı test |
| **Üretim** | Herkes                                                       | Genel yayına çıkarken     |

**Test durumundan üretime geçmek:**

```
OAuth izin ekranı
  ↓
UYGULAMAYI YAYINLA  /  ÜRETİME GEÇ
  ↓
onay penceresinde ONAYLA
```

> ✅ **Bu üç kapsamla üretime geçmek doğrulama gerektirmez** — geçiş anında olur.
> Hassas kapsam eklenmişse Google doğrulama isteyecektir.

> 🔴 **En sık tuzak:** Uygulama "Test" durumundayken **listede olmayan bir Google hesabıyla**
> giriş denenirse Google hesap seçiciyi gösterir ama sonra
> _"Bu uygulama doğrulanmadı"_ / _"erişim engellendi"_ hatası verir. Kapalı testteki 12 kişinin
> hepsi ya test kullanıcısı listesinde olmalı ya da uygulama üretime alınmalıdır.

#### 2.2.7 Test kullanıcıları

```
OAuth izin ekranı → Hedef Kitle → Test kullanıcıları
  ↓
KULLANICI EKLE
  ↓
E-posta adreslerini tek tek gir (her satıra bir adres)
  ↓
KAYDET
```

- En fazla **100** test kullanıcısı.
- Adres **Google hesabı** olmalıdır (Gmail veya Google'a bağlı bir adres).
- Kullanıcı eklendikten sonra **hemen** geçerlidir; bekleme yoktur.

### 2.3 Web OAuth istemcisi 🔴

Bu, tüm akışın merkezindeki kimliktir.

```
Sol menü → API'ler ve Hizmetler → Kimlik bilgileri
  ↓
+ KİMLİK BİLGİLERİ OLUŞTUR
  ↓
OAuth istemci kimliği
  ↓
Uygulama türü:  Web uygulaması
  ↓
Ad:  Ehliyet Akademi — sunucu doğrulama
  ↓
Yetkili JavaScript kaynakları:
      (bu akışta GEREKMEZ — §2.3.1)
  ↓
Yetkili yönlendirme URI'leri:
      (bu akışta GEREKMEZ — §2.3.2)
  ↓
OLUŞTUR
  ↓
Açılan pencerede "İstemci Kimliği"ni KOPYALA
      430417XXXXXXXX-xxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

> **İstemci gizli anahtarı (client secret) bu akışta kullanılmaz.** Kopyalamana gerek yoktur ve
> hiçbir yere yazılmamalıdır. Biz yalnız ID token doğruluyoruz; kod değişimi (code exchange)
> yapmıyoruz.

#### 2.3.1 Yetkili JavaScript kaynakları — ne zaman gerekir

| Durum                                                                    | Gerekli mi |
| ------------------------------------------------------------------------ | ---------- |
| Android uygulaması → ID token → backend doğrulaması **(bizim akışımız)** | **Hayır**  |
| Web sitesinde "Google ile Oturum Aç" düğmesi (GIS JavaScript kitaplığı)  | **Evet**   |

İleride web tarafına da Google girişi eklenirse şunlar girilir:

```
https://www.ehliyetegitim.com
http://localhost:3000          ← yalnız geliştirme için
```

Kurallar: şema (`https://`) **dâhil**, yol (`/giris`) **hariç**, sonda `/` **yok**.

#### 2.3.2 Yetkili yönlendirme URI'leri — ne zaman gerekir

| Durum                                                              | Gerekli mi |
| ------------------------------------------------------------------ | ---------- |
| ID token doğrulaması **(bizim akışımız)**                          | **Hayır**  |
| Sunucu tarafı OAuth kod akışı (authorization code → refresh token) | **Evet**   |

Bu projede yönlendirme yoktur: Google, token'ı doğrudan Android SDK'sına verir, tarayıcı
yönlendirmesi olmaz. Bu alanı **boş bırakmak doğrudur** ve Google buna izin verir.

---

## BÖLÜM 3 — Android OAuth istemcisi

Bu istemci **kodda hiçbir yerde geçmez**, ama olmadan hesap seçici açılıp hemen kapanır.

### 3.1 Ne işe yarar

Google Play Services, `authenticate()` çağrıldığında çağıran uygulamanın **paket adını** ve
**imza sertifikasının SHA-1'ini** okur ve projedeki Android OAuth istemcileriyle karşılaştırır.
Eşleşme yoksa `ApiException: 10` (`DEVELOPER_ERROR`) döner.

### 3.2 Oluşturma

```
API'ler ve Hizmetler → Kimlik bilgileri
  ↓
+ KİMLİK BİLGİLERİ OLUŞTUR
  ↓
OAuth istemci kimliği
  ↓
Uygulama türü:  Android
  ↓
Ad:                          Ehliyet Akademi — upload key
Paket adı:                   com.ehliyetegitim.ehliyet_akademi
SHA-1 sertifika parmak izi:  7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57
  ↓
OLUŞTUR
```

> Google Cloud'un Android istemci formu **yalnız SHA-1 ister**. SHA-256 alanı yoktur.
> (SHA-256 App Links / Digital Asset Links için gerekir — Google girişi için değil.)

### 3.3 Paket adı

```bash
grep -n "applicationId" apps/mobile/android/app/build.gradle.kts
```

Bu değer **harfi harfine** aynı olmalıdır: `com.ehliyetegitim.ehliyet_akademi`

Tek karakter farkı (nokta, alt çizgi, büyük harf) girişin çalışmaması için yeterlidir.

### 3.4 SHA-1 parmak izini alma

#### 3.4.1 Debug anahtarı — `flutter run` ile test ederken

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

Çıktıdaki `SHA1:` satırı. **Bu projede ölçülen:**

```
20:AE:CA:91:98:1B:EE:12:3A:CD:0A:CE:54:9E:BA:7F:D0:A3:04:CF
```

> Debug anahtarı **her geliştirme makinesinde farklıdır**. Ekipteki her geliştirici kendi
> SHA-1'ini eklemeli (ya da herkes aynı `debug.keystore` dosyasını paylaşmalıdır).

#### 3.4.2 Upload anahtarı — kendi imzaladığın APK/AAB

```bash
keytool -list -v \
  -keystore apps/mobile/android/upload-keystore.jks \
  -alias upload
```

Parola sorulur (`apps/mobile/android/key.properties` içindeki `storePassword`).
**Bu projede ölçülen:**

```
SHA-1   : 7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57
SHA-256 : 46:B2:DF:CE:2F:78:BD:A0:EB:C6:A0:19:FE:4F:14:98:C0:52:37:42:19:94:68:C5:47:D0:4F:68:6F:06:07:D3
```

#### 3.4.3 Play App Signing anahtarı — Play'den inen yapı 🔴

```
play.google.com/console
  ↓
Uygulamayı seç
  ↓
Test ve yayınlama → Kurulum → Uygulama imzalama
  ↓
"Uygulama imzalama anahtarı sertifikası" bölümü
  ↓
SHA-1 sertifika parmak izi  → KOPYALA
```

> Bu ekran **ilk AAB yüklenene kadar boştur**. Yani bu adım zorunlu olarak yükleme sonrasıdır.
> Ayrıntı: [§7](#bölüm-7--google-play-console).

### 3.5 Hangi imza ne zaman kullanılır

| Uygulamayı nasıl çalıştırıyorsun                         | Çalışan imza                  | Hangi SHA-1 kayıtlı olmalı |
| -------------------------------------------------------- | ----------------------------- | -------------------------- |
| `flutter run` (debug)                                    | Debug anahtarı                | §3.4.1                     |
| `flutter build apk --release` + `adb install`            | Upload anahtarı               | §3.4.2                     |
| `flutter build appbundle` → Play → **kullanıcı indirir** | **Play App Signing anahtarı** | §3.4.3                     |

> 🔴 Üçü de farklı imzalardır. Üçüyle de test edeceksen **üç Android OAuth istemcisi** oluştur
> (aynı paket adı, farklı SHA-1). Google buna izin verir ve olağan yöntem budur.

### 3.6 Kaç Android istemcisi oluşturmalı

```
Ehliyet Akademi — debug          → paket + debug SHA-1
Ehliyet Akademi — upload key     → paket + upload SHA-1
Ehliyet Akademi — Play signing   → paket + Play App Signing SHA-1
```

Adları senin için; Google yalnız **paket adı + SHA-1** çiftine bakar.

### 3.7 Değişiklikten sonra yayılma süresi

Yeni bir Android istemcisi eklendikten sonra Google'ın altyapısına yayılması **birkaç dakika**
sürebilir. Hemen denemek yerine:

1. Uygulamayı **tamamen kapat** (arka plandan da kaldır).
2. 5 dakika bekle.
3. Tekrar dene.

---

## BÖLÜM 4 — Hangi istemci kimliği nereye gider

### 4.1 Ana tablo

| İstemci türü                | Nereye girilir                                                                              | Kim okur                                                  | Kodda geçer mi                    |
| --------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------- | --------------------------------- |
| **Web istemci kimliği**     | ① Vercel → `GOOGLE_SERVER_CLIENT_ID`<br>② Flutter → `--dart-define=GOOGLE_SERVER_CLIENT_ID` | Backend (`aud` doğrulaması)<br>Flutter (`serverClientId`) | **Evet — iki yerde, aynı değer**  |
| **Android istemci kimliği** | Hiçbir yere                                                                                 | Google Play Services (çalışma anında)                     | **Hayır — asla kopyalanmaz**      |
| **İstemci gizli anahtarı**  | Hiçbir yere                                                                                 | Kimse                                                     | **Hayır — bu akışta kullanılmaz** |

### 4.2 Akış olarak

```
WEB istemci kimliği
   │
   ├──────────────► Backend  (GOOGLE_SERVER_CLIENT_ID)
   │                   └─ gelen ID token'ın `aud` alanı bununla EŞİT olmalı
   │
   └──────────────► Flutter  (--dart-define ile serverClientId)
                       └─ Google'a "token'ı bu kimlik için üret" der

ANDROID istemci kimliği
   │
   └──────────────► YALNIZ Google Play Services
                       └─ paket adı + imza eşleşmesini doğrular
                       └─ HİÇBİR ZAMAN koda kopyalanmaz
```

### 4.3 Neden ikisi de aynı Web kimliği olmalı

Flutter'ın `serverClientId` olarak verdiği değer, Google'ın ürettiği ID token'ın `aud`
(audience) alanına yazılır. Backend de aynı değeri bekler:

```
Flutter serverClientId  ==  token.aud  ==  Backend GOOGLE_SERVER_CLIENT_ID
```

Bu üçü eşit değilse backend **401** döner (`bad-audience`). Bu, kasıtlı bir güvenlik
kontrolüdür: başka bir Google uygulamasının token'ı bizim hesabımıza giriş yapamaz.

---

## BÖLÜM 5 — Flutter

### 5.1 `serverClientId` nedir

Google'a "bu token'ı hangi sunucu tüketecek?" bilgisini veren değerdir. Uygulamanın kendi
Android istemci kimliği **değildir**.

```dart
await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
```

### 5.2 Değer nereden geliyor

```dart
GoogleSignInServiceImpl({String? serverClientId})
  : _serverClientId =
        serverClientId ?? const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

@override
bool get isConfigured => _serverClientId.isNotEmpty;
```

`String.fromEnvironment` **derleme zamanında** okunur. Uygulamanın `.env` dosyası **yoktur**;
değer ikiliye (binary) gömülür.

### 5.3 Düğmenin görünme koşulu

```dart
final googleReady = ref.watch(googleAuthServiceProvider).isConfigured;
...
if (googleReady) ...[  /* Google ile devam et düğmesi */ ]
```

> `GOOGLE_SERVER_CLIENT_ID` verilmezse düğme **hiç çizilmez**. Bu bilinçli bir karardır:
> çalışmayacak bir düğme göstermek yerine hiç göstermemek. Uygulama çökmez, hata da vermez.
> Yani **"düğme yok" belirtisi doğrudan "dart-define verilmedi" demektir.**

### 5.4 Release derlemesi

```bash
cd apps/mobile

flutter build appbundle --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=430417XXXXXXXX-xxxxxxxx.apps.googleusercontent.com
```

APK için:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=430417XXXXXXXX-xxxxxxxx.apps.googleusercontent.com
```

### 5.5 Debug derlemesi

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=430417XXXXXXXX-xxxxxxxx.apps.googleusercontent.com
```

> Debug yapı **debug anahtarıyla** imzalanır → §3.4.1'deki SHA-1'in kayıtlı olması gerekir.

### 5.6 Değeri tekrar yazmamak için

```bash
# ~/.bashrc veya proje dışı bir dosyada
export GID=430417XXXXXXXX-xxxxxxxx.apps.googleusercontent.com

flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID="$GID"
```

Ya da bir dart-define dosyası kullan:

```bash
# defines.json  (depoya EKLENMEZ)
{ "GOOGLE_SERVER_CLIENT_ID": "430417XXXXXXXX-xxxxxxxx.apps.googleusercontent.com" }

flutter build appbundle --release --dart-define-from-file=defines.json
```

### 5.7 Kimliğin derlemeye gerçekten gömüldüğünü doğrulama

En güvenilir yol **davranışa bakmaktır**: uygulamayı aç → Profil → "Giriş yap / Kayıt ol" →
**Google düğmesi görünüyorsa** kimlik gömülmüştür.

Görünmüyorsa §5.3 gereği `--dart-define` verilmemiş demektir.

### 5.8 Akışın kod tarafındaki karşılığı

```dart
final account = await GoogleSignIn.instance.authenticate();
final idToken = account.authentication.idToken;
if (idToken == null || idToken.isEmpty) {
  // En sık neden: serverClientId olarak ANDROID istemci kimliği verilmiş.
  return const GoogleSignInError('Google kimliği alınamadı. Tekrar dene.');
}
```

Kullanıcı seçiciyi kapatırsa `GoogleSignInExceptionCode.canceled` gelir ve **hiçbir hata
mesajı gösterilmez** — bu bir hata değildir.

---

## BÖLÜM 6 — Backend

### 6.1 `GOOGLE_SERVER_CLIENT_ID`

| Alan                | Değer                                                                |
| ------------------- | -------------------------------------------------------------------- |
| **Amaç**            | Gelen ID token'ın `aud` alanını doğrulamak                           |
| **Değer**           | §2.3'teki **Web** istemci kimliği (Flutter'a verilenle **aynı**)     |
| **Nerede saklanır** | Vercel → Settings → Environment Variables (Production + Preview)     |
| **Zaman türü**      | Çalışma zamanı                                                       |
| **Yoksa**           | Uç **503** döner: _"Google ile giriş bu sunucuda yapılandırılmadı."_ |

```
vercel.com → Proje → Settings → Environment Variables
  ↓
Key:    GOOGLE_SERVER_CLIENT_ID
Value:  430417XXXXXXXX-xxxxxxxx.apps.googleusercontent.com
Environments:  ☑ Production  ☑ Preview  ☑ Development
  ↓
Save
  ↓
Deployments → en üstteki → ⋯ → Redeploy      ← ŞART: eklemek tek başına yetmez
```

### 6.2 ID token doğrulaması — sıra

`POST /api/auth/google` gövdesi: `{ "idToken": "..." }`

```
1. Hız sınırı           → 10 istek / dakika (kova: auth-google)
2. audience oku         → boşsa 503 (dürüst hata, sahte başarı YOK)
3. JWT'yi çöz           → header.kid + claims   (bozuksa 401)
4. JWKS çek             → https://www.googleapis.com/oauth2/v3/certs
                          1 saat önbellekli; ulaşılamazsa 503
                          (doğrulanmamış token ASLA kabul edilmez)
5. RS256 imzasını doğrula (kid ile eşleşen anahtar)
6. İddiaları denetle    → §6.3
7. Kullanıcıyı bul/oluştur
8. Oturum üret          → Bearer jetonu
```

### 6.3 İddia (claim) doğrulaması — tam sıra

| #   | Kontrol                                                        | Başarısızlık nedeni | HTTP |
| --- | -------------------------------------------------------------- | ------------------- | ---- |
| 1   | İmza geçerli mi                                                | `bad-signature`     | 401  |
| 2   | `iss` ∈ {`accounts.google.com`, `https://accounts.google.com`} | `bad-issuer`        | 401  |
| 3   | **`aud` == `GOOGLE_SERVER_CLIENT_ID`**                         | `bad-audience`      | 401  |
| 4   | `exp` + 60 sn > şimdi                                          | `expired`           | 401  |
| 5   | `email` dolu                                                   | `email-missing`     | 401  |
| 6   | `email_verified` true (veya `"true"`)                          | `email-unverified`  | 401  |

> **Kullanıcıya dönen mesaj neden hep aynı?** `expired` ve `email-unverified` dışında bütün
> nedenler **aynı** mesajı verir: _"Google ile giriş doğrulanamadı."_ Hangi kontrolün düştüğünü
> söylemek saldırgana bilgi verirdi.
>
> Teşhis için HTTP kodu ve sunucu günlükleri kullanılır, kullanıcı mesajı değil.

### 6.4 Oturum oluşturma

```
E-posta veritabanında VAR MI?
  ├─ EVET → HESAP BİRLEŞTİRME
  │          Aynı kullanıcı kaydı kullanılır; yeni hesap AÇILMAZ.
  │          Daha önce parolayla kaydolan kullanıcı Google ile de girebilir,
  │          ilerlemesi ikiye bölünmez.
  │          → HTTP 200
  │
  └─ HAYIR → YENİ KULLANICI
             passwordHash = 'google$no-password'   (parolayla giriş imkânsız)
             emailVerified = true                  (Google zaten doğruladı)
             → HTTP 201
```

Her iki durumda da yanıt:

```json
{ "user": { "id": "...", "email": "...", "name": "..." }, "token": "<bearer>" }
```

Mobil bu jetonu saklar ve sonraki isteklerde `Authorization: Bearer <token>` gönderir.

### 6.5 Sunucunun yapılandırıldığını doğrulama

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST https://www.ehliyetegitim.com/api/auth/google \
  -H 'content-type: application/json' \
  -d '{"idToken":"a.b.c"}'
```

| Sonuç   | Anlamı                                                                                     |
| ------- | ------------------------------------------------------------------------------------------ |
| **401** | ✅ `GOOGLE_SERVER_CLIENT_ID` **ayarlı** (token geçersiz olduğu için reddedildi — beklenen) |
| **503** | ❌ Değişken **yok** ya da Redeploy yapılmamış                                              |
| **429** | Hız sınırına takıldın, bir dakika bekle                                                    |

> Bu tek komut, sunucu tarafını **kesin olarak** ayırır. 401 alıyorsan sorun backend'de değildir.

---

## BÖLÜM 7 — Google Play Console

> Bu bölüm **yalnız Google girişini ilgilendiren** kısmı anlatır. Ürünler, faturalandırma,
> mağaza listesi bu belgenin konusu değildir.

### 7.1 Play'in Google girişine tek etkisi: imza

Play App Signing varsayılan olarak açıktır ve şunu yapar:

```
1. Sen AAB'yi UPLOAD anahtarıyla imzalarsın
2. Play bu imzayı doğrular
3. Play, AAB'yi KENDİ App Signing anahtarıyla YENİDEN imzalar
4. Kullanıcının cihazına giden APK PLAY'İN anahtarıyla imzalıdır
```

Google Sign-In **çalışma anındaki** imzaya bakar. Yani Play'den inen yapı için geçerli olan
imza **senin upload anahtarın değil**, Play'in App Signing anahtarıdır.

### 7.2 App Signing SHA-1'ini alma

```
play.google.com/console
  ↓
Uygulamayı seç
  ↓
Test ve yayınlama → Kurulum → Uygulama imzalama
  ↓
"Uygulama imzalama anahtarı sertifikası"
  ↓
SHA-1 sertifika parmak izi → kopyala
```

### 7.3 Zorunlu sıra 🔴

App Signing sertifikası **ilk AAB yüklenmeden önce mevcut değildir**. Bu yüzden sıra şudur:

```
1. AAB'yi derle (dart-define ile)          §5.4
2. Play Console → kapalı teste yükle
3. Uygulama imzalama ekranından SHA-1'i al  §7.2
4. Google Cloud'da YENİ Android OAuth istemcisi oluştur (bu SHA-1 ile)  §3.2
5. 5 dakika bekle (Google yayılımı)
6. Test cihazında uygulamayı Play'den yeniden indir
```

> ⚠️ **4. adım atlanırsa** giriş yalnız Play'den inen yapılarda bozulur; senin sideload
> ettiğin yapıda çalışmaya devam eder. Bu, teşhisi en zor senaryodur — çünkü "bende çalışıyor".

### 7.4 Upload anahtarı ne zaman devreye girer

| Senaryo                                            | Geçerli imza                  |
| -------------------------------------------------- | ----------------------------- |
| AAB'yi Play'e yüklerken (Play doğruluyor)          | Upload anahtarı               |
| Kendi derlediğin APK'yı `adb install` ile kurarken | Upload anahtarı               |
| Kullanıcı Play'den indirirken                      | **Play App Signing anahtarı** |

### 7.5 Upload anahtarını kaybedersen

Play App Signing açıksa **kurtarılabilir**:

```
Play Console → Test ve yayınlama → Kurulum → Uygulama imzalama
  ↓
"Yükleme anahtarını sıfırlama isteğinde bulun"
  ↓
Yeni anahtarın sertifikasını (.pem) yükle → Google onaylar (birkaç gün)
```

Yeni upload anahtarının SHA-1'i için **yeni bir Android OAuth istemcisi** de oluşturman gerekir.

---

## BÖLÜM 8 — Doğrulama kontrol listesi

Sırayla işaretle. Bir madde geçmiyorsa **sonrakine geçme**.

### 8.1 Google Cloud

- [ ] Doğru projedeyim (üst çubuktaki proje adı: `ehliyet-akademi`)
- [ ] OAuth izin ekranı yapılandırıldı (uygulama adı, destek e-postası, alan adları)
- [ ] Yetkili alan adı eklendi: `ehliyetegitim.com`
- [ ] Kapsamlar **yalnız** `openid`, `email`, `profile`
- [ ] Yayınlama durumu: **Üretim** — ya da giriş yapacak herkes **test kullanıcısı** listesinde
- [ ] **Web** OAuth istemcisi var ve istemci kimliği kopyalandı
- [ ] **Android** OAuth istemcisi var → paket adı `com.ehliyetegitim.ehliyet_akademi`
- [ ] Debug SHA-1 için Android istemcisi (geliştirme yapacaksan)
- [ ] Upload SHA-1 için Android istemcisi
- [ ] Play App Signing SHA-1 için Android istemcisi (AAB yüklendikten sonra)

### 8.2 Backend

- [ ] Vercel → `GOOGLE_SERVER_CLIENT_ID` girildi (**Web** istemci kimliği)
- [ ] Değişken eklendikten sonra **Redeploy** yapıldı
- [ ] Doğrulama komutu **401** dönüyor (503 değil) → §6.5

### 8.3 Flutter

- [ ] Derleme komutunda `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` var
- [ ] Verilen değer **Web** istemci kimliği (Android değil)
- [ ] Backend'deki değerle **birebir aynı**
- [ ] Uygulamada Google düğmesi **görünüyor**

### 8.4 Uçtan uca

- [ ] Hesap seçici açılıyor ve **açık kalıyor** (hemen kapanmıyor)
- [ ] Hesap seçilince giriş tamamlanıyor
- [ ] `GET /api/auth/me` kullanıcıyı dönüyor
- [ ] Aynı e-postayla daha önce parolayla kaydolmuş kullanıcı **aynı hesaba** giriyor
- [ ] **Play'den indirilen yapıda** da giriş çalışıyor (§7.3)

### 8.5 Tek komutta ön kontrol

```bash
# 1) Sunucu yapılandırılmış mı? (401 bekleniyor)
curl -s -o /dev/null -w "backend: %{http_code}\n" \
  -X POST https://www.ehliyetegitim.com/api/auth/google \
  -H 'content-type: application/json' -d '{"idToken":"a.b.c"}'

# 2) Upload anahtarı SHA-1
keytool -list -v -keystore apps/mobile/android/upload-keystore.jks -alias upload 2>/dev/null | grep SHA1

# 3) Debug anahtarı SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
  -storepass android -keypass android 2>/dev/null | grep SHA1

# 4) Paket adı
grep -n applicationId apps/mobile/android/app/build.gradle.kts
```

---

## BÖLÜM 9 — Sık yapılan hatalar

### 9.1 `serverClientId` olarak Android istemci kimliğini vermek 🔴

**En sık hata.**

| Belirti     | Hesap seçici açılır, hesap seçilir, sonra _"Google kimliği alınamadı"_                      |
| ----------- | ------------------------------------------------------------------------------------------- |
| **Sebep**   | `idToken` **null** döner. Android istemcileri ID token üretmez; bu Web istemcisinin işidir. |
| **Kontrol** | Google Cloud → Kimlik bilgileri → verdiğin kimliğin **türü** "Web uygulaması" mı?           |
| **Çözüm**   | Web istemci kimliğiyle yeniden derle (§5.4)                                                 |

### 9.2 Yanlış SHA-1 kayıtlı 🔴

| Belirti     | Hesap seçici açılır ve **hemen kapanır**                                           |
| ----------- | ---------------------------------------------------------------------------------- |
| **Sebep**   | Çalışan yapının imzası hiçbir Android istemcisiyle eşleşmiyor (`ApiException: 10`) |
| **Kontrol** | `adb logcat \| grep -iE "GoogleSignIn\|DEVELOPER_ERROR\|ApiException"`             |
| **Çözüm**   | Çalıştırdığın yapının imzasına karşılık gelen SHA-1'i ekle (§3.5)                  |

### 9.3 Play App Signing SHA-1'ini unutmak 🔴

| Belirti     | **Sideload'da çalışıyor, Play'den inende çalışmıyor**                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Sebep**   | Play AAB'yi kendi anahtarıyla yeniden imzaladı; o SHA-1 kayıtlı değil                           |
| **Kontrol** | Play Console → Kurulum → Uygulama imzalama → SHA-1'i Google Cloud'daki istemcilerle karşılaştır |
| **Çözüm**   | §7.3'teki altı adımı uygula                                                                     |

> Bu hatanın sinsi tarafı: geliştirici kendi cihazında test ettiği için **sorunu hiç görmez**.
> Yalnız testçiler ve kullanıcılar yaşar.

### 9.4 Paket adı uyuşmazlığı

| Belirti     | Hesap seçici açılıp kapanır (§9.2 ile aynı)                             |
| ----------- | ----------------------------------------------------------------------- |
| **Sebep**   | Android istemcisindeki paket adı `applicationId` ile birebir aynı değil |
| **Kontrol** | `grep applicationId apps/mobile/android/app/build.gradle.kts`           |
| **Çözüm**   | İstemciyi düzelt; nokta/alt çizgi/büyük harf farkı bile yeterlidir      |

### 9.5 Yanlış Google Cloud projesi

| Belirti     | Her şey doğru görünüyor ama giriş çalışmıyor                                                                                                                                                                |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sebep**   | İstemciler bir projede, `GOOGLE_SERVER_CLIENT_ID` başka bir projeden                                                                                                                                        |
| **Kontrol** | Web istemci kimliğinin başındaki sayı (`430417…`) = **proje numarası**. Google Cloud → Ana Sayfa → Proje bilgileri → Proje numarası ile karşılaştır. Android ve Web istemcileri de **aynı** projede olmalı. |
| **Çözüm**   | Tüm istemcileri tek projede topla                                                                                                                                                                           |

### 9.6 Eski AAB / eski dart-define

| Belirti     | Kimlik doğru ama düğme yok ya da eski davranış sürüyor                                                |
| ----------- | ----------------------------------------------------------------------------------------------------- |
| **Sebep**   | `--dart-define` **derleme zamanında** gömülür; değeri değiştirmek yeniden derlemeyi gerektirir        |
| **Kontrol** | Cihazdaki yapı gerçekten yeni mi? `adb uninstall com.ehliyetegitim.ehliyet_akademi` sonra yeniden kur |
| **Çözüm**   | `flutter clean && flutter build ... --dart-define=...`                                                |

### 9.7 Vercel'e değişken eklendi ama Redeploy yapılmadı

| Belirti   | Backend hâlâ **503** dönüyor                                                        |
| --------- | ----------------------------------------------------------------------------------- |
| **Sebep** | Vercel ortam değişkenlerini dağıtıma bağlar; mevcut dağıtım eski değerlerle çalışır |
| **Çözüm** | Deployments → ⋯ → Redeploy                                                          |

### 9.8 Uygulama "Test" durumunda, kullanıcı listede değil

| Belirti   | _"Erişim engellendi"_ / _"Bu uygulama doğrulanmadı"_                         |
| --------- | ---------------------------------------------------------------------------- |
| **Sebep** | OAuth izin ekranı Test durumunda ve giriş yapan hesap test kullanıcısı değil |
| **Çözüm** | Ya kullanıcıyı ekle (§2.2.7) ya da uygulamayı üretime al (§2.2.6)            |

### 9.9 Fazla kapsam istemek

| Belirti   | Google doğrulama süreci başlatıyor, uygulama 100 kullanıcı sınırında |
| --------- | -------------------------------------------------------------------- |
| **Sebep** | `openid`/`email`/`profile` dışında hassas kapsam eklenmiş            |
| **Çözüm** | Fazla kapsamları kaldır; bu proje üçünden fazlasına ihtiyaç duymaz   |

### 9.10 `aud` uyuşmazlığını kesin teşhis etmek

Flutter'daki ve backend'deki değerin gerçekten aynı olduğundan emin olmak için, cihazdan
yakalanan token'ın `aud` alanını oku (imza doğrulamadan, yalnız teşhis için):

```bash
python3 -c "
import base64, json, sys
p = sys.argv[1].split('.')[1]; p += '=' * (-len(p) % 4)
print(json.loads(base64.urlsafe_b64decode(p))['aud'])
" <idToken>
```

Çıkan değer Vercel'deki `GOOGLE_SERVER_CLIENT_ID` ile **birebir aynı** olmalıdır.

---

## Ek — Belirtiden nedene hızlı tablo

| Belirti                              | En olası neden                               | Bölüm |
| ------------------------------------ | -------------------------------------------- | ----- |
| Google düğmesi hiç yok               | `--dart-define` verilmedi                    | §5.3  |
| Seçici açılıp hemen kapanıyor        | SHA-1 / paket adı eşleşmiyor                 | §9.2  |
| "Google kimliği alınamadı"           | `serverClientId` Android istemcisi           | §9.1  |
| Backend 503                          | `GOOGLE_SERVER_CLIENT_ID` yok / Redeploy yok | §9.7  |
| Backend 401                          | `aud` uyuşmazlığı                            | §9.10 |
| "Erişim engellendi"                  | Test durumu + kullanıcı listede değil        | §9.8  |
| Sideload çalışıyor, Play çalışmıyor  | Play App Signing SHA-1 eksik                 | §9.3  |
| Yeni hesap açıldı, ilerleme kayboldu | E-postalar farklı (`+etiket` vb.)            | §6.4  |

---

## Ek — Bu projeye özgü sabitler

| Alan                   | Değer                                                         |
| ---------------------- | ------------------------------------------------------------- |
| Paket adı              | `com.ehliyetegitim.ehliyet_akademi`                           |
| Backend                | `https://www.ehliyetegitim.com`                               |
| Giriş ucu              | `POST /api/auth/google`                                       |
| JWKS                   | `https://www.googleapis.com/oauth2/v3/certs`                  |
| Upload SHA-1           | `7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57` |
| Debug SHA-1            | `20:AE:CA:91:98:1B:EE:12:3A:CD:0A:CE:54:9E:BA:7F:D0:A3:04:CF` |
| Play App Signing SHA-1 | _(AAB yüklendikten sonra Play Console'dan alınır)_            |
