# Ehliyet Akademi — Post-Beta Ürün Geliştirme Programı · Uygulama Raporu

**Tarih:** 1 Ağustos 2026 · **Taban:** `c4a296b` (RC 1.0.0+4) → `feature/post-beta-improvement`
**Kapsam:** 9 faz. Faz 1–6 bu belgede; Faz 7–9 [`CONTENT_EXPANSION_MASTERPLAN.md`](CONTENT_EXPANSION_MASTERPLAN.md) içinde.

---

## 1. Durum

| Kapı              | Sonuç                                            |
| ----------------- | ------------------------------------------------ |
| `flutter analyze` | **0 sorun**                                      |
| Mobil test        | **943 ✓** (program başı 889 → **+54**)           |
| Web test          | **633 ✓**                                        |
| GitHub Actions    | **9/9 yeşil**                                    |
| Cihaz doğrulaması | Redmi Note 8 (Android 11) — aşağıda kanıtlarıyla |
| AAB               | `versionCode 5` · imzalı · doğrulandı            |

**Cihaz notu (dürüstçe):** program boyunca yalnız **Redmi Note 8 (2021), Android 11** bağlıydı.
Tercih edilen Redmi Note 11R ve Huawei ANE-LX1 bu oturumda hiç görünmedi
(`adb devices` her fazda kontrol edildi). Talimattaki geri düşüş sırası uygulandı:
Redmi Note 11R → Huawei → **en son bağlı Redmi**. Hiçbir faz cihaz doğrulaması atlanmadan
kapatılmadı.

---

## 2. Faz 1 — Sürüm derlemesi

`pubspec.yaml` elle `1.0.0+4` → **`1.0.0+5`** yükseltilmişti; doğrulandı.

### Bulunan tuzak: `local.properties` BAYAT kalır

`android/local.properties` hâlâ `flutter.versionCode=4` diyordu. `flutter build` onu pubspec'ten
yeniden yazıyor — ama **doğrudan `./gradlew bundleRelease`** çağıran biri eski numarayla derlerdi.

**Kural değişti:** sürüm artık pubspec'ten değil, **artefaktın kendisinden** doğrulanıyor:

```
bundletool dump manifest --bundle=app-release.aab
  → versionCode="5"  versionName="1.0.0"
```

| Doğrulama              | Sonuç                                                             |
| ---------------------- | ----------------------------------------------------------------- |
| AAB versionCode        | **5** (bundletool)                                                |
| AAB versionName        | **1.0.0**                                                         |
| AAB imzası             | `jar verified.` · `CN=Emre Dogan, O=Ehliyet Akademi - Sınav 2026` |
| Hata ayıklama anahtarı | **YOK**                                                           |
| Cihazda kurulu sürüm   | `versionCode=5` (`dumpsys package`)                               |

---

## 3. Faz 2 — Sayfa geçişindeki saydam çakışma

### 3.1 Kök neden — cila değil, **bileşim (compositing)** hatası

İskele şeffaftır (`scaffoldBackgroundColor: Colors.transparent`); canlı zemin uygulamanın
kökünde tek örnek olarak yaşar. `CupertinoPageTransitionsBuilder` gelen sayfayı gidenin üstüne
**hiç soldurmadan** kaydırır. İki saydam katman aynı anda çizilince ikisi de görünür.

### 3.2 Kanıt — tek kare yetmez, VİDEO gerekir

320–400 ms'lik bir geçiş `screencap` ile yakalanamaz. Yöntem:
`adb shell screenrecord` → `adb pull` → `ffmpeg -vf fps=30` → kareleri `tile` ile birleştir.

**Düzeltme öncesi:** Öğren → Dersler geçişinde Öğren sayfasının **baykuş görseli ve liste metni,
gelen Dersler sayfasının içinden okunuyordu** (28–47. kareler).

**Düzeltme sonrası:** aynı karelerde giden sayfa solup bitiyor, gelen sonra beliriyor; **hiçbir
karede iki sayfa birden okunmuyor.**

### 3.3 Çözüm — Material shared-axis, **sıralı** solma

`SharedAxisPageTransitionsBuilder` yazıldı:

