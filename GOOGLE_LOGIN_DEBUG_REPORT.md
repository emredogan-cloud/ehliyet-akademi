# Google Girişi — Teşhis Raporu

**2026-07-27 · Cihaz: AYXSUKIVJVPZ7HPZ (Android 11) · Sürüm derlemesi (release APK)**

Belirti: hesap seçici açılıyor, kullanıcı hesabı seçiyor, sonra hiçbir şey olmuyor.

**Sonuç: zincir 6. adımda kırılıyor.** Google SDK'sı `authenticate()` çağrısında
`[28444] Developer console is not set up correctly.` hatasıyla düşüyor.

Bu bir tahmin değildir; hatanın metni **cihazdan alınmış günlüktedir** (§2).

---

## 1. Kimlik doğrulama zinciri

Her adım cihazda ölçüldü. İzleme geçici olarak eklendi, ölçüm alındı, sonra kaldırıldı.

| #   | Adım                                               | Durum          | Kanıt / açıklama                                                                                |
| --- | -------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------- |
| 0   | Google düğmesine basıldı                           | ✅             | `[GLOGIN] 0 Google düğmesine basıldı`                                                           |
| 1   | `GoogleAuthService.signIn()` çağrıldı              | ✅             | `isConfigured=true serverClientIdLen=72`                                                        |
| 2   | `serverClientId` biçimi                            | ✅             | 72 karakter · boşluk yok · `…ps.googleusercontent.com` ile bitiyor · proje öneki `430417323295` |
| 3   | `GoogleSignIn.initialize()`                        | ✅             | `[GLOGIN] 3 initialize() TAMAM`                                                                 |
| 4   | `supportsAuthenticate()`                           | ✅             | `true`                                                                                          |
| 5   | `authenticate()` çağrıldı → hesap seçici açıldı    | ✅             | Ekran görüntüsü: "Bir hesap seçin" · logcat: `SignInCredentialChooserActivity`                  |
| 6   | **`authenticate()` ID token döndürmeli**           | ❌             | **`GoogleSignInException` fırlattı — burada kırılıyor**                                         |
| 7   | `account.authentication.idToken` okunması          | ⚠              | Ulaşılmadı                                                                                      |
| 8   | `GoogleSignInToken` döndürülmesi                   | ⚠              | Ulaşılmadı                                                                                      |
| 9   | `AuthController.loginWithGoogle()` sonucu işlemesi | ✅ (hata yolu) | `outcome=GoogleSignInError`                                                                     |
| 10  | **`POST /api/auth/google` çağrısı**                | ⚠              | **HİÇ ÇAĞRILMADI** — §4                                                                         |
| 11  | Backend ID token doğrulaması                       | ⚠              | Ulaşılmadı                                                                                      |
| 12  | `TokenStore.write()`                               | ⚠              | Ulaşılmadı                                                                                      |
| 13  | Oturum durumu `authenticated`                      | ⚠              | Ulaşılmadı                                                                                      |
| 14  | Ekrana dönüş                                       | ✅             | `err="Google ile giriş tamamlanamadı." mounted=true`                                            |
| 15  | Gezinme (`context.pop()`)                          | ⚠              | Ulaşılmadı — hata yolu çalıştı, gezinme zaten yapılmaz                                          |

---

## 2. İlk kırılan adım — ham kanıt

**Adım 6:** `GoogleSignIn.instance.authenticate()`

Cihazdan alınan izleme çıktısı:

```
[GLOGIN] 5 authenticate() çağrılıyor (hesap seçici açılacak)
[GLOGIN] E1 GoogleSignInException :: code=GoogleSignInExceptionCode.unknownError
         description=[28444] Developer console is not set up correctly. details=null
[GLOGIN] E1 stack :: #0 GoogleSignInAndroid._authenticate
         (package:google_sign_in_android/google_sign_in_android.dart:231)
[GLOGIN] 10 outcome=GoogleSignInError
[GLOGIN] 10b ERROR → "Google ile giriş tamamlanamadı."
[GLOGIN] 14 ekrana dönen err=Google ile giriş tamamlanamadı. mounted=true
[GLOGIN] 15b hata gösteriliyor
```

Android katmanı **sorunsuz** çalıştı — `ApiException` veya `DEVELOPER_ERROR` yok:

```
SignInCredentialChooserActivity  → açıldı
GoogleSignInActivity             → açıldı
HiddenActivity (androidx.credentials.playservices) → döndü
MainActivity                     → öne geldi
```

Yani hesap seçici çalıştı; hata **token üretilirken** Google tarafında oluştu.

---

## 3. Kök neden

`28444`, Google Identity Services'in **"bu uygulama için uygun bir OAuth istemcisi bulamadım"**
hatasıdır. Google, `authenticate()` sırasında çağıran uygulamanın

```
paket adı  +  çalışma anındaki imza sertifikasının SHA-1'i
```

çiftini projedeki **Android OAuth istemcileriyle** karşılaştırır. Eşleşme yoksa ID token
üretmez ve bu hatayı döndürür.

### 3.1 Uygulama tarafı elenmiştir — ölçümle

