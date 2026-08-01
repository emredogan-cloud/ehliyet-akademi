# Ehliyet Akademi — Soru Motoru Yol Haritası (QIP v3)

**Tarih:** 1 Ağustos 2026 · **Taban:** `d8f20e5` · **Durum:** Faz 0 denetimi tamamlandı
**Tek yol haritası. Tek uygulama raporu.** (`QUESTION_ENGINE_IMPLEMENTATION_REPORT.md`)

---

## 0. Denetim — ne VAR, ne YOK

Aşağıdaki her satır depodan okundu.

### 0.1 Web tarafı (QIP v1/v2) — **olgun**

`apps/web/lib/qip/` altında **19 modül · 4.626 satır**, hepsi testli:

| Modül                 | Ne yapıyor                                                               | Durum |
| --------------------- | ------------------------------------------------------------------------ | ----- |
| `normalize.ts`        | `Question` → `NormalizedQuestion` (kategori, tahmini süre, parmak izi)   | ✅    |
| `categorize.ts` (418) | 32 kesişen tema; 1132/1534 soru bir temaya bağlı                         | ✅    |
| `quality.ts`          | `scoreQuality` — 0–100 puan + kırılım                                    | ✅    |
| `dedup.ts`            | Jaccard benzerliği (eşik 0,82) + parmak izi                              | ✅    |
| `families.ts`         | Kavram aileleri (aynı aileden iki soru aynı sınava girmesin)             | ✅    |
| `exam.ts`             | `buildDynamicExam` — dağılım, zorluk dengesi, aile/görsel tekrarı engeli | ✅    |
| `adaptive.ts`         | `weakTopicsFrom` + `adaptiveSelect`                                      | ✅    |
| `historical.ts`       | Gerçek MEB oturum TARİHİ → o tarihten tohumlanmış ÖZGÜN sınav            | ✅    |
| `archive.ts`          | 18 gerçek oturum tarihi (yalnız olgu)                                    | ✅    |
| `visual.ts`           | İşaret kataloğundan görsel "anlamı nedir?" soruları                      | ✅    |
| `gaps.ts` `growth.ts` | Boşluk tespiti, büyüme ölçümü                                            | ✅    |
| `review.ts`           | Otomatik gözden geçirici                                                 | ✅    |
| `analytics.ts`        | Soru başına istatistik                                                   | ✅    |

### 0.2 Şema — iki katman

```
Question           (yazılmış banka)  — id, subject, topic, difficulty, stem, options(4),
                                        answerIndex, explanation, badge, whyWrong,
                                        objective?, tags[], review, reviewedBy?, sourceRef?
                                        ⛔ GÖRSEL ALANI YOK

NormalizedQuestion (QIP katmanı)     — Question + category, subcategory, learningOutcome,
                                        relatedLesson, relatedSigns[], relatedVehicleParts[],
                                        estimatedSeconds, commonMistakes[],
                                        ✅ image?, video?, source, qualityScore?, fingerprint, version
```

`NormalizedQuestion` **zaten** görsel, kaynak metaverisi, kalite puanı ve sürüm taşıyor.

### 0.3 Veritabanı — 31 tablo

Yazarlık hattı için gereken tablolar **zaten var**:
`content_items` (type=`question`, status `draft→in_review→approved→published→retired`, `payload`
JSONB Zod-doğrulamalı, `version`) · `content_versions` · `media_assets` · `audit_logs` ·
`analytics_events`.

**Yazılmış 1.562 soru veritabanında DEĞİL** — `packages/question-bank/src/*.ts` içinde **kodda**
duruyor. Bu bilinçli: mobil banka çevrimdışı ve tek dosyada sevk ediliyor.

### 0.4 ⛔ ASIL BULGU — olgun platform kullanıcıya ULAŞMIYOR

Ürün **mobil uygulamadır** ve çevrimdışı-öncelikli çalışır: pratik, sınav, SRS'in tamamı Dart'ta,
cihazda koşar. Zincir şurada kopuyor:

```
visual.ts 121 görsel soru üretebiliyor
        ↓
NormalizedQuestion.image  ✅ var
        ↓
/api/mobile/question-bank → lean()  ⛔ image ALANINI DÜŞÜRÜYOR
        ↓
Mobil Question modeli     ⛔ image alanı YOK
        ↓
Kullanıcı                 ⛔ TEK BİR GÖRSEL SORU GÖRMÜYOR
```

`lean()` projeksiyonu (route.ts) yalnız şu alanları geçiriyor:
`id, subject, topic, difficulty, stem, options, answerIndex, explanation, badge, whyWrong`.

**Sonuç:** 1.562 sorunun **%100'ü metin**. Uygulamada 81 işaret vektörü + 60 ikaz ışığı + 101
mekanik görseli var — hepsi yalnız **Öğren** bölümünde. Gerçek e-Sınav görsel ağırlıklıdır.