```
t:      0 ────────── 0,35 ────────────── 1
giden:  1 ─────────► 0        (0 kalır)
gelen:       (0 kalır)        0 ────────► 1
```

Çarpımları her `t` için sıfır → **iki sayfa hiçbir anda birden çizilmez.** 1000 örnekle
`page_transition_test.dart` içinde kapı altında.

**Gecikme ya da opaklık numarası kullanılmadı** — geçişin kendisi değişti.

### 3.4 Flutter'ın hazır çözümü neden kullanılmadı

`FadeForwardsPageTransitionsBuilder` (Flutter 3.41, Android 16 geçişi) solma aralıkları
**örtüşüyor**: giden `Interval(0, 0.25)`, gelen `Interval(0, 0.75)`. `t≈0,12`'de giden ≈0,5 ve
gelen ≈0,17 → ikisi birden çizilir. Opak sayfalarda sorunsuz, **bizde aynı kusuru üretir**.
Ayrıca geçiş boyunca `ColorScheme.surface` ile opak bir kutu çizip canlı zemini söndürüyor.

### 3.5 iOS bilinçli olarak Cupertino'da bırakıldı

O geçiş aynı zamanda **kenardan kaydırıp geri gitme jestini** kurar; kaldırmak iOS'ta bir platform
davranışını sessizce yok ederdi. Bu makinede iOS derlenemiyor (disiplin kuralı 7) ve
**doğrulanamayan platformda davranış değiştirilmez.** Aynı çakışma iOS'ta da vardır — kayıt
altında, iOS gerçekten derlenebildiğinde ele alınmalı.

---

## 4. Faz 3 — Dönüşüm sistemi ve Kampanya Motoru

### 4.1 Kampanya artık bir VERİ nesnesi

`Campaign`: `id · title · explanation · kind · discountPercent · oldPriceLabel · newPriceLabel ·
startsAt · endsAt · enabled`. Kaynak: `--dart-define=CAMPAIGNS_JSON=[...]`.

**Varsayılan: HİÇ KAMPANYA YOK.** Bu, sahte aciliyeti **yapısal olarak** imkânsız kılar:

- sayaç yalnız `enabled && pencere içinde && endsAt != null` ise çizilir,
- üstü çizili fiyat yalnız yürürlükteki kampanyada çizilir,
- `enabled` açıkça `true` yazılmadıkça kampanya kapalıdır,
- bozuk JSON = boş katalog (**çökme yok**) — bir pazarlama yapılandırma hatası uygulamayı
  açılamaz hâle getirmemeli,
- `discountPercent` 0–100'e kırpılır.

Sunucu kaynağı eklendiğinde yalnız `CampaignSource` uygulaması değişir; ekranlar ve karar mantığı
aynı kalır.

### 4.2 Yakalanan kusur — adı bir şeyi anlatan kod, o şeyi kontrol etmiyordu

`PremiumTrigger.firstExam` başlığı **"İlk deneme sınavını tamamladın! 🎉"** diyordu. Ama
tetikleyici **ilk sınav olup olmadığına hiç bakmıyordu** — yalnız 24 saatlik soğumaya bakıyordu.
Beşinci sınavdan sonra da "ilk sınavını tamamladın" çıkabiliyordu.

Artık `shouldRunFirstExamConversion` gerçekten `examsFinished == 1` soruyor — ayrıca premium
olmadığını ve daha önce gösterilmediğini de.

### 4.3 Tebrik ile satış AYNI pencerede olmaz

Akış ikiye ayrıldı:

1. **Tebrik** — koç sonucu okur. **Satış yok.**
2. **Teklif** — yalnız kullanıcı "Koçun önerisini gör" derse açılır. Kapatırsa akış biter.

Koçun okuması üç banda ayrılır ve **sonuçtan bağımsız övgü içermez**. Cihazda ölçülen gerçek
örnek (50 soruda 4 doğru):

> **Başlangıç noktan belli** — "50 soruda 4 doğru. Geçme sınırı 35. Bu sonuç bir başarısızlık
> değil, ölçüm: nereden başlayacağını artık biliyorsun."

