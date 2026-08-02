# Ürün Evrim Programı v1.1 — Yol Haritası

**Tarih:** 1 Ağustos 2026 · **Dal:** `feature/product-evolution-v11` · **Taban:** `d8f20e5` sonrası, PR #14 (QIP v3) birleşmiş
**Referans:** `/screenshots` (11 ekran görüntüsü — `sweetmarkiz.com.ehliyet`, rakip uygulama)

Bu belge **Faz 0 denetiminin bulgularından** üretildi. Tahmin yok; her madde ya ölçülmüş bir sayıya ya
da okunmuş bir dosyaya dayanır. Uygulama raporu ayrıdır: `PRODUCT_EVOLUTION_IMPLEMENTATION_REPORT.md`.

---

## 0. Denetim — bulunan her tutarsızlık

Denetim beş koldan yürüdü: soru bankası (ölçümle), ekranlar (okuyarak), varlıklar (sayarak),
koç/tur (kod okuyarak), referans ekran görüntüleri (karşılaştırarak).

### 0.1 🔴 KRİTİK — Banka sorularının %91,1'i soru okunmadan doğru cevaplanabiliyor

En ağır bulgu bu ve programın önceliğini o belirliyor.

Ölçüm: **"soruyu hiç okuma, en uzun şıkkı işaretle"** stratejisi 1562 sorunun **1423'ünde** doğru
cevabı buluyor.

| Strateji                                |           Doğru |      Oran |
| --------------------------------------- | --------------: | --------: |
| **En uzun şıkkı seç (soruyu okumadan)** | **1423 / 1562** | **%91,1** |
| En uzun (beraberlikte ilk)              |     1434 / 1562 |     %91,8 |
| "Mutlak" ifadeli şıkkı ele + en uzun    |     1412 / 1562 |     %90,4 |
| Her zaman B                             |      459 / 1562 |     %29,4 |
| Rastgele (taban çizgisi)                |               — |     %25,0 |

Geçme barajı %70. Yani **uygulamayı hiç açmamış, tek ders okumamış bir aday her denemeyi %91 ile
geçer.** Bu, sınav simülasyonunu geçersiz kılar.

Ders bazında (aynı strateji): motor %95,8 · adab %98,5 · pratik %97,3 · ilkyardım %87,8 · trafik %79,7.

**Kök neden — üreteç, _açıklamayı doğru şıkkın içine yazmış_.** Şık uzunlukları:

|            |      ortalama |
| ---------- | ------------: |
| doğru şık  | 91,9 karakter |
| yanlış şık | 36,9 karakter |
| **oran**   |     **2,49×** |

Örnek (`motor-640`, oran 8,1×):

```
S: ...debriyaj pedalına basıldığı anda ortaya çıkan ... ses ... hangi parça akla gelmelidir?
   A) Radyatör fanı                    (13)
   B) Yakıt pompası                    (14)
 ✓ C) Debriyaj baskı rulmanı (bilyası); yalnızca pedala basıldığında yük altına
      girdiği için aşındığında sesi bu anlarda duyulur      (113)
   D) Ön cam sileceği                  (17)
```

Gerçek cevap "Debriyaj baskı rulmanı". Noktalı virgülden sonrası **açıklamadır** ve `explanation`
alanına ait. 1228 soruda doğru şık, en uzun çeldiricinin 1,35 katından uzun.

Karşılaştırma — referans ekran görüntülerindeki gerçek MEB sorularında şıklar **paralel uzunlukta**,
hatta doğru cevap çoğu zaman **en kısa** olan:

| Referans soru               | Şık uzunlukları      | Doğru            |
| --------------------------- | -------------------- | ---------------- |
| "…yöntemler bütünüdür?"     | 11 / 13 / 14 / 16    | **en kısa** (11) |
| "…genel adı nedir?"         | 12 / 13 / 12 / **4** | **en kısa** (4)  |
| "Şekildeki trafik işareti…" | 30 / 32 / 34 / 46    | 32               |
| "Trafik sıkışıklığından…"   | 39 / 32 / 46 / 29    | 46 (oran 1,18×)  |

### 0.2 🔴 Ürün turu, gerçekleşmeyen ve hukuken riskli bir vaat veriyor

`features/onboarding/product_tour.dart:65`:

> "Geçmiş dönemlerde sorulmuş **gerçek sınavları olduğu gibi** çöz."

Oysa `domain/practice/historical.dart` tam tersini yapar ve doğrusu odur:

> `historicalLabel = 'MEB formatında hazırlanmış özgün deneme sınavı'`

QIP v3 Faz 6'da telif gereği "asla telifli sınav kâğıdı sunma" kuralı konmuştu; motor buna uyuyor,
**tanıtım metni uymuyor**. Kullanıcıya yalan söyleyen ve aynı anda telif iddiası ima eden bir cümle.

### 0.3 🟠 Koç turu takılmasının gerçek nedeni — her karede tam ekran `Path.combine`

`design/coach_marks.dart:422`, `_SpotlightPainter.paint`:

```dart
canvas.drawPath(
  Path.combine(PathOperation.difference,          // ← tam ekran boolean yol işlemi
    Path()..addRect(Offset.zero & size),
    Path()..addRRect(rrect)),
  Paint()..color = ...);
```

`_pulse` 1600 ms'lik `repeat(reverse: true)` ile **turun tamamı boyunca** koşar; `shouldRepaint`
`pulse` değiştiği için her karede `true` döner. Sonuç: **saniyede ~60 kez, tam ekran boyutunda
Skia boolean yol işlemi + iki yeni `Path` ayırma**. `Path.combine` Skia'nın en pahalı işlemlerinden
biridir ve GPU'ya devredilmez.

Koddaki yorum bunu bir _başarım tercihi_ olarak anlatıyor ("tek geçişte çizilir") — tersi doğru.
Doğru ilkel `canvas.clipRRect(rrect, clipOp: ClipOp.difference)`: yol ayırma yok, boolean işlem yok.

İkinci kusur: `_spot` adımlar arası `setState` ile **ışınlanıyor** (ara değer yok). Altta
`Scrollable.ensureVisible` animasyonu sürerken ışık halkası zıplıyor.

### 0.4 🟠 Ödeme duvarı — kaydırmalı ve tek ürünlü

`features/premium/paywall_screen.dart:395` `ListView` (kaydırma), `domain/premium/products.dart`
tek ürün: `komple-ehliyet`, 399 TL, ömür boyu. İstenen üç paket (haftalık/aylık/ömür boyu) ve
kaydırmasız yerleşim yok.

### 0.5 🟡 Sınav kütüphanesi yok, tarihler bayat

Bugün yalnız `historicalSessionDates` var: **18 sabit tarih, 2015–2018**. Referans uygulama
**günlük ve güncel** tarihler gösteriyor (1 Ağustos 2026, 31 Temmuz 2026, …) ve **kategori başına**
ayrı sınav listesi tutuyor. Bizde kategori kırılımı ve ücretsiz/premium ayrımı yok.

Referansın kataloğu (ekran görüntüsünden) ve arkasındaki matematik:

| Kategori                | Sınav | Soru | Soru/sınav |
| ----------------------- | ----: | ---: | ---------: |
| Genel Sınav             |    31 | 1550 |     **50** |
| İlk Yardım Bilgisi      |    34 |  408 |     **12** |
| Trafik ve Çevre Bilgisi |    34 |  782 |     **23** |
| Motor ve Araç Tekniği   |    34 |  306 |      **9** |
| Trafik Adabı            |    34 |  204 |      **6** |
| Animasyonlu Sorular     |    24 |  120 |          5 |

Ders başına sınav uzunluğu, o dersin **50 soruluk MEB planındaki payına eşit** (23/12/9/6). Bu
zarif ve bizim `ExamConfig` yapımıza doğrudan oturuyor.

### 0.6 🟡 Diğer sayılan bulgular