### 0.5 Mobil sınav üreteci — web'in çok gerisinde

| Yetenek               | Web `buildDynamicExam` | Mobil `buildExam` |
| --------------------- | :--------------------: | :---------------: |
| MEB dağılımı          |           ✅           |        ✅         |
| Zorluk dengesi        |           ✅           |        ❌         |
| Aile tekrarı engeli   |           ✅           |        ❌         |
| Görsel tekrarı engeli |           ✅           |        ❌         |
| Şık karıştırma        |           ✅           |        ❌         |
| Zayıf konu önceliği   |    ✅ (`adaptive`)     |        ❌         |
| Yapılandırılabilirlik |           ✅           |        ❌         |
| Kip (mod) desteği     |           ✅           |        ❌         |

Mobil üreteç: dersten payı kadar rastgele al, karıştır. Hepsi bu.

### 0.6 Faz 6 (Tarihsel sınav) — **istenen şey ZATEN YAPILMIŞ**

Sprint'in Faz 6'da tarif ettiği sistem birebir mevcut, hem web hem mobilde:
gerçek oturum **tarihi** (olgu) → o tarihten tohumlanmış **özgün** sınav → açık etiket
_"MEB formatında hazırlanmış özgün deneme sınavı"_. Kopyalanan soru **yok**.

**Karar: yeniden yazılmayacak.** Eksiği görsel yoğunluk ve kip yapılandırması; o da Faz 5'in
işidir.

---

## 1. Bu sprintin tezi

> Platform eksik değil — **bağlı değil.** Sprintin işi yeni bir QIP kurmak değil, olgun QIP'i
> ürüne ulaştırmak ve mobil motoru web seviyesine çıkarmaktır.

Bu, "yeni özellik" değil **kanal açma** işidir ve en yüksek getirili iş budur: hazır varlıklardan
(121 işaret + 60 ikaz + 101 mekanik) **kod değişmeden yüzlerce özgün görsel soru** üretilebilir
hâle gelir.

---

## 2. Faz planı

### Faz 1 — Soru modeli evrimi ⭐ temel

`kind` ayırıcısı + `media` bloğu, **geriye dönük tam uyumlu** (hepsi opsiyonel):

```ts
kind?: 'text' | 'image' | 'scenario' | 'diagram' | 'intersection'
     | 'sign' | 'mechanic' | 'dashboard'          // varsayılan 'text'
media?: {
  images: Array<{ assetId: string; alt: string; caption?: string;
                  hotspots?: Array<{ id, x, y, w, h, label }> }>;   // ÇOKLU görsel
  layout?: 'single' | 'grid' | 'compare';
}
generation?: { generator: string; version: number; seed?: number; generatedAt?: string }
```

**Kurallar:** `media` varsa `alt` **zorunlu** (görsel yüklenmezse soru cevaplanamaz);
`assetId` çözümlenebilmeli; `kind` verilmezse `text`. Mevcut 1.562 soru **tek satır değişmeden**
geçerli kalır.

Hotspot alanı **bugün çizilmiyor** — şemada yer tutuyor ki ileride şema göçü gerekmesin.

### Faz 2 + 4 — Görsel soru sistemi (uçtan uca) ⭐ asıl kazanç

1. **Varlık önce ARANIR** (`AssetCatalog`, önceki sprint) — varsa yeniden kullanılır.
2. Yoksa **Varlık Kataloğu'na kaydedilir** (eksik olarak işaretlenir).
3. Hâlâ yoksa **GPT Image istemi üretilir** — **kimliğe göre tekilleştirilmiş**, aynı varlık için
   ikinci istem üretilmez.
4. Üretilen sorular `lean()`'den **geçer** ve mobilde **çizilir**.

Kaynak katalogları (hepsi özgün, hepsi doğrulanmış):

| Katalog        | Adet | Soru açısı            | Üretilebilir |
| -------------- | ---- | --------------------- | ------------ |
| Trafik işareti | 121  | anlam · davranış      | ~242         |
| İkaz ışığı     | 60   | anlam · sürücü eylemi | ~120         |
| Mekanik        | 101  | parça adı · görevi    | ~202         |

**Toplam ~564 özgün görsel soru** — varlık üretimi **gerekmeden**.

### Faz 3 — Banka genişlemesi (dürüst kapsam)

Sprint "her dersi genişlet" diyor. Bu sprintte yapılabilecek **özgün** genişleme, Faz 2/4'ün
ürettiği **~564 görsel sorudur**: kaynağı bizim doğrulanmış kataloglarımız, ifadesi bizim,
kopya yok.

**Yapılmayacak olan:** binlerce yeni **metin** sorusunun tek oturumda yazılması. Bir soruyu
gerçekten yazmak (kazanım, dört şık, çeldirici mantığı, açıklama, `whyWrong`) içerik işidir;
model üretimini kalite kapısından geçirmeden bankaya basmak, Faz 11'de kazanılan
"her soru dört şıklı ve şemaya bağlı" güvencesini bir gecede geri alır. Hat (Faz 8/9) bunun için
kuruluyor.