50 soruda 4 doğru yapmış birine "harikasın" demek, ürünün kendi ölçümüne inanmadığını gösterir.

Teklifin giriş cümlesi de kullanıcının **kendi sayısını** taşır:

> "İlerlemeni inceledim: 50 soruda 4 doğru, geçmek için 31 soru daha gerekiyor. Bu farkı en hızlı
> kapatan şey sınırsız deneme ve konu tekrarı — Premium'un sana gerçekten yardımcı olacağını
> düşünüyorum."

### 4.4 Teklif penceresinin içeriği

- Koçun gerekçesi (gerçek veriden),
- **Ücretsiz ↔ Premium karşılaştırma tablosu** — ücretsiz sütunu **dürüst** ("Günde 1",
  "Temel dersler"); "ücretsizde hiçbir şey yok" demek satışa yarar ama yalandır ve ilk
  kullanımda çürür,
- **Kampanya kartı** — yalnız yürürlükte kampanya varsa: başlık, indirim rozeti, açıklama,
  eski→yeni fiyat, sayaç.

### 4.5 Cihazda doğrulandı

Kampanyalı bir yapı (`--dart-define-from-file`) ile tam zincir koşturuldu:
tebrik → teklif → ödeme ekranı. Kampanya kartı, **%40** rozeti, üstü çizili **₺799,99 → ₺479,99**
ve **canlı sayaç** (47:48:14 → 47:46:10 → 47:44:21) çalışıyor. Ödeme ekranı da aynı kampanyayı
devraldı ("SINIRLI SÜRE" 47:44:21).

**Sevk edilen AAB'de `CAMPAIGNS_JSON` yoktur** — varsayılan kampanyasız hâl.

---

## 5. Faz 4 — Ödeme ekranı iyileştirmeleri

### 5.1 Terk sonrası TEK hatırlatma

- Ödeme ekranı satın alma olmadan kapatılırsa damga alınır,
- **24 saat sonra**, **ömür boyu bir kez** hatırlatılır,
- Ton alçak: baskı yok, sayaç yok, indirim iddiası yok; iki eşit seçenek sunulur.

24 saat, mevcut bağlamsal teşvikin soğumasıyla **aynı** → iki sistem aynı gün üst üste binemez.

**İLK terk anı korunur:** ekran beş kez açılıp kapatılırsa bekleme her seferinde baştan
başlamamalı, yoksa hatırlatma sonsuza kadar ötelenir.

**Teknik not:** damga `deactivate()` içinde alınır. `dispose` sırasında sağlayıcı sökülmüş olabilir
ve Riverpod `ref` okumayı yasaklar.

### 5.2 "Premium Aktif" — **zaten uygulanmıştı**

Talep: sahiplik varsa "Satın Al" yerine "Premium Aktif" göster ve satın almayı devre dışı bırak.

Denetimde görüldü ki bu **önceki bir fazda çözülmüş**: `hasPremium` olduğunda ödeme yüzeyi
(fiyat, sayaç, satın alma düğmesi, güven şeridi) **hiç çizilmiyor**; yerine `Semantics(enabled: false)`
taşıyan yeşil bir **"Premium Aktif"** rozeti geliyor.

Yeniden yazılmadı — mevcut davranış testle kapı altına alındı. (Bir talebin zaten karşılandığını
görüp geçmek de bir sonuçtur.)

---

## 6. Faz 5 — Geri kazanım (win-back)

- Sahiplik geçişleri her açılışta gözlenir (`observePremium`): yok→var `everOwned` işaretler,
  var→yok kayıp anını damgalar.
- Kayıptan **1 saat sonra**, **bir kez** teklif edilir. Sıfır değil: açılışta sunucu senkronu
  geçici olarak "sahip değil" diyebilir; bekleme gerçek kaybı gürültüden ayırır.
- Teklif **Kampanya Motoru'ndan** gelir (`kind: winBack`) — hardcoded değil.
- **Kampanya yoksa indirim UYDURULMAZ.** Pencere yalnız dürüst bilgilendirme yapar:
  "İlerlemen, rozetlerin ve çalışma geçmişin duruyor — hiçbiri silinmedi."
