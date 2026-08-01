# Premium Kalite Programı — Yol Haritası

**Tarih:** 1 Ağustos 2026 · **Dal:** `feature/product-evolution-v11-ci` · **Taban:** `fab069e`
**Uygulama raporu:** `PREMIUM_QUALITY_IMPLEMENTATION_REPORT.md` · **Başka rapor üretilmeyecek.**

Bu belge, depo **yeniden taranarak** yazıldı. Önceki sprintlerin iddialarına güvenilmedi; her satır
ya bugün ölçüldü ya da bugün okunan bir dosyaya dayanıyor.

---

## 0. Bugün ölçülen taban çizgisi

| Kapı                    | Bugünkü değer                                                  |
| ----------------------- | -------------------------------------------------------------- |
| `flutter analyze`       | **0 sorun**                                                    |
| `flutter test`          | **1073 ✓**                                                     |
| Web testi (`@ea/web`)   | **633 ✓**                                                      |
| Paket testleri          | content-schema 31 ✓ · question-bank 14 ✓ · srs 12 ✓            |
| Banka                   | **1562 soru**                                                  |
| **"En uzun şıkkı seç"** | **907 / 1562 = %58,1** (hedef %40, rastgele taban %25)         |
| Paralel şıklı           | 1009 (%64,6)                                                   |
| Doğru/çeldirici uzunluk | 1,55×                                                          |
| Cevap konumu (A/B/C/D)  | 373 / **459** / 382 / 348 — B'de +%4,4 sapma                   |
| Kalan iş dersi bazında  | trafik 206 · pratik 194 · ilkyardım 186 · motor 183 · adab 138 |

Bu tabloda tek kırmızı **%58,1**. Geçme barajı %70 olduğuna göre, soruları hiç okumayan bir aday
hâlâ barajın yakınında geziniyor. Programın birinci işi budur.

### 0.1 Kalan 907 sorunun gerçek kusuru — ölçmekle görülmeyen kısım

Metrik "doğru şık tek başına en uzun" diyor; ama örnekleri okuyunca asıl kusur başka:

```
motor-225 · Soğutma sistemindeki termostatın görevi nedir?
  ✓(85) Motorun çalışma sıcaklığına ulaşınca su geçişini ayarlayarak sıcaklığı dengede tutmak
  ✗(16) Yakıtı ateşlemek
  ✗(21) Direksiyonu döndürmek          ← termostat sorusunda DİREKSİYON
  ✗(28) Lastik dişini derinleştirmek   ← ve LASTİK
```

Çeldiriciler yalnız **kısa** değil, **alan dışı**. Gerçek MEB sorusunda termostat sorusunun
çeldiricileri de soğutma sisteminden gelir (radyatör, devirdaim pompası, fan müşiri). Alan dışı
çeldirici iki kez zarar verir: soruyu kolaylaştırır **ve** hiçbir şey öğretmez.

Bu yüzden Faz 1'in ölçütü "uzat" değil, **"aynı alandan, aynı dilbilgisel biçimde, akla yatkın
ve karşılaştırılabilir uzunlukta yaz"**. Metrik bunun yan ürünü olarak düzelir.

### 0.2 Konu kapsamı — nerede gerçekten boşluk var

Banka konu bazında sanılandan geniş: trafik 380 · motor 310 · ilkyardım 303 · pratik 297 ·
adab 272. Kullanıcının saydığı başlıkların çoğu **zaten var** (kavşak önceliği, park, gösterge
paneli, levhalar, ilk yardım, yol çizgileri, acil durum).

Gerçekten ince ya da hiç olmayanlar — sayarak:

