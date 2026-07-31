# Ehliyet Akademi — İçerik Genişleme Ana Planı

**Kapsam:** Faz 7 (soru genişleme yol haritası) · Faz 8 (görsel varlık hattı) · Faz 9 (özerk içerik sistemi)
**Tarih:** 1 Ağustos 2026 · **Durum:** plan + ölçüm. **Bu belge hiçbir soru üretmez** — üretimin
nasıl yapılacağını tanımlar.

---

## 0. Ölçülen başlangıç noktası

Aşağıdaki sayılar **depodan sayıldı**, tahmin değil.

| Ne                          | Sayı      | Kaynak                                       |
| --------------------------- | --------- | -------------------------------------------- |
| Toplam soru                 | **1.562** | `packages/question-bank/src/*.ts` (39 dosya) |
| · Trafik ve Çevre           | 380       |                                              |
| · Motor / Araç Tekniği      | 310       |                                              |
| · İlk Yardım                | 303       |                                              |
| · Pratik (direksiyon)       | 297       |                                              |
| · Trafik Adabı              | 272       |                                              |
| **GÖRSELLİ soru**           | **0**     | şemada `image` alanı **yok**                 |
| Trafik işareti içeriği      | 121       | `apps/web/content/signs.ts`                  |
| · Resmî vektörü olan        | 86        | `official_signs.dart`                        |
| · Resmî vektörü **olmayan** | **35**    | parametrik çizicide                          |
| Gösterge ikaz ışığı         | 60        | `assets/dash/` — **eksiksiz**                |
| Kabin/mekanik görseli       | 101       | `assets/mech/` — **eksiksiz**                |

### 0.1 En önemli bulgu — görselli soru **yapısal olarak imkânsız**

`Question` modelinde görsel alanı **yoktur**:

```dart
Question({ id, subject, topic, difficulty, stem, options, answerIndex, explanation, badge, whyWrong })
```

Uygulamada 81 işaret vektörü, 60 ikaz ışığı ve 101 mekanik görseli **var** — ama hepsi yalnız
**Öğren** bölümünde kullanılıyor. Soru bankası tamamen metindir.

Gerçek e-Sınav ise görsel ağırlıklıdır (levha okuma, kavşak önceliği, gösterge paneli). Yani
bugünkü bankanın kapsayamadığı bir soru ailesi var ve bu, **içerik değil şema** eksiğidir.
**Faz 7 buradan başlamalıdır**; şema açılmadan üretilecek her görselli soru yerini bulamaz.

---

# FAZ 7 — Soru genişleme yol haritası

## 7.1 Kural: önce ŞEMA, sonra içerik

Binlerce soru üretmeden önce altı tipin taşıyabileceği bir veri modeli gerekiyor. Önerilen
ek alan **geriye dönük uyumludur** (tümü isteğe bağlı) — mevcut 1.562 soru tek satır
değişmeden geçerli kalır:

```ts
media?: {
  kind: 'sign' | 'intersection' | 'mechanical' | 'dashboard' | 'firstaid' | 'scenario';
  assetId: string;      // varlık çözümleyicisinin kimliği (Faz 8)
  alt: string;          // ZORUNLU — ekran okuyucu + görsel yüklenmezse yedek metin
  focus?: string;       // "sağdaki araç", "kırmızı ikaz" — dikkat yönlendirme
}
```

**`alt` neden zorunlu:** görselli bir soruda görsel yüklenmezse soru cevaplanamaz hâle gelir.
Metin yedeği olmayan görselli soru, erişilebilirlik açısından da kullanılamaz (E8 gizlilik/erişim
ilkeleri). Şema bunu isteğe bağlı bırakırsa er geç `alt`sız soru girer.

**Doğrulama kapısı:** `media` varsa `assetId` çözümlenebilmeli. Bu, `pnpm verify`ye eklenecek bir
kontroldür; çözülmeyen varlık kimliği taşıyan soru **yayına giremez**.

## 7.2 Altı soru ailesi — üretim şablonları

Her aile için **zincir** aynıdır: görsel → soru → anlam → doğru davranış. Aşağıdaki tabloda her
ailenin ne ürettiği, hangi varlığa dayandığı ve mevcut durumu var.

### A. Trafik işareti soruları