- Geri kazanım ile ödeme hatırlatması **aynı anda açılmaz**; geri kazanım önceliklidir
  (erişimini kaybetmiş kullanıcıya "ödeme ekranına bakmıştın" demek olan biteni görmezden
  gelmektir).

### 6.1 Doğrulanamayan kısım — dürüstçe

Faz 4 hatırlatması **24 saat**, Faz 5 teklifi **premium sahibi olup sonra kaybetmeyi** gerektirir.
İkisi de tek oturumda cihazda tetiklenemez. Karar mantığının tamamı saf fonksiyon olarak
yazıldı ve **13 testle** kapı altına alındı; pencerelerin kendisi mevcut pencere kabuğunu
(`PremiumDialogShell`) kullanıyor — o kabuk cihazda bu programda üç kez çizildi.

---

## 7. Faz 6 — Fiyatlandırma mimarisi (yalnız mimari; Play ürünü **oluşturulmadı**)

### 7.1 Bugünkü durum — ölçüldü

| Ne                       | Değer                                                     |
| ------------------------ | --------------------------------------------------------- |
| Ürün modeli              | **Tek ürün**, tek seferlik / ömür boyu (`komple_ehliyet`) |
| Play'in bildirdiği fiyat | **₺479,99** (cihazda ölçüldü)                             |
| Belgelerdeki fiyat       | **399 TL** (`STORE_LISTING.md`, `products.dart`)          |
| Deneme (trial)           | **Yok**                                                   |

