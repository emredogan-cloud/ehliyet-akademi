# Beta Faz 2 Raporu — Google ile Giriş

**Prepared:** 2026-07-26 · device-validated on `AYXSUKIVJVPZ7HPZ`

## Verdict: 🟢 GO (Firebase kurulumu elle yapılacak — §6)

`flutter analyze` **0** · `flutter test` **275** (+8) · web **516** (+32) · verify/lint/format temiz ·
CI · Mobile CI · CodeQL yeşil.

## 1. Mimari karar

Google girişi **yeni bir oturum sistemi getirmez**. Mevcut Bearer oturumuna bir **giriş kapısı**
ekler; e-posta/parola ve misafir yolları olduğu gibi durur.

```
Android → google_sign_in → ID token (JWT)
   → POST /api/auth/google → Google JWKS ile imza doğrulaması
   → iss/aud/exp/email_verified kontrolü → kullanıcı bul/oluştur
   → MEVCUT createSession() → Bearer jeton → TokenStore
```

**Neden sunucu doğrulaması:** istemcinin kimlik iddiasına güvenilemez. Uygulama değiştirilerek
herhangi bir e-posta iddia edilebilirdi. Tek güvenilir kanıt, Google'ın imzaladığı token'ın
**sunucuda** doğrulanmasıdır.

## 2. Katmanlar

| Katman         | Dosya                                | Sorumluluk                                                          |
| -------------- | ------------------------------------ | ------------------------------------------------------------------- |
| Sunucu (saf)   | `lib/server/google-verify.ts`        | iss · aud · exp · email_verified · ad türetme. **Ağ yok** → 21 test |
| Sunucu (uç)    | `app/api/auth/google/route.ts`       | JWKS (önbellekli) + RS256 imza + oturum                             |
| Mobil (arayüz) | `data/auth/google_auth_service.dart` | `GoogleAuthService` + v7 uygulaması                                 |
| Mobil (durum)  | `domain/auth/auth_controller.dart`   | `loginWithGoogle()`                                                 |
| Mobil (yüzey)  | `features/auth/auth_screen.dart`     | Düğme + ayırıcı + marka işareti                                     |

## 3. Güvenlik — testle sabitlenen redler

| Durum                                           | Sonuç                                       |
| ----------------------------------------------- | ------------------------------------------- |
| Başka anahtarla imzalanmış token                | 401                                         |
| **Başka uygulamanın token'ı** (`aud` uyuşmuyor) | 401                                         |
| Süresi dolmuş                                   | 401                                         |
| Sahte `iss`                                     | 401                                         |
| **Doğrulanmamış e-posta**                       | 401 **ve hesap AÇILMAZ**                    |
| Bilinmeyen `kid`                                | 401                                         |
| Bozuk/eksik JWT                                 | 401 / 400                                   |
| Google'a ulaşılamıyor                           | 503 — doğrulanmamış token **kabul edilmez** |

**Durum sızdırmama:** imza/aud/issuer/biçim hatalarının hepsi **aynı** mesajı verir; hangi
kontrolün düştüğü saldırgana bilgi vermez. Yalnız kullanıcının düzeltebileceği iki durum
(doğrulanmamış e-posta, süre dolması) ayrı mesaj alır.

**Saat kayması:** 60 sn pay; yeni dolmuş token kabul, payın dışı ret (testli).

## 4. Hesap birleştirme

Aynı e-postayla **parolayla** kaydolmuş kullanıcı Google ile girince **aynı hesaba** bağlanır —
ikinci hesap açılmaz, ilerleme ikiye bölünmez. Entegrasyon testi bunu kullanıcı kimliği
karşılaştırarak kanıtlıyor.

Google ile açılan yeni hesaba `passwordHash: 'google$no-password'` yazılır → parola girişi
her zaman başarısız olur; hesap yalnız Google ile açılır.

## 5. Device validation

| #   | Doğrulanan                                                                   | Kanıt            |
| --- | ---------------------------------------------------------------------------- | ---------------- |
| 1   | **Yapılandırılmamış** derlemede Google düğmesi **hiç yok** (ölü gezinme yok) | `b2_07`          |
| 2   | **Yapılandırılmış** derlemede "veya" ayırıcısı + "Google ile devam et"       | `b2_08`          |
| 3   | Google'ın dört renkli "G" işareti doğru çiziliyor                            | `b2_08`          |
| 4   | E-posta/parola alanları ve girişi bozulmadı                                  | `b2_07`, `b2_08` |
| 5   | Parola göster/gizle (Faz E13 ipucu) çalışıyor                                | `b2_07`          |

## 6. Honest limitations

1. **Gerçek Google hesabıyla uçtan uca giriş DENENMEDİ.** Firebase projesi, `google-services.json`
   ve SHA parmak izleri **elle** kurulacak adımlardır (`GOOGLE_AUTH_SETUP.md` §10). Bu ortamda
   yapılamaz. Doğrulanan: arayüz koşulları, sunucu doğrulaması (gerçek RSA imzasıyla), reddedilmesi
   gereken bütün durumlar.
2. **Play App Signing SHA'sı henüz yok** — uygulama Play'e yüklenmeden bu parmak izi görünmez.
   Kapalı teste ilk yükleme sonrası Firebase'e eklenmelidir, yoksa **Play'den kurulan yapıda giriş
   çalışmaz**.
3. **Apple ile giriş yok.** Referans mockup'ta vardı; iOS derlemesi olmadığı için çalışmayan bir
   düğme **ölü gezinme** olurdu (disiplin kural 3) → konmadı.
4. **Token yenileme yok.** Google ID token yalnız giriş anında kullanılır; oturum ömrü mevcut
   Bearer oturumu kurallarına tabidir. Bu, mevcut mimarinin davranışıdır ve değiştirilmedi.

## 7. Next phase prerequisites

Faz 3 (RevenueCat) için: `.env.example` deseni kuruldu; "anahtar yoksa dürüst davran" kalıbı
Faz 2'de uygulandı ve testle korunuyor — Faz 3 aynı kalıbı kullanacak.
