# Ehliyet Akademi — Final Release Report

**Sürüm adayı:** `1.0.0 (4)` · **Tarih:** 31 Temmuz 2026
**Taban commit:** `9726123` → **sürüm commit’i:** `ce617e2`
**Kapsam:** son cihaz doğrulaması + üretim AAB'si. Yeni özellik eklenmedi; yalnız doğrulama
sırasında bulunan kusurlar düzeltildi.

---

## 1. Karar

# 🟢 READY FOR CLOSED BETA

Kodda kalan yayın engeli **yok**. Kapalı betayı durduracak bir kusur bulunamadı. Genel yayın
(production) için üç engel duruyor ve **üçü de sahibin Play Console / sunucu tarafındaki işi**
(§8) — bunlar kapalı betayı engellemez.

---

## 2. Derleme künyesi

| Alan                   | Değer                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| Uygulama kimliği       | `com.ehliyetegitim.ehliyet_akademi`                                      |
| Sürüm adı / kodu       | **1.0.0 (4)** — cihazda Profil ekranında doğrulandı                      |
| Flutter / Dart         | 3.41.9 (stable) · Dart 3.11.5                                            |
| minSdk / targetSdk     | 24 / 36                                                                  |
| **APK boyutu**         | **81.359.455 bayt — 81,4 MB** (77,6 MiB)                                 |
| **AAB boyutu**         | **65.090.332 bayt — 65,1 MB** (62,1 MiB)                                 |
| APK imzası             | `Verifies` · v2 şeması · `CN=Emre Dogan, O=Ehliyet Akademi - Sınav 2026` |
| AAB imzası             | `jar verified.` · aynı sertifika                                         |
| Sertifika SHA-256      | `46b2dfce…0607d3` (cihazın App Links kaydıyla aynı)                      |
| Sertifika SHA-1        | `7e1fead9…767357`                                                        |
| Hata ayıklama anahtarı | **YOK** — DN'de `CN=Android Debug` geçmiyor                              |

### 2.1 Üretim yapılandırması — derleme komutu

```bash
flutter build appbundle --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-istemci-kimliği>.apps.googleusercontent.com
```

> **Bu bayrak zorunludur.** `GOOGLE_SERVER_CLIENT_ID` verilmezse Google giriş düğmesi uygulamada
> **hiç görünmez** (bilinçli tasarım, `google_auth_service.dart`). Doğrulamanın ilk turunda bayrak
> verilmeden derlenmişti ve düğme yoktu; bayrakla yeniden derlendi ve düğme cihazda çalıştı (§5.4).
> Her iki artefaktın da kimliği taşıdığı, derlenmiş `libapp.so` içinde `apps.googleusercontent.com`
> aranarak **doğrulandı**.

**RevenueCat bilinçli olarak KAPALI bırakıldı.** `REVENUECAT_PUBLIC_KEY` verilmedi; uygulama
denetimden geçmiş `in_app_purchase` yolunda kalıyor (tek ürün: `komple_ehliyet`). RevenueCat yolu
sunucu köprüsü olarak **webhook** ister ve o kurulmadı — kapalı beta öncesinde kanıtlanmış yolu
kanıtlanmamışla değiştirmek gereksiz risk olurdu.

---

## 3. Doğrulamada kullanılan cihazlar

| Cihaz                                | Android     | Ekran                  | Rol                                    |
| ------------------------------------ | ----------- | ---------------------- | -------------------------------------- |
| **Redmi Note 11R** (22095RA98C)      | 13 (SDK 33) | 1080×2408 · 393×876 dp | **Ana doğrulama** — §5'in büyük bölümü |
| **Redmi Note 8 (2021)** (M1908C3JGG) | 11 (SDK 30) | 1080×2340 · 393×851 dp | Devamı + entegrasyon paketi (8/8)      |
| Huawei ANE-LX1                       | 9 (SDK 28)  | 1080×2280 · 360×760 dp | **Kullanılamadı** — aşağıdaki not      |

**Cihaz değişikliği dürüstçe:** doğrulamanın ortasında Redmi Note 11R USB bağlantısı düştü
(`- waiting for device -`) ve yerine farklı bir Redmi (Note 8) bağlandı. Talimattaki sıraya göre
önce Huawei denendi: cihaz kilitliydi, **"Kazara dokunma engelleme"** modundaydı (yakınlık sensörü
kapalı) ve pili %0'dı — dokunma girdisi kabul etmiyordu, sürülemedi. Bu yüzden sıradaki kural
uygulandı: **en son erişilebilir Redmi cihaza geçildi.** Doğrulamanın hiçbir adımı atlanmadı;
Redmi Note 11R'de bitirilemeyen maddeler Redmi Note 8'de tamamlandı ve bu, Android 13'e ek olarak
**Android 11 kapsaması** kazandırdı.

