# Beta Faz 4 Raporu — Google Play Yayın Hazırlığı

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `jfzxugsgnnvsrsg6` (Xiaomi 22095RA98C · Android 13)

## Karar: 🟢 GO — **B1 ve B2 KAPANDI**

`flutter analyze` **0** · `flutter test` **311** · web **516** · `@ea/db` **6** ·
`content-schema` **17** · `question-bank` **10** · `srs-engine` **12** ·
`pnpm lint` 0 hata · `format` · `verify` · `typecheck` temiz.

---

## 1. B1 — Release imzalama artık gerçek upload key ile

### Önceki durum

`android/app/build.gradle.kts` release bloğu debug imzalama yapılandırmasını kullanıyordu.
Google Play debug anahtarıyla imzalanmış bir yapıyı **kabul etmez**; bu, programın en eski açık
yayın engeliydi.

### Yeni tasarım

İmzalama gizli değerleri `android/key.properties`'ten okunur (Git dışı). Kritik tasarım kararı:

```kotlin
signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
```

**Neden `null`, neden debug'a düşmüyor:** sessiz bir geri düşüş, hatanın ancak Play'e yükleme
anında fark edilmesine yol açardı. Anahtar yoksa release artefaktı istendiğinde derleme
**anlaşılır bir mesajla durur**.

### CI'ı kırmayan kurulum — dikkat gerektiren nokta

Gradle imzalama yapılandırması **her derlemede** değerlendirilir. Naif bir bağlama
(`props["keyAlias"] as String`) `key.properties` yokken **yapılandırma aşamasında** patlar ve
`flutter build apk --debug`'ı da kırardı — yani **Mobile CI'ı kırmızıya çevirirdi** (CI yalnız
debug derliyor: `.github/workflows/mobile.yml`).

Çözüm: yapılandırma anahtarsız da **başarılı** olur; hata `gradle.taskGraph.whenReady` içinde,
yalnız bir `assemble*Release` / `bundle*Release` / `package*Release` görevi istendiğinde fırlatılır.

**Her iki dal da ölçüldü** (`key.properties` geçici olarak taşınarak):

| Derleme                             | Beklenen                      | Ölçülen                                                                                                        |
| ----------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `flutter build apk --debug`         | Anahtarsız **çalışmalı** (CI) | ✅ `Built build/app/outputs/flutter-apk/app-debug.apk`                                                         |
| `flutter build appbundle --release` | Anahtarsız **dürüst hata**    | ✅ `Release imzalama yapılandırılmamış — derleme durduruldu.` + beklenen dosya yolu + şablon + belge referansı |

## 2. B2 — Şablon notları temizlendi

`build.gradle.kts` içindeki Flutter şablonundan kalan üç yer-tutucu yorum kaldırıldı
(uygulama kimliği notu, "değerleri kendine göre güncelle" notu, imzalama notu). Yerlerine
gerçek bilgi yazıldı — ör. uygulama kimliğinin Play'e ilk yüklemeden sonra değiştirilemeyeceği.

> Bu rapor o yorumları **birebir alıntılamıyor**: `pnpm verify` `.md` dosyalarında yasaklı kalıp
> tarıyor ve Faz 0'da CI tam bu yüzden bir kez kırılmıştı (bellek §J.1).

## 3. DoD kapısı — imza kanıtı

### 3.1 Ölçüm aracı hakkında bir düzeltme

`RELEASE_CHECKLIST.md` §C ve `PLAY_CONSOLE_SETUP.md` §2.3, AAB'nin `apksigner` ile
doğrulanmasını söylüyordu. **Bu talimat yanlıştı ve ölçülerek bulundu:**

```
com.android.apksig.apk.ApkFormatException: Missing AndroidManifest.xml
```

AAB bir APK değildir; kök `AndroidManifest.xml` taşımaz. **Araç çöktüğü için çıktısında
`androiddebugkey` geçmemesi bir kanıt değil, yanlış bir negatiftir.** İlk denemede bu tuzağa
düşüldü ve sonuç kanıt sayılmadı; iki belge de düzeltildi.

### 3.2 Gerçek kanıt

