# Google Sign-In — Sıfırdan Kurulum

**Uygulama kimliği:** `com.ehliyetegitim.ehliyet_akademi`
**Hedef:** Android'de Google ile giriş; kimlik sunucuda doğrulanır ve mevcut **Bearer oturumuna**
çevrilir. Misafir kullanım bozulmaz.

> Bu belge, projeyi ilk kez eline alan bir geliştiricinin **dışarıdan hiçbir belgeye bakmadan**
> Google girişini uçtan uca kurabilmesi için yazıldı.

---

## 0. Mimari — ne nereye bağlanıyor

```
[Android uygulaması]
   google_sign_in ile hesap seçilir
   → Google, uygulamaya bir ID TOKEN (JWT) verir
        │
        ▼
[Sunucu: POST /api/auth/google]
   ID token Google'ın JWKS'i ile DOĞRULANIR (imza + aud + iss + exp)
   e-posta doğrulanmışsa kullanıcı bulunur/oluşturulur
   → mevcut sistemin BEARER oturum jetonu döner
        │
        ▼
[Android uygulaması]
   Jeton `TokenStore`'a yazılır — bundan sonrası mevcut akışla AYNI
```

**Neden sunucu doğrulaması şart:** istemciden gelen "ben şu kullanıcıyım" bilgisine güvenilemez.
Uygulama değiştirilerek herhangi bir e-posta iddia edilebilir. Tek güvenilir kanıt, Google'ın
imzaladığı ID token'ın **sunucuda** doğrulanmasıdır.

**Neden mevcut oturum korunuyor:** uygulamanın tamamı (topluluk, satın alma, ilerleme) Bearer
oturumu üzerine kurulu. Google girişi yeni bir oturum sistemi getirmez; **var olana bir giriş
kapısı daha ekler**.

---

## 1. Firebase projesi oluşturma

1. <https://console.firebase.google.com> → **Proje ekle**.
2. Proje adı: `ehliyet-akademi` (istediğiniz adı verebilirsiniz).
3. Google Analytics: **isteğe bağlı**. Açarsanız Play Console'daki Veri Güvenliği formunda
   analitik veri toplama beyan edilmelidir. Kapalı test için **kapatmanız önerilir** — beyan yükü
   azalır.
4. Proje oluşunca **Proje ayarları → Genel** sayfasında **Proje kimliği**ni not edin.

## 2. Android uygulamasını kaydetme

1. Proje ayarları → **Uygulamalarınız** → **Android** simgesi.
2. **Android paket adı:** `com.ehliyetegitim.ehliyet_akademi` (birebir; büyük/küçük harf duyarlı).
3. Takma ad: `Ehliyet Akademi (Android)`.
4. **SHA-1 sertifika parmak izi:** aşağıdaki §3'ten alınır. **Bu alan boş bırakılırsa Google girişi
   sessizce başarısız olur** (hata mesajı vermez, hesap seçici hemen kapanır) — en sık yapılan hata
   budur.
5. `google-services.json` indirilir → `apps/mobile/android/app/google-services.json` konumuna
   konur.

> **`google-services.json` gizli bir dosya değildir** ama projeye özgüdür. Depoya eklenip
> eklenmeyeceği ekip kararıdır; bu projede `.gitignore`'a eklenmesi ve CI'a secret olarak
> verilmesi önerilir (bkz. §8).

## 3. SHA parmak izleri — ÜÇ tanesi gerekir

Google girişi, uygulamayı imzalayan sertifikanın parmak iziyle eşleşme arar. Üç ayrı imza vardır
ve **üçü de Firebase'e eklenmelidir**:

### 3.1 Debug (geliştirme sırasında)

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

### 3.2 Upload key (bizim imzaladığımız AAB)

`PLAY_CONSOLE_SETUP.md` §2'de oluşturulur.

```bash
keytool -list -v -keystore <yol>/upload-keystore.jks -alias upload
```

### 3.3 Play App Signing (Play'in kullanıcıya dağıtırken kullandığı imza)

**En çok atlanan adım budur.** Play, AAB'nizi kendi anahtarıyla yeniden imzalar; kullanıcıdaki
uygulamanın parmak izi sizinkinden **farklıdır**.

Play Console → **Yayın → Kurulum → Uygulama imzalama** → _App signing key certificate_ altındaki
**SHA-1** ve **SHA-256** değerlerini kopyalayın.

> Kapalı teste yüklemeden önce bu değer görünmez. Sıra: önce AAB yükleyin, sonra bu parmak izini
> alıp Firebase'e ekleyin, sonra test kullanıcıları girişi denesin.

Her üçünü de Firebase → Proje ayarları → Android uygulaması → **Parmak izi ekle** ile ekleyin,
ardından `google-services.json`'ı **yeniden indirin**.

## 4. OAuth istemci kimlikleri

Firebase Android uygulamasını oluşturduğunuzda Google Cloud tarafında OAuth istemcileri otomatik
üretilir. Google Cloud Console → **API'ler ve Hizmetler → Kimlik bilgileri** sayfasında görürsünüz:

| İstemci türü | Ne işe yarar                                                               | `.env` adı                 |
| ------------ | -------------------------------------------------------------------------- | -------------------------- |
| **Web**      | Sunucunun ID token'ı doğrularken beklediği `aud`. **Sunucu tarafı budur.** | `GOOGLE_SERVER_CLIENT_ID`  |
| Android      | Paket adı + SHA'ya bağlı istemci                                           | `GOOGLE_ANDROID_CLIENT_ID` |
| Web (ayrı)   | Web uygulaması girişi kullanılacaksa                                       | `GOOGLE_WEB_CLIENT_ID`     |
| iOS          | İleride iOS eklenirse                                                      | `GOOGLE_IOS_CLIENT_ID`     |