---

## 4. Kapılar

| Kapı                               | Sonuç                                            |
| ---------------------------------- | ------------------------------------------------ |
| `flutter analyze`                  | **0 sorun**                                      |
| Mobil birim/widget testi           | **889 ✓** (sprint başı 888 — +1 gerileme kapısı) |
| Web testi                          | **633 ✓** (83 dosya)                             |
| Cihazda entegrasyon testi          | **8/8 ✓** (Redmi Note 8)                         |
| `pnpm typecheck` / `lint`          | **✓ / ✓** (1 uyarı, bu sprint öncesinden)        |
| APK / AAB imza doğrulaması         | **✓ / ✓**                                        |
| Canlı zemin kare bütçesi (cihazda) | p10 **6,13 ms** < 12 ms bütçe                    |

> Web paketinin ilk koşusunda 10 test kırmızı geldi; hepsi paylaşılan Neon veritabanına giden
> **entegrasyon** testleriydi ve aynı komut tekrar koşturulduğunda **633/633 yeşil** oldu. Kırılma
> bu sprintteki değişikliklerden değil, eşzamanlı koşuda veritabanı zaman aşımından kaynaklanıyor.
> Bu, bilinen bir kırılganlıktır (§7.4).

---

## 5. Cihazda tek tek doğrulanan özellikler

Her satır telefonda **elle** açıldı, ekran görüntüsü alındı ve `logcat` hata akışı ayrıca tarandı.
"Varsayıldı" hiçbir madde yok.

| #   | Özellik                    | Sonuç | Cihazda görülen                                                                   |
| --- | -------------------------- | :---: | --------------------------------------------------------------------------------- |
| 1   | Uygulama açılışı           |  ✅   | Soğuk açılış temiz; `logcat`'te istisna yok                                       |
| 2   | Splash                     |  ✅   | Yerel tema → Flutter'a boşluksuz geçiş                                            |
| 3   | Onboarding                 |  ✅   | 4 adımın hepsi; seçimler Karşılama ekranında birebir özetlendi                    |
| 4   | Coach Marks                |  ✅   | **9/9 adım**; her baloncuk ekran içinde kaldı (alt sekmelerde yukarı konumlandı)  |
| 5   | Kayıt (Registration)       |  ✅   | Form + davet kodu alanı; boş gönderimde 3 alan hatası ayrı ayrı ve doğru          |
| 6   | Giriş (Login)              |  ✅   | E-posta/şifre ekranı; tabletde çöken ekran telefonda ve 360 dp'de sağlam          |
| 7   | **Google Login**           |  ✅   | Yerel hesap seçici → oturum açıldı; **misafir ilerlemesi korundu**                |
| 8   | Misafir modu               |  ✅   | "Misafir" kimliği; çıkış satırı dürüstçe **yok**                                  |
| 9   | Çıkış (Logout)             |  ✅   | Cihaz entegrasyon testi: Profil → Çıkış yap → Giriş ekranı                        |
| 10  | Hesap silme                |  ✅*  | Pencere cihazda kaydırılabilir, yıkıcı düğme ekran içinde, İptal çalışıyor        |
| 11  | Davet akışı                |  ✅   | Sunucudan gerçek kod `UK7JYWC8`; sayaçlar ve ödül merdiveni                       |
| 12  | **Davet derin bağlantısı** |  ✅   | `ehliyetakademi://app/davet/<KOD>` soğuk açılışta kodu yakaladı                   |
| 13  | Davet ödülleri             |  ✅   | "5 sayılan davette 1 ay premium (0/5)" ilerleme çubuğu                            |
| 14  | Premium ekranı             |  ✅   | Referans tasarım; başlık, avantajlar, güven şeridi                                |
| 15  | Satın alma arayüzü         |  ✅   | **Play'den canlı fiyat ₺479,99**; düğme etkin (mağaza gerçekten bağlı)            |
| 16  | Geri yükleme               |  ✅   | Dönen gösterge → normale döndü; **sonsuz dönme yok**                              |
| 17  | İlerleme                   |  ✅   | Tek soru sonrası hazırlık %0 → %13, doğruluk %100, Lv 1                           |
| 18  | Rozetler                   |  ✅   | Profil kartında rozet/ilerleme/seri sayaçları                                     |
| 19  | **Bildirimler**            |  ✅   | Ana anahtar + 8 alt tercih; test bildirimi **işletim sisteminde doğrulandı**      |
| 20  | AI Koç                     |  ✅   | Kişiselleştirilmiş içgörüler + 7 günlük plan + soru kutusu                        |
| 21  | Akıllı Çalışma             |  ✅   | Gerçek soru, konu/zorluk etiketi, doğru/yanlış geri bildirimi + açıklama          |
| 22  | Topluluk                   |  ✅   | Varsayılan **KAPALI**; katılım kapısı ve gizlilik vaadi açıkça yazılı             |
| 23  | **Çevrimdışı mod**         |  ✅   | Uçak modunda soğuk açılış + **önbellekten sorular**; boş önbellekte dürüst hata   |
| 24  | Ayarlar                    |  ✅   | 8 satırın hepsi açıldı; sürüm damgası **v1.0.0 (4)**                              |
| 25  | Tema                       |  ✅   | Koyu ↔ açık; açık temada kontrast ve okunabilirlik sağlam                         |
| 26  | Hata durumları             |  ✅   | Form doğrulama · "Sorular yüklenemedi" · "Mağaza kullanılamıyor" · geçersiz davet |
| 27  | Yüklenme durumları         |  ✅   | Geri yükleme göstergesi; ekranlar boş/iskelet durumdan içeriğe geçiyor            |
| 28  | Öğren + alt ekranlar       |  ✅   | 6 kategori (19/121/70/60/39/9) ve altı alt ekranın hepsi gerçek içerikle          |

