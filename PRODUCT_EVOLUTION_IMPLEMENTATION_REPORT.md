# Ürün Evrim Programı v1.1 — Uygulama Raporu

**Tarih:** 1 Ağustos 2026 · **Dal:** `feature/product-evolution-v11` · **PR:** #15
**Yol haritası:** `PRODUCT_EVOLUTION_ROADMAP.md`

---

## 0. Özet

| Faz                         | Durum                                                           |
| --------------------------- | --------------------------------------------------------------- |
| 0 · Denetim                 | ✅ tamam — 14 tutarsızlık, en ağırı ölçüldü                     |
| 1 · Soru kalitesi           | 🟡 **kısmi** — %91,1 → **%58,1**; hedef %40, kalan ~283 soru    |
| 2 · Sınav kütüphanesi       | ✅ tamam                                                        |
| 3 · İşaret varlık denetimi  | ✅ tamam (belge + kod bağlantısı)                               |
| 4 · Yarış Modu → **Düello** | ✅ tamam                                                        |
| 5 · Tur başarımı            | ✅ tamam — kök neden bulundu ve giderildi                       |
| 6 · Koç evrimi              | 🟡 **kısmi** — hareket var; göz kırpma katmanlı varlık bekliyor |
| 7 · Görsel soru genişletme  | ❌ **yapılmadı**                                                |
| 8 · Ders zenginleştirme     | ❌ **yapılmadı**                                                |
| 9 · Seslendirme             | ❌ **yapılmadı**                                                |
| 10 · Ödeme duvarı           | ✅ tamam                                                        |
| 11 · Cihaz doğrulaması      | ✅ tamam                                                        |