### Faz 5 — Sınav Üreteci V2 (mobil) ⭐

Mobil üreteç web seviyesine çıkarılır ve **yapılandırılabilir** olur:

```dart
ExamConfig(
  mode: ExamMode.exam | practice | quick | random | historical | adaptive,
  count, subjects?, difficultyBalance, avoidSameFamily, noRepeatImage,
  randomizeChoices, visualRatio, weakTopics, seed,
)
```

- **Zorluk dengeleme** · **konu dengeleme** · **tekrar engeli** (aile + görsel)
- **Zayıf konu önceliği** (cihazdaki gerçek cevap geçmişinden)
- **Görsel soru enjeksiyonu** — `visualRatio` ile
- **Kipler:** sınav (50/45dk) · pratik · hızlı (10) · rastgele · tarihsel · uyarlanabilir

### Faz 7 — Kalite motoru

Mevcut `quality.ts`/`validate.ts`/`dedup.ts` **medyayı bilmiyor**. Genişletilir:

kopya · yakın kopya (Jaccard) · şık sayısı ≠ 4 · açıklama eksik/zayıf · **görsel eksik** ·
**bozuk varlık** (çözülmeyen `assetId`) · **`alt` eksik** · geçersiz etiket · zorluk dengesizliği ·
konu dengesizliği.

**Her yeni soru bu kapıdan geçer.**

### Faz 6 — Tarihsel deneyim

**Zaten var** (§0.6). Bu sprintte yalnız Faz 5'in kip yapılandırması ve görsel yoğunluğu
devralır.

### Faz 8 — Yazarlık hattı

Altyapı **zaten var**: `content_items` + durum geçişleri + `api.admin.integration.test.ts`
(`draft → in_review → approved` akışını koşuyor). Bu sprintte **belgelenir** ve kalite kapısı
(Faz 7) hattın `in_review` adımına bağlanır. Yeni tablo **gerekmiyor**.

### Faz 9 — AI içerik hattı

`CONTENT_EXPANSION_MASTERPLAN.md` §9'da tasarlandı. Bu sprintte **çalışan parçası** teslim edilir:
boşluk tespiti (`gaps.ts` mevcut) → varlık arama (`AssetCatalog` mevcut) → **istem üretimi
(tekilleştirilmiş)** → taslak → kalite → insan onayı.

**Onay insanda kalır** — pazarlık edilemez.

### Faz 10 — Cihaz doğrulaması

Dersler · görsel sorular · sınav üretimi · tarihsel · rastgele · uyarlanabilir · AI Koç ·
Akıllı Çalışma.

---

## 3. Veritabanı göçü — gerekli mi?

**Hayır, zorunlu değil.** Gerekçe:

- Yazılmış banka **kodda** duruyor (çevrimdışı sevk için bilinçli) → şema alanı eklemek göç değil,
  tip değişikliğidir.
- `content_items.payload` **JSONB** ve Zod ile doğrulanıyor → yeni alanlar **göçsüz** girer.
- Yazarlık hattı tabloları (`content_items`, `content_versions`, `media_assets`) zaten mevcut.

**Göç yapılacak tek yer** varlık kataloğu kalıcılığı olurdu; o da bu sprintte **kod tarafında**
(derleme zamanı varlık listesi) çözüldüğü için gereksiz. Göç gerekirse rapora yazılır — gereksiz
göç yapılmaz.

---

## 4. Sıra ve gerekçe

| #   | Faz           | Neden bu sırada                             |
| --- | ------------- | ------------------------------------------- |
| 1   | Model evrimi  | Diğer her şeyin taşıyıcısı                  |
| 2   | Görsel sistem | En yüksek getiri; varlıklar hazır           |
| 3   | Üreteç V2     | Görsel sorular üretilmeden enjekte edilemez |
| 4   | Kalite motoru | Üretilen içeriği kapıdan geçirir            |
| 5   | Hat belgeleme | Kod bittikten sonra                         |
| 6   | Cihaz         | Hepsinin gerçekten çalıştığını gösterir     |

---

## 5. Başarı ölçütü

Sprint şu doğrulandığında başarılıdır:

1. Mobil kullanıcı **cihazda görsel soru görüyor** (bugün: sıfır).
2. Sınav üreteci **yapılandırılabilir** ve zayıf konuyu önceliklendiriyor.
3. Kalite kapısı **bozuk varlık taşıyan soruyu reddediyor**.
4. Mevcut 1.562 soru ve tüm testler **kırılmadan** çalışıyor.
5. `flutter analyze` 0 · tüm testler yeşil · CI yeşil · cihazda doğrulandı.