| Şüphe                                  | Ölçüm                                                                          | Sonuç                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| `dart-define` verilmedi mi?            | `isConfigured=true`, uzunluk 72                                                | ❌ Değil                                                                 |
| Değer kirli mi (boşluk/tırnak)?        | İlk karakter `4`, son karakter `m`, boşluk yok                                 | ❌ Değil                                                                 |
| Web yerine Android kimliği mi verildi? | `…apps.googleusercontent.com` biçiminde, proje öneki `430417323295`            | ❌ Belirti uyuşmuyor (o durumda `idToken` **null** döner, istisna değil) |
| Yanlış uç nokta / API adresi mi?       | O adıma **hiç ulaşılmadı**                                                     | ❌ İlgisiz                                                               |
| `await` eksik mi?                      | Zincirin tamamı `await`li; izler sırayla düştü                                 | ❌ Değil                                                                 |
| Sessiz `catch {}` var mı?              | Tüm `catch` blokları bir sonuç döndürüyor ve izlendi                           | ❌ Değil                                                                 |
| `if (…) return;` erken çıkışı?         | Erken çıkışların hepsi izlendi; hiçbiri tetiklenmedi                           | ❌ Değil                                                                 |
| Gezinme engellendi mi?                 | Başarı yoluna hiç girilmedi                                                    | ❌ İlgisiz                                                               |
| APK yanlış anahtarla mı imzalı?        | `apksigner`: `CN=Emre Dogan`, SHA-1 `7e1fead920bee1e662a140acffd78dc0b6767357` | ✅ Upload anahtarı, beklenen                                             |

**Uygulama kodu 5. adıma kadar her şeyi doğru yapıyor.** Kırılma noktası Google'ın kendi
yanıtıdır.

### 3.2 Eksik olan yapılandırma

Google Cloud projesi **430417323295** içinde şu çiftle eşleşen bir **Android OAuth istemcisi**
bulunmuyor:

```
Paket adı : com.ehliyetegitim.ehliyet_akademi
SHA-1     : 7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57   (upload anahtarı)
```

> **Not — talimat gereği:** Google Console yapılandırmasını araştırmam istenmemişti; ancak
> talimattaki _"kod aksini kanıtlamadıkça"_ koşulu gerçekleşti. Kanıt, Google SDK'sının kendi
> hata metnidir: `Developer console is not set up correctly`. Bu, benim çıkarımım değil,
> servisin ifadesidir.

---

## 4. `POST /api/auth/google` çağrıldı mı?

**HAYIR.** Hiç çağrılmadı.

Sebep: zincir 6. adımda kırıldığı için `GoogleSignInToken` üretilmedi; denetleyici
`GoogleSignInError` dalına girdi ve backend çağrısı olan dal hiç çalışmadı:

```dart
case GoogleSignInToken(:final idToken):
  return _apply(await _api.loginWithGoogle(idToken));   // ← bu satıra ULAŞILMADI
```

Doğrulama: izlemede `[GLOGIN] 11 POST /api/auth/google gönderiliyor` ve `A1 POST …` satırları
**hiç görünmedi**.

Ayrıca backend'in kendisi **sağlamdır** — bağımsız olarak ölçüldü:

```bash
curl -X POST https://www.ehliyetegitim.com/api/auth/google \
  -H 'content-type: application/json' -d '{"idToken":"a.b.c"}'
→ HTTP 401
```

`401` dönmesi `GOOGLE_SERVER_CLIENT_ID`'nin sunucuda **ayarlı olduğunu** kanıtlar
(ayarlı olmasaydı `503` dönerdi).

---

## 5. Sorumlu kod — ve uygulamadaki GERÇEK kusur

Kırılmanın kendisi uygulama kodunda değil. Ama bu teşhisin **neden bu kadar zor** olduğu
uygulama kodundaki gerçek bir kusurdur:

`apps/mobile/lib/data/auth/google_auth_service.dart` (düzeltme öncesi):

```dart
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) {
    return const GoogleSignInCancelled();
  }
  return const GoogleSignInError('Google ile giriş tamamlanamadı.');   // ← e ATILIYOR
} catch (_) {
  return const GoogleSignInError('Google ile giriş tamamlanamadı.');   // ← hata ATILIYOR
}
```

İki somut sonuç:

1. **Teşhis bilgisi yok ediliyordu.** Google `[28444] Developer console is not set up correctly`
   diyordu; kod bunu okumadan atıyordu. Sürüm derlemesinde nedeni öğrenmenin **hiçbir yolu
   yoktu** — bu raporu üretmek için cihaza özel geçici günlük eklemek gerekti.
2. **Mesaj yanlış yönlendiriyordu.** "Google ile giriş tamamlanamadı." kullanıcıyı örtük olarak
   *tekrar dene*meye çağırır. Oysa yapılandırma hatasında tekrar denemek **hiçbir zaman
   düzelmez**; kullanıcı çalışan yolu (e-posta girişi) deneyeceğine aynı düğmeye basıp durur.
   Kullanıcının "hiçbir şey olmuyor" demesinin sebebi budur: mesaj vardı ama **bir şey
   söylemiyordu**.

