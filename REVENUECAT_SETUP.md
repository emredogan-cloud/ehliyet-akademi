# RevenueCat — Sıfırdan Kurulum

**Uygulama kimliği:** `com.ehliyetegitim.ehliyet_akademi`
**Hedef:** Abonelik/satın alma yaşam döngüsünü RevenueCat üzerinden yönetmek; gizli anahtarlar
depoya **girmeden**.

---

## 0. Önce bir gerçeği kayda geçirelim — model çakışması

Mevcut uygulamada premium şudur (`lib/domain/premium/products.dart`):

```
TEK ürün: "Komple Ehliyet Paketi" · 399 TL · TEK SEFERLİK / ÖMÜR BOYU
Play ürün türü: yönetilen ürün (non-consumable) — `buyNonConsumable`
Yetenekler: teori-premium · direksiyon-premium · sinirsiz-deneme ·
            soru-bankasi-tam · ai-sinirsiz · video-tam
```

Bu programın istediği ortam değişkenleri ise **abonelik** ima ediyor:
`REVENUECAT_MONTHLY_PRODUCT`, `REVENUECAT_YEARLY_PRODUCT`.

**Bu bir çelişki değil, bir ürün kararıdır ve kararı vermek geliştiricinin işi değildir.**
Bu yüzden entegrasyon **her iki modeli de** taşıyacak biçimde kurulur:

| Kurulum                   | RevenueCat karşılığı                              |
| ------------------------- | ------------------------------------------------- |
| Ömür boyu paket (bugünkü) | Non-consumable ürün → aynı **entitlement**'ı açar |
| Aylık abonelik (istenen)  | Subscription ürün → aynı **entitlement**'ı açar   |
| Yıllık abonelik (istenen) | Subscription ürün → aynı **entitlement**'ı açar   |

**Birleştirici kavram `entitlement`'tır.** Uygulama "kullanıcı hangi ürünü aldı" diye sormaz;
"`premium` yetkisi var mı" diye sorar. Böylece ürün modeli sonradan değişse bile **uygulama kodu
değişmez**. Bu, mevcut `capabilities` modeliyle de birebir örtüşür.

> Ürün sahibi ömür boyu modelde kalmaya karar verirse aylık/yıllık ürünler Play'de hiç
> oluşturulmaz; `.env` şablonundaki iki satır boş kalır ve kod bunu dürüstçe karşılar.

---

## 1. RevenueCat hesabı ve proje

1. <https://app.revenuecat.com> → kayıt ol.
2. **Create new project** → ad: `Ehliyet Akademi`.
3. **Project settings → API keys**: iki tür anahtar vardır:

| Anahtar                      | Nerede kullanılır               | Depoya girer mi                |
| ---------------------------- | ------------------------------- | ------------------------------ |
| **Public SDK key** (Android) | Mobil uygulama içinde           | `.env` şablonu — **değer yok** |
| **Secret API key**           | Yalnız sunucu → RevenueCat REST | **ASLA** — Vercel secret       |

> Public SDK key "gizli" sayılmaz (uygulamada bulunur) ama yine de depoya yazılmaz; `.env` ile
> derleme zamanında verilir. Secret key hiçbir koşulda istemciye konmaz.

4. **Project settings → Project ID** değerini not edin → `REVENUECAT_PROJECT_ID`.

## 2. Play Console tarafında ürünleri oluşturma

RevenueCat, Play'deki ürünleri **kendisi oluşturmaz**; var olanları okur.

### 2.1 Ömür boyu paket (mevcut model)

**Para kazanma → Ürünler → Uygulama içi ürünler → Ürün oluştur**

| Alan         | Değer                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------ |
| Ürün kimliği | `komple_ehliyet` (kodda `storeProductId` bunu üretir: `komple-ehliyet` → `komple_ehliyet`) |
| Ad           | Komple Ehliyet Paketi                                                                      |
| Açıklama     | Tüm konular, sınırsız deneme, sınırsız AI Koç, tüm videolar                                |
| Fiyat        | 399,00 TRY                                                                                 |
| Durum        | Etkin                                                                                      |

