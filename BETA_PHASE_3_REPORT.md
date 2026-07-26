# Beta Faz 3 Raporu — RevenueCat

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `jfzxugsgnnvsrsg6` (**cihaz değişti** — §7)

## Karar: 🟢 GO (RevenueCat panosu kurulumu elle yapılacak — §8)

`flutter analyze` **0** · `flutter test` **311** (+36) · web **516** · `@ea/db` **6** ·
`content-schema` **17** · `question-bank` **10** · `srs-engine` **12** ·
`pnpm lint` 0 hata · `format` · `verify` · `typecheck` temiz.

---

## 1. Kritik keşif — RevenueCat mevcut sunucu ucunu YENİDEN KULLANAMAZ

Faz 3'e girerken varsayım şuydu: RevenueCat satın almasından Play `purchaseToken`'ı alınır ve
mevcut `POST /api/iap/validate` ucuna gönderilir. **Bu varsayım yanlış çıktı ve kod yazılmadan
önce doğrulandı.**

`purchases_flutter` 10.4.3'ün `StoreTransaction` modeli yalnız üç alan taşır:

```
transactionIdentifier · productIdentifier · purchaseDate
```

Ham Play `purchaseToken`'ı **yoktur**. (Android'in yerel RevenueCat SDK'sında `orderId` ve
`purchaseToken` ayrı alanlardır; Flutter köprüsü bunları tek bir `transactionIdentifier`'a
indirger.) Mevcut sunucu ucu ise `androidpublisher` doğrulaması için gerçek `purchaseToken`
bekliyor (`apps/web/app/api/iap/validate/route.ts`).

**Sonuç:** RevenueCat'te doğru sunucu köprüsü **webhook**'tur (RevenueCat → sunucumuz), istemci
makbuzu değil. Bu, gizlenecek bir ayrıntı değil; mimariye **açıkça** kodlandı:

```dart
enum BillingServerBridge { clientReceipt, revenueCatWebhook }
```

Her ağ geçidi hangi köprüyü kullandığını bildirir; ödeme ekranı buna göre davranır. Böylece
"satın alma başarılı ama sunucu yetkiyi hiç görmedi" sessiz hatası **mimari olarak imkânsız**
hâle geldi.

> Bu keşif olmasaydı, gerçek anahtarlarla ilk satın almada kullanıcı parayı öder, RevenueCat
> yetkiyi açar, **bizim sunucumuz haberdar olmaz** ve AI/içerik kapıları kapalı kalırdı.

## 2. Mimari

**Mevcut `in_app_purchase` yolu SÖKÜLMEDİ.** `iap_service.dart` dosyasına **tek satır
dokunulmadı**; ortak sözleşmeye bir sarmalayıcı ile bağlandı.

| Katman       | Dosya                                    | Sorumluluk                                            |
| ------------ | ---------------------------------------- | ----------------------------------------------------- |
| Saf kural    | `domain/premium/entitlement_status.dart` | Yaşam döngüsü kuralları. **Eklenti bağımlılığı YOK**  |
| Arayüz       | `data/premium/billing_gateway.dart`      | Yansız modeller + sözleşme + `billingGatewayProvider` |
| Uygulama (A) | `data/premium/play_billing_gateway.dart` | Mevcut `IapService`'i sarar — **iç mantık değişmedi** |
| Uygulama (B) | `data/premium/revenuecat_gateway.dart`   | `purchases_flutter` 10.4.3                            |
| Yüzey        | `features/premium/paywall_screen.dart`   | Artık **somut eklenti tanımıyor**, yalnız sözleşmeyi  |
| Yapılandırma | `core/config.dart`                       | `revenueCatEntitlement` (varsayılan `premium`)        |

**Seçim:** `REVENUECAT_PUBLIC_KEY` derleme zamanında verilmişse RevenueCat, verilmemişse mevcut
yol. Faz 2'de Google girişi için kurulan **"anahtar yoksa dürüst davran"** kalıbının aynısı.

**Yansız modeller neden şart:** arayüz `ProductDetails` (in_app_purchase) ya da `StoreProduct`
(RevenueCat) sızdırsaydı ödeme ekranı hangi altyapının etkin olduğunu bilmek zorunda kalır ve
widget testleri platform kanalı olmadan çalışamazdı. İkisi de `BillingProduct`'a indirgeniyor.