| #   | Bulgu                                                          | Ölçü                               |
| --- | -------------------------------------------------------------- | ---------------------------------- |
| 1   | `whyWrong` boş olan soru                                       | **1177 / 1562** (%75)              |
| 2   | Hiçbir soru uzman onaylı değil                                 | `review: draft` = **1562 / 1562**  |
| 3   | Alan dışı çeldirici ("aracın rengi", "silecek suyu")           | 55 şık / 48 soru                   |
| 4   | Saçma çeldirici ("…görmezden gelip…")                          | 16                                 |
| 5   | Tembel çeldirici ("Fark etmez", "Geri dön")                    | 3                                  |
| 6   | Cevap konumu dengesizliği                                      | B=459, beklenen ~391               |
| 7   | Resmî SVG'si olmayan işaret                                    | **35 / 121**                       |
| 8   | …bunlardan sayısal hız levhası (prosedürel çizim _doğru_ olan) | **17**                             |
| 9   | Yinelenen gövde / yinelenen şık / 3 şıklı soru                 | **0** ✅                           |
| 10  | Tekrarlayan gövde kalıbı (≥12 kez)                             | **0** ✅                           |
| 11  | Yarış Modu                                                     | yok                                |
| 12  | Ders görsel bloğu (şema/diyagram/infografik)                   | yok (`Callout`+`CompareTable` var) |
| 13  | Seslendirme altyapısı                                          | yok                                |
| 14  | Koç maskotu                                                    | 7 durağan `.webp`, animasyon yok   |

Not: 9 ve 10 temiz çıktı — QIP v3'te konan kapılar tutmuş. Bozuk olan **şık dengesi**, yapı değil.

---

## 1. Programın sırası ve gerekçesi

Kullanıcı Faz 1'i "artık en yüksek öncelik" ilan etti; denetim bunu doğruluyor. Sıralama, **her fazın
bir öncekinin ürettiği temele yaslanması** ilkesine göre:

```
Faz 1  Soru kalitesi           ← her şeyin girdisi; bozuk soruyla iyi sınav kurulamaz
  └─ Faz 2  Sınav kütüphanesi   ← düzelmiş bankayı kataloğa açar
       └─ Faz 4  Yarış Modu     ← kütüphanenin soru seçicisini kullanır
Faz 3  İşaret varlık denetimi   ← bağımsız, belge çıktısı
Faz 5  Tur başarımı             ← bağımsız, ölçülebilir düzeltme
  └─ Faz 6  Koç animasyonu      ← aynı animasyon bütçesine dokunur
Faz 7  Görsel soru genişletme   ← Faz 1'in kalite kapısına tabi
Faz 8  Ders zenginleştirme      ← Faz 3'ün varlık sözleşmesini kullanır
  └─ Faz 9  Seslendirme         ← ders modeline alan ekler
Faz 10 Ödeme duvarı             ← Faz 2'nin ücretsiz/premium sınırını gösterir
Faz 11 Cihaz doğrulaması        ← hepsinin üstünde
```

---

## 2. Faz 1 — Soru Kalitesi Kurtarma

**Hedef metrik.** "En uzun şıkkı seç" doğruluğu **%91,1 → ≤%40**. Rastgele taban %25 olduğuna göre
%40, ölçüm gürültüsüne yer bırakan ama tellalığı bitiren bir eşik. Metrik kalıcı bir teste bağlanır.

### 2.1 Neden kesip kısaltmak TEK BAŞINA yetmez — ve nerede tehlikeli

Ölçtüm. Doğru şıktan açıklama kuyruğunu ayıran güvenli kodmod (noktalı virgül, parantez kuyruğu,
bağlaç kuyruğu) 590 şıkkı ayırıyor ve:

|                   |  önce | kodmod sonrası |
| ----------------- | ----: | -------------: |
| en uzun şıkkı seç | %91,1 |      **%74,3** |
| ort. doğru şık    |  91,9 |           64,8 |
| ort. yanlış şık   |  36,9 |           36,9 |
| oran              | 2,49× |          1,76× |

%74,3 hâlâ barajın üstünde. Kalan sorun **doğru şıkkın uzunluğu değil, çeldiricilerin kısalığı**.

Daha agresif kesme kurallarını da denedim ve **reddettim** — cevabı bozuyorlar:

| Kural                            | Örnek                                                                    | Sonuç                                        |
| -------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------- |
| baştaki `-arak/-erek` ulacını at | `adab-005`: «Sakin kalmak, takip» ⇒ «mesafesini açmak…»                  | ❌ "takip mesafesi" ortadan bölünüyor        |
| `ve` sonrası kuyruğu at          | `trafik-131`: «…ön» ⇐ «arka tüm koltuklarda»                             | ❌ "ön ve arka" saçmalaşıyor                 |
| son virgüllü öbeği at            | `trafik-505`: «Varsa levhalara» ⇐ «yoksa kontrolsüz kavşak kurallarına…» | ❌ cevabın yarısı gidiyor, **yanlış** oluyor |

