# Evolution Phase 6 Report — Onboarding Experience: Coach + Insight Cards

**Phase Group 4 · Onboarding Experience.** _Prepared: 2026-07-25 · Existing architecture preserved ·
device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

Onboarding'in her adımı artık **AI Koç'un konuştuğu, dönen bir içgörü kartı** taşıyor ve düzen
**kaydırmasız** hâle getirildi: içerik dikey ORTALI, ilerleme düğmesi her zaman görünür.
**24 içgörü** (6 adım × 4), **3 yoğunluk kademesi** ve **4 farklı ekran ölçüsünde** kaydırma payının
sıfır olduğunu doğrulayan testler eklendi. `flutter analyze` 0 · `flutter test` **145** (+14) ·
backend değişmedi.

## Completed work

1. **`lib/domain/onboarding/onboarding_insights.dart`** — saf içgörü modeli: 6 tür (`İpucu · Bilgi ·
Motivasyon · Sürüş · Sınav · Strateji`), adım başına 4 içgörü, **deterministik** seçim
   (`insightAt(step, tick)`), ardışık tekrar yok.
2. **`lib/features/onboarding/widgets/coach_insight_card.dart`** — `CoachInsightCard` (dönen kart) +
   `IdleMascot` (yumuşak süzülen maskot). İkisi de `MediaQuery.disableAnimations`'a uyar.
3. **Kaydırmasız uyarlanır düzen** — `_CenteredScroll` (sığarsa ortala, sığmazsa kaydır),
   `OnboardingDensity` (roomy · tight · dense) ve **yatay iki sütun** düzeni.