## 3. Ürün modeli çakışması — kod kararı beklemiyor

`REVENUECAT_SETUP.md` §0'daki çakışma (bugün ömür boyu tek ürün · program aylık/yıllık istiyor)
**bir ürün kararıdır ve verilmedi.** Kod her iki modeli de taşıyor:

- Uygulama "hangi ürün alındı" diye **sormaz**; `premium` yetkisi var mı diye sorar.
- `BillingPeriod` (`lifetime` · `monthly` · `yearly` · `unknown`) paket türünden türetilir;
  RevenueCat'te paket türü `custom` bırakılmışsa ürün kimliğinden yedek eşleşme yapılır.
- `REVENUECAT_MONTHLY_PRODUCT` / `YEARLY_PRODUCT` **boş kalabilir** — kod bunu dürüstçe karşılar.

Ürün modeli sonradan değişse bile **uygulama kodu değişmez**.

## 4. Yaşam döngüsü — saf kural katmanı

`REVENUECAT_SETUP.md` §5'teki tablo çalışan koda çevrildi ve **doğrudan** test edildi (eklenti
gerekmez):

| Durum         | Kural                            | Erişim | Kullanıcı eylemi |
| ------------- | -------------------------------- | ------ | ---------------- |
| `lifetime`    | `expiresAt == null` → süresiz    | ✅     | —                |
| `active`      | etkin + yenilenecek              | ✅     | —                |
| `cancelled`   | iptal algılandı / yenilenmeyecek | ✅     | —                |
| `gracePeriod` | ödeme sorunu, erişim sürüyor     | ✅     | **Evet**         |
| `accountHold` | ödeme sorunu + erişim durdu      | ❌     | **Evet**         |
| `none`        | yetki yok                        | ❌     | —                |

**Sıralama kararı:** ödeme sorunu, iptalden **önce** değerlendirilir — ikisi aynı anda doğru
olabilir ve kullanıcıya gösterilecek en acil mesaj ödeme sorunudur (testle sabitlendi).

**Ömür boyu üründe iptal/grace/hold YOKTUR** — `expiresAt == null` bu dalları hiç açmaz.

`in_app_purchase` yolu yaşam döngüsü **bildirmez** ve boş liste döner: uydurma durum üretilmez,
ekran hiçbir uyarı göstermez.

## 5. Play politikası — "Satın Alımı Geri Yükle"

Geri yükleme eylemi `AppBar`'da **koşulsuzdur**: mağaza kapalıyken, yapılandırma yokken ve
kullanıcı premium değilken de görünür. Testle sabitlendi.

**Düzeltilen dürüstlük hatası:** eski kod geri yüklemeden sonra koşulsuz
_"Satın almalar geri yüklendi."_ diyordu — hiçbir şey geri yüklenmemiş olsa bile. Artık sonuca
göre konuşuyor: sahiplik varsa _"Satın almaların geri yüklendi."_, yoksa
_"Geri yüklenecek bir satın alma bulunamadı."_ **Cihazda doğrulandı** (`b3_06`).

## 6. Testler — +36

| Küme                               | Sayı | Kapsam                                                                   |
| ---------------------------------- | ---: | ------------------------------------------------------------------------ |
| Yaşam döngüsü (saf)                |   10 | Altı durum + sıralama + eşleşmeyen yetki + süresiz-etkin-değil çelişkisi |
| RevenueCat yapılandırma            |    4 | Anahtarsız/anahtarlı · webhook köprüsü · **hiçbir çağrıda fırlatmaz**    |
| `in_app_purchase` yolu (SÖKÜLMEDİ) |    9 | Makbuz köprüsü · ürün çevirimi · **Play token'ının korunduğu**           |
| Ödeme ekranı                       |   13 | Mağaza kapalı/açık · vazgeçme · hata · geri yükleme · yaşam döngüsü      |

**`FakeIapService implements IapService`** — Dart'ın örtük arayüzü sayesinde `iap_service.dart`
dosyasına **dokunmadan** mevcut yol test edilebildi. (İlk denemede gerçek `IapService`
örneklenmiş ve test gerçek bir Play Billing bağlantısı açmıştı; sahte uygulamayla kapatıldı.)