> **Ürün kimliği koddaki değerle birebir eşleşmeli.** Eşleşmezse `queryProducts()` boş döner ve
> ödeme ekranı "mağaza kullanılamıyor" gösterir.

### 2.2 Abonelikler (istenirse)

**Para kazanma → Ürünler → Abonelikler → Abonelik oluştur**

| Ürün kimliği         | Temel plan | Fatura dönemi | Not                          |
| -------------------- | ---------- | ------------- | ---------------------------- |
| `ea_premium_monthly` | `monthly`  | P1M           | `REVENUECAT_MONTHLY_PRODUCT` |
| `ea_premium_yearly`  | `yearly`   | P1Y           | `REVENUECAT_YEARLY_PRODUCT`  |

Her abonelik için **temel plan (base plan)** oluşturmayı unutmayın; Play'de plan olmadan abonelik
satın alınamaz. Ödemesiz deneme/indirim teklifleri isteğe bağlıdır.

### 2.3 Play ↔ RevenueCat bağlantısı

RevenueCat → **Project settings → Integrations → Google Play**:

1. Google Cloud'da bir **servis hesabı** oluşturun.
2. Play Console → **Kullanıcılar ve izinler** → servis hesabını davet edin; yetkiler:
   _Finansal verileri görüntüle_ + _Siparişleri ve abonelikleri yönet_.
3. Servis hesabının JSON anahtarını RevenueCat'e yükleyin.
4. Play Console → **Para kazanma kurulumu → Gerçek zamanlı geliştirici bildirimleri**: RevenueCat'in
   verdiği Pub/Sub konu adını yapıştırın.

> Adım 4 atlanırsa iptal/yenileme/ödeme hatası olayları uygulamaya **gecikmeli** yansır. Grace
> period ve account hold davranışları bu bildirimlere dayanır.

## 3. Entitlement ve Offering

### 3.1 Entitlement

RevenueCat → **Entitlements → New**

| Alan          | Değer                                                       |
| ------------- | ----------------------------------------------------------- |
| Identifier    | `premium` → `REVENUECAT_ENTITLEMENT`                        |
| Bağlı ürünler | `komple_ehliyet`, `ea_premium_monthly`, `ea_premium_yearly` |

Üç ürün de **aynı** entitlement'ı açar. Uygulama yalnız şunu sorar:
`customerInfo.entitlements.active['premium'] != null`.

### 3.2 Offering

RevenueCat → **Offerings → New** → identifier `default`, paketler:

| Paket         | Ürün                 |
| ------------- | -------------------- |
| `$rc_monthly` | `ea_premium_monthly` |
| `$rc_annual`  | `ea_premium_yearly`  |
| `lifetime`    | `komple_ehliyet`     |

Offering, ödeme ekranının **sunucudan yönetilmesini** sağlar: fiyat/paket değişimi uygulama
güncellemesi gerektirmez.

## 4. Uygulama tarafı mimarisi (Faz 3'te kodlanacak)