**AAB — `jarsigner`** (AAB'ler v1/JAR imzalıdır):

```
jar verified.
Signed by "CN=Emre Dogan, OU=Mobile, O=Ehliyet Akademi - Sınav 2026, L=adana, ST=TR, C=TR"
Signature algorithm: SHA384withRSA, 4096-bit key
```

**APK — `apksigner verify --print-certs`:**

```
V2 Signer: certificate DN: CN=Emre Dogan, OU=Mobile, O=Ehliyet Akademi - Sınav 2026, ...
V2 Signer: certificate SHA-1   digest: 7e1fead920bee1e662a140acffd78dc0b6767357
V2 Signer: certificate SHA-256 digest: 46b2dfce2f78bda0ebc6a019fe4f1498c0523742199468c547d04f686f0607d3
```

**Keystore ile karşılaştırma** (`keytool -list -v`):

| Ölçüt                                  | keystore                                                      | artefakt                | Sonuç   |
| -------------------------------------- | ------------------------------------------------------------- | ----------------------- | ------- |
| SHA-1                                  | `7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57` | `7e1fead9…b6767357`     | ✅ aynı |
| SHA-256                                | `46:B2:DF:CE:…:06:07:D3`                                      | `46b2dfce…6f0607d3`     | ✅ aynı |
| İmza algoritma                         | SHA384withRSA, 4096-bit                                       | SHA384withRSA, 4096-bit | ✅ aynı |
| `androiddebugkey` / `CN=Android Debug` | —                                                             | **0 eşleşme**           | ✅      |

**Bağımsız üçüncü kanıt:** release imzalı APK'yı mevcut (debug imzalı) kurulumun üzerine
kurmaya çalışmak reddedildi —

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: ... signatures do not match newer version
```

İmzanın gerçekten değiştiğini bağımsız olarak doğrular.

## 4. Üretilen artefaktlar

| Artefakt      | Boyut   | İmza          |
| ------------- | ------- | ------------- |
| AAB (release) | 62,5 MB | upload key ✅ |
| arm64 APK     | 35,0 MB | upload key ✅ |

> AAB, Play'e yüklenecek olandır; boyutu Play'in kullanıcıya dağıttığı APK boyutu **değildir**
> (Play bölmeyi kendisi yapar). Kapalı teste **AAB** yüklenir.

## 5. Cihaz doğrulaması

Release imzalı APK gerçek cihaza kuruldu ve çalıştırıldı:

| #   | Doğrulanan                                                  | Sonuç                       |
| --- | ----------------------------------------------------------- | --------------------------- |
| 1   | Debug imzalı kurulumun üzerine kurulum **reddedilir**       | ✅ (§3.2)                   |
| 2   | Kaldır → release imzalı kur                                 | ✅ `Success`                |
| 3   | Soğuk açılış, tanıtım ekranı                                | ✅ `b4_01`                  |
| 4   | `logcat -b crash`                                           | ✅ **boş**                  |
| 5   | Cihazda bildirilen sürüm: `versionName=1.0.0 versionCode=1` | ✅ beklenen                 |
| 6   | `minSdk=24 targetSdk=36`                                    | ✅ Play asgarisinin üstünde |

## 6. Faz 4'te bulunan ve düzeltilen üç depo sorunu

### 6.1 `apps/ASO_IMAGE/` izlenmiyordu ama ignore da değildi

Play Store varlıkları (**12 MB** ham PNG) bir sonraki `git add -A` ile depoya girecekti.
Deponun kendi kuralıyla tutarlı biçimde (`/apps/assets/` zaten ignore'lu — ham/kaynak görseller
depoda tutulmaz) `.gitignore`'a eklendi.

**Ölçülen varlıklar** — Play şartlarıyla karşılaştırıldı:

| Dosya                           | Ölçü         | Play şartı | Sonuç                |
| ------------------------------- | ------------ | ---------- | -------------------- |
| `PlayStore-APP-ICON.png`        | **512×512**  | 512×512    | ✅ tam uyuyor        |
| `PlayStore-özellik-grafiği.png` | **1024×500** | 1024×500   | ✅ tam uyuyor        |
| `001/002/003.png`               | 941×1672     | ≥320 px    | ✅ 3 adet (asgari 2) |

### 6.2 `google-services.json` ignore değildi — gitleaks riski

Firebase yapılandırması projeye eklenmiş ama `.gitignore` kapsamında değildi. İçinde
`api_key.current_key` bulunuyor; commit edilseydi **CI'daki gitleaks taraması yapıyı kırabilirdi**.
Projenin kendi kararı zaten bunu söylüyordu (`GOOGLE_AUTH_SETUP.md` §8: depoda düz metin
tutulmaz, CI'a base64 secret olarak verilir) — `apps/mobile/android/.gitignore`'a eklendi.

### 6.3 ⚠️ Google girişi mevcut Firebase durumuyla ÇALIŞMAZ

`google-services.json` incelendi. Paket adı doğru (`com.ehliyetegitim.ehliyet_akademi`), ancak:

```
oauth_client sayısı: 0
```

| Eksik                       | Sonuç                                                                      |
| --------------------------- | -------------------------------------------------------------------------- |
| Android OAuth istemcisi yok | Firebase'e **SHA-1 eklenmemiş** → hesap seçici açılır ve **hemen kapanır** |
| Web OAuth istemcisi yok     | **`GOOGLE_SERVER_CLIENT_ID` henüz mevcut değil**                           |

Yapılacaklar `GOOGLE_AUTH_SETUP.md` **§9.5**'e yazıldı; gereken SHA-1/SHA-256 değerleri artık
ölçülmüş durumda ve §3.2'de hazır. **Uygulama bu durumda çökmez** — Google düğmesini hiç
göstermez (Faz 2'de testle sabitlendi).

## 7. Güncellenen belgeler

| Belge                   | Değişiklik                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------ |
| `PLAY_CONSOLE_SETUP.md` | §1 imzalama durumu · §2 kapandı · **§2.3 doğrulama komutları düzeltildi** · §6 mağaza varlıkları |
| `RELEASE_CHECKLIST.md`  | §C: AAB↔APK doğrulama ayrımı + `apksigner`'ın AAB'yi doğrulayamadığı uyarısı                     |
| `GOOGLE_AUTH_SETUP.md`  | §3.2 ölçülen parmak izleri · **§9.5 mevcut durum ve eksik adımlar**                              |

## 8. Dürüst sınırlar

1. **Play Console'a hiçbir şey yüklenmedi.** B6 (uygulama oluşturma, beyanlar, mağaza listesi)
   **elle** yapılacak adımlardır; kod yapamaz. Belgeler eksiksiz, işlem bekliyor.
2. **Play App Signing sertifikası henüz yok** — yalnız Play'e ilk yüklemeden sonra görünür.
   Firebase'e eklenmezse **Play'den kurulan yapıda Google girişi çalışmaz** (§6.3 ile aynı sınıf hata).
3. **Google girişi uçtan uca denenmedi** — §6.3'teki üç adım tamamlanmadan mümkün değil.
4. **AAB Play'de sınanmadı.** İmza doğrulandı, ancak Play'in kabul edip etmeyeceği yalnız gerçek
   yüklemede kesinleşir.
5. **versionCode hâlâ 1.** İlk yükleme için doğru; her sonraki yüklemede artırılmalıdır
   (`RELEASE_CHECKLIST.md` §B).
6. **`key.properties` bu makineye özgüdür.** CI release derlemesi yapmıyor; yapması istenirse
   anahtar deposu base64 secret olarak verilmelidir.

## 9. Sonraki faz

Faz 5 — **Giriş ekranı yeniden tasarımı**. Girdiler `ASSET_GENERATION_LIBRARY.md` §4.2'de hazır:
`022-assets.png` hero olarak sevk edilir (**Renault logosu rötuşlanmalı**), `023`/`024`
mockup'ları **widget olarak** uygulanır (raster sevk edilmez), "Apple ile giriş" **konmaz**
(ölü gezinme), "MEB müfredatına uygun" ifadesi kaynak gösterilemiyorsa **kullanılmaz**.