```
Levha görseli → "Bu levha ne anlatır?" → anlamı → sürücünün yapması gereken
```

- **Varlık:** `assets/signs/<id>.svg` — **hazır** (86 resmî + 35 parametrik).
- **Üretilebilir soru:** 121 levha × 3 açı (tanı · anlam · davranış) = **~363 soru**.
- **Bugünkü engel:** yalnız şema. Varlık tarafında eksik **yok**.
- **Öncelik: 1** — en yüksek getiri/maliyet oranı; varlıklar zaten ödenmiş.

### B. Kavşak / öncelik soruları

```
Yol çizimi → kim önce geçer? → şerit → dönüş → yol verme
```

- **Varlık:** **YOK.** Kavşak şeması bulunmuyor.
- **Üretim biçimi:** **SVG olarak KOD** (AI raster değil) — gerekçe §8.2.
- **Parametrik üretilebilir:** kavşak tipi (ışıksız/ışıklı/dönel) × araç yerleşimi × öncelik
  kuralı. Tek bir şema bileşeninden yüzlerce varyant çıkar.
- **Öncelik: 2** — sınavda ağırlığı yüksek, bugün hiç yok.

### C. Araç tekniği / mekanik soruları

```
Gerçek görsel → "Bu parça nedir?" → görevi → arızasında ne olur
```

- **Varlık:** `assets/mech/` — **101 görsel hazır**.
- **Üretilebilir soru:** 101 × 2 (tanı · görev) = **~202 soru**.
- **Öncelik: 1** — varlık hazır, şema açılınca doğrudan üretilebilir.

### D. Gösterge paneli ikaz ışıkları

```
İkaz ışığı → "Bu ikaz ne demek?" → anlamı → sürücü ne yapmalı
```

- **Varlık:** `assets/dash/` — **60 görsel hazır**.
- **Üretilebilir soru:** 60 × 2 = **~120 soru**.
- **Öncelik: 1** — varlık hazır.

### E. İlk yardım soruları

```
Çizim → doğru işlem sırası → sonrasında ne olmalı
```

- **Varlık:** **YOK.**
- **Üretim biçimi:** AI görsel üretimi **uygun** (§8.2 "betimleyici" sınıfı) — ama tıbbi
  doğruluk **insan onayı** ister (§9.6).
- **Öncelik: 3** — yanlış ilk yardım görseli zararlıdır; hız değil doğruluk önceliklidir.

### F. Trafik senaryosu soruları

```
Gerçekçi çizim → karar → öncelik → risk analizi
```

- **Varlık:** **YOK.**
- **Üretim biçimi:** AI görsel üretimi uygun (sahne betimlemesi).
- **Öncelik: 3** — en pahalı, en yüksek sanatsal tutarlılık riski.

## 7.3 Sıralama ve hedef

| Sıra | Aile                        | Varlık durumu  | Tahmini soru | Ön koşul                   |
| ---- | --------------------------- | -------------- | ------------ | -------------------------- |
| 1    | İşaret · Mekanik · Gösterge | **hazır**      | ~685         | yalnız şema                |
| 2    | Kavşak                      | SVG üretilecek | ~200         | şema + şema bileşeni       |
| 3    | İlk yardım · Senaryo        | AI üretilecek  | ~200         | şema + varlık + tıbbi onay |

**Toplam potansiyel: ~1.085 görselli soru** — mevcut 1.562 metin sorusunun üzerine.

