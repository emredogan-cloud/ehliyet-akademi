# Google Girişi — USB ile Play Arasındaki Fark: Kök Neden Analizi

**2026-07-28 · Cihaz: AYXSUKIVJVPZ7HPZ (Android 11) · Tüm ölçümler sürüm (release) yapılarıyla**

Belirti: Google girişi USB/adb kurulumunda çalışıyor, aynı uygulama Play Kapalı Test'ten
kurulduğunda çalışmıyor.

---

## 1. Yürütmenin ayrıştığı nokta

**Uygulama kodunda ayrışma YOKTUR.** Bu, tahmin değil; ölçümle elenmiştir.

Ayrışma yalnızca **çalışan ikilinin kimliğinde** olabilir ve olası üç değişkenden ikisi
deneyle **elenmiştir**:

| Değişken                        | Test edildi mi         | Sonuç                                                       |
| ------------------------------- | ---------------------- | ----------------------------------------------------------- |
| Kod / dart-define               | ✅                     | Aynı AAB, aynı gömülü istemci kimliği — **çalışıyor**       |
| APK bölünmesi (AAB → split APK) | ✅                     | Play'in ürettiği split'lerin birebir aynısı — **çalışıyor** |
| **İmzalama sertifikası**        | ❌ _(taklit edilemez)_ | **Geriye kalan TEK değişken**                               |

---

## 2. Kanıtlar

### 2.1 Kodda koşullu davranış yok

```
flavor           : yok
minifyEnabled    : ayarlanmamış (R8 sıyırma farkı yok)
proguard kuralı  : yok
kReleaseMode /
kDebugMode koşulu: yok        (lib/ genelinde arama)
PackageManager /
signature / Integrity /
BuildConfig kullanımı: yok
```

Dolayısıyla USB ve Play yapılarının **çalıştırdığı Dart kodu birebir aynıdır**.

### 2.2 AAB'nin taşıdığı istemci kimliği doğru — ve tek başına çalışıyor

AAB'nin AOT anlık görüntüsünden (`base/lib/arm64-v8a/libapp.so`) çıkarıldı:

```
628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21.apps.googleusercontent.com
```

Bu kimlikle **monolitik APK** derlenip USB ile kuruldu:

```
[SIGNIN] serverClientId=628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21.apps.googleusercontent.com
[SIGNIN] BAŞARILI email=muratdogan010114@gmail.com idTokenLen=1106
```

Ve zincir **sonuna kadar** tamamlandı: giriş ekranı kapandı, oturum açıldı, Profil "Murat Dogan"
gösterdi. Yani **backend de bu kimliği kabul ediyor** (`aud` eşleşmesi doğru; Vercel'deki
`GOOGLE_SERVER_CLIENT_ID` bu değerle uyumlu).