Kullanıcının kuralı: _"Never generate nonsense."_ Bu kurallar tam olarak onu üretirdi. Yalnız
**açık açıklama ayracı** taşıyan kesme uygulanır.

### 2.2 Yapılacaklar

1. **Kalıcı kalite kapısı** — `naive-guess` testi. Eşik aşılırsa CI kırılır. Kalitenin "his" değil
   **sayı** olması, bu programın geri kalanının da güvencesi.
2. **Güvenli kodmod** — açıklama kuyruğunu şıktan `explanation`'a **taşır** (silmez; bilgi kaybı yok).
3. **Çeldirici paralelleştirme** — asıl iş. Şişkin sorularda üç çeldirici, doğru şıkla aynı
   dilbilgisel biçimde ve karşılaştırılabilir uzunlukta yeniden yazılır.
4. **Saçma/tembel/alan dışı çeldiricilerin tasfiyesi** — 74 şık.
5. **Cevap konumu dengeleme** — üreteç zaten karıştırıyor; bankadaki ham dengesizlik de düzeltilir.
6. **`whyWrong` tamamlama** — çeldirici yeniden yazılırken zaten gerekçesi biliniyor, aynı geçişte yazılır.

### 2.3 Kapsam dürüstlüğü

862 soru × 3 çeldirici = 2586 metin. Bu, programın en büyük tek kalemi. Tek oturumda hepsini
_iyi_ yazmak mümkün değil; **kapı + kodmod + öncelikli yeniden yazım** yapılır ve raporda
**hangi sorunun düzeldiği, hangisinin kaldığı sayıyla** bildirilir. Sınav üreteci bu arada
kalite puanı yüksek soruları tercih eder, böylece kullanıcı düzelmiş havuzu görür.

---

## 3. Faz 2 — Sınav Kütüphanesi

Referans yapıyı alıp **kendi motorumuzla** kuruyoruz. Kullanıcı yalnız tarih görür; arkada her sınav
`buildExamV2` ile o tarihin tohumundan üretilir.

```
Sınav Soruları
├── Genel Sınav            50 soru   (23/12/9/6 MEB planı)
├── Trafik ve Çevre        23 soru
├── İlk Yardım             12 soru
├── Motor ve Araç Tekniği   9 soru
├── Trafik Adabı            6 soru
└── Görsel Sorular          ~10 soru (kind ∈ VISUAL_KINDS)
```

- **Takvim yuvarlanır**: bugünden geriye günlük tarihler. Sabit liste yok, tarih bayatlamaz.
- **Belirlenimci**: `(kategori, tarih)` → tohum → hep aynı sınav. Çevrimdışı çalışır.
- **İlk üç ücretsiz**, gerisi premium. Sınır kategori başına değil, **katalog genelinde** sayılır.
- **Telifsiz**: hiçbir sınav elle yazılmaz, hiçbir telifli kâğıt sunulmaz. Etiket dürüst kalır.

"Animasyonlu Sorular" adı bizde **Görsel Sorular** olur — elimizde animasyon yok, olmayan şeyi vaat
etmeyiz (0.2'deki hatanın aynısını tekrarlamamak için).

## 4. Faz 3 — İşaret Varlık Denetimi (belge)

35 işaretin resmî SVG'si yok. Ama **hepsi görsel üretimi hak etmiyor**:

- **17'si sayısal hız levhası** (`azami-hiz-20…120`, `asgari-hiz-30…50`). Bunlar kırmızı/mavi halka
  - rakamdır; rakam _veridir_, çizim değil. Prosedürel çizim burada **doğru** çözüm. 17 ayrı görsel
    üretmek "Do NOT generate duplicate prompts" kuralının tam ihlali olurdu → **tek parametrik istem**.
- **18'i gerçek piktogram istiyor** (`kaygan-yol`, `vahsi-hayvan`, `lokanta`, `tunel`, `havalimani`,
  `taksi-duragi`, `engelli-parki`, `otoyol-cikisi`, …).