> ⚠️ Belge ile mağaza **çelişiyor**. Uygulama artık ekranda yalnız mağazanın fiyatını gösteriyor
> (RC'de düzeltildi), ama hangisinin doğru olduğuna sahibin karar vermesi gerekiyor.

### 7.2 Sektör verisi (2026)

| Ölçüt                                 | Değer                                                |
| ------------------------------------- | ---------------------------------------------------- |
| Eğitim uygulaması ortalama aylık      | $8,13                                                |
| Eğitim uygulaması ortalama yıllık     | $56,09 (medyan $44,99 — kategoriler arası en yüksek) |
| Yıllık ↔ aylık ortalama indirim       | %67                                                  |
| Dönüşüm — yüksek fiyatlı              | medyan **%2,8** (üst çeyrek %6,1)                    |
| Dönüşüm — düşük fiyatlı               | medyan **%1,4**                                      |
| 12 aylık LTV (eğitim)                 | $45,10 (kategoriler arası 3.)                        |
| Denemeli kullanıcı LTV farkı          | **+%50,4** doğrudan satın alana göre                 |
| En yüksek dönüşen ödeme ekranı        | onboarding + deneme: **%1,78**                       |
| Sert (hard) paywall LTV avantajı      | abone başına **+%21**                                |
| Fiyat denemesi LTV'yi iyileştiriyor   | testlerin **%46**'sında                              |
| Fiyat denemesi dönüşümü iyileştiriyor | testlerin yalnız **%28**'inde                        |
| Türkiye fiyat çarpanı                 | ABD'nin **~0,7×**'i                                  |

**İki veri doğrudan strateji belirliyor:**

1. **Yüksek fiyatlı uygulamalar düşük fiyatlıların 2 KATI dönüşüyor** (%2,8 ↔ %1,4). Fiyatı
   düşürerek dönüşüm aramak, bu kategoride veriye aykırı.
2. **Fiyat denemesini aynı gün dönüşümüne bakarak yargılamak, vakaların çoğunda yanlış sonuç
   verir** (LTV %46, dönüşüm %28). Fiyat kararı LTV ile ölçülmeli.

### 7.3 Bu ürünün kategoriden AYRILDIĞI nokta

Genel eğitim uygulamaları **süresiz** kullanılır (dil öğrenme yıllarca sürer). Ehliyet sınavı
uygulamasının kullanım penceresi **sınırlıdır**: kullanıcı ~4–8 hafta hazırlanır, sınava girer,
**geçer ve gider**.

Sonuçları:

- **Churn bir başarısızlık değil, ürünün doğasıdır.** Abonelik churn'ünü "düzeltmeye" çalışmak
  bu üründe yanlış hedeftir.
- **LTV sınav tarihiyle tavanlıdır.** Yıllık abonelik satmak, kullanıcının ihtiyaç duymadığı
  10 ayı satmaktır — Play iade taleplerini ve kötü yorumu davet eder.
- **Tek seferlik ürün, yapılacak işle hizalıdır.** Mevcut model tesadüf değil, doğru seçim.

### 7.4 Seçeneklerin değerlendirmesi

| Model                        |       Uygunluk       | Gerekçe                                                                                                       |
| ---------------------------- | :------------------: | ------------------------------------------------------------------------------------------------------------- |
| **Tek seferlik / ömür boyu** |   ✅ **Çekirdek**    | Kullanım penceresiyle hizalı, churn yönetimi gerektirmez, iade riski düşük. Bugünkü model.                    |
| **Aylık abonelik**           | 🟡 **Giriş katmanı** | Türkiye fiyat hassasiyeti yüksek; ₺479 peşin ödeyemeyecek segmenti yakalar. **Ön koşulu var (§7.6).**         |
| **Haftalık**                 |          ❌          | Eğitimde yırtıcı okunur, Play incelemesinde risk, kötü yorum üretir. Kısa vadeli gelir için itibar riski.     |
| **Yıllık**                   |          ❌          | Kullanıcının ihtiyacı 4–8 hafta. 12 ay satmak, kullanılmayacak süreyi satmaktır.                              |
| **Aile paketi**              |          ❌          | Ehliyet **bireysel** bir belgedir; ilerleme, zayıf konu ve rozet kişiye özeldir. Paylaşımın anlamı yok.       |
| **Paket (bundle)**           |    🟡 **İleride**    | Sürücü kursuyla ortaklık (kurs + uygulama) gerçek bir fırsat, ama satış kanalı işi — ürün mimarisi işi değil. |

### 7.5 Öneri — "iki basamaklı merdiven", çapa ömür boyu

```
Giriş     →  Aylık abonelik      ₺199/ay
Çapa      →  Komple Paket        ₺479,99  (tek seferlik, ömür boyu)  ← "en çok tercih edilen"
```

**Fiyat aritmetiği bilinçli:** 2 ay abonelik = ₺398 (< ₺479), 3 ay = ₺597 (> ₺479). Yani

- 2,5 aydan uzun hazırlanan **herkes için ömür boyu rasyonel seçimdir** → çapa korunur,
- daha kısa hazırlanan ya da peşin ödeyemeyen kullanıcı **kaybedilmez**,
- abonelik ömür boyu ürünü **yamyamlaştırmaz** (fiyatlandırma bunu garanti eder).

**Neden fiyat düşürülmüyor:** veri, yüksek fiyatlının 2 kat daha iyi dönüştüğünü söylüyor (§7.2).
₺479,99 Türkiye çarpanıyla (~0,7×) ≈ $16 — kategori yıllık medyanı ($44,99) ile
karşılaştırıldığında **zaten agresif biçimde düşük**. İndirim, kampanya motoruyla **dönemsel**
yapılmalı; liste fiyatı düşürülmemeli.

**Deneme (trial):** veri en güçlü tek kaldıraç olarak bunu gösteriyor (+%50,4 LTV; en yüksek
dönüşen ödeme ekranı denemeli olan). Aylık katman geldiğinde **3 günlük deneme** ile başlanmalı.
Ömür boyu üründe deneme Play'de mümkün değildir — bu, aylık katmanın ikinci gerekçesidir.

### 7.6 ⛔ Ön koşul — abonelik BUGÜN eklenemez

Abonelik, yenileme ve iptalin **sunucu tarafında görülmesini** zorunlu kılar. Bugün:

- **E1 açık:** `GOOGLE_PLAY_SA_JSON` yok → sunucu tarafı Play makbuz doğrulaması iskele hâlinde,
- **RTDN bağlı değil:** sunucu bir iptali/iadeyi kendiliğinden **öğrenmez**.

Bu ikisi kapanmadan abonelik satmak, "kullanıcı iptal etti ama erişimi sürüyor" ve "yenilendi ama
sunucu bilmiyor" hatalarını **kaçınılmaz** kılar. Tek seferlik üründe bu risk yoktur (cihaz
defteri + geri yükleme yeterlidir) — bugünkü modelin ayakta durmasının sebebi de budur.