| Alan                  | Bugünkü soru                               | Durum       |
| --------------------- | ------------------------------------------ | ----------- |
| ESP / ASR / çekiş     | **0**                                      | ❌ yok      |
| Bagaj / yük yerleşimi | **0**                                      | ❌ yok      |
| Römork / karavan      | 1 (`romork-yolcu-yasagi`) + 4 çekme kuralı | 🟠 çok ince |
| Motosiklet            | 3 (levha + şerit arası + kask)             | 🟠 çok ince |
| Motor bölmesi         | 1 (`motor-bolmesi-guvenlik`)               | 🟠 çok ince |
| Araç içi kumandalar   | dağınık, konu başlığı yok                  | 🟠          |
| ABS                   | 4                                          | 🟠 ince     |

### 0.3 Ders görselleri — web'de VAR, mobilde YOK

`apps/web/components/LessonFigure.tsx` **12 satır içi SVG** taşıyor (işaret grupları, ABC,
gösterge renkleri, kavşak, takip mesafesi, sollama, yaya geçidi, TYD, araca hazırlık, rampa,
paralel park, dönel kavşak). Hepsi telifsiz, tema uyumlu, erişilebilir.

Mobil `Lesson` modeli `figureId` alanını **taşıyor** ama hiçbir yerde **çizmiyor**:

```
grep -rn "figureId" apps/mobile/lib --include=*.dart
  → yalnız lesson.dart:79 (alan tanımı) ve üretilmiş freezed/g dosyaları
```

Yani ürünün asıl yüzü olan mobil uygulamada ders görselleri **hiç görünmüyor**. Bu, QIP v3'teki
"platform eksik değil, bağlı değil" bulgusunun ders tarafındaki ikizi.

### 0.4 Seslendirme — hiçbir parçası yok

`grep -ri "tts\|narration\|seslendir"` mobil ve web kaynağında **sıfır** eşleşme veriyor
(tek eşleşme `auth_screen.dart` içinde alakasız bir kelime). Veri modeli, oynatıcı, önbellek,
sağlayıcı soyutlaması — hiçbiri yok.

### 0.5 Ölü bağımlılık — RevenueCat

Kullanıcı "RevenueCat kullanılmıyor" diyor ve doğru: `billing_gateway.dart:185` ağ geçidini
yalnız `REVENUECAT_PUBLIC_KEY` derleme bayrağı verilirse seçiyor, o da verilmiyor.
Ama `purchases_flutter: ^10.4.3` hâlâ `pubspec.yaml`'da ve `revenuecat_gateway.dart` (256 satır)
derleniyor, APK'ya giriyor. **Ödenen bedel var, alınan fayda yok.**

---

## 1. Faz sırası — kullanıcının verdiği öncelik korunuyor

Sıra kullanıcı tarafından belirlendi ve **değişmeyecek**. Gerekçe her fazın bir öncekinin
ürettiği temele yaslanması:

```
Faz 1  Soru kalitesi        ← her şeyin girdisi
  └─ Faz 2  Soru genişletme  ← yeni sorular AYNI kaliteyle doğmalı, yoksa metrik geri gider
       └─ Faz 3  Görsel soru ← genişleyen konular varlık ister
Faz 4  Ders zenginleştirme  ← Faz 3'ün varlık sözleşmesini kullanır
  └─ Faz 5  Seslendirme      ← ders modeline alan ekler
Faz 6  Kod kalitesi          ← en son: üstündeki her faz kod ekler, önce eklensin sonra ölçülsün
Faz 7  Cihaz doğrulaması     ← hepsinin üstünde, her fazda tekrarlanır
```

---

## 2. Faz 1 — Soru Kalitesi (öncelik 1)

**Hedef:** `longestWinsRate` %58,1 → **%40 altı**, mümkün olduğunca **%25 (rastgele taban)**
yakınına.

### 2.1 Yazım kuralı — dört madde

Her yeniden yazılan çeldirici şunları sağlayacak:

1. **Aynı alan.** Termostat sorusunun çeldiricisi soğutma sisteminden gelir.
2. **Aynı dilbilgisel biçim.** Doğru şık `-mak/-mek` mastarıysa üçü de mastar.
3. **Akla yatkın ve yanlış.** Öğrencinin gerçekten düşebileceği bir yanılgı olmalı;
   "Direksiyonu döndürmek" yanılgı değil, gürültü.
