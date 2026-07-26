# Evolution Phase 12 Report — Video Content Production

**Phase Group 7 · Video.** _Prepared: 2026-07-26 · Mevcut üretim hattı genişletildi ·
device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

Manevra seti tamamlandı ve üretim hattı premium standarda çıkarıldı. Oynatılabilir video sayısı
**2 → 7**; gerçekten gerçek çekim gerektiren **2** başlık dürüstçe `planned` kaldı.

web **484** (+5) · `flutter analyze` **0** · `flutter test` **265** (+2) · E2E yeşil ·
video varlıkları toplam **2,2 MB**.

## 1. Üretim hattı — premium standart

| Ölçüt            | Önce           | Sonra                                        |
| ---------------- | -------------- | -------------------------------------------- |
| Çözünürlük       | 840×480        | **1120×640**                                 |
| Kare hızı        | 12 fps         | **30 fps**                                   |
| Araç görseli     | düz dikdörtgen | tekerlek + cam + far ayrıntısı               |
| Adım etiketi     | yok            | **videonun içine gömülü**, bölümle eşzamanlı |
| Altyazı (VTT)    | elle yazılı    | **hattan üretilir**                          |
| Bölüm/transkript | elle yazılı    | **hattan üretilir**                          |
| Renkler          | serbest        | tasarım token'ları                           |

## 2. Mimari kararı — tek kaynak

Roadmap E12 için şu riski işaretlemişti: **"render hattının sahne kaynağından sapması."**
Bölüm/altyazı verisi elle, ayrı dosyalarda tutulursa er geç videoyla uyuşmaz.

Çözüm: `scripts/video-scenes.mjs` artık **tek kaynak** — her sahne görüntüyü (svg+css), bölümleri
ve altyazıyı birlikte taşır. `render-video.mjs` bu tek nesneden şunları üretir:

```
public/videos/<id>.mp4 · <id>.webm · <id>-poster.jpg · <id>.tr.vtt
content/videos.generated.ts   (süre + bölümler + transkript)
```

`content/videos.ts` üretilmiş veriyi `animated()` yardımcısıyla kullanır. Böylece video, katalog ve
altyazı arasında sapma **yapısal olarak imkânsızdır** — testle değil, kurguyla.

Test bunu ayrıca kilitliyor: her oynatılabilir videonun VTT damgaları transkript zamanlarıyla
birebir eşleşmek zorunda.

## 3. Üretilen içerik

**Roadmap'in istediği manevra seti — tamamı üretildi:**

| Video           | Süre  | Bölüm | Konu                         |
| --------------- | ----- | ----- | ---------------------------- |
| `parallel-park` | 12 sn | 4     | Paralel park (yükseltildi)   |
| `l-park`        | 13 sn | 4     | **L park / dik park (yeni)** |
| `u-turn`        | 12 sn | 4     | **U dönüşü (yeni)**          |
| `reverse-25m`   | 12 sn | 4     | **25 m geri gidiş (yeni)**   |

**`planned` listesinden animasyona çevrilenler:**

| Video             | Süre  | Bölüm | Not                                                         |
| ----------------- | ----- | ----- | ----------------------------------------------------------- |
| `hill-start`      | 12 sn | 4     | El freni → kavrama noktası → gaz sırası; geri kayma uyarısı |
| `common-mistakes` | 14 sn | 3     | Üç hata, her birinin yanında **doğrusu** gösteriliyor       |
| `right-of-way`    | 10 sn | 4     | Kavşakta sağdan gelen (yükseltildi)                         |

## 4. Dürüstlük — en önemli karar

`hill-start` ve `common-mistakes` katalogda **"(Gerçek Çekim)"** olarak duruyordu:
"pedal kamerasıyla gösterim" ve "sınavda en sık 10 hata". Ürettiğim animasyon bunların aynısı
**değil** — biri pedal görüntüsü, diğeri on ayrı sınav anı vaat ediyordu.

Bu yüzden animasyonu bu vaatlerin üstüne koymadım; **başlık ve açıklamaları gerçekte ne
gösterdiklerini söyleyecek biçimde yeniden yazdım**:

- "Yokuşta Kalkış — Adım Adım (Animasyon)" · açıklamada _pedal kamerasıyla gerçek çekim ayrıca
  planlanıyor_ deniyor.
- "Sık Yapılan **3** Manevra Hatası (Animasyon)" — on değil, üç; ne kadarsa o.

**Gerçek çekim gerektirdiği için `planned` kalanlar** (ve nedeni):

- `exam-walkthrough` — gerçek sınav güzergâhı gerekir; şematik animasyon yanıltıcı olurdu.
- `vehicle-inspection` — gerçek parçaların görünümü gerekir. Açıklaması, parça tanıma için
  **bugün zaten kullanılabilir** olan Araç Tekniği fotoğraf kütüphanesine yönlendiriyor.

Bu dürüstlük artık **testle zorunlu**:

- Her oynatılabilir video başlığında `(Animasyon)` taşımak zorunda.
- Hiçbir animasyon `Gerçek Çekim —` diye sunulamaz.
- Her `planned` video başlığında `planlanıyor`, açıklamasında `gerçek` geçmek zorunda.

## 5. Tests executed

| Kapsam                      | Sonuç                      |
| --------------------------- | -------------------------- |
| web `test`                  | **484 geçti** (E12 ile +5) |
| — `content/videos.test.ts`  | **9** (5'i E12'de eklendi) |
| `flutter analyze`           | **0 sorun**                |
| `flutter test`              | **265 geçti** (E12 ile +2) |
| Playwright E2E              | yeşil (yerelde de koşuldu) |
| `pnpm lint` · `pnpm format` | 0 hata · temiz             |