**Test yüzeyi ölçüsü:** ödeme ekranı testleri 800×**1400**'de koşuyor. Varsayılan 800×600'de
`ListView` ekranın alt yarısını hiç inşa etmiyor ve fiyat/uyarı/düğme bulunamıyordu. Genişlik
800'de **bırakıldı**: testlerin Ahem yazı tipi gerçeğinden geniştir ve 400 dp'de ana ekranda
**gerçek olmayan** taşmalar üretiyordu — cihazda 393 dp'de taşma yok (`b3_02`).

## 7. Cihaz doğrulaması — CİHAZ DEĞİŞTİ

**Belgelenen cihaz `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG, Android 11) bu oturumda BAĞLI DEĞİL.**
Yeniden başlatma sonrası farklı bir cihaz takılı. Doğrulama gerçek donanımda yapıldı, ama
**başka bir cihazda** — bu, sahiplenilmesi gereken bir sapmadır:

| Alan    | Belgelenen         | **Kullanılan**          |
| ------- | ------------------ | ----------------------- |
| Kimlik  | `AYXSUKIVJVPZ7HPZ` | **`jfzxugsgnnvsrsg6`**  |
| Model   | Redmi M1908C3JGG   | **Xiaomi 22095RA98C**   |
| Android | 11                 | **13 (SDK 33)**         |
| Ekran   | 1080×2340          | **1080×2408 · 440 dpi** |
| ABI     | arm64-v8a          | arm64-v8a               |

Android 13 daha yeni bir hedef olduğu için doğrulama **zayıflamadı**, güçlendi.

### Faz 2'deki gibi İKİ AYRI DERLEME

| #   | Derleme                                    | Beklenen                                         | Sonuç | Kanıt   |
| --- | ------------------------------------------ | ------------------------------------------------ | ----- | ------- |
| 1   | `--dart-define` **YOK**                    | Mevcut yol · "Mağaza kullanılamıyor" · çökme yok | ✅    | `b3_04` |
| 2   | `REVENUECAT_PUBLIC_KEY` **VAR** (geçersiz) | RevenueCat seçilir · **yine çökmez**             | ✅    | `b3_08` |

**Derleme 2'nin kanıtı ekran görüntüsü değil, `logcat`:**

```
W dex2oat64: Compilation of ... PurchasesFactory.createPurchases(...)
E [Purchases] - ERROR: The specified API Key is not recognized.
E [Purchases] - ERROR: 🤖‼️ Error fetching offerings - PurchasesError(code=InvalidCredentialsError, ...)
```

Bu üç satır birlikte şunu **kanıtlıyor**: (a) RevenueCat SDK gerçekten başlatıldı → ağ geçidi
seçimi çalıştı, (b) geçersiz anahtar RevenueCat sunucusunca reddedildi, (c) `logcat -b crash`
**boş** ve `FATAL` yok → uygulama hayatta kaldı ve dürüst durumu gösterdi.

> DoD yalnız "anahtar yokken çökmez" istiyordu. Ölçülen daha güçlü: **yanlış anahtarla da
> çökmüyor** — gerçek kurulumda en olası hata budur.

Doğrulanan diğer yüzeyler: soğuk açılış · tanıtım · ana sayfa (**taşma yok**) · profil · öğren
(`b3_01`, `b3_02`, `b3_03`, `b3_09`). Oturum boyunca `logcat -b crash` **boş kaldı**.

## 8. Dürüst sınırlar

1. **GERÇEK SATIN ALMA TEST EDİLMEDİ.** Play Billing yalnız Play'den yüklenmiş, imzalı yapıda
   çalışır; bu Linux ortamında (`adb install`) mümkün değil. Sınanan: satın almanın etrafındaki
   bütün mantık ve arayüz davranışı. Doğru yol: AAB'yi iç teste yükle, **lisans test hesabıyla**
   dene (`REVENUECAT_SETUP.md` §6.1).
2. **Gerçek RevenueCat anahtarıyla uçtan uca akış denenmedi** — hesap, Play ürünleri, servis
   hesabı ve Pub/Sub bildirimleri **elle** kurulacak adımlardır (§9). Denenen: geçersiz anahtarın
   uygulamayı çökertmediği.
3. **Sunucu tarafı RevenueCat webhook'u YAZILMADI.** Bu bilinçli: webhook, RevenueCat secret
   key'i ve panoda tanımlı bir genel URL gerektirir; ikisi de henüz yok. §1'deki köprü ayrımı
   kodda hazır, sunucu ucu Play ürünleri oluşturulduktan sonra yazılmalıdır. **Bugünkü etkin yol
   (`in_app_purchase` + `/api/iap/validate`) bundan etkilenmiyor ve çalışıyor.**
4. **`transactionIdentifier`'ın Android'de tam olarak neye karşılık geldiği** (orderId mi, başka
   bir kimlik mi) bu ortamda **doğrulanamadı** — yerel eşleme `purchases-hybrid-common` Maven
   artefaktında ve kaynağı depoda yok. Bu yüzden ondan **hiçbir güvenlik varsayımı türetilmedi**;
   RevenueCat yolunda sahiplik sunucudan tazeleniyor.
5. **Abonelik yaşam döngüsü gerçek Play olaylarıyla görülmedi** — grace period/account hold
   yalnız gerçek abonelikte oluşur. Kural katmanı testle sabitlendi; gerçek olaylar Faz 13'te
   lisans test hesabıyla denenecek.

## 9. Elle yapılacaklar (kod bunu yapamaz)

`REVENUECAT_SETUP.md` §7 tam liste. Özet: RevenueCat hesabı + proje · Play'de ürünler · servis
hesabı + Play yetkileri · Pub/Sub bildirimleri · `premium` entitlement + `default` offering ·
lisans test hesapları · anahtarların CI/Vercel secret'larına girilmesi.

## 10. Yan bulgu — Faz 2'nin `.env.example`'ı depoya hiç girmemiş

`apps/web/.env.example` Faz 2 çıktısı olarak raporlanmıştı, ancak **Git'te izlenmiyordu**: kök
`.gitignore`'un 18. satırındaki `.env*`, 10. satırdaki `!.env.example` istisnasını geçersiz
kılıyordu (son eşleşen kalıp kazanır). Aynı tuzak `apps/web/.gitignore`'da da vardı.

Sonuç: depoyu klonlayan **hiçbir şablon almıyordu** — Faz 2'nin bir çıktısı yalnız bu diskte
duruyordu. Faz 3'ün `apps/mobile/.env.example`'ı da aynı tuzağa düşecekti.

**Düzeltildi:** her iki `.gitignore`'a gerekçeli `!.env.example` eklendi; iki şablon da bu
commit'le depoya giriyor. Kapı gevşetilmedi — şablonlarda gizli değer yok, `verify` ve prettier
temiz.

**Ders:** _"belgede yazıyor" ile "depoda var" aynı şey değildir._ Bir dosyanın teslim edildiğini
söylemeden önce `git ls-files` ile izlendiği doğrulanmalıdır.

## 11. Ölçülen artefakt boyutları

| Artefakt        | Boyut                       |
| --------------- | --------------------------- |
| arm64-v8a APK   | 31.312.050 B (**29,8 MiB**) |
| armeabi-v7a APK | 29.163.404 B (27,8 MiB)     |
| x86_64 APK      | 32.780.099 B (31,2 MiB)     |

**Delta hakkında dürüst not:** diskteki önceki arm64 artefaktı 29.305.991 B idi → fark
**+2.006.059 B (+1,91 MiB)**. Ancak o artefakt Faz 2 commit'inden **önce** üretilmiştir; bu
fark `purchases_flutter` **ve** `google_sign_in`'i birlikte kapsar. **Yalnız RevenueCat'in payı
ölçülmedi** ve tahmin edilmedi.

## 12. Sonraki faz için zemin

Faz 4 (Play yayın hazırlığı) **B1 + B2**'yi kapatacak. Bu fazda ikisine de **dokunulmadı** ve
`android/app/build.gradle.kts` olduğu gibi duruyor (release hâlâ debug anahtarıyla imzalanıyor).

Faz 3'ten Faz 4'e taşınan girdi: `apps/mobile/.env.example` artık **depoda** ve
`--dart-define` listesi eksiksiz — imzalı AAB derlenirken hangi değerlerin verileceği belli.