---

## 6. Uygulanan düzeltme

### 6.1 Ham neden korunuyor ve günlüğe yazılıyor

```dart
class GoogleSignInError extends GoogleSignInOutcome {
  const GoogleSignInError(this.message, {this.technical});
  final String message;

  /// Geliştirici için HAM neden. Kullanıcıya gösterilmez, günlüğe yazılır.
  final String? technical;
}
```

```dart
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) {
    return const GoogleSignInCancelled();
  }
  final technical = 'GoogleSignInException code=${e.code} description=${e.description}';
  _logFailure(technical);
  return GoogleSignInError(_messageFor(e.description), technical: technical);
}
```

`_logFailure` yalnız **başarısız** girişte çalışır ve gizli değer içermez (jeton yok, e-posta
yok). Sürüm derlemesinde de görünür olması bilinçlidir.

### 6.2 Mesaj eyleme dönüştürüldü

```dart
static String _messageFor(String? description) {
  final d = (description ?? '').toLowerCase();
  if (d.contains('developer console') || d.contains('28444')) {
    return 'Google ile giriş şu an kullanılamıyor. E-posta ile giriş yapabilirsin.';
  }
  if (d.contains('network') || d.contains('timeout')) {
    return 'Bağlantı sorunu. İnternetini kontrol edip tekrar dene.';
  }
  return 'Google ile giriş tamamlanamadı. Tekrar dene.';
}
```

Ayrım bilinçli: **düzelmeyecek** bir hatada "tekrar dene" denmez, **geçici** bir hatada denir.

### 6.3 Düzeltme sonrası cihaz ölçümü

Aynı akış tekrar çalıştırıldı:

```
[auth/google] GoogleSignInException code=GoogleSignInExceptionCode.unknownError
              description=[28444] Developer console is not set up correctly.
```

> Bu satır artık **sürüm derlemesinde kalıcıdır**. Bir sonraki teşhis için geçici kod eklemek
> gerekmeyecek.

Kullanıcının gördüğü mesaj (ekran görüntüsüyle doğrulandı):

> **Google ile giriş şu an kullanılamıyor. E-posta ile giriş yapabilirsin.**

### 6.4 Giriş Ana Sayfa'ya ulaştı mı?

**Hayır — ve ulaşamaz.** Eksik olan Android OAuth istemcisi **uygulama kodundan
oluşturulamaz**; Google Cloud Console'da yapılacak bir işlemdir ve talimat gereği ona
dokunmadım.

Uygulama tarafında yapılabilecek her şey yapıldı: zincir doğru, kimlik doğru taşınıyor, hata
artık teşhis edilebilir ve kullanıcı çalışan yola yönlendiriliyor.

**Girişi çalışır hâle getirmek için gereken tek işlem** (kod değil, konsol):

```
Google Cloud Console → proje 430417323295
  → API'ler ve Hizmetler → Kimlik bilgileri
  → + KİMLİK BİLGİLERİ OLUŞTUR → OAuth istemci kimliği
  → Uygulama türü: Android
      Paket adı : com.ehliyetegitim.ehliyet_akademi
      SHA-1     : 7E:1F:EA:D9:20:BE:E1:E6:62:A1:40:AC:FF:D7:8D:C0:B6:76:73:57
  → OLUŞTUR → 5 dakika bekle → uygulamayı yeniden dene
```

Play'den dağıtılacak yapı için **ayrıca** Play App Signing SHA-1'iyle ikinci bir Android
istemcisi gerekir (`GOOGLE_LOGIN_SETUP.md` §7.3).

---

## 7. Değiştirilen dosyalar

| Dosya                                                | Değişiklik                                                                                                                                                        |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `apps/mobile/lib/data/auth/google_auth_service.dart` | `GoogleSignInError.technical` alanı · `_logFailure()` · `_messageFor()` · `messageForDescription()` (test için)                                                   |
| `apps/mobile/test/google_auth_test.dart`             | 5 yeni test: yapılandırma hatasında "tekrar dene" **denmez**, ağ hatasında denir, bilinmeyen hata genel mesaja düşer, `null` açıklamada çökmez, ham neden taşınır |

**Geçici izleme kodu tamamen kaldırıldı** — depoda `[GLOGIN]` satırı kalmadı.

### Kapılar

```
flutter analyze → 0 sorun
flutter test    → 400 test (+5)
cihaz           → hata mesajı doğrulandı, ham neden logcat'te
```

---

## 8. Bu teşhisten çıkan kalıcı ders

> **Yakalanan istisnayı okumadan atmak, hatayı sahada teşhis edilemez kılar.**

Google zaten doğru cevabı vermişti: `Developer console is not set up correctly`. Kod bu cümleyi
okumadan attığı için sorun, bir sürüm derlemesine geçici günlük eklenerek çözülebildi.

Kural: `catch` bloğu kullanıcıya sadeleştirilmiş bir mesaj gösterebilir, ama **ham nedeni asla
yok etmemelidir**.