4. **Seçenek kartları yeniden yapılandırıldı** — ehliyet sınıfı kartında fotoğraf artık sabit
   genişlikte (ölçüm sonucu: esnek genişlik metin sütununu 118 px'e düşürüp kartı 196 px yapıyordu).
5. **`pumpApp(reduceMotion:)`** test dikişi — varsayılan `true`, böylece mevcut 131 test dönen
   zamanlayıcıdan etkilenmez; dönüşü test edenler hareketi açıp zamanı elle ilerletir.
6. **`test/onboarding_experience_test.dart`** — 14 yeni test.

## Architecture & decisions

**Preserved:** Riverpod · go_router · tasarım token'ları · PageView tabanlı adım akışı · `StudyProfile`
kaydetme yolu. **Yeni paket yok, yeni ekran yok, backend değişmedi.**

- **Maskot ile içgörü kartı TEK bileşendir.** Roadmap hem "animasyonlu koç maskotu" hem "dönen içgörü
  kartları" hem de "kaydırmasız düzen" istiyor; ayrı bir maskot bloğu her adıma 100+ px eklerdi.
  Maskotu kartın içine almak koçu her adımda görünür kılar, **boş alanı değerlendirir** ve dikey
  maliyeti tek bir kompakt satıra indirir. Roadmap'in "boş alana değer kat" amacı böyle karşılanır.
- **"Kaydırmasız" ölçülebilir bir ölçüte çevrildi.** Gövde `_CenteredScroll` içindedir: içerik sığarsa
  `Column(mainAxisAlignment: center)` ile **dikey ortalanır** ve `maxScrollExtent == 0` olur; sığmazsa
  kırpmak yerine kaydırır. Testler tam olarak `maxScrollExtent == 0` doğrular — "taşma yok" ile
  "kaydırma yok" ayrı ayrı ve nesnel biçimde ölçülür.
- **Yoğunluk kademesi yalnız piksele değil YAZI ÖLÇEĞİNE de bakar.** `densityFor()` kullanılabilir
  yüksekliği metin ölçeğine böler; 1,3× yazı ölçeği kullanan kullanıcı da otomatik olarak daha kompakt
  (ama kaydırmasız) bir düzen alır. Kademeler ölçümle belirlendi: `<520 dense`, `<700 tight`, üstü roomy.
- **Hareket azaltma gerçek bir özellik, aynı zamanda test sabitleyicisi.** `disableAnimations` açıkken
  maskot sallanmaz ve kart dönmez. Bu hem erişilebilirlik gereği hem de widget testlerinin
  `pumpAndSettle` ile sonsuz kare kuyruğuna takılmamasını sağlayan doğal çözüm.
- **Yatayda iki sütun.** Yatayda dikey bütçe ~210 px'e düşer; tek sütunda 4 seçenekli adım imkânsız.
  Sol sütun anlatım + koç kartı, sağ sütun seçenekler; 4 seçenekli adımda seçenekler de 2×2 dizilir
  (3 seçenekte 2 sütun satırları dengesizleştirip DAHA uzun yaptığı için yalnız 4+ seçenekte açılır —
  ölçüldü).
- **İçerik disiplini.** İçgörülerdeki her sayı uygulamanın kendi doğrulanmış verisinden gelir
  (`EXAM_BLUEPRINT`: 50 soru · 45 dakika · 35 doğru · 23/12/9/6). "Kullanıcıların %X'i" türü kaynaksız
  istatistik yazılmadı.

## Ölçüm günlüğü (düzen bu sayılarla kuruldu)

Tahminle değil ölçümle çalışıldı; testin hata mesajı görünen/gerçek yüksekliği yazar.

| Bulgu                                | Ölçüm                                           | Sonuç                                            |
| ------------------------------------ | ----------------------------------------------- | ------------------------------------------------ |
| Ehliyet sınıfı kartı (B)             | **196 px** — metin sütunu yalnız **118 px**     | Fotoğraf sabit genişliğe alındı → kart **71 px** |
| Adım başlığı (360×640)               | **84 px** · 1,3× ölçekte **144 px**             | Kısa sorular + kademeye göre başlık stili        |
| Koç kartı (ilk metinlerle)           | **170 px**                                      | Metinler ≤ 95 karaktere indirildi + kompakt kip  |
| Karşılama gövdesi (360×640, ilk hâl) | 675 px / 492 px görünen → **183 px fazla**      | Kademeli sıkıştırma → sığdı                      |
| `_FocusCard` seçim satırı (1,3×)     | **17 px yatay taşma**                           | `Flexible` + tek satır elips                     |
| Gerçek cihaz ölçüsü (393×780)        | roomy kademe 648 px alanda **665 px** istiyordu | roomy eşiği 640 → **700** (cihaz artık tight'ta) |

## Content added (measured)

| Item                | Count                                                           |
| ------------------- | --------------------------------------------------------------- |
| İçgörü kartı metni  | **24** (6 adım × 4) · hepsi 40–95 karakter arası (testle sabit) |
| İçgörü türü         | **6** — hepsi en az bir kez kullanılıyor (testle sabit)         |
| Yoğunluk kademesi   | **3** (roomy · tight · dense) + yatay iki sütun                 |
| Yeni varlık (asset) | **0** — mevcut maskotlar kullanıldı                             |

## Screens & flows

- **Karşılama** — süzülen maskot, marka bloğu, özellik şeridi ve koç kartı; dar kademede marka çipi ve
  ikincil satırlar düşer.
- **Adım 1–4** — kısa soru, seçenek kartları, altında **adıma özel** koç kartı. Geniş kademede
  kahraman görsel ve seçenek açıklamaları da çizilir.
- **AI Koç** — koç tanıtımı, 3 yetenek kartı ve koç kartı; yatayda iki sütun.
- Her adımda **CTA ekranın altında sabittir** ve hiçbir ölçüde kaydırma gerektirmez.

## Tests executed

- `flutter analyze` — **0 issues**.
- `flutter test` — **145 passed** (131 önce, **+14**):
  - **Saf (7):** her adımda ≥3 içgörü, uzunluk alt/üst sınırı, cümle bütünlüğü, determinizm, **ardışık
    tekrar yok**, döngüsel dönüş, adımların birbirinden farklı olması, tanımsız adımın boş dönmemesi,
    her türün kullanılması.
  - **Dönüş (2):** hareket açıkken sahte zamanla kartın 0→1→2 ilerlemesi ve widget kaldırıldığında
    zamanlayıcının iptal edilmesi; **hareket azaltma açıkken 30 saniye boyunca DÖNMEMESİ**.
  - **Kaydırmasız düzen (4):** 360×640, 360×640 @1,3× yazı ölçeği, **gerçek cihaz ölçüsü 393×780** ve
    yatay 740×360 — altı slaydın hepsinde dikey kaydırıcıların `maxScrollExtent == 0` olması ve hiçbir
    taşma hatası oluşmaması.
  - **Koç görünürlüğü (1):** altı adımın her birinde tam bir koç kartı ve o adımın ilk içgörüsü.
- Web/backend bu fazda **değişmedi** (yeni uç nokta, yeni içerik alanı yok).

## Build

`flutter build apk --debug` temiz. Yeni varlık eklenmediği için paket boyutu pratikte değişmedi.
iOS — **N/A (Linux'ta macOS yok)**.

## Device validation (`AYXSUKIVJVPZ7HPZ` · Redmi M1908C3JGG · Android 11)

`pm clear` ile veri sıfırlanıp **ilk açılış** akışı baştan sona koyu temada yürütüldü
(kanıt: `e6_01`–`e6_06`):

- **Karşılama** — maskot, marka bloğu, özellik şeridi ve koç kartı; kart 14 saniye sonra üçüncü
  içgörüde görüldü → **dönüş cihazda çalışıyor**.
- **Adım 1** — "Hangi ehliyeti alıyorsun?" + yeniden yapılandırılmış B/A/D kartları (fotoğraf, sınıf
  harfi, ad, seçim halkası) + adıma özel koç kartı ("Sınıfını sonradan Profil'den değiştirebilirsin").
- **Adım 4** — 4 seçenek **açıklamalarıyla birlikte** + koç kartı ("Sınavın yakınsa denemeyle başla…").
  Cihaz `tight` kademesine düşüyor ve her şey kaydırmasız sığıyor.
- **AI Koç** — süzülen koç maskotu, 3 yetenek kartı, koç kartı.
- **Bitiş** — "Koç ile Başla" → Ana Sayfa; seçilen süreye göre plan **"Akıllı çalışma oturumu
  (20 soru)"** olarak kişiselleşti (1 Hafta – 1 Ay → günlük 20).
- Hiçbir adımda kaydırma, taşma, kırpılmış metin veya görünmeyen düğme yok.

## Honest limitations

- **Test edilen ölçülerin ALTINDA düzen kaydırmaya geçer, kırpmaz.** Kaydırmasızlık 4 ölçüde
  (360×640 · 360×640@1,3× · 393×780 · 740×360) testle garanti altındadır; daha küçük ekran + daha
  büyük yazı bileşimlerinde içerik kaydırılabilir hâle gelir. Bu bilinçli bir bozulma tercihidir —
  alternatifi metni kırpmak veya kullanıcının yazı ölçeği tercihini ezmekti.
- **Kahraman görseller yalnız en geniş kademede çizilir.** Orta kademede 4 seçenekli adım, görselle
  birlikte kaydırmasız sığmıyor (ölçüldü: 885 px / 648 px). Görseli koşullu göstermek yerine kademeye
  bağlamak öngörülebilir davranış sağlıyor.
- **Hareket azaltma açıkken kart dönmez** (ilk içgörüde kalır). Bu erişilebilirlik gereğidir; dönen
  içeriği görmek isteyen kullanıcı sistem ayarını kapatmalıdır.
- **İçgörüler statiktir** — kullanıcının o ana kadarki verisine göre kişiselleşmez, adıma göre seçilir.
  Onboarding sırasında henüz ilerleme verisi yoktur; kişiselleşmiş içgörü Ana Sayfa'daki koç
  kartlarının işidir (Faz 5/6'da yapıldı).
- **Dönüş süresi sabittir (3 sn)** ve kullanıcı elle kart değiştiremez; kaydırmalı bir taşıyıcı
  eklemek adım akışındaki yatay `PageView` ile jest çakışması yaratırdı.
- Yatayda 3 seçenekli adımlar tek sütun kalır (2 sütun onları daha uzun yapıyordu — ölçüldü).

## Next phase prerequisites

**E7 — Welcome Experience.** Bağımlılığı olan E6 tamam. E7 onboarding bittikten sonra gösterilecek,
tek seferlik (`ea:welcomeSeen`) bir karşılama anı ekleyecek: seçilen **sınıf · çalışma planı · sınav
hedefi · günlük hedef** değerlerini `StudyProfile`'dan okuyup özetleyecek ve Ana Sayfa'ya geçecek.
Hazır olanlar: `StudyProfile` zaten kaydediliyor ve `main()`'de senkron okunup enjekte ediliyor
(`pumpApp(studyProfile:)` test dikişi E5'te eklendi); yönlendirme zinciri `onboardingSeen` redirect'i
ile aynı desende genişletilecek; koç kartı bileşeni (`CoachInsightCard`, `IdleMascot`) yeniden
kullanılabilir. Dikkat: yönlendirme sırası (onboarding → welcome → home) birim testiyle sabitlenmeli
ve "Atla" yolu welcome'ı da atlamalı.