Belge her kalem için: dosya adı · klasör · kullanım yeri · GPT Image istemi · stil · çözünürlük ·
saydamlık. Uygulama dosya adlarını **şimdiden** referans eder (`AssetCatalog.byConvention`), böylece
görsel klasöre konduğu an kod değişikliği olmadan görünür.

## 5. Faz 4 — Yarış Modu

Ad: **Düello**. "Race" yerine Türkçe ve sınav bağlamına uygun.

```
Rakip aranıyor…  (3–5 sn)  →  Rakip bulundu  →  20 sn/soru düello  →  Sonuç
```

- Rakip başta **belirlenimci yapay zekâ**: seviye profilinden (doğruluk oranı + cevap gecikmesi
  dağılımı) türetilir. Sahte "çevrimiçi oyuncu" ismi uydurulmaz.
- Ağ katmanı **arayüzle** ayrılır (`DuelOpponent`) — çevrimiçi eşleşme sonradan aynı arayüzü
  uygular, ekran kodu değişmez.
- Enerji (günlük), günlük sınır, çiftçilik önleme (aynı soru havuzunun tekrar sayılmaması,
  sonuçların sunucu doğrulamasına hazır imzalanması), XP, sıralama.

## 6. Faz 5 — Tur Başarımı

`Path.combine` → `clipRRect(ClipOp.difference)`. Işık halkası `RectTween` ile **kayar**.
Ölçüm: aynı turda kare süresi, önce/sonra, cihazda.

## 7. Faz 6 — Koç Evrimi

Kütüphane araştırması sonucu: **Rive** ve **Lottie** en olgun seçenekler, ama ikisi de _yazılmış
animasyon dosyası_ (`.riv` / `.json`) ister — elimizde yok ve üretemem. Var olan 7 durağan `.webp`
katmanı üzerinde **yerel Flutter animasyonu** ile gerçek hareket elde edilir: göz kırpma, nefes
(ölçek), baş eğimi, bakış takibi, yazma/direksiyon hareketi. Sıfır yeni bağımlılık, sıfır dış varlık.
Abartısız; "premium eğitim" tonunda.

## 8. Faz 7 — Görsel Soru Genişletme

Yeni kategoriler (motor bölmesi, kabin, park, kavşak önceliği, acil durum, el işaretleri, ilk yardım
pozisyonları, motosiklet/otobüs kumandaları, römork…). Her eksik görsel için **tek** GPT Image istemi;
kayıt `ASSET_GENERATION_LIBRARY.md` ile çakışma kontrolünden geçer (yinelenen istem yok).

## 9. Faz 8 — Ders Zenginleştirme

Ders modeline görsel blok: `LessonFigure` (şema/diyagram/infografik/patlatılmış mekanik/öncelik
diyagramı). `Callout` ve `CompareTable` zaten var; eksik olan **çizim**.

## 10. Faz 9 — Seslendirme

Ders başına kısa özet + uzun anlatım metni **veri modelinde**; oynatma hızı, indirme, önbellek,
çevrimdışı **uygulanır**. Ses sentezi dış servis olduğu için orada **mimari + arayüz** bırakılır
(`NarrationSource`), gerçek ses dosyası geldiğinde kod değişmez.

## 11. Faz 10 — Ödeme Duvarı

Kaydırmasız, üç kart tek ekranda: Haftalık 50 TL (abonelik) · Aylık 200 TL (abonelik) ·
**Ömür Boyu 479,99 TL (önerilen, en büyük kart, tek seferlik)**. Deneme süresi **yok**, sahte aciliyet
**yok**. Kampanya Motoru uyumlu kalır: kampanya varsa geri sayım, yoksa yok.

## 12. Faz 11 — Cihaz Doğrulaması

Tercih: Redmi Note 11R → Huawei → son bağlanan Redmi. Oturum başında bağlı tek cihaz
**Redmi Note 8 (M1908C3JGG, Android 11)**; diğer ikisi bağlı değil. Rapor hangi cihazda ne
doğrulandığını açıkça yazar.

---

## 13. Her faz için değişmez kural

`update memory → commit → push → CI yeşil → testler → cihaz doğrulaması`

## 14. Çıktılar

Yalnız iki belge: **`PRODUCT_EVOLUTION_ROADMAP.md`** (bu) ve
**`PRODUCT_EVOLUTION_IMPLEMENTATION_REPORT.md`**. Faz raporu üretilmez.