**Sıra: E1 → RTDN → aylık katman + deneme.** Öncesinde değil.

### 7.7 Mimari — kodda ne değişir

| Konu             | Bugün                                                                                                            | Abonelik geldiğinde                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Sahiplik         | `isPremium(owned)` — ürün kimliği listesi                                                                        | **süre** taşımalı; `PremiumLifecycle` bunu zaten modelliyor (`active/cancelled/gracePeriod/accountHold`) |
| Süreli erişim    | Davet ödülünde **zaten var** — `GET /api/purchases` içinde türetiliyor ve süresi dolunca kendiliğinden kapanıyor | aynı mekanizma abonelik için kullanılır                                                                  |
| Kampanya/indirim | **Kampanya Motoru** (Faz 3)                                                                                      | yeni SKU gerekmez — indirim kampanyadan gelir                                                            |
| Ödeme ekranı     | tek fiyat bloğu                                                                                                  | iki katmanlı seçim; `PaywallPriceBlock` çoğullanır                                                       |

**Kayda değer:** süreli erişim altyapısı **zaten mevcut** (davet ödülü). Abonelik, sıfırdan bir
mekanizma değil, var olanın ikinci kullanıcısı olacak.

### 7.8 Bu fazda YAPILMAYAN

Play Console'da **hiçbir ürün oluşturulmadı** — istenen buydu. Fiyatlar da koda yazılmadı: uygulama
fiyatı **yalnız mağazadan** okur (RC'de bu kural kapı altına alındı).

---

## 8. Faz 7–9 — İçerik genişleme

Ayrıntı: [`CONTENT_EXPANSION_MASTERPLAN.md`](CONTENT_EXPANSION_MASTERPLAN.md).

En kritik bulgu burada da tekrarlanmalı: **`Question` şemasında görsel alanı yok.** 1.562 sorunun
tamamı metin. Uygulamada 81 işaret vektörü + 60 ikaz ışığı + 101 mekanik görseli **var** ama
yalnız Öğren bölümünde kullanılıyor. Görselli soru üretmek bir içerik işi değil, önce bir
**şema** işidir.

Bu fazda **kod da yazıldı**: `AssetCatalog` (varlık çözümleyicisi). Önceden klasöre bırakılan bir
görsel pakete giriyor ama elle tabloya satır eklenmedikçe kullanılmıyordu; artık
`assets/<kategori>/<id>.<uzantı>` sözleşmesi kendiliğinden çözülüyor.

---

## 9. Bilinen sınırlar

1. **Tek cihaz.** Program boyunca yalnız Redmi Note 8 / Android 11 bağlıydı. Android 13 ve
   360 dp genişlik (Huawei) bu programda **doğrulanmadı**.
2. **Gerçek satın alma yapılmadı.** Ödeme ekranının Play'e bağlandığı ve gerçek fiyatı çektiği
   doğrulandı; ücretlendirme tetiklenmedi.
3. **Faz 4/5 pencereleri cihazda tetiklenmedi** (24 saat / sahiplik kaybı gerekir) — karar
   mantığı testle kapı altında (§6.1).
4. **iOS geçişi düzeltilmedi** — bilinçli (§3.5).
5. **Belge–mağaza fiyat çelişkisi** sürüyor (399 TL ↔ ₺479,99) — ürün sahibinin kararı.

---

## 10. Öneri

Kapalı beta **devam edebilir**; bu programın hiçbir çıktısı yayın engeli üretmedi.

Sıradaki iş, önem sırasıyla:

1. **E1 (`GOOGLE_PLAY_SA_JSON`) + RTDN** — hem çapraz cihaz senkronunu açar hem abonelik
   katmanının ön koşuludur (§7.6).
2. **Görsel soru şeması** — hazır varlıklarla ~685 soru üretilebilir hâle gelir
   (masterplan §7.3).
3. **Fiyat kararı** — belge ile mağaza çelişkisi kapatılmalı.