`*` **Hesap silme bilinçli olarak SONUNA KADAR GÖTÜRÜLMEDİ.** Pencerenin açıldığı, kaydırılabildiği,
yıkıcı düğmenin ekran içinde kaldığı ve İptal'in çalıştığı doğrulandı; onay **basılmadı**, çünkü
bu gerçek bir hesabı geri dönüşsüz siler. Silmenin kendisi sunucu entegrasyon testinde ve
`delete_account_test.dart` içinde koşuyor.

### 5.1 Kapsam dışı bırakılan iki şey — dürüstçe

- **Gerçek para ile satın alma yapılmadı.** Ödeme ekranının Play'e bağlandığı, gerçek yerelleştirilmiş
  fiyatı çektiği ve düğmenin etkin olduğu doğrulandı; ücretlendirme tetiklenmedi.
- **İkinci bir Google hesabına girilmedi.** Redmi Note 8'de cihazın sahibi olmayan üçüncü bir
  kişinin Google hesabı vardı; o hesapla oturum açmak üretim veritabanında o kişi adına hesap
  yaratırdı. Google girişi zaten Redmi Note 11R'de sahibin kendi hesabıyla uçtan uca doğrulandı.

---

## 6. Bu doğrulamada BULUNAN ve DÜZELTİLEN kusurlar

Dördü de yalnız gerçek cihazda görülebilecek türdendi; hiçbiri mevcut 888 teste takılmıyordu.

### 6.1 🔴 AI Koç, **%100 ustalıktaki** dersi "en zayıf dersin" diye gösteriyordu

**Cihazda görülen.** Tek soru doğru cevaplandıktan sonra koç kartı şunu yazdı:

> 📉 **En zayıf dersin: İlk Yardım Bilgisi** — %100 ustalık. Bu derse biraz daha çalışalım mı?

Gösterilen sayı iddianın kendisini yalanlıyor. Kullanıcı için bu, ürünün "düşünmediğinin" kanıtı.

**Kök neden.** `computeReadiness` ışığı **güven katsayısıyla düşürülmüş** değerden hesaplıyor
(`mastery × min(1, answered/8)` → 1 cevapta %12,5 → kırmızı), ama `PerSubjectReadiness.mastery`
alanına **ham** değeri (%100) koyuyor. Dürtme kapısı ışığa bakıyor, gövde ham ustalığı yazıyor,
sıralama da ham ustalıkla yapılıyordu — **üç yerde iki farklı ölçüt**.

**Düzeltme.** `apps/mobile/lib/domain/coach/nudge.dart` — kapı da ham ustalığa bakıyor
(`lightFor(weak.first.mastery) != yesil`). Veri azlığından kırmızı yanan ders "zayıf" sayılmaz;
kullanıcıyı zaten düşük-hazırlık dürtmesi yönlendiriyor. **Cihazda doğrulandı:** yanlış kart kayboldu,
"Hazırlık %13" kartı yerinde kaldı. Gerileme kapısı: `test/nudge_test.dart`.