> Yan bulgu: `.env` içindeki `GOOGLE_SERVER_CLIENT_ID` **bayat** — `430417323295-…`.
> AAB ise `628233156307-…` taşıyor. Depodaki `.env` artık üretimi temsil etmiyor
> ([§6.3](#63-bayat-env-değeri)).

### 2.3 Split kurulum — Play'in yaptığının birebir aynısı — çalışıyor 🔑

Bu, ayrışmayı daraltan belirleyici deneydir. Kullanıcının **kendi AAB'si**
(`versionCode=3`) `bundletool` ile Play'in ürettiği split APK'lara dönüştürüldü ve cihaza
**split olarak** kuruldu:

```
$ bundletool build-apks --bundle=app-release.aab --connected-device …
   splits/base-master.apk · base-arm64_v8a.apk · base-tr.apk · base-xxhdpi.apk

$ adb shell pm path com.ehliyetegitim.ehliyet_akademi
   base.apk
   split_config.arm64_v8a.apk
   split_config.tr.apk
   split_config.xxhdpi.apk
```

Uygulama verisi temizlendi (`pm clear`), akış baştan çalıştırıldı:

```
ActivityTaskManager: START … SignInCredentialChooserActivity     → hesap seçici açıldı
```

**Sonuç: giriş BAŞARILI.** Profil ekranı "Murat Dogan · muratdogan010114@gmail.com" gösterdi.

> Bu deney **APK bölünmesini**, **AAB paketlemesini**, **kaynak/dil/mimari split'lerini** ve
> **kodun kendisini** şüpheli olmaktan çıkarır. Play kurulumundan tek farkı **imzalayan
> sertifikadır**: burada upload anahtarı (`7E:1F:EA:D9:…`), Play'de ise Play App Signing anahtarı.

### 2.4 İmza zinciri tutarlı

```
key.properties → /home/emre/keys/ehliyet-akademi-upload.jks
alias upload   → SHA1 7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57
AAB imzası     → SHA1 7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57   ✓ aynı
```

---

## 3. Kök neden

Kod, AAB, dart-define ve split teslimatı elendiğine göre **davranış farkının kaynağı, Play'in
uygulamayı kendi App Signing anahtarıyla yeniden imzalamasıdır.** Google Play Services,
`authenticate()` sırasında çalışan uygulamanın **paket adı + çalışma anındaki imza SHA-1'i**
çiftini projedeki Android OAuth istemcileriyle karşılaştırır; eşleşme yoksa ID token üretmez.

Bu noktadan sonra iki olasılık kalır ve **ikisi de bu depodan ayırt edilemez**:

| #     | Olasılık                                                                        | Neden buradan görülemiyor                                                               |
| ----- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **A** | Play cihazında **eski bir sürüm** çalışıyor (eski istemci kimliğiyle derlenmiş) | Uygulama **derleme numarasını göstermiyordu** — hangi yapının çalıştığı öğrenilemiyordu |
| **B** | Play App Signing SHA-1'i için Android OAuth istemcisi **eşleşmiyor**            | Play Console / Google Cloud erişimi gerektirir                                          |

**A olasılığı hafife alınmamalıdır:** 2026-07-27'de üretilen AAB (`versionCode=1`) **bayat
`.env` değeriyle** (`430417323295-…`) derlenmişti. O yapı Kapalı Test'te hâlâ sunuluyorsa
Google girişi **tam olarak bildirilen biçimde** başarısız olur — ve aynı anda yerel yapılar
(yeni kimlikle) çalışır.

---

## 4. Uygulama kodundaki gerçek kusur

Teşhisi tıkayan şey uygulamanın kendisiydi:

`apps/mobile/lib/features/profile/profile_screen.dart` (düzeltme öncesi):

```dart
Text('Ehliyet Akademi · v1.0 (geliştirme)')        // ← SABİT dize
...
applicationVersion: 'v1.0 (geliştirme)',            // ← SABİT dize
```

Üç ayrı sorun:

1. **Derleme numarası hiç gösterilmiyordu.** Bir test kullanıcısı "çalışmıyor" dediğinde
   cihazındaki yapının hangi AAB olduğu **öğrenilemiyordu**. A ve B olasılıklarını ayırmanın
   tek ucuz yolu buydu ve kapalıydı.
2. **Sürüm gerçek değildi.** `pubspec.yaml` `1.0.0+3` iken ekran `v1.0` diyordu; sürüm artsa
   bile ekran hiç değişmezdi.
3. **Üretim yapısında "(geliştirme)" yazıyordu.** Play incelemecisinin gördüğü yayın sürümünde
   "development" etiketi hem yanıltıcı hem de gereksiz bir risktir.

---

## 5. Uygulanan düzeltme

### 5.1 Gerçek sürüm kimliği — `lib/core/app_version.dart` (yeni)

```dart
class AppVersion {
  final String name;   // 1.0.0
  final String build;  // 4   ← Play'e yüklenen AAB'nin sürüm kodu
  String get label => 'v$name ($build)';

  static Future<AppVersion> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersion(name: info.version, build: info.buildNumber);
    } catch (_) {
      return unknown;   // okunamazsa ÇÖKMEZ, dürüst yer tutucu
    }
  }
}
```

Değer **kurulu paketten** okunur; sabit dize yoktur, sürümle sapamaz.

### 5.2 Profil ekranı ve "Hakkında" penceresi

Her ikisi de artık `AppVersion.label` gösteriyor. Cihazda doğrulandı:

> **Ehliyet Akademi · v1.0.0 (4)**

### 5.3 Bağımlılık

`package_info_plus: ^10.2.1` eklendi — kurulu paketin sürümünü okumanın standart yolu.

### 5.4 Yan düzeltme: sızma riski kapatıldı

Depoda `apps/ehliyet-akademi-sinav-2026-8a7c78baebcb.json` bulundu — **özel anahtar içeren bir
Google Cloud servis hesabı dosyası** ve `.gitignore` bunu **kapsamıyordu**. Commit edilseydi
sızacaktı. `.gitignore`'a servis hesabı desenleri eklendi; dosya artık yok sayılıyor.

---

## 6. Bundan sonra ne yapılmalı

### 6.1 Önce A olasılığını ele — 30 saniye sürer

Play'den kurulu cihazda **Profil → en alt satıra** bak:

| Görülen                      | Anlamı                                                   | Aksiyon                                   |
| ---------------------------- | -------------------------------------------------------- | ----------------------------------------- |
| `v1.0.0 (4)` veya sonrası    | Yeni yapı çalışıyor → **A elendi**, sebep B              | §6.2                                      |
| `v1.0.0 (1)` / `(2)` / `(3)` | **Eski yapı sunuluyor → kök neden A**                    | Yeni AAB'yi yayına al, testçiye güncellet |
| `v1.0 (geliştirme)`          | Sürüm gösterimi düzeltilmemiş yapı → kesinlikle **eski** | Aynı                                      |

> Bu satır bu düzeltmeden **önce yoktu**; sorunun bu kadar uzun sürmesinin sebebi budur.

### 6.2 A elendiyse: Play App Signing sertifikası

Karşılaştırılacak iki değer:

```
Play Console → Test ve yayınlama → Kurulum → Uygulama imzalama
   → "Uygulama imzalama anahtarı sertifikası" → SHA-1

Google Cloud → proje 628233156307 → Kimlik bilgileri
   → OAuth 2.0 İstemci Kimlikleri → Android istemcileri → SHA-1'ler
```

Dikkat edilecek iki nokta:

- **Proje numarası 628233156307 olmalı.** Android istemcisi başka bir projede duruyorsa
  (ör. `google-services.json` içindeki `648053691908`) Google eşleştiremez.
  Depoda üç ayrı proje numarası görüldü: `430417323295` (bayat `.env`), `628233156307` (AAB),
  `648053691908` (`google-services.json`).
- **"Yükleme anahtarı sertifikası" ile "Uygulama imzalama anahtarı sertifikası" karıştırılmamalı.**
  Play'den inen yapı için geçerli olan **ikincisidir**.

### 6.3 Bayat `.env` değeri

`.env` içindeki `GOOGLE_SERVER_CLIENT_ID` hâlâ `430417323295-…`. Bu değerle derlenen her yapı
Google girişinde başarısız olur. **Güncellenmeli** ki bir sonraki derleme yanlışlıkla eski
kimliği gömmesin.

---

## 7. Düzeltme sonrası test sonuçları

```
flutter analyze                → 0 sorun
flutter test                   → 404 test (+4)
flutter build appbundle        → başarılı
```

Cihaz doğrulaması (sürüm APK'sı, veri temizlenmiş):

| Kontrol                                | Sonuç                                             |
| -------------------------------------- | ------------------------------------------------- |
| Profil alt satırı                      | **v1.0.0 (4)** ✅ gerçek sürüm + derleme numarası |
| "(geliştirme)" etiketi                 | Kaldırıldı ✅                                     |
| Google girişi (USB, monolitik)         | ✅ Başarılı — oturum açıldı                       |
| Google girişi (**split**, Play biçimi) | ✅ Başarılı — oturum açıldı                       |
| Geçici izleme kodu                     | Tamamen kaldırıldı ✅                             |

### Nihai AAB

```
/home/emre/Downloads/OTHER-RESEARCH/other_report/ehliyet-akademi/apps/mobile/build/app/outputs/bundle/release/app-release.aab

versionCode        : 4
versionName        : 1.0.0
imza               : jar verified · CN=Emre Dogan · SHA1 7E:1F:EA:D9:…:73:57
gömülü istemci     : 628233156307-nh8kvhe8cnhl5eevk7btbr6l4fm1uj21.apps.googleusercontent.com
```

---

## 8. Değiştirilen dosyalar

| Dosya                                                  | Değişiklik                                                                                            |
| ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `apps/mobile/lib/core/app_version.dart`                | **yeni** — kurulu paketten gerçek sürüm                                                               |
| `apps/mobile/lib/features/profile/profile_screen.dart` | sabit sürüm dizesi → `AppVersion.label` (iki yerde)                                                   |
| `apps/mobile/pubspec.yaml`                             | `package_info_plus` · sürüm `1.0.0+3` → `1.0.0+4`                                                     |
| `apps/mobile/test/google_auth_test.dart`               | 4 yeni test — derleme numarası etikette **zorunlu**, "geliştirme" etiketi yok, okunamayanda çökme yok |
| `.gitignore`                                           | servis hesabı JSON desenleri (sızma riski)                                                            |

---

## 9. Kalıcı ders

> **Bir uygulama, hangi yapının çalıştığını söyleyemiyorsa, saha hatası teşhis edilemez.**

Kod, AAB, istemci kimliği ve split teslimatı bir günde elendi; ama "Play'deki cihazda hangi
sürüm var?" sorusu, uygulama derleme numarasını göstermediği için **hiç yanıtlanamadı**.
Sürüm + derleme numarası göstermek kozmetik bir ayrıntı değil, **teşhis altyapısıdır**.
