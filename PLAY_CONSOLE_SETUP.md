# Google Play Console — Sıfırdan Yayın Hazırlığı

**Uygulama kimliği:** `com.ehliyetegitim.ehliyet_akademi` · **Sürüm:** 1.0.0 (versionCode 1)
**Hedef:** Kapalı Test (12 test kullanıcısı).

> Bu belge sıfırdan yazılmıştır: hesap açmaktan AAB yüklemeye, beyanlardan geri almaya kadar.

---

## 1. Ön koşullar

| Gereksinim                     | Durum / not                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| Google Play geliştirici hesabı | **25 USD tek seferlik** · kimlik doğrulaması gerekir (birkaç gün)        |
| Kuruluş mu birey mi            | Birey seçilirse adresiniz mağazada görünür; kuruluş için D-U-N-S gerekir |
| Uygulama kimliği               | `com.ehliyetegitim.ehliyet_akademi` — **yayından sonra DEĞİŞTİRİLEMEZ**  |
| targetSdk                      | **36** ✅ (Play'in asgarisinin üstünde)                                  |
| İmzalama                       | ⛔ şu an **debug anahtarı** — §2'de düzeltilir                           |

## 2. Upload key oluşturma (yayın engeli B1)

Şu anki durum — `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")   // ⛔ Play kabul etmez
    }
}
```

### 2.1 Anahtarı üret

```bash
keytool -genkey -v \
  -keystore ~/keys/ehliyet-akademi-upload.jks \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias upload
```

- **Depo Git'in DIŞINDA tutulur.** `~/keys/` gibi bir dizin uygundur.
- Parolayı bir parola yöneticisine yazın. **Kaybederseniz** Play'e "upload key reset" talebi
  açmak gerekir (günler sürer). Play App Signing açıksa uygulama kurtarılabilir; kapalıysa
  uygulamayı bir daha güncelleyemezsiniz.
- `-validity 10000` (~27 yıl) Play'in asgari şartını fazlasıyla karşılar.

### 2.2 Gradle'a bağla

`android/key.properties` (**`.gitignore`'a eklenir**):

```properties
storeFile=/home/<kullanıcı>/keys/ehliyet-akademi-upload.jks
storePassword=<parola>
keyAlias=upload
keyPassword=<parola>
```

Şablonu depoda `release-keystore.properties.example` olarak durur (Faz 4'te üretilir).

`build.gradle.kts` release bloğu bu dosyayı okuyacak biçimde güncellenir; **dosya yoksa derleme
anlaşılır bir hata verir**, sessizce debug anahtarına düşmez.

### 2.3 Doğrula

```bash
flutter build appbundle --release
apksigner verify --print-certs build/app/outputs/bundle/release/app-release.aab
```

Çıktıdaki SHA-1/SHA-256, `keytool -list` ile aldığınız değerlerle **aynı** olmalı; `androiddebugkey`
görünüyorsa imzalama hâlâ yanlıştır.

## 3. Play Console'da uygulama oluşturma

**Tüm uygulamalar → Uygulama oluştur**

| Alan                | Değer                                                                    |
| ------------------- | ------------------------------------------------------------------------ |
| Uygulama adı        | `Ehliyet Akademi`                                                        |
| Varsayılan dil      | Türkçe (tr-TR)                                                           |
| Uygulama mı oyun mu | Uygulama                                                                 |
| Ücretsiz mi ücretli | **Ücretsiz** (uygulama içi satın alma var; sonradan ücretliye geçilemez) |
| Beyanlar            | Geliştirici Programı Politikaları + ABD ihracat yasaları                 |

## 4. Play App Signing

Uygulama oluşturulunca **Yayın → Kurulum → Uygulama imzalama** açılır. Varsayılan olarak açıktır
ve **açık bırakılmalıdır**: Play, dağıtım anahtarını sizin adınıza saklar; siz yalnız upload key
ile imzalarsınız.

Bu sayfadaki **App signing key certificate → SHA-1 / SHA-256** değerlerini alın ve
`GOOGLE_AUTH_SETUP.md` §3.3 uyarınca Firebase'e ekleyin. **Bu adım atlanırsa Play'den kurulan
uygulamada Google girişi çalışmaz.**

## 5. Zorunlu beyanlar (Uygulama içeriği)

Sol menü → **Politika → Uygulama içeriği**. Kapalı testte bile **hepsi** doldurulmalıdır.

### 5.1 Gizlilik politikası

Genel erişime açık bir URL gerekir. Projede web uygulaması var; `/gizlilik` sayfası yayınlanmalı
ve URL buraya girilmelidir.

### 5.2 Uygulama erişimi (App Access)

Uygulamanın bir bölümü giriş gerektiriyor (topluluk, premium). **"Tüm işlevler kısıtlama olmadan
kullanılamıyor"** seçilir ve incelemeciye **çalışan bir test hesabı** verilir:

```
E-posta:  reviewer@ehliyetegitim.com
Parola:   <parola yöneticisinde>
Not:      Topluluk özellikleri Profil → Topluluk üzerinden açılır (isteğe bağlı katılım).
          Premium içerik için hesapta yetkilendirme tanımlıdır.
```

> İncelemeci giremezse **kesin ret** gelir. Bu hesabın gerçekten çalıştığı her yüklemeden önce
> sınanmalıdır.

### 5.3 Reklamlar

Uygulamada reklam **yok** → "Hayır".

### 5.4 İçerik derecelendirmesi

Anketi doldurun. Uygulama eğitim içeriklidir; şiddet/cinsellik/kumar yoktur. **Ancak
kullanıcı-üretimi içerik (topluluk mesajları, tartışmalar) VARDIR** — bu soruya **evet** denmeli,
aksi hâlde yanlış beyan olur. Moderasyon araçları (şikâyet + engelleme) mevcuttur ve bunu
belirtin.

### 5.5 Hedef kitle ve çocuklar

Hedef kitle **18+** (ehliyet sınavı adayları). "Çocuklara yönelik" **hayır**. Bu, Families
politikası yükümlülüklerini kaldırır.

### 5.6 Veri Güvenliği (Data Safety)

Bu formu **kodun gerçekten yaptığına göre** doldurun. Mevcut durum:

| Veri türü           | Toplanıyor?              | Paylaşılıyor? | Amaç              | Zorunlu mu | Not                                              |
| ------------------- | ------------------------ | ------------- | ----------------- | ---------- | ------------------------------------------------ |
| E-posta adresi      | Evet                     | Hayır         | Hesap yönetimi    | Hesap için | Topluluk yüzeylerinde **asla gösterilmez**       |
| Ad (görünen ad)     | Evet                     | Hayır         | Topluluk          | Hayır      | Kullanıcının seçtiği takma ad; gerçek ad değil   |
| Uygulama etkileşimi | Evet                     | Hayır         | Analitik/ilerleme | Hayır      | XP, seri, çözülen soru                           |
| Satın alma geçmişi  | Evet                     | Hayır         | Yetkilendirme     | Evet       | Premium erişimi                                  |
| Fotoğraflar         | **Faz 7'den sonra Evet** | Hayır         | Profil avatarı    | Hayır      | Faz 7 tamamlanınca bu satır **güncellenmelidir** |
| Konum               | **Hayır**                | —             | —                 | —          | Toplanmıyor                                      |
| Kişiler / Rehber    | **Hayır**                | —             | —                 | —          | Toplanmıyor                                      |

Ek beyanlar: veri **aktarımda şifrelenir** (HTTPS) ✅ · kullanıcı **silme talep edebilir**
(Topluluktan ayrılma verisini siler) ✅.

> **Faz 7 (avatar) tamamlandığında bu tablo güncellenmeden yayın yapılmamalıdır.** Yanlış Veri
> Güvenliği beyanı, uygulamanın mağazadan kaldırılma sebebidir.

### 5.7 Yapay zekâ beyanları

Uygulamada **AI Koç** var. Play'in üretken yapay zekâ politikası gereği:

- Uygulama listesinde ve uygulama içinde AI'ın **üretken** olduğu belirtilir.
- Kullanıcıların **uygunsuz çıktıyı bildirebileceği** bir yol bulunmalıdır (mevcut şikâyet
  altyapısı AI yanıtları için de kullanılabilir; Faz 13'te doğrulanacak).
- AI çıktısının hatalı olabileceği kullanıcıya söylenir (mevcut "AI Koç yanılabilir" uyarısı).

### 5.8 İzinler

Yalnız ikisi bildirilir ve gerekçelendirilir:

| İzin                     | Gerekçe                                             |
| ------------------------ | --------------------------------------------------- |
| `POST_NOTIFICATIONS`     | Kullanıcının açtığı günlük çalışma hatırlatması     |
| `RECEIVE_BOOT_COMPLETED` | Cihaz yeniden başlayınca hatırlatmayı yeniden kurma |

**Hassas izin yok** → `QUERY_ALL_PACKAGES`, konum, rehber, SMS, arama kaydı **istenmiyor**.
Faz 7 kamera/galeri eklerse: modern Android'de `image_picker` **izin gerektirmeyen** sistem
seçicisini kullanır; `READ_MEDIA_IMAGES` **eklenmemelidir** (eklenirse gerekçe formu açılır).

## 6. Mağaza listesi

| Öğe                     | Şart                                     | Not                                              |
| ----------------------- | ---------------------------------------- | ------------------------------------------------ |
| Uygulama adı            | ≤ 30 karakter                            | `Ehliyet Akademi`                                |
| Kısa açıklama           | ≤ 80 karakter                            | Sınava hazırlığı tek cümlede anlatır             |
| Tam açıklama            | ≤ 4000 karakter                          | Özellikler + dürüst sınırlar                     |
| Uygulama simgesi        | 512×512 PNG, 32-bit, ≤ 1 MB              | `design-sources/new_icon.png` (1254²) küçültülür |
| **Öne Çıkan Grafik**    | **1024×500** PNG/JPG                     | **Zorunlu** — olmadan yayın yapılamaz            |
| Telefon ekran görüntüsü | **En az 2**, en fazla 8 · 16:9 veya 9:16 | 1080×2340 cihaz görüntüleri uygundur             |
| Kategori                | Eğitim                                   |                                                  |
| İletişim                | E-posta **zorunlu**                      |                                                  |

Ekran görüntüsü önerisi (mevcut ekranlardan): Ana Sayfa · Pratik/soru · Trafik işaretleri ·
Video dersi · Topluluk sıralaması · AI Koç · Premium.

## 7. AAB yükleme ve kapalı test

1. **Test → Kapalı test → Yeni sürüm oluştur**.
2. `app-release.aab` yüklenir (Play App Signing açık olduğu için upload key ile imzalı olması
   yeterlidir).
3. Sürüm adı: `1.0.0 (1)` · Sürüm notları Türkçe yazılır.
4. Test kullanıcısı listesi oluşturulur → `CLOSED_TEST_GUIDE.md`.
5. **Kaydet → İncele → Kapalı teste sun.**

### versionCode kuralı

Her yükleme bir öncekinden **büyük** versionCode ister. `pubspec.yaml`'daki `1.0.0+1` içindeki
`+1` versionCode'dur; her yüklemede artırılmalıdır (`1.0.0+2`, `1.0.0+3` …).

> **Not:** `flutter build apk --split-per-abi` çıktısında versionCode'lar ABI'ye göre ötelenir
> (armeabi-v7a `1001`, arm64-v8a `2001`, x86_64 `3001`). **AAB kullanıldığında bu öteleme
> gerekmez**; Play bölmeyi kendisi yapar. Kapalı test için **AAB yükleyin**.

## 8. İnceleme süreci

- İlk inceleme genelde **birkaç saat–7 gün** sürer; yeni hesaplarda daha uzundur.
- Ret gelirse Play Console'da gerekçe yazılıdır. En sık nedenler: çalışmayan test hesabı (§5.2),
  eksik/yanlış Veri Güvenliği (§5.6), gizlilik politikası URL'sinin erişilemez olması.
- Düzeltip **aynı sürümü** yeniden sunabilirsiniz; versionCode artırmanız gerekmez (sürüm
  yayınlanmadıysa).

## 9. Geri alma (rollback)

Play'de yayınlanmış bir sürüm **geri alınamaz**; yerine **daha yüksek versionCode'lu düzeltilmiş
bir sürüm** yayınlanır. Bu yüzden:

- Kapalı testte **aşamalı yayın** (staged rollout) kullanın.
- Önceki AAB'yi ve eşleşen kaynak etiketini (`git tag v1.0.0+1`) saklayın ki hızlı bir düzeltme
  sürümü üretebilesiniz.
- Ciddi bir sorunda sürümü **durdurabilirsiniz** (halt rollout) — yeni kullanıcılara dağıtım
  durur, mevcut kurulumlar kalır.

## 10. Elle yapılacaklar özeti (kod bunu yapamaz)

1. Geliştirici hesabı aç, kimlik doğrula (25 USD).
2. Upload key üret, `key.properties` yaz, **Git dışında** sakla.
3. Play'de uygulamayı oluştur.
4. Play App Signing SHA'sını al → Firebase'e ekle.
5. Gizlilik politikası sayfasını yayınla, URL'yi gir.
6. Uygulama içeriği beyanlarının tamamını doldur (§5).
7. Simge, Öne Çıkan Grafik, ekran görüntülerini hazırla ve yükle.
8. İncelemeci test hesabını oluştur ve **çalıştığını sına**.
9. AAB'yi kapalı teste yükle, test kullanıcılarını davet et.