**Kural (Evolution'dan devam): mevcut `in_app_purchase` yolu SÖKÜLMEZ.** RevenueCat onun yanına,
arayüz + uygulama deseniyle eklenir.

| Katman | Dosya                                             | Sorumluluk                                                            |
| ------ | ------------------------------------------------- | --------------------------------------------------------------------- |
| Veri   | `lib/data/premium/billing_gateway.dart` (yeni)    | **Arayüz**: `products()`, `purchase()`, `restore()`, `entitlements()` |
| Veri   | `lib/data/premium/revenuecat_gateway.dart` (yeni) | `purchases_flutter` uygulaması                                        |
| Veri   | `lib/data/premium/iap_service.dart` (mevcut)      | Aynı arayüzün mevcut uygulaması — **korunur**                         |
| Seçim  | `billingGatewayProvider`                          | Anahtar varsa RevenueCat, yoksa mevcut yol                            |

**Anahtar yoksa ne olur:** uygulama **çökmez**; ödeme ekranı bugünkü dürüst
"Mağaza kullanılamıyor" durumunu gösterir. Bu davranış Faz 3'te **testle** korunacaktır.

## 5. Yaşam döngüsü davranışları — ne beklenmeli

| Durum                      | Ne olur                                                      | Uygulama ne yapmalı                                               |
| -------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------------- |
| **Satın alma**             | Entitlement anında aktifleşir                                | Premium yüzeyleri açılır                                          |
| **Geri Yükleme**           | Kullanıcı cihaz değiştirdi/uygulamayı sildi                  | **"Satın Alımı Geri Yükle" düğmesi ZORUNLUDUR** (Play politikası) |
| **İptal**                  | Kullanıcı iptal eder ama dönem sonuna kadar erişim **sürer** | Dönem bitene kadar premium açık kalır                             |
| **Ödemesiz dönem (grace)** | Ödeme başarısız; Play 3–30 gün tanır, erişim **sürer**       | Premium açık; kullanıcıya ödeme yöntemini güncelle uyarısı        |
| **Hesap beklemesi (hold)** | Grace bitti, hâlâ ödenmedi; erişim **durur** (30 güne kadar) | Premium kapanır; "aboneliğini yenile" mesajı                      |
| **Yenileme**               | Otomatik                                                     | Bir şey yapılmaz                                                  |
| **Para iadesi**            | RevenueCat webhook ile bildirir                              | Entitlement kapanır                                               |

> **Ömür boyu üründe** iptal/grace/hold **yoktur**; yalnız satın alma ve geri yükleme vardır.

## 6. Test etme

### 6.1 Lisans test hesapları

Play Console → **Kurulum → Lisans testi** → test hesabı e-postalarını ekleyin. Bu hesaplar
**gerçek para ödemeden** satın alma akışını uçtan uca çalıştırır ve abonelikler hızlandırılmış
sürede yenilenir:

| Gerçek dönem | Test süresi |
| ------------ | ----------- |
| 1 hafta      | 3 dakika    |
| 1 ay         | 5 dakika    |
| 1 yıl        | 30 dakika   |

### 6.2 Ortam kısıtı — dürüst uyarı

**Gerçek satın alma bu geliştirme ortamında (Linux, `adb install`) TEST EDİLEMEZ.** Play Billing
yalnız **Play'den yüklenmiş, imzalı** bir yapı ile çalışır. Bu, mevcut `iap_service.dart`
belgesinde de yazılıdır ve değişmemiştir.

Doğru test yolu: AAB'yi **iç teste** yükleyin, test hesabıyla Play üzerinden kurun, satın almayı
orada deneyin.

### 6.3 Sınanacak senaryolar (Faz 13 denetiminde tekrar edilir)

1. Satın alma → premium açılır
2. Uygulamayı sil/yeniden kur → **Geri Yükle** → premium geri gelir
3. İptal → dönem sonuna kadar erişim sürer
4. Ödeme yöntemi bozuk → grace period davranışı
5. Anahtarsız derleme → çökme yok, dürüst "mağaza kullanılamıyor"

## 7. Elle yapılacaklar özeti (kod bunu yapamaz)

1. RevenueCat hesabı + proje oluştur; Public SDK key ve Project ID'yi al.
2. Play'de ürünleri oluştur (`komple_ehliyet` ve/veya abonelikler).
3. Servis hesabı oluştur, Play'de yetkilendir, RevenueCat'e bağla.
4. Gerçek zamanlı geliştirici bildirimlerini (Pub/Sub) bağla.
5. `premium` entitlement'ını ve `default` offering'i tanımla.
6. Lisans test hesaplarını ekle.
7. Anahtarları Vercel/CI secret'larına gir — **depoya değil**.