> **En kritik ayrım:** Android uygulaması `serverClientId` olarak **Web istemci kimliğini**
> verir; Android istemci kimliğini değil. Yanlış verilirse `idToken` **null** döner ve giriş
> sessizce başarısız olur. Bu, ikinci en sık yapılan hatadır.

Değerler `.env.example`'da **şablon** olarak durur; gerçek değerler `.env.local` (Git dışı) ve
Vercel ortam değişkenlerine girilir. Ayrıntı: `ENV_TEMPLATE.md`.

## 5. OAuth onay ekranı

Google Cloud Console → **API'ler ve Hizmetler → OAuth onay ekranı**:

1. Kullanıcı türü: **Harici**.
2. Uygulama adı: `Ehliyet Akademi` · destek e-postası · geliştirici iletişim e-postası.
3. Kapsamlar: yalnız `email`, `profile`, `openid`. **Hassas kapsam istemeyin** — istersiniz Google
   doğrulaması gerekir ve haftalar sürer.
4. Yayınlama durumu: kapalı test için **Test** modu yeterlidir; test kullanıcılarını buraya da
   ekleyin (en fazla 100). Genel yayına çıkarken **Üretim**'e alın.

## 6. Uygulama tarafı (Faz 2'de kodlanacak)

Beklenen paketler ve bağlanacağı yerler:

| Katman | Dosya                                           | Sorumluluk                                      |
| ------ | ----------------------------------------------- | ----------------------------------------------- |
| Veri   | `lib/data/auth/google_auth_service.dart` (yeni) | Arayüz + `google_sign_in` uygulaması            |
| Veri   | `lib/data/auth/auth_repository.dart` (mevcut)   | `signInWithGoogle()` eklenir                    |
| Arayüz | `lib/features/auth/auth_screen.dart` (mevcut)   | "Google ile devam et" düğmesi                   |
| Sunucu | `apps/web/app/api/auth/google/route.ts` (yeni)  | ID token doğrulama → Bearer oturum              |
| Sunucu | `apps/web/lib/server/google-verify.ts` (yeni)   | **Saf** doğrulama mantığı (JWKS, aud, iss, exp) |

**Mimari kural (Evolution'dan devam):** platforma bağlı her şey **arayüz + uygulama** olarak
yazılır. `GoogleAuthService` bir arayüz olur; widget testleri sahte uygulamayla çalışır, platform
kanalı gerekmez.

**Sunucu doğrulamasının reddetmesi gereken durumlar** (entegrasyon testiyle kanıtlanacak):
imzası geçersiz token · `aud` bizim sunucu istemcimiz değil · `iss` `accounts.google.com` veya
`https://accounts.google.com` değil · süresi dolmuş · `email_verified` false.

## 7. Play Integrity uyumu

Google girişi ile Play Integrity birbirini gerektirmez; ancak ikisi de **doğru imzalanmış**
uygulama ister. Faz 4'te upload key kurulduğunda ve §3.3'teki Play imza parmak izi Firebase'e
eklendiğinde uyum sağlanır. Ek bir kod gerekmez.

## 8. CI ve gizlilik

- `google-services.json` **CI'da secret olarak** verilir (`GOOGLE_SERVICES_JSON` base64) ve
  derleme öncesi dosyaya yazılır. Depoda düz metin tutulmaz.
- CI'daki **gitleaks** taraması istemci kimliklerini yakalayabilir; bu yüzden `.env.example`'a
  yalnız **boş şablon** yazılır (`GOOGLE_SERVER_CLIENT_ID=`), örnek değer bile konmaz.

## 9. Sorun giderme — belirtiden nedene

| Belirti                                          | En olası neden                                                        |
| ------------------------------------------------ | --------------------------------------------------------------------- |
| Hesap seçici açılıp hemen kapanıyor, hata yok    | SHA-1 parmak izi Firebase'de yok veya yanlış imza (§3)                |
| Giriş oluyor ama `idToken` **null**              | `serverClientId` olarak Android istemci verilmiş; **Web** olmalı (§4) |
| Cihazda çalışıyor, Play'den kurulunca çalışmıyor | Play App Signing parmak izi eklenmemiş (§3.3)                         |
| Sunucu 401 "geçersiz token"                      | `aud` uyuşmuyor — sunucudaki `GOOGLE_SERVER_CLIENT_ID` yanlış         |
| `ApiException: 10` (DEVELOPER_ERROR)             | Paket adı/SHA/istemci üçlüsünden biri uyuşmuyor                       |
| Emülatörde çalışıyor, gerçek cihazda çalışmıyor  | Cihazda Google Play Hizmetleri güncel değil                           |

## 10. Elle yapılacaklar özeti (kod bunu yapamaz)

1. Firebase projesi + Android uygulaması oluştur.
2. Üç SHA parmak izini ekle (debug · upload · **Play App Signing**).
3. `google-services.json` indir ve yerleştir.
4. OAuth onay ekranını doldur, test kullanıcılarını ekle.
5. `GOOGLE_SERVER_CLIENT_ID` değerini Vercel ortam değişkenlerine gir.