E12'de eklenen testler: manevra setinin eksiksizliği · VTT ↔ transkript birebir eşleşmesi ·
animasyon/gerçek-çekim etiket dürüstlüğü · `planned` gerekçe zorunluluğu · dosya boyutu bütçesi
(20 KB–1 MB) ve posterin gerçek bir kare olması.

## 6. Yol boyunca düzeltilen üç şey

1. **`(a + b ?? c)` öncelik hatası** poster zaman damgasını `NaN` yapıyordu — açıkça yazıldı.
2. **L park sahnesi yanlış okunuyordu:** park cepleri çizilmemişti, iki araç çimenin üstünde
   duruyordu. Asfalt zemin + dört ayırıcı çizgi + vurgulanmış hedef cep olarak yeniden çizildi.
3. **Adım etiketi poster rozetiyle çakışıyordu** (cihazda görüldü): mobil listedeki
   "İZLE"/"PREMIUM" rozeti sol üstte, etiket de sol üstteydi. Etiket alt şeride alındı — hem
   çakışma bitti hem de altyazıya benzer, daha doğal bir yerleşim oldu.

Ayrıca CI, E2E testinin **eski içeriği kodladığını** yakaladı (transkript ifadesi değişmişti ve
`planned` sayısı 4'ten 2'ye inmişti). Test yeni gerçeğe göre güncellendi ve bu kez **yerelde de**
koşuldu.

## 7. Device validation

**Cihaz:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG · Android 11.

| #   | Doğrulanan                                                                   | Kanıt    |
| --- | ---------------------------------------------------------------------------- | -------- |
| 1   | Yeni katalog cihazda: 7 oynatılabilir video, doğru süreler (0:12/0:13/…)     | `e12_03` |
| 2   | Yükseltilen `parallel-park` **oynuyor** (0:02 / 0:12)                        | `e12_04` |
| 3   | Videoya gömülü **adım etiketi** oynatma sırasında görünüyor                  | `e12_04` |
| 4   | Bölüm listesi üretilmiş veriyle birebir (0:00 · 0:03 · 0:06 · 0:09)          | `e12_04` |
| 5   | Altyazı düğmesi (CC) çıkıyor → VTT cihaza indi ve çözümlendi                 | `e12_04` |
| 6   | Yeni videoların posterleri doğru sahneyi gösteriyor (L park cepleri, U yayı) | `e12_06` |
| 7   | **Premium kapısı** çalışıyor: ilki ücretsiz, kalanı kilitli                  | `e12_06` |
| 8   | Adım etiketi rozetle ARTIK çakışmıyor (alt şerit düzeltmesi)                 | `e12_06` |

**Premium kilidi nedeniyle** cihazda yalnız ücretsiz video oynatılabildi. Kalan altısının
gerçekten oynatılabilir olduğu, **yayındaki dosyalar `ffprobe` ile çözümlenerek** doğrulandı —
hepsi 1120×640, 30 fps, kare sayısı ve süresi sahne tanımıyla birebir:

```
parallel-park 360 kare/12,0 sn · right-of-way 300/10,0 · l-park 390/13,0 · u-turn 360/12,0
reverse-25m   360 kare/12,0 sn · hill-start   360/12,0 · common-mistakes 420/14,0
```

Yedi VTT dosyasının hepsi yayında **200** dönüyor.

**Not (kusur değil):** poster düzeltmesinden sonra cihaz bir süre ESKİ posteri gösterdi —
uygulamanın görsel önbelleği. Yayındaki dosya ile yerel dosya bayt bayt aynıydı; önbellek
temizlenince doğru poster göründü.

## 8. Bütçe

| Kalem                       | Değer                          |
| --------------------------- | ------------------------------ |
| Video başına mp4            | 58–103 KB                      |
| Video başına webm           | 149–274 KB                     |
| Poster                      | 13–23 KB                       |
| **Toplam `public/videos/`** | **2,2 MB** (7 video × 4 dosya) |

Testte video başına 1 MB üst sınırı var; en büyük dosya bunun onda biri.

## 9. Honest limitations

1. **Bunlar animasyondur, gerçek çekim değildir.** Projenin baştan beri açıkladığı model bu; her
   başlıkta `(Animasyon)` yazıyor ve test bunu zorunlu kılıyor.
2. **İki başlık hâlâ `planned`** — sınav yürüyüşü ve araç kontrolü. Gerçek çekim gerektiriyor;
   uydurulmadı.
3. **Ses yok.** Videolar sessiz; anlatım altyazı ve adım etiketleriyle veriliyor. Seslendirme
   ayrı bir üretim (ve dil/telaffuz) işidir, kapsamda değildi.
4. **Kuş bakışı şematik anlatım.** Sürücü gözünden görüş, ayna görüntüsü ve mesafe hissi
   veremez; bunlar gerçek çekimin alanı.
5. **Süreler kısa (10–14 sn).** Manevranın adımlarını göstermeye yeter; gerçek zamanlı bir
   manevra değildir.

## Next phase prerequisites

E13 (Evolution Polish, Asset Optimization & Final Report) için: video varlıkları ölçüldü ve
bütçesi testle korunuyor; oynatıcı (E11) içerikten bağımsız çalışıyor. E13'te tüm program
özetlenecek ve `MOBILE_EVOLUTION_FINAL_REPORT.md` yazılacak.