### 6.2 🟠 Ana sayfada istatistikler birbirine yapışıyordu — "%100Lv 1"

**Cihazda görülen.** Doğruluk %100'e çıkınca hazırlık kartındaki üç istatistik bitişti ve
`%100 doğruluk` ile `Lv 1 seviye` **"%100Lv 1"** olarak okundu.

**Kök neden.** `StatTile` içeriğini sola yaslar. Üç `Expanded` **aralıksız** dizilmişti; geniş bir
değer kendi payını doldurunca komşusuna değiyordu. Uygulamadaki diğer bütün `StatTile` satırları
(davet ekranı, topluluk profili) zaten `AppSpacing.s3` ile ayrılmış — **yalnız burası ayrık kalmıştı.**

**Düzeltme.** `apps/mobile/lib/features/home/home_screen.dart` — araya `s3` boşluk. `FittedBox`
zaten daraldığında küçültüyor, taşma riski yok. **Cihazda doğrulandı.**

### 6.3 🟠 Mağaza kapalıyken ödeme ekranı **uydurma fiyat** gösteriyordu

**Cihazda görülen.** Play'in bildirdiği gerçek fiyat **₺479,99**. Ama mağaza kapalıyken ekran
katalog sabitine düşüyordu: **`₺399`** — gerçeğin %17 altında bir rakam.

**Neden önemli.** Düğme o durumda devre dışı ve "Mağaza kullanılamıyor" uyarısı görünüyor; yani
kimse yanlış fiyattan satın alamıyor. Ama yanlış bir rakam görmek yanlış beklenti bırakır ve bu
ekranın tamamı (bkz. `PaywallOffer` sınıf notu: üstü çizili fiyat ve geri sayım varsayılan olarak
kapalı) **yanıltıcı fiyatlandırmadan kaçınmak** üzere kurulmuş.

**Düzeltme.** `apps/mobile/lib/features/premium/paywall_screen.dart` — fiyatı **yalnız mağaza**
söyler; yoksa `—` gösterilir. Katalogdaki `priceTRY` sunucu/ürün eşlemesi için duruyor, ekranda
fiyat olarak kullanılmıyor. Gerileme kapısı: `test/billing_test.dart`.

### 6.4 🟡 Web davet sayfası, **alfabe** hatasını **uzunluk** hatası diye açıklıyordu

**Cihazda görülen.** `https://www.ehliyetegitim.com/davet/ABC12345` açıldığında sayfa şöyle dedi:

> Bu davet kodu okunamadı. … Davet kodları **8 karakterdir**.

Oysa gönderilen kod **tam 8 karakter**. Gerçek sorun `1` karakterinin alfabede olmaması
(`ABCDEFGHJKMNPQRSTUVWXYZ23456789` — karıştırılabilir `0/O` ve `1/I/L` çıkarılmış). Kullanıcı
"kodum zaten 8 karakter" deyip çıkmaza giriyordu. **Mobil tarafta aynı çelişki bir kez düzeltilmişti;
web tarafında duruyordu.**

**Düzeltme.** `apps/web/app/(marketing)/davet/[code]/page.tsx` — sayfa artık deponun kendi
`describeReferralCodeProblem` yardımcısını kullanıyor; hangi karakterin sorunlu olduğunu adıyla
söylüyor, uzunluk gerçekten yanlışsa uzunluğu söylüyor.

> Bu düzeltme **web** uygulamasında; AAB'ye girmez, Vercel dağıtımıyla yayına çıkar.

---

## 7. Kalan bilinen sınırlar — kapalı betayı ENGELLEMEZ

### 7.1 App Links doğrulaması bu cihazda geçmedi (beklenen)

`pm get-app-links` her iki alan için de `1024` (doğrulanmadı) döndü ve `https://…/davet/<KOD>`
bağlantısı **tarayıcıda** açıldı. Bu, yandan yüklenmiş (sideload) bir yapı için beklenen sonuçtur:
doğrulama, imza parmak izinin sunucudaki `assetlinks.json` dosyasında bulunmasına bağlıdır ve
Play App Signing devreye girdiğinde parmak izi **değişir**. Akış kırılmıyor: web sayfası kullanıcıyı
uygulamaya yönlendiriyor, özel şema (`ehliyetakademi://app/davet/<KOD>`) ise **her koşulda çalıştı**
(§5, madde 12). Play'e yükledikten sonra Play Console'un verdiği SHA-256 ile `assetlinks.json`
tazelenmeli.