**Kapılar:** `flutter analyze` **0** · mobil **1073 ✓** (978'den) · content-schema **31 ✓** ·
question-bank **14 ✓** · `pnpm lint` 0 hata · `pnpm typecheck` temiz.

**Çıktılar:** APK 81,9 MB · **AAB 65,3 MB, versionCode 5, versionName 1.0.0, `jar verified.`**

7, 8 ve 9 açıkça yapılmadı; gerekçe ve bugünkü durumları §9'da.

---

## 1. Faz 0 — Denetimin tek cümlesi

**Bankanın %91,1'i soru okunmadan doğru cevaplanabiliyordu.**

"Soruyu hiç okuma, en uzun şıkkı işaretle" stratejisi 1562 sorunun **1423'ünü** buluyordu.
Geçme barajı %70; yani uygulamayı hiç açmamış bir aday her denemeyi %91 ile geçerdi.

Kök neden: üreteç **açıklamayı doğru şıkkın içine yazmış**. Doğru şık ortalama 91,9 karakter,
çeldirici 36,9 — **2,49×**.

Bu kusur biçimsel doğrulamadan geçiyordu (dört şık, geçerli `answerIndex`, boş alan yok).
Kusur biçimde değil, **istatistikteydi** — ve hiçbir test istatistiğe bakmıyordu.

Diğer 13 bulgu yol haritası §0.2–0.6'da; hepsi bu raporun ilgili fazında ele alındı.

---

## 2. Faz 1 — Soru kalitesi (kısmi)

| Ölçüt                               | Başlangıç |     Şimdi |  Hedef |
| ----------------------------------- | --------: | --------: | -----: |
| "en uzun şıkkı seç" ile bilinebilir | **%91,1** | **%58,1** |    %40 |
| paralel şıklı soru                  |     %21,4 | **%64,6** | %60 ✅ |
| doğru/çeldirici uzunluk oranı       |     2,49× | **1,55×** |   1,5× |

**Üç ölçütten ikisi hedefe ulaştı.** Bağlayıcı olan üçüncüsü — ~283 sorunun şıkları daha elden
geçmeli.

### Ne yapıldı

1. **Kalite ölçeri ve kapısı** (`content-schema/quality.ts`) — kalite artık his değil sayı.
2. **Kodmod**: 588 soruda açıklama kuyruğu şıktan `explanation` alanına **taşındı** (silinmedi).
3. **516 sorunun çeldiricileri** doğru şıkla paralel uzunlukta yeniden yazıldı.
4. **Mandal (ratchet)**: CI bugünkü en iyi değeri dayatır; geri gidiş imkânsız.

### Reddedilen kısayol

Doğru şıkkı daha agresif kesen kurallar denendi ve **ölçülerek reddedildi** — cevabı bozuyorlardı:

| Kural                            | Örnek        | Sonuç                                     |
| -------------------------------- | ------------ | ----------------------------------------- |
| baştaki `-arak/-erek` ulacını at | `adab-005`   | "takip \| mesafesi" ortadan bölünüyor     |
| `ve` sonrasını at                | `trafik-131` | "ön \| arka" saçmalaşıyor                 |
| son virgüllü öbeği at            | `trafik-505` | cevabın yarısı gidiyor, **yanlış** oluyor |

_"Never generate nonsense"_ kuralı tam olarak bunları yasaklıyor. Yanlış cevap, uzun cevaptan
kötüdür.

### Neden mandal

1228 sorunun şıkkı elden geçmeli; bu tek oturumda bitmez. `QUALITY_GATE` **hedefi** (%40),
`QUALITY_RATCHET` **bugün ulaşılanı** (%58,2) tutar ve CI ikincisini dayatır. Ayrı bir test
mandalın ulaşılan değere yakın kalmasını zorlar — gevşek mandal, mandal değildir.

Kapıyı geçirmek için eşiği yükseltmek yasaktır ve bu, kodda yazılıdır.

### Kalan iş

`node scripts/quality-worklist.mjs --subject motor` kalan soruları yazım talimatıyla listeler;
`scripts/apply-option-patches.mjs <yama.json> --check` yamayı uygulamadan ölçer. Kalan dağılım:
trafik 206 · pratik 194 · ilkyardım 186 · motor 183 · adab 138.

---

## 3. Faz 2 — Sınav kütüphanesi

Referans uygulamanın "Sınav Soruları" kataloğunun karşılığı, kendi motorumuzla.

```
Sınav Arşivi
├── Genel Sınav              50 soru   ← ilk 3'ü ÜCRETSİZ
├── Trafik ve Çevre Bilgisi  23 soru
├── İlk Yardım Bilgisi       12 soru
├── Motor ve Araç Tekniği     9 soru
├── Trafik Adabı              6 soru
└── Görsel Sorular           10 soru
```

**Ders sınavının uzunluğu keyfi değil**: o dersin 50 soruluk e-Sınavdaki payı (23/12/9/6). Ders
sınavı böylece gerçek sınavın o bölümünün provası oluyor.

**Takvim yuvarlanır.** Eski `historical.dart` 2015–2018 arası **18 sabit tarih** tutuyordu; 2026'da
açılan uygulama sekiz yıl önceki tarihleri gösteriyordu. Artık tarihler bugünden türetiliyor.

**Her sınav üretilir**: `(kategori, tarih)` → tohum → hep aynı sınav. Elle yazılmış sınav yok,
telifli kâğıt yok. Etiket bunu açıkça söylüyor ve ekranda görünüyor.

**Ücretsiz sınır kategori başına DEĞİL.** Altı kategoride üçer ücretsiz = 18 ücretsiz sınav
demekti; premium'un anlamı kalmazdı. Sınır katalog genelinde üç ve yalnız Genel kategoride.

Referanstaki "Animasyonlu Sorular" bizde **"Görsel Sorular"** — elimizde animasyon yok, olmayan
şeyi vaat etmiyoruz.

### Üreteç düzeltmesi (bu fazda yakalandı)

Görsel enjeksiyonu **ders dağılımını bozuyordu**: metin sorusunun yerine _herhangi_ bir görsel
soru konuyordu ve "İlk Yardım" sınavına trafik levhası sorusu giriyordu. Değişim artık aynı ders
içinde yapılıyor — MEB dağılımı görsel enjeksiyonu altında da korunuyor.

---

## 4. Faz 3 — İşaret varlık denetimi

121 işaretin **35'inin** resmî SVG'si yok. Ama hepsi görsel üretimi hak etmiyor:

- **17'si rakam taşıyan hız levhası** (`azami-hiz-20…120`, `asgari-hiz-30…50`, `yukseklik-siniri`…).
  Rakam **veridir**, çizim değil; prosedürel çizim orada **doğru** çözüm. 17 ayrı görsel üretmek
  _"Do NOT generate duplicate prompts"_ kuralının tam ihlali olurdu → **üretilmeyecek.**
- **18'i gerçek piktogram istiyor** → dosya adı, klasör, kullanım yeri, GPT Image istemi, stil,
  çözünürlük ve saydamlık `ASSET_GENERATION_LIBRARY.md` **§7**'ye işlendi.

**Yeni rapor açılmadı** — var olan varlık kütüphanesine bölüm eklendi ("no report spam").

### Görsel konduğu an görünsün

Dosya adları `assets/signs/<işaret-id>.svg` olarak **şimdiden ayrıldı**. `pubspec.yaml` bu dizinin
tamamını kaydettiği için yeni dosya derlemede kendiliğinden paketleniyor; `AssetCatalog` çalışma
zamanında dosyanın gerçekten var olduğunu doğruluyor ve ancak o zaman kullanıyor. Yoksa prosedürel
çizim sürüyor — yani **kırık görsel çıkmıyor.**

Bunu mümkün kılan `AssetCatalog` Post-Beta'da yazılmıştı ama **hiçbir yerden çağrılmıyordu**;
denetimde `grep` ile bulundu ve `main()` içine bağlandı.

---

## 5. Faz 4 — Düello ("Race Mode")

Ad **Düello**: bu modda hız tek başına kazandırmıyor, doğruluk ağır basıyor.

Akış istendiği gibi: **rakip aranıyor (3 sn) → rakip bulundu → 10 soru, soru başına 20 saniye →
sonuç.**

### Puanlama neden böyle

Doğru **100 puan**, hız bonusu **en fazla 50**. Yani en yavaş doğru bile en hızlı yanlıştan çok
eder. Yalnız hıza puan verilseydi en iyi strateji _"soruyu okuma, rastgele bas"_ olurdu.
Yanlış cevap puan **götürmüyor**: ceza, tahmin etmeyi değil cevaplamayı caydırır.

**Kaybeden de XP alır.** Sıfır veren sistem, oyuncuyu zayıf olduğu konudan kaçırır — tam olarak
çalışması gereken konudan.

### Rakip

Belirlenimci yapay zekâ; doğruluk seviyeden türer ve **%85'te tavanlı**. Kusursuz rakip, oyuncunun
kusursuz oynamadıkça kazanamayacağı demektir. Düşünme süresi sabit değil (2,5–9 sn) — sabit
gecikme "bot" hissi verir.

**Çevrimiçi için hazır:** rakip `DuelOpponent` arayüzüyle soyutlandı, `answerFor` asenkron.
Gelecek `RemoteOpponent` aynı arayüzü uygular, **ekran kodu değişmez.**

**Sahte oyuncu yok:** uydurma kullanıcı adı üretilmiyor, "çevrimiçi 12.483 kişi" gibi bir sayı
yazılmıyor. Çevrimiçi olmayan bir özelliği çevrimiçiymiş gibi göstermek olurdu.

### Enerji ve çiftçilik önleme

- Ücretsiz **5**, premium **30** düello/gün. Premium **sınırsız değil**: sınırsız hak, sunucu
  sıralaması geldiğinde beceriyi değil boş vakti ölçen bir tablo üretir.
- Enerji **başlangıçta** harcanır (yarıda bırakıp bedava düello alınamasın).
- Bekleme **bitişte** başlar (20 sn) — art arda açıp kapatarak XP toplamayı engeller.
- Sıralama basamağı yerel XP'den; **"dünya sıralamasında 43." gibi doğrulanamaz bir şey
  söylenmiyor.**

---

## 6. Faz 5 — Tur başarımı (kök neden)

`_SpotlightPainter` **karartmayı** (tam ekran `Path.combine`) ve **nefes alan halkayı** aynı
boyacıda çiziyordu. Nabız 1600 ms'lik `repeat(reverse: true)` ile turun tamamı boyunca koştuğu
için `shouldRepaint` her karede `true` dönüyor ve **saniyede ~60 kez tam ekran boyutunda Skia
boolean yol işlemi** yapılıyor, her karede üç yeni `Path` ayrılıyordu.

`Path.combine` Skia'nın en pahalı işlemlerinden biridir ve GPU'ya devredilmez. **Koddaki eski
yorum bunu bir başarım tercihi olarak anlatıyordu; tersi doğruydu.**

Çözüm ilkeli değiştirmek değildi (`clipRRect` `ClipOp` almıyor; yuvarlak delik için `Path.combine`
kaçınılmaz) — **onu artık her kare çağırmamaktı:**

- `_ScrimPainter` — karartma + kenar halkası, **yalnız hedef değişince** çizilir
- `_PulseRingPainter` — tek `drawRRect` konturu, her kare çizilir

Tur bir adımda beklerken (kullanıcı metni okurken) **sıfır yol işlemi** yapılıyor. Dört test bunu
ölçüyor: nabız ilerlerken karartmanın `shouldRepaint`'i `false` dönmeli.

Ayrıca ışık halkası artık adımdan adıma **kayıyor** (`RectTween`); önceden ışınlanıyor ve alttaki
`ensureVisible` animasyonuyla birlikte zıplıyordu.

---

## 7. Faz 6 — Koç evrimi (kısmi)

### Kütüphane araştırması

| Seçenek                       | Karar                                                                                            |
| ----------------------------- | ------------------------------------------------------------------------------------------------ |
| **Rive**                      | En güçlüsü (durum makinesi). `.riv` dosyası ister — elimizde yok, durağan `.webp`den üretilemez. |
| **Lottie**                    | Yaygın. `.json` ister — aynı sorun.                                                              |
| **Yerel Flutter dönüşümleri** | **Seçilen.** Sıfır bağımlılık, sıfır dış varlık, bugün çalışıyor.                                |

Bağımlılık eklemek, animasyon dosyası gelene kadar hiçbir şey çalıştırmazdı: bugün sıfır kazanç,
kalıcı bakım yükü.

### Yapılan

Nefes (dikeyde %1,5 ölçek), süzülme, mikro eğim, konuşurken öne yaklaşma. Üç döngünün periyodu
**birbirine bölünmüyor** (2600 / 4100 / 5900 ms) — eşit ya da katı olsalardı hareket birkaç
saniyede aynı kareye döner ve göz bunu "döngü" olarak yakalardı. Bir test bunu kilitliyor.

### Yapılmayan ve nedeni

**Göz kırpma ve bakış takibi yok.** İkisi de gözün nerede olduğunu bilmeyi gerektiriyor; maskot
tek parça bir raster. Göz konumunu tahmin edip üstüne kapak çizmek, gözün yanına siyah bir çubuk
koymak olurdu. Gereken beş katman (gövde / baş / göz akı / göz bebeği / göz kapağı) istemleriyle
`ASSET_GENERATION_LIBRARY.md` **§8**'e yazıldı; katmanlar geldiğinde `LivingMascot` tek değiştirme
noktası.

---

## 8. Faz 10 — Ödeme duvarı

Katalog tek üründen üç pakete çıktı:

| Paket         | Fiyat         | Tür                                        |
| ------------- | ------------- | ------------------------------------------ |
| Haftalık      | 50 TL         | abonelik                                   |
| Aylık         | 200 TL        | abonelik                                   |
| **Ömür Boyu** | **479,99 TL** | **tek seferlik — ÖNERİLEN, en geniş kart** |

**Kaydırma yok.** Kahraman görseli düştü — dikey alanın en pahalı ögesiydi ve karar vermeye
katkısı yoktu. Deneme süresi yok, sahte aciliyet yok; geri sayım yalnız gerçekten tanımlı bir
kampanya varsa çıkıyor (Kampanya Motoru uyumlu).

### Geriye uyumluluk

Ömür boyu paketin kimliği **`komple-ehliyet` olarak kaldı**. Değiştirmek, ödeme yapmış
kullanıcıları premium'suz bırakırdı. Bir test bunu kilitliyor.

`_storeProduct` geri düşüşü kaldırıldı: tek ürünlü dönemde zararsızdı, üç üründe _"Aylık seç →
Ömür Boyu satın al"_ demekti.

### Dürüstlük düzeltmeleri

- Ders detayında `Kilidi aç · 399 ₺` yazıyordu — **katalog fiyatı ekranda kullanılmaz**
  (RC 1.0.0'da ödeme ekranında düzeltilen kusurun ikizi başka bir dosyada yaşıyordu).
- Güven şeridi **"7 gün iade"** diyordu; iade süresini Play belirler, biz vaat edemeyiz.
- **"Ömür boyu"** yazıyordu; artık yalnız bir paket için doğru → seçime göre değişiyor.
- Başlıktaki "Komple Ehliyet Paketi" adı kaldırıldı (cihazda görüldü, düzeltildi).

### Gizli kusur ortaya çıktı

Kaydırma kaldırılınca 320 dp'de taşma çıktı. Ölçüldü: **taşma eskiden de vardı** — `ListView`
tembel olduğu için o satır hiç yerleşmiyordu. Kaydırmayı kaldırmak kusuru yaratmadı, **görünür
kıldı.**

---

## 9. Yapılmayanlar — açıkça

### Faz 7 · Görsel soru genişletme — ❌

Motor bölmesi, kabin, park, kavşak önceliği, acil durum, el işaretleri, ilk yardım pozisyonları,
motosiklet/otobüs kumandaları, römork kategorileri **eklenmedi**.

Bugün elde olan: QIP v3'te kurulan görsel soru motoru çalışıyor ve cihazda **1895 soruluk havuz**
üretiyor (1562 yazılı banka + katalogdan üretilen görsel sorular). Yeni kategoriler bu motora
kategori eklemekle gelir; her biri için varlık istemi de gerekir.

### Faz 8 · Ders zenginleştirme — ❌

Ders modeli bugün `Callout`, `CompareTable`, `ReviewCard` ve `LessonMistake` taşıyor; **eksik olan
çizim bloğu** (şema, diyagram, infografik, patlatılmış mekanik, öncelik diyagramı). `LessonFigure`
tipi eklenmedi.

### Faz 9 · Seslendirme — ❌

Hiçbir parçası yapılmadı: ne veri modeli, ne oynatıcı, ne önbellek.

### Neden

Faz 1 "artık en yüksek öncelik" olarak ilan edilmişti ve denetim bunu doğruladı: %91,1
bilinebilirlik, diğer her şeyin üstünde bir kusurdu. Bu oturumun bütçesi Faz 1'in ölçüm
altyapısına, 588 sorunun kodmodla onarımına ve 516 sorunun elle yeniden yazımına gitti.

Kalan üç faz için **eldeki temel sağlam** ve hiçbiri engellenmiş değil — sırayla ele alınabilir.

---

## 10. Faz 11 — Cihaz doğrulaması

**Cihaz:** Redmi Note 8 (`M1908C3JGG`), Android 11, 1080×2340 @440 dpi (393 dp).

### Tercih edilen cihaz neden kullanılmadı

**Redmi Note 11R (`22095RA98C`, Android 13) bağlıydı** ama üzerinde **Google Play'den yüklenmiş**
kapalı beta sürümü vardı (`installerPackageName=com.android.vending`, versionCode 5, 04:24'te
kurulmuş). Yerel imzalı derleme onun üzerine kurulamıyor; kurmak için Play sürümünü **kaldırmak**
gerekiyordu.

Sahibinin telefonundaki Play beta kurulumunu ve verisini silmek geri alınamaz bir işlem ve
istenmemişti — **yapılmadı.** Doğrulama, aynı imzayı kabul eden Redmi Note 8'de yapıldı.

> Redmi Note 11R'de doğrulama isteniyorsa Play sürümünün kaldırılması gerekiyor; bu bir onay
> sorusudur, sessizce yapılacak bir şey değil.

### Cihazda kanıtlanan

| Ne                           | Kanıt                                                                                                                              |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Açılış**                   | Ana Sayfa, hazırlık halkası, AI Koç paneli — temiz                                                                                 |
| **Faz 2 · katalog**          | Altı kategori; havuzlar **hesaplanmış**: Genel **1895**, Trafik 501, İlk Yardım 303, Motor 522                                     |
| **Faz 2 · takvim**           | "1 Ağustos 2026 Sınav Soruları" — **bugünün tarihi**, geriye günlük                                                                |
| **Faz 2 · ücretsiz sınır**   | İlk üç kart "Ücretsiz" rozetli ve oynatılabilir; dördüncüden itibaren kilit + "Premium"                                            |
| **Faz 2 · üretim**           | 1 Ağustos sınavı açıldı: 50 soru, 44:54 sayaç, soru haritası                                                                       |
| **Faz 1 · şık paralelliği**  | Sınavın 1. sorusunun şıkları **22–27 karakter**, hepsi akla yatkın mekanik arıza, doğru cevap **en uzun değil**                    |
| **Faz 4 · düello**           | "Rakip bulundu · Rakip · Seviye 5", "Bugün kalan düello: 5", 1/10 ekranı **16 sn** sayaçla                                         |
| **Faz 4 · çiftçilik önleme** | Düello yarıda bırakıldı → kalan hak **5 → 4**; iade edilmedi                                                                       |
| **Faz 10 · ödeme duvarı**    | Üç kart yan yana: ₺50/hafta · ₺200/ay · **ÖNERİLEN Ömür Boyu ₺479,99 tek seferlik**; deneme yok, geri sayım yok, hepsi tek ekranda |
| **Faz 3 · fiyat kaynağı**    | Mağaza kapalı (yandan yükleme) olduğu için **yedek** etiketler göründü — tasarlandığı gibi                                         |

Sürüm satırı: **Ehliyet Akademi · v1.0.0 (5)**.

### Bulunan ve düzeltilen

Ödeme duvarının başlığı hâlâ tek ürünlü dönemin adını taşıyordu ("Komple Ehliyet Paketi ile…").
Cihazda görüldü, düzeltildi, AAB ondan sonra üretildi.

---

## 11. Çıktılar

```
apps/mobile/build/app/outputs/flutter-apk/app-release.apk    81,9 MB
apps/mobile/build/app/outputs/bundle/release/app-release.aab 65,3 MB
  versionCode="5"  versionName="1.0.0"  jarsigner: jar verified.
```

`GOOGLE_SERVER_CLIENT_ID` ikisinde de gömülü (APK'nın `libapp.so`'sunda doğrulandı).

> **`.env` tuzağı yine çıktı.** Değer satır sonunda `# final client` yorumu taşıyor; naif bir
> `sed` bunu değere dahil ediyor ve derleme sessizce bozuk kimlikle çıkıyor. Ayıklama artık
> yorumu ve tırnakları temizliyor, sonuç `.apps.googleusercontent.com` ile bitiyor mu diye
> denetleniyor.

---

## 12. Belgeler

Yalnız iki yeni belge:

- `PRODUCT_EVOLUTION_ROADMAP.md`
- `PRODUCT_EVOLUTION_IMPLEMENTATION_REPORT.md` (bu)

`ASSET_GENERATION_LIBRARY.md` (§7 levhalar, §8 maskot katmanları) ve `MOBILE_PROJECT_MEMORY.md`
**genişletildi**, yeni dosya açılmadı.