4. **En az bir çeldirici doğru şık kadar uzun.** Ölçütün bağlayıcı yanı bu. Gerçek sınavda da
   ayrıntılı ama yanlış bir şık bulunur.

Kullanıcının kuralı geçerli: **boş, yapay, saçma, gereksiz şık üretilmeyecek.**

### 2.2 Kapının güçlendirilmesi — yeni ölçütler

Bugünkü kapı dört şey ölçüyor (en uzun şık · paralellik · uzunluk oranı · cevap konumu).
Eklenecekler — her biri denetimde **sayılmış** bir kusura karşılık geliyor:

| Yeni ölçüt                | Neyi yakalar                                                                                  |
| ------------------------- | --------------------------------------------------------------------------------------------- |
| **Alan dışı çeldirici**   | Soru gövdesiyle hiç sözcük paylaşmayan, konu dışı şık                                         |
| **"Mutlak" ifade tuzağı** | "asla/hiçbir zaman/kesinlikle" taşıyan şık genelde yanlıştır → sınav tekniğiyle elenebilirlik |
| **Tembel çeldirici**      | "Fark etmez", "Hiçbiri", "Yukarıdakilerin hepsi"                                              |
| **En kısa şık tuzağı**    | Doğru cevabın sistematik olarak en KISA olması (ters tellalık)                                |
| **`whyWrong` kapsaması**  | Çeldirici yeniden yazıldıysa gerekçesi de yazılmalı                                           |

Mandal (ratchet) ilkesi korunur: eşik yalnız **aşağı** çekilir, kapıyı geçirmek için gevşetilmez.

### 2.3 Kapsam dürüstlüğü

907 soru × 3 çeldirici = **2721 metin**. Rapor, kaç sorunun gerçekten düzeldiğini **sayıyla**
bildirecek; "büyük ölçüde iyileştirildi" gibi ölçülemez bir cümle kurulmayacak.

---

## 3. Faz 2 — Soru Genişletme (öncelik 2)

§0.2'de sayılan **gerçek** boşluklar doldurulur. Var olan konuya "biraz daha" eklenmez —
sıfır ya da bire yakın olanlar hedeflenir:

```
ESP / ASR / çekiş kontrolü · Bagaj ve yük yerleşimi · Römork ve karavan çekme
Motosiklet · Motor bölmesi (kaput altı) · Araç içi kumandalar · ABS derinleştirme
```

**Kural:** yeni sorular kalite kapısına **doğuştan** uyar. Kapıyı bozan tek bir yeni soru bile
eklenmez — Faz 1'de kazanılanı Faz 2'nin geri alması, programın en kolay düşülen tuzağıdır.
Bunu bir test zorlar: yeni soruların `longestOptionWins` oranı, banka ortalamasından **kötü
olamaz**.

Her soru: 4 şık · gerçek MEB tarzı · kaliteli çeldirici · `explanation` · `whyWrong`.

---

## 4. Faz 3 — Görsel Soru Genişletme (öncelik 3)

1. **Önce envanter.** Bugünkü varlıklarla (121 işaret · 60 ikaz · 101 mekanik) hangi yeni görsel
   soru üretilebiliyor — kod yazmadan, sayarak.
2. **Sonra eksik listesi.** Faz 2'nin getirdiği konular hangi görseli istiyor
   (motor bölmesi kesiti, bagaj yerleşimi, römork bağlantısı, kavşak öncelik diyagramı…).
3. **Her eksik için TEK istem** — `ASSET_GENERATION_LIBRARY.md`'ye çakışma denetiminden geçirilerek
   yazılır. Yinelenen istem üretilmez (17 hız levhası kararının aynı gerekçesi).
4. **Dosya adları şimdiden koda bağlanır.** Görsel klasöre konduğu an, **kod değişmeden** çalışır;
   yoksa bugünkü davranış sürer (kırık görsel çıkmaz).