> **Neden "binlerce soru hemen" değil:** bugün 1.562 sorunun tamamı dört şıklı ve şemaya bağlı
> (Faz 11'de `.length(4)` kuralı konuldu). Kalite kapısı olmayan bir üretim, o kazanımı bir
> gecede geri alır. Hattın kendisi (Faz 9) kuruluncaya kadar üretim **kasıtlı olarak** yavaştır.

---

# FAZ 8 — Görsel varlık hattı

## 8.1 Önce ARA, sonra üret

Kural: yeni varlık üretmeden önce depoda aranır. Ölçüldü:

| Kategori         | İhtiyaç | Mevcut | Eksik | Karar                                         |
| ---------------- | ------- | ------ | ----- | --------------------------------------------- |
| Gösterge ışığı   | 60      | 60     | **0** | üretim **YOK** — hepsi var                    |
| Kabin / mekanik  | 101     | 101    | **0** | üretim **YOK** — hepsi var                    |
| Trafik işareti   | 121     | 86     | 35    | 14'ü üretilmeyecek (§8.3), 21'i vektörlenecek |
| Kavşak şeması    | ~40     | 0      | 40    | **SVG kod** olarak yazılacak                  |
| İlk yardım       | ~25     | 0      | 25    | AI üretimi                                    |
| Trafik senaryosu | ~30     | 0      | 30    | AI üretimi                                    |

**Bu denetimin kazancı:** 161 varlık için üretim talebi açılabilirdi; ölçüm sonrası gerçek
ihtiyaç **116**'ya indi ve bunun 21'i üretim değil **vektörleme** işi.

## 8.2 Varlık sınıflandırması — üretim aracını bu belirler

Bu ayrım ana plandaki en önemli mühendislik kararıdır.

| Sınıf                | Örnek                      | Doğru araç                     | Neden                                                                                                                                       |
| -------------------- | -------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Düzenlemeye tabi** | Trafik levhası, ikaz ışığı | **Resmî kaynaktan vektörleme** | Levhanın biçimi KGM standardıyla, ikaz ışığı ISO 2575 ile sabittir. AI'ın "uydurduğu" bir levha **yanlış öğretir** ve hukuken de yanlıştır. |
| **Şematik**          | Kavşak, öncelik, şerit     | **SVG olarak kod**             | Geometri anlamı taşır (kim nerede, kim önce). Raster üretimde araç sayısı/yönü tutarsız çıkar; kodda **deterministik** ve varyantlanabilir. |
| **Betimleyici**      | İlk yardım, trafik sahnesi | **AI görsel üretimi**          | Tam biçim önemli değil, anlaşılırlık önemli. Üretim burada gerçekten kazandırır.                                                            |

> **AI ile levha üretilmez.** Bu, "yapabiliriz ama yapmamalıyız" kararıdır: modelin ürettiği
> bir "dur" levhası gerçeğe %95 benzese bile, ehliyet öğreten bir üründe %5 sapma kabul edilemez.

## 8.3 Üretilmeyecek 14 varlık — parametrik çizici zaten DOĞRU

Eksik görünen 35 levhanın 14'ü sayı-parametrik hız levhasıdır:

```
azami-hiz-20 · 30 · 40 · 50 · 60 · 70 · 80 · 90 · 100 · 110 · 120   (11)
asgari-hiz-30 · 40 · 50                                              (3)
```

Bunlar **kırmızı/mavi daire + sayı**dır. `TrafficSignView` parametrik çizicisi bunu zaten
üretiyor ve sonuç raster üretimden **daha iyi**: her ölçekte keskin, sayı veriden geliyor, yeni
bir hız sınırı eklemek varlık değil **veri** işi.

**Karar: bu 14 için varlık ÜRETİLMEYECEK.** (Bir üretim hattının en değerli çıktısı bazen
"bunu üretme" demesidir.)

## 8.4 Vektörlenecek 21 resmî levha

Aşağıdakiler resmî karşılığı olan ama vektörü çıkarılmamış levhalar. **Kaynak: KGM 2020 standart
levha kataloğu / İBB posterleri** (E1'de kullanılan aynı kaynak). Araç: kaynaktan izleme, AI değil.

```
kaygan-yol · tehlikeli-viraj-sag · dik-cikis · vahsi-hayvan
park-yasak · park-yasagi-sonu · park-saat-sinirli · engelli-parki
yukseklik-siniri · hiz-siniri-sonu · tum-yasaklarin-sonu
saga-donus-mecburi · sola-donus-mecburi
devlet-yolu · motorlu-tasit-yolu · otoyol-cikisi · otoyol-cikisi-300m
lokanta · taksi-duragi · tunel · havalimani
```

**Ortak spesifikasyon (21 varlığın tamamı için):**

| Alan         | Değer                                               |
| ------------ | --------------------------------------------------- |
| Klasör       | `apps/mobile/assets/signs/`                         |
| Dosya adı    | `<id>.svg` (yukarıdaki id'ler birebir)              |
| Kategori     | `signs` — düzenlemeye tabi                          |
| Amaç         | Levha tanıma sorusu + Öğren galerisi                |
| Üretim aracı | **Vektörleme** (Inkscape/`potrace` + elle temizlik) |
| Çözünürlük   | Vektör — `viewBox="0 0 100 100"`                    |
| Arka plan    | **Şeffaf**                                          |
| En-boy oranı | 1:1                                                 |
| Kabul ölçütü | KGM kataloğundaki renk kodları ve oranlarla birebir |

## 8.5 Üretilecek varlıklar — tam spesifikasyon

Aşağıdaki tablo, **AI üretimi uygun olan** varlıklar için istenen sekiz alanı taşır. Sahne
varlıkları için ortak stil sözleşmesi:

> **Stil sözleşmesi (tüm betimleyici varlıklar):** düz (flat) vektör-benzeri illüstrasyon,
> kalın okunaklı konturlar, sınırlı palet (uygulamanın turkuaz/amber tokenlarıyla uyumlu),
> **metin YOK** (metin uygulamada widget olarak gelir — yerelleştirilebilir kalmalı ve
> `design_tokens_test` renk kuralına takılmamalı), gerçek marka/logo YOK, tanınabilir gerçek
> kişi YOK.

### 8.5.1 İlk yardım (25 varlık) — örnek üç tam spesifikasyon

| Alan       | `firstaid-recovery-position`                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Klasör     | `apps/mobile/assets/firstaid/`                                                                                                                                                                                                                                                                                                                                                                                                               |
| Kategori   | `firstaid` — betimleyici                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Amaç       | "Bilinci kapalı ama solunumu olan kazazede nasıl yatırılır?" sorusunun görseli                                                                                                                                                                                                                                                                                                                                                               |
| **Prompt** | `Flat vector illustration, thick clean outlines, limited palette of teal and warm amber on transparent background. A single unconscious adult lying on their side in the recovery position: head tilted back and resting on the lower arm, upper knee bent forward at 90 degrees for stability, airway open. Neutral clothing, no logos, no text, no facial detail beyond simple features. Side view, full body, centered, generous margin.` |
| Çözünürlük | 1024×768                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Arka plan  | **Şeffaf** (PNG → derlemede WebP'ye çevrilir)                                                                                                                                                                                                                                                                                                                                                                                                |
| En-boy     | 4:3                                                                                                                                                                                                                                                                                                                                                                                                                                          |

| Alan       | `firstaid-bleeding-pressure`                                                                                                                                                                                                                                                                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Klasör     | `apps/mobile/assets/firstaid/`                                                                                                                                                                                                                                                                                                                                     |
| Kategori   | `firstaid`                                                                                                                                                                                                                                                                                                                                                         |
| Amaç       | Dış kanamada doğrudan basınç uygulama adımı                                                                                                                                                                                                                                                                                                                        |
| **Prompt** | `Flat vector illustration, thick clean outlines, limited teal and amber palette, transparent background. Close-up of two gloved hands pressing a folded sterile gauze firmly onto a bleeding forearm wound of another person. The injured arm is raised above heart level. No blood spray, restrained depiction, no text, no logos. Three-quarter view, centered.` |
| Çözünürlük | 1024×768                                                                                                                                                                                                                                                                                                                                                           |
| Arka plan  | Şeffaf                                                                                                                                                                                                                                                                                                                                                             |
| En-boy     | 4:3                                                                                                                                                                                                                                                                                                                                                                |

| Alan       | `firstaid-heimlich-adult`                                                                                                                                                                                                                                                                                                                                        |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Klasör     | `apps/mobile/assets/firstaid/`                                                                                                                                                                                                                                                                                                                                   |
| Kategori   | `firstaid`                                                                                                                                                                                                                                                                                                                                                       |
| Amaç       | Yetişkinde tam tıkanmada Heimlich manevrası                                                                                                                                                                                                                                                                                                                      |
| **Prompt** | `Flat vector illustration, thick clean outlines, limited teal and amber palette, transparent background. A rescuer standing behind a choking adult, arms wrapped around the abdomen just above the navel, one fist grasped by the other hand, performing an inward and upward thrust. Both figures upright, side-rear view, simple features, no text, no logos.` |
| Çözünürlük | 1024×1024                                                                                                                                                                                                                                                                                                                                                        |
| Arka plan  | Şeffaf                                                                                                                                                                                                                                                                                                                                                           |
| En-boy     | 1:1                                                                                                                                                                                                                                                                                                                                                              |

> Kalan 22 ilk yardım varlığı aynı tabloyla üretilir; konu listesi `ilkyardim` sorularının
> `topic` alanından **türetilir** (elle liste yazılmaz — §9.2).

### 8.5.2 Trafik senaryosu (30 varlık) — örnek iki tam spesifikasyon

| Alan       | `scenario-uncontrolled-intersection-right`                                                                                                                                                                                                                                                                                                                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Klasör     | `apps/mobile/assets/scenario/`                                                                                                                                                                                                                                                                                                                                                                                                              |
| Kategori   | `scenario` — betimleyici                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Amaç       | Işıksız kavşakta sağdan gelene yol verme kararı                                                                                                                                                                                                                                                                                                                                                                                             |
| **Prompt** | `Flat vector illustration, top-down three-quarter perspective, thick outlines, limited teal/amber/grey palette, plain light background. An uncontrolled four-way intersection with no traffic lights and no signs. A blue car approaches from the bottom heading north; a red car approaches from the right heading west. Clear lane markings, empty sidewalks. No text, no license plates, no brand logos, no recognizable real vehicles.` |
| Çözünürlük | 1200×900                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Arka plan  | Düz açık zemin (şeffaf değil — sahne bütünlüğü için)                                                                                                                                                                                                                                                                                                                                                                                        |
| En-boy     | 4:3                                                                                                                                                                                                                                                                                                                                                                                                                                         |

| Alan       | `scenario-pedestrian-crossing-night`                                                                                                                                                                                                                                                                                                                                      |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Klasör     | `apps/mobile/assets/scenario/`                                                                                                                                                                                                                                                                                                                                            |
| Kategori   | `scenario`                                                                                                                                                                                                                                                                                                                                                                |
| Amaç       | Gece yaya geçidinde hız ve görüş mesafesi riski                                                                                                                                                                                                                                                                                                                           |
| **Prompt** | `Flat vector illustration, driver's point of view from inside a car at night, thick outlines, limited palette with teal highlights on dark background. A zebra crossing ahead lit by headlights; a pedestrian is stepping onto the crossing from the right, partially outside the headlight cone. Wet asphalt reflections. No text, no brand logos, no readable signage.` |
| Çözünürlük | 1200×675                                                                                                                                                                                                                                                                                                                                                                  |
| Arka plan  | Koyu sahne (şeffaf değil)                                                                                                                                                                                                                                                                                                                                                 |
| En-boy     | 16:9                                                                                                                                                                                                                                                                                                                                                                      |

### 8.5.3 Kavşak şemaları (40 varlık) — **prompt YOK, kod var**

Bunlar üretilmez, **yazılır**. Bir `IntersectionDiagram` widget'ı parametre alır:

```dart
IntersectionDiagram(
  type: IntersectionType.uncontrolled,   // uncontrolled | signalised | roundabout | tJunction
  vehicles: [Vehicle(from: Side.south, to: Side.north, color: VehicleColor.blue), ...],
  highlight: Side.east,
)
```

**Neden kod:** 40 şemanın her biri elle üretilseydi araçların yönü/rengi/konumu insan hatasına
açık olurdu ve bir kural değişince 40 dosya yeniden üretilirdi. Kodda tek bileşen değişir.
Ayrıca şema **temaya uyar** (açık/koyu) ve ekran okuyucuya `alt` üretir.

## 8.6 Varlığın kod değişmeden kullanılması — **uygulandı**

Bu fazda `lib/core/asset_resolver.dart` yazıldı ve testle kapı altına alındı.

**Önceki durum:** `official_signs.dart`, `dash_assets.dart`, `mech_assets.dart` elle yazılmış
`id → yol` tabloları taşıyordu. `pubspec.yaml` klasörün tamamını bildirdiği için klasöre bırakılan
dosya **pakete giriyor** ama tabloya satır eklenmedikçe **kullanılmıyordu**. Yani üretim hattının
çıktısı kod değişmeden ürüne ulaşamıyordu.

**Şimdiki davranış:**

1. **Sözleşme:** `assets/<kategori>/<id>.<uzantı>` paketteyse **o kullanılır** (svg → webp → png).
2. **İstisna tablosu:** dosya adı kimlikten farklıysa (resmî levha kodları: `agirlik-siniri` →
   `tt-24.svg`) mevcut tablo devreye girer.
3. Sözleşmeye uyan **yeni** dosya, eski istisna satırını **geçersiz kılar** — varlık yenilemek
   için tablo düzenlemek gerekmez.

**Dürüst sınır:** Flutter varlıkları **derleme zamanında** gömülür. Verilen söz "kod değişmeden
kullanılır"dır; "kurulu uygulamaya dosya eklenince görünür" **değildir** — öyle bir şey mümkün
değil. Yeni varlık için **yeniden derleme şarttır**.

## 8.7 Yeni kategoriler için yapılacak tek yapılandırma

`apps/mobile/pubspec.yaml` içine iki satır (klasör bazlı, dosya bazlı değil):

```yaml
assets:
  - assets/img/
  - assets/signs/
  - assets/mech/
  - assets/dash/
  - assets/firstaid/ # YENİ
  - assets/scenario/ # YENİ
```

Bundan sonra o klasörlere bırakılan her dosya otomatik paketlenir ve çözümleyici tarafından
bulunur.

---

# FAZ 9 — Özerk içerik genişleme hattı

## 9.1 Hattın tamamı

```
Araştırma → Boşluk tespiti → Varlık tespiti → Prompt üretimi
   → Soru yazımı → Kalite denetimi → Taslak → Onay → Yayın
```

Her adımın **girdisi**, **çıktısı** ve **durma koşulu** aşağıda. Hiçbir adım "model iyi yapar"
varsayımına bırakılmamıştır.

## 9.2 Adım adım

### 1) Araştırma

- **Girdi:** MEB/MTSK müfredat başlıkları, geçmiş e-Sınav dağılımı (`examDistribution`).
- **Çıktı:** konu × ağırlık tablosu.
- **Kural:** ağırlık **uydurulmaz**; sınavın gerçek dağılımından gelir (kod tabanında zaten var).

### 2) Boşluk tespiti — **otomatik**

- **Girdi:** soru bankası + konu × ağırlık tablosu.
- **Çıktı:** "hangi konuda kaç soru eksik" listesi.
- **Uygulama:** bu iş için depoda zaten bir araç var — `packages/question-bank` `gaps` testleri ve
  `apps/web/lib/qip/gaps.ts`. Hat bunu **yeniden yazmaz**, çağırır.
- **Durma koşulu:** hedef dağılıma ulaşıldıysa üretim **durur**. Sonsuz üretim bir hedef değildir.

### 3) Varlık tespiti — **üretmeden önce ARA**

- **Girdi:** üretilecek soru tipi + konu.
- **Çıktı:** "bu soru için varlık var mı?" → varsa kimlik, yoksa üretim talebi.
- **Uygulama:** `AssetCatalog.resolve()` (Faz 8). §8.1'deki denetim tam olarak bu adımın elle
  koşturulmuş hâliydi ve ihtiyacı 161'den 116'ya indirdi.

### 4) Prompt üretimi

- **Girdi:** eksik varlık kimliği + kategori.
- **Çıktı:** §8.5 şablonuna uyan sekiz alanlı spesifikasyon.
- **Kural:** kategori **düzenlemeye tabi** ise prompt üretilmez, **vektörleme görevi** açılır
  (§8.2). Bu kontrol hatta gömülüdür; insan hatırlamak zorunda kalmaz.

### 5) Soru yazımı

- **Girdi:** konu + varlık + zorluk hedefi.
- **Çıktı:** taslak soru (`stem`, 4 şık, `answerIndex`, `explanation`, `whyWrong`, `media.alt`).
- **Değişmez kurallar:** tam **dört** şık (şemada `.length(4)`), tek doğru cevap, açıklama
  zorunlu, görselli soruda `alt` zorunlu.

### 6) Kalite denetimi — **makine**

Otomatik reddedilenler:

| Kontrol                                   | Neden                                             |
| ----------------------------------------- | ------------------------------------------------- |
| Şık sayısı ≠ 4                            | Faz 11'de kapatılan kusur; geri gelmemeli         |
| Çift/çelişkili doğru cevap                | Şıklar arası anlam çakışması                      |
| Kopya soru (benzerlik eşiği)              | Bankada aynı sorunun ikinci hâli                  |
| `media.assetId` çözülmüyor                | Görsel olmayan görselli soru                      |
| `alt` boş                                 | Erişilebilirlik + görsel yüklenmezse cevaplanamaz |
| Açıklama boş / şıkkı tekrarlıyor          | Öğretmeyen açıklama                               |
| Mevzuat sayısı içeriyor (hız, ceza, süre) | **İnsan onayına zorlar** — sayı eskir             |

### 7) Taslak

- Soru `draft` durumunda veritabanına yazılır. **Uygulamaya gitmez.**
- Depoda bu hat zaten var: `draft → in_review → approved → published`
  (`api.admin.integration.test.ts` bunu koşuyor). Hat **yeniden kurulmaz**, kullanılır.

### 8) Onay — **insan, ve pazarlık edilemez**

- İlk yardım ve mevzuat soruları **konu uzmanı** onayı ister.
- Diğerleri editör onayı ister.
- **Kural:** hiçbir soru insan onayı olmadan `published` olamaz. Bu, hattın "özerk" olmadığı tek
  yerdir ve bilinçlidir: yanlış bir ilk yardım bilgisi, yavaş bir içerik hattından **çok** daha
  pahalıdır.

### 9) Yayın

- `published` → `/api/mobile/question-bank` → uygulama çevrimdışı önbelleğe alır.
- Yayın sonrası **ölçüm**: sorunun doğru cevaplanma oranı. %95 üstü (çok kolay) ya da %25 altı
  (muhtemelen hatalı/çeldirici bozuk) sorular **incelemeye geri düşer**.

## 9.3 Hattın özerklik sınırı — dürüstçe

| Adım            | Özerk mi?                        |
| --------------- | -------------------------------- |
| Araştırma       | ✅ tam                           |
| Boşluk tespiti  | ✅ tam                           |
| Varlık tespiti  | ✅ tam                           |
| Prompt üretimi  | ✅ tam                           |
| Soru yazımı     | ✅ tam                           |
| Kalite denetimi | ✅ tam (makine kuralları)        |
| Taslak          | ✅ tam                           |
| **Onay**        | ❌ **insan** — pazarlık edilemez |
| Yayın           | ✅ onay sonrası otomatik         |

"Özerk hat" **onaya kadar** özerktir. Bunu "tam otomatik içerik üretimi" diye anlatmak yanlış
olurdu.

## 9.4 Ölçüler — hattın kendisi ölçülür

| Ölçüt                          | Neden                                                |
| ------------------------------ | ---------------------------------------------------- |
| Taslak → onay geçme oranı      | Düşükse üretim kalitesi kötü, hat boşa çalışıyor     |
| Onaydan dönme sebebi dağılımı  | En sık sebep, hattın bir sonraki düzeltmesini söyler |
| Yayın sonrası incelemeye düşme | Makine kapısının kaçırdıklarını gösterir             |
| Konu kapsama açığı             | Hedefe ne kadar kaldı                                |

## 9.5 Bu fazda ÜRETİLMEYEN şey

Bu belge **hiçbir soru ve hiçbir görsel üretmedi** — istenen buydu. Üretilen: ölçüm, sınıflandırma,
şablonlar, karar kuralları ve varlık çözümleyicisinin **çalışan kodu**.

## 9.6 Bilinen riskler

1. **Tıbbi doğruluk.** İlk yardım görselleri ve soruları yanlış olursa zarar verir. Bu yüzden
   öncelik sırasında en sonda ve insan onayı zorunlu.
2. **Mevzuat eskimesi.** Hız sınırları, ceza tutarları ve süreler değişir. Sayı içeren sorular
   işaretlenir ve dönemsel gözden geçirmeye girer.
3. **Sanatsal tutarsızlık.** 30 sahne görseli farklı zamanlarda üretilirse üslup kayar. Stil
   sözleşmesi (§8.5) bunun içindir; yine de partiler hâlinde üretilmeli ve birlikte incelenmeli.
4. **Aşırı üretim.** Hedefsiz üretim bankayı şişirir, kaliteyi düşürür. Durma koşulu (§9.2/2)
   bunun panzehiridir.