### 7.2 Belgelerdeki fiyat ile mağazadaki fiyat farklı

`STORE_LISTING.md` ve `products.dart` **399 TL** diyor; Play'in bildirdiği canlı fiyat **₺479,99**.
Uygulama artık ekranda yalnız mağazanın fiyatını gösterdiği için kullanıcı doğru rakamı görüyor
(§6.3), ama **belgeler ile mağaza uyumsuz**. Sahibin hangisinin doğru olduğuna karar verip diğerini
güncellemesi gerekiyor.

### 7.3 `.env` içinde biçimsel bir aksaklık

`.env:24` satırı `GOOGLE_SERVER_CLIENT_ID ="…"` biçiminde — `=` işaretinden **önce boşluk** var.
`dotenv` bunu okuyabiliyor (Next.js etkilenmez), ama `source .env` gibi kabuk yollarıyla okuyan her
şey bu satırı **sessizce atlar**. Derleme betiklerinde bu tuzağa düşmemek için boşluk kaldırılmalı.

### 7.4 Web entegrasyon testleri kırılgan

10 test ilk koşuda zaman aşımına düştü, tekrar koşuda 633/633 yeşil (§4). Paylaşılan Neon
veritabanına eşzamanlı giden testlerin bilinen kırılganlığı; ürün kodunda karşılığı yok.

### 7.5 `jarsigner` bilgilendirme uyarısı

AAB doğrulaması `jar verified.` veriyor; yanında tek bir bilgilendirme satırı var
(`warning-triangle.webp … signed in JarFile but is not signed in JarInputStream`). Bu, `jarsigner`'ın
AAB'lerde bilinen akış/manifest görünüm farkıdır; imza geçerli ve Play kabulünü engellemez.

---

## 8. Genel yayın engelleri — üçü de sahibin işi (kapalı betayı engellemez)

Önceki sprintten devralınan üç engel; **kodda karşılığı yok**, bu doğrulamada da kodda yeni engel
bulunmadı.

| #   | Engel                                                    | Durum bu doğrulamada                                                      |
| --- | -------------------------------------------------------- | ------------------------------------------------------------------------- |
| E1  | Sunucuda Play makbuz doğrulaması (`GOOGLE_PLAY_SA_JSON`) | Hâlâ eksik → satın alma **ikinci cihaza** senkron olmaz (kod fail-closed) |
| E2  | Play "Veri güvenliği" formu                              | Doldurulmalı; içerik `PLAY_DATA_SAFETY.md` içinde hazır                   |
| E3  | Play Console ürünü `komple_ehliyet`                      | **ÇÖZÜLMÜŞ görünüyor** — cihaz Play'den canlı fiyat çekti (₺479,99)       |

> E3 bu doğrulamada **fiilen kapandı**: uygulama Play Billing'e bağlanıp ürünün yerelleştirilmiş
> fiyatını aldı; ürün tanımsız olsaydı fiyat gelmez ve düğme devre dışı kalırdı.

---

## 9. Teslim edilenler

| Artefakt        | Yol                                                            | Boyut   |
| --------------- | -------------------------------------------------------------- | ------- |
| **Release APK** | `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`    | 81,4 MB |
| **Release AAB** | `apps/mobile/build/app/outputs/bundle/release/app-release.aab` | 65,1 MB |

İkisi de üretim yapılandırmasıyla (`--dart-define=GOOGLE_SERVER_CLIENT_ID=…`) derlendi, imzası
doğrulandı ve APK doğrulamanın son turunda cihaza kurulup çalıştırıldı.

---

## 10. Öneri

Kapalı betaya **çıkılabilir.** Beta sırasında öncelikle izlenecekler:

1. **Google girişi** — bu, üretim yapılandırmasının en kırılgan parçası; bayrak unutulursa düğme
   sessizce kaybolur. Beta yapısında düğmenin göründüğü ilk gün doğrulanmalı.
2. **Satın alma** — gerçek parayla ilk satın almayı sahibin kendisi yapıp cihaz defteri + sunucu
   senkronunu izlemesi gerekiyor (E1 kapanana kadar ikinci cihazda açılmayacak).
3. **App Links** — Play'in verdiği imza parmak iziyle `assetlinks.json` tazelenmeli (§7.1).

---

# 🟢 READY FOR CLOSED BETA