## 5. Faz 4 — Ders Zenginleştirme (öncelik 4)

Web'deki 12 SVG'nin mobil karşılığı **`CustomPainter` ile** yazılır — raster değil:

- tema ile birlikte değişir (açık/koyu),
- yazı tipi ölçeğiyle büyür,
- APK'ya bayt eklemez,
- çevrilebilir (metin `Text` widget'ı olarak çizilir).

`figureId` zaten modelde ve içerikte dolu; eksik olan **çizici** ve **çağrı yeri**. Web'de olmayan
yeni şemalar da eklenir: araç kesiti, motor bölmesi yerleşimi, trafik akış diyagramı, ilk yardım
pozisyonları.

## 6. Faz 5 — Seslendirme Altyapısı (öncelik 5)

İstenen açıkça "altyapı + arayüz + model + sağlayıcı soyutlaması"; gerçek TTS sonra bağlanacak.

```
NarrationSource (soyut)
├── AssetNarrationSource     — pakete gömülü ses dosyası (bugün: yok, yarın: var)
├── RemoteNarrationSource    — sunucudan indirilen ses (önbellekli)
└── SilentNarrationSource    — bugünkü varsayılan; ses YOKKEN arayüz dürüst davranır
```

**Kural:** ses yokken oynatıcı **görünmez** ya da açıkça "hazırlanıyor" der. Çalışmayan bir
oynat düğmesi koymak ölü gezinmedir (mühendislik disiplini kural 3) — yapılmayacak.

## 7. Faz 6 — Kod Kalitesi (öncelik 6)

Ölçülecek, tahmin edilmeyecek:

- **Ölü bağımlılık:** `purchases_flutter` + `revenuecat_gateway.dart` (§0.5) — kaldırma kararı
  ölçümle verilir (APK farkı).
- **Kod tekrarı:** 37.860 satır mobil kaynakta yinelenen desenler taranır.
- **Widget rebuild:** `Consumer` kapsamları, gereksiz `watch`, eksik `const`.
- **Frame drop / animasyon:** Faz 5'te (`coach_marks`) kurulan "pahalı olanı sık çizme" ilkesi
  diğer boyacılara da uygulanır; ölçüm cihazda.
- **Bellek sızıntısı:** `dispose` edilmeyen `Timer` / `AnimationController` / `StreamSubscription`
  taraması (`Future.delayed` tuzağı daha önce yakalanmıştı).

## 8. Faz 7 — Cihaz Doğrulaması

Oturum başında **iki cihaz da bağlı**:

```
AYXSUKIVJVPZ7HPZ  Redmi Note 8    (M1908C3JGG, Android 11)
jfzxugsgnnvsrsg6  Redmi Note 11R  (22095RA98C,  Android 13)  ← tercih edilen
```

Tercih sırası uygulanır: **Redmi Note 11R → Huawei → son bağlı Redmi**. Not: önceki oturumda
Note 11R'de Play'den kurulmuş kapalı beta vardı ve yerel imzalı derleme üzerine kurulamıyordu.
Bu oturumda **yeniden denenecek**; hâlâ engelse gerekçe raporda açıkça yazılacak ve Redmi Note 8
kullanılacak. Sahibinin telefonundaki Play kurulumu **izinsiz kaldırılmayacak**.

---

## 9. Her faz için değişmez döngü

```
kod → flutter analyze → flutter test → pnpm lint/typecheck/test → build
    → memory güncelle → commit → push → CI → cihazda doğrula → sonraki faz
```

## 10. Çıktılar

Yalnız iki belge: **bu yol haritası** ve **`PREMIUM_QUALITY_IMPLEMENTATION_REPORT.md`**.
`ASSET_GENERATION_LIBRARY.md` ve `MOBILE_PROJECT_MEMORY.md` **genişletilir**, yeni dosya açılmaz.
Faz raporu üretilmez.
