# Beta Faz 6 Raporu — Onboarding Cilası

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG · Android 11)

## Karar: 🟢 GO

`flutter analyze` **0** · `flutter test` **334** (+8) · web **516** · `@ea/db` **6** ·
`content-schema` **17** · `question-bank` **10** · `srs-engine` **12** ·
`pnpm lint` 0 hata · `format` · `verify` · `typecheck` temiz.

---

## 1. Kök sorun: görsel yalnız YÜKSEKLİĞE bağlıydı

E6'da onboarding illüstrasyonu `maxHeight × 0.20` (200 dp tavan) ile boyutlanıyordu. 393 dp
genişlikte bu, görselin ekran genişliğinin ancak **~%37**'sini kaplaması demekti — yol haritasının
"illüstrasyon düzene hâkim" ölçütünün çok altında.

**Çözüm — tek ve saf bir kural** (`onboardingHeroBox`):

- Görsele **içerik genişliğinin tamamı** verilir (yanlardaki pay sayfa padding'inden gelir).
- Yükseklik yalnız bir **ÜST SINIR**'dır (yoğunluğa göre).
- `BoxFit.contain` ikisinden küçüğünü uygular → dikey bütçe elverdiğinde görsel **genişliğe
  dayanır**, daraldığında **kendiliğinden küçülür** ve kaydırma oluşmaz.

`IdleMascot`'a isteğe bağlı `width` eklendi (eklemeli; verilmezse eski davranış). `MascotImage`
zaten `width` destekliyordu — yalnız iletilmiyordu.

## 2. Oranlar tahmin değil, ÖLÇÜM

Her oran, E6'nın kaydırmasızlık kapısına (`maxScrollExtent == 0`, dört ölçü) karşı **ampirik
olarak** bulundu:

| Kademe  | Oran     | Nasıl bulundu                                                       |
| ------- | -------- | ------------------------------------------------------------------- |
| `roomy` | **0.50** | Kapı yeşil                                                          |
| `tight` | **0.52** | 0.38 → %69 · 0.44 → %80 · **0.48 → %87** · 0.52 → %90 (hepsi yeşil) |
| `dense` | **0.30** | **0.36'da kapı KIRILIYOR** → 0.30 güvenli üst sınır                 |

`dense` için sınır gerçekten ölçüldü: 0.36'da 360×640'ta içerik sığmıyor. Yani küçük telefonda
hedef banda **ulaşılamaz** ve bu, kaydırmaya yeğlenen bilinçli bir sonuçtur (E6'nın "dürüst
bozulma" ilkesi).

## 3. Ölçülen sonuç — çizilen genişlik

| Ekran                   | Önce (E6) | **Sonra** | Hedef %85–95 |
| ----------------------- | --------- | --------- | ------------ |
| 393×780 (gerçek cihaz)  | ~%37      | **%89,8** | ✅           |
| 393×851 (tam)           | ~%37      | **%89,8** | ✅           |
| 360×640 (küçük telefon) | ~%37      | **%46,3** | ❌ (§6.1)    |

### ⚠️ Ölçüm tuzağı — kayda değer

İlk ölçümüm **yanlıştı**: `tester.getSize()` widget **kutusunu** verir. `BoxFit.contain` ile
görsel kutunun içine en-boy koruyarak yerleşir; kutu geniş ama alçaksa **çizilen** görsel kutudan
dardır. İlk ölçüm 393×780 için "%89,8" diyordu; **çizilen** genişlik ise **%69,1**'di.

Doğru metrik `min(kutuGenişliği, kutuYüksekliği × enBoy)` olarak düzeltildi ve
`onboarding_hero_test.dart` bu metrikle yazıldı. **Yanlış metrikle "hedefe ulaşıldı" denmedi.**

## 4. Cihazda bulunan ve düzeltilen kusur

Adım 2'nin (`onb_think`) görseli **hiç çizilmiyordu** ve ekranda ~500 dp boşluk kalıyordu
(`b6_03`). Neden: görsel yalnız `roomy` kademede çiziliyordu, gerçek cihazda gövde ise 700 dp
eşiğinin **hemen altına** düşüyor → adım `tight` sayılıyor.

**Düzeltme içeriğe bağlandı**, yoğunluğa değil: `heroFitsTight` bayrağı eklendi.

| Adım | Seçenek | `tight` kademede görsel | Gerekçe (ölçüm)                               |
| ---- | ------- | ----------------------- | --------------------------------------------- |
| 2    | 2       | ✅ çizilir              | Sığıyor                                       |
| 4    | 4       | ❌ çizilmez             | **158 px taşıyor** — E6'nın ölçümü doğrulandı |

Adım görseli de genişlik-farkındalı oldu ve tavanı 156 → **210 dp**'ye çıktı
(`roomy` 0.30 · `tight` 0.22).

## 5. Testler — +8 (`onboarding_hero_test.dart`)

| Küme                | Kapsam                                                                                          |
| ------------------- | ----------------------------------------------------------------------------------------------- |
| Düzene hâkimlik (3) | 393×780 ve 393×851'de **%85–95 bandı** · E6 öncesine göre belirgin artış                        |
| Dürüst bozulma (2)  | 360×640 ve 1.3× yazıda görsel **küçülür ama kaybolmaz**; banda ulaşılamadığı **testle kayıtlı** |
| Saf kutu kuralı (3) | Genişlik = içerik genişliği · yoğunluk arttıkça bütçe daralır · taban/tavan                     |

E6'nın 14 kaydırmasızlık testi **değiştirilmeden** yeşil kaldı — mimari korundu, yalnız
boyutlandırma kuralı değişti.

## 6. Dürüst sınırlar

### 6.1 Küçük telefonda hedef banda ULAŞILAMIYOR

360×640 dp'de çizilen genişlik **%46,3**. Ölçüldü: `dense` oranı 0.36'ya çıkarıldığında
kaydırmasızlık kapısı kırılıyor. Dikey bütçe gerçekten yetmiyor; görselin küçülmesi kaydırmaya
yeğlendi. **Bu, testle kayıt altına alındı** (`lessThan(0.85)` — sessizce geçiştirilmedi).

### 6.2 Varlıklar 1080 px'e YENİDEN ÜRETİLMEDİ

`ASSET_GENERATION_LIBRARY.md` §4.3, beş onboarding görselinin **1080×1080** olarak yeniden
üretilmesini istiyor. Mevcut ölçüler:

| Dosya               | Mevcut  | Gereken   | Açık  |
| ------------------- | ------- | --------- | ----- |
| `onb_welcome.webp`  | 820×721 | 1080×1080 | 1,32× |
| `onb_wheel.webp`    | 760×722 | 1080×1080 | 1,42× |
| `onb_think.webp`    | 695×820 | 1080×1080 | 1,55× |
| `onb_tablet.webp`   | 820×641 | 1080×1080 | 1,32× |
| `onb_calendar.webp` | 820×623 | 1080×1080 | 1,32× |

**Yapılmadı, çünkü:** bu ortamda görsel üretim aracı yok ve hedef kare kompozisyonlar mevcut
kaynaklardan **kırpılarak/büyütülerek elde edilemez** (hepsi farklı en-boy oranında).
**Büyütme (upscale) bilinçle YAPILMADI:** dosyayı büyütür, detay eklemez; Flutter zaten çizim
anında ölçekliyor. Üretime hazır promptlar `ASSET_GENERATION_LIBRARY.md` §4.3'te duruyor.

**Pratik etki:** görsel şu an 393 dp'de ~353 dp genişlikte çiziliyor; 3× cihazda bu **1059 px**
kaynak ister, elde **820 px** var → **%29 eksik**. Yumuşama gözle fark edilebilir düzeydedir ve
yeniden üretimle kapanacaktır.

### 6.3 Görülemeyenler

- **Yatay (landscape) düzen cihazda denenmedi** — testte 740×360 yeşil, cihazda döndürülmedi.
- **Adım 4'ün `roomy` kademedeki görseli cihazda görülmedi** — bu cihaz o kademeye çıkmıyor.

## 7. Cihaz doğrulaması — İKİ EKRAN ÖLÇÜSÜ

DoD "en az iki ekran ölçüsünde kaydırmasız doğrulama" istiyor. Cihazın çözünürlüğü **gerçekten
değiştirilerek** yapıldı (`wm size` / `wm density`), sonra geri alındı:

| Ölçü                    | Karşılama         | Adım 2             | Adım 4               | Kaydırma | Kanıt                     |
| ----------------------- | ----------------- | ------------------ | -------------------- | -------- | ------------------------- |
| **393×851** (yerel)     | Görsel hâkim ✅   | Görsel çizildi ✅  | Hero yok (ölçüm) ✅  | Yok      | `b6_01`, `b6_04`, `b6_05` |
| **360×640** (`wm size`) | Görsel küçüldü ✅ | `dense` bozulma ✅ | Açıklamalar düştü ✅ | Yok      | `b6_06`, `b6_08`, `b6_09` |

`RenderFlex overflowed` ve `EXCEPTION CAUGHT`: **0 eşleşme**. `logcat -b crash`: boş.

> **Yanlış alarm:** 360×640'ta ilk karede koç kartında iki metin üst üste göründü. Ardışık kareler
> alındığında geçici olduğu görüldü — dönen içgörünün **çapraz geçiş karesi** (E6 özelliği), kusur
> değil (`b6_07`).

## 8. Sonraki faz

Faz 7 — **Profil avatarları**. ⚠️ Kritik: E8'de "fotoğraf yükleme YOK" **bilinçli bir moderasyon
kararıydı**; bu faz onu değiştiriyor. Dolayısıyla moderasyon yüzeyi (avatarın şikâyet hedefi
olması, engelleme, varsayılan maskota dönüş) **aynı fazda** ele alınmak zorundadır. Ayrıca
`PLAY_CONSOLE_SETUP.md` §5.6'daki **Veri Güvenliği "Fotoğraflar" satırı** güncellenmelidir —
yanlış beyan mağazadan kaldırılma sebebidir.
