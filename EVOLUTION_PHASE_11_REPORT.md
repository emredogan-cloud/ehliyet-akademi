# Evolution Phase 11 Report — Premium Video Player

**Phase Group 7 · Video.** _Prepared: 2026-07-26 · Existing architecture preserved ·
device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

`video_player` **korundu**, üzerine tasarım token'larıyla yazılmış tam bir denetim katmanı kuruldu:
bölüm işaretli sürüklenebilir zaman çizgisi, altyazı, hız, 10 sn atlama, tam ekran, yer imleri,
kaldığı yerden devam ve "izlendi" durumu.

`flutter analyze` **0** · `flutter test` **263** (+59) · lint/format temiz · APK **69,9 MiB**.

## 1. Kütüphane kararı (DoD gereği — gerekçesiyle)

Varsayım yerine **pub.dev'den güncel veriyle** karşılaştırıldı:

| Seçenek                     | Sürüm / güncelleme     | Beğeni | Puan | Önbellek      | PiP     | Boyut etkisi                 |
| --------------------------- | ---------------------- | ------ | ---- | ------------- | ------- | ---------------------------- |
| **`video_player` (mevcut)** | 2.11.1 · Flutter ekibi | resmî  | —    | yok           | yok     | **0** (zaten bağımlı)        |
| `chewie` 1.14.1             | 2 ay önce              | 2,3k   | 150  | yok           | yok     | küçük (+provider, +wakelock) |
| `better_player_plus` 1.3.4  | 37 gün önce            | 168    | 160  | **var**       | **var** | orta                         |
| `media_kit` 1.2.6           | 7 ay önce              | 902    | 140  | kendi katmanı | —       | **büyük** (libmpv gömülü)    |

**Karar: `video_player` korundu, denetim katmanı elle yazıldı.** Gerekçeler:

1. **chewie kendi görsel dilini getiriyor.** Bizim her pikselimiz `context.palette`'ten geliyor;
   chewie'nin kabuğunu token'larımıza zorlamak, kabuğu baştan yazmakla aynı işi yapıp üstüne iki
   bağımlılık (provider, wakelock_plus) eklemek olurdu. Ayrıca belgelenmiş açık bir hatası var:
   arabellek durumu yanlış raporlanıyor ve yükleme göstergesi denetimleri gizliyor.
2. **better_player_plus** istediğimiz iki özelliği (önbellek, PiP) sunuyor ama 168 beğeni ile dar
   bir kullanıcı tabanı var ve README'si açıkça **"sürümler arasında kırıcı değişiklikler
   görülebilir"** diyor. Oynatıcı, uygulamanın en görünür yüzeyi; oraya kırılgan bir soyutlama
   koymak orantısız.
3. **media_kit** libmpv'yi gömüyor → hâlihazırda 69,9 MiB olan APK'yı belirgin biçimde büyütürdü;
   ayrıca E8'den beri bilinçle istemediğimiz depolama izinlerini gerektiriyor.
4. Roadmap'in **"üçüncü taraf arayüz bağımlılığı yok"** ilkesi ve tasarım sistemi disiplini zaten
   bu yönü işaret ediyordu; karar artık **ölçülmüş veriyle** de destekleniyor.

**Not:** chewie'nin kullandığı `wakelock_plus` (oynatırken ekranı açık tutma) ŞU AN eklenmedi —
mevcut içerik 8–9 saniyelik animasyonlar olduğu için gereksiz. Gerçek çekim içerik geldiğinde
(E12) yeniden değerlendirilecek; bu, bilinçli ve kayıtlı bir erteleme.

## 2. Mimari

- **`PlaybackController` soyutlaması** (`features/learn/widgets/playback_controller.dart`).
  `VideoPlayerController` platform kanalına bağlıdır, widget testinde örneklenemez. Uygulamanın
  yerleşik deseni (arayüz + uygulama; `CommunityApi`/`SocialApi`/`GroupsApi`) oynatıcıya da
  uygulandı → **denetimlerin tamamı sahte bir oynatıcıyla test ediliyor**, platform kanalı gerekmiyor.
- **Saf mantık katmanı** (`domain/video/`): WebVTT çözümleyici, devam/izlendi kuralları, bölüm
  eşleme, arabellek/ilerleme oranları, biçimlendirme, yer imi kuralları. Hiçbiri `video_player`'a
  dokunmuyor → 38 birim testiyle doğrudan doğrulandı.
- **Kalıcılık cihazda** (`SharedPreferences`, tek JSON anahtarı — diğer tercihlerle aynı desen).
  İzleme konumu kişisel ve düşük değerli bir veri; sunucuya taşımak E8'in gizlilik yükünü
  gereksiz büyütürdü.

## 3. Yol boyunca düzeltilen üç gerçek kusur

1. **Bölüm zaman damgaları sessizce kırpılıyordu.** İçerik `t: 2.7` gibi **kesirli** saniyeler
   taşıyor ama Dart modeli `int` ilan etmişti; üretilen kod `(json['t'] as num).toInt()` ile 2.7'yi
   **2'ye** indiriyordu. 9 saniyelik bir videoda bu ~%8'lik bir atlama hatası. Model `double`'a
   çevrildi, üretim yeniden yapıldı, atlama milisaniye üzerinden yapılıyor.
2. **Altyazı kutusu ortadaki düğmelerin üstüne biniyordu** (cihazda görüldü). Sabit 84 px uzaklık
   yerine: satır içi oynatıcıda altyazı denetimler görünürken gizleniyor (3 sn sonra denetimler
   kendiliğinden kayboldu mu altyazı yerini alıyor), tam ekranda ikisi birlikte gösteriliyor.
3. **"Tam ekran" tam ekran değildi:** uygulamanın alt sekme çubuğu görünmeye devam ediyordu, çünkü
   iç içe (shell) gezgine itiliyordu. `rootNavigator: true` ile düzeltildi ve cihazda doğrulandı.

## 4. Tests executed

| Kapsam                                | Sonuç                                        |
| ------------------------------------- | -------------------------------------------- |
| `flutter analyze`                     | **0 sorun**                                  |
| `flutter test`                        | **263 geçti** (E11 ile +59)                  |
| — `video_logic_test.dart` (saf)       | **38** (VTT, devam, izlendi, bölüm, yer imi) |
| — `video_controls_test.dart` (widget) | **21** (bütün denetimler, sahte oynatıcıyla) |
| `pnpm lint` · `pnpm format`           | 0 hata · temiz                               |

## 5. Device validation — her denetim tek tek

**Cihaz:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG · Android 11 · 1080×2340.

| #   | Denetim / davranış                                                         | Kanıt             |
| --- | -------------------------------------------------------------------------- | ----------------- |
| 1   | Oynat / duraklat                                                           | `e11_04`,`e11_05` |
| 2   | Zaman çizgisi: ilerleme + **bölüm işaretleri** + tutamaç                   | `e11_04`          |
| 3   | Konum/süre okuması (`0:00 / 0:09`)                                         | `e11_04`          |
| 4   | **Altyazı**: VTT ağdan çekildi, çözümlendi, zamanında göründü              | `e11_05`          |
| 5   | Altyazı yerleşimi düzeltildikten sonra alt çubuk kutuya sığıyor            | `e11_07`          |
| 6   | **Bölüm listesi**: dokunma sarıyor, etkin bölüm vurgulanıyor               | `e11_08`          |
| 7   | Üstteki **bölüm başlığı** konuma göre değişiyor                            | `e11_08`          |
| 8   | **Hız**: 1x → 1.25x → 1.5x döngüsü                                         | `e11_08`          |
| 9   | **Yer imi**: eklendi, çip listesi çıktı, çubukta **sarı işaret**           | `e11_08`          |
| 10  | **Tam ekran**: yatay yönelim, sürükleyici mod, konum ve hız KORUNUYOR      | `e11_11`          |
| 11  | Tam ekranda sekme çubuğu YOK (kök gezgin düzeltmesi)                       | `e11_11`          |
| 12  | Tam ekrandan çıkışta dikey yönelim geri geliyor                            | `e11_12`          |
| 13  | **Kaldığın yerden devam** başlığı (`0:05 konumunda kalmıştın`)             | `e11_12`          |
| 14  | **İzlendi** işareti (başlıktaki yeşil ✓) uygulama yeniden açılınca duruyor | `e11_07`          |
| 15  | Yer imi uygulama yeniden açılınca duruyor                                  | `e11_10`          |

10 sn ileri/geri düğmeleri cihazda görünüyor ve basılabiliyor; sınır davranışları (0'ın altına
inmeme, süreyi aşmama) widget testleriyle doğrulandı — 9 saniyelik içerikte 10 sn'lik atlama
ekran görüntüsüyle anlamlı biçimde gösterilemiyor.

## 6. Honest limitations

1. **PiP (Picture-in-Picture) YAPILMADI.** Roadmap bunu "pratikse, değilse belgelensin" diye
   koşullamıştı. Flutter'da PiP, tek bir video yüzeyini değil **bütün Flutter görünümünü** küçük
   pencereye alır; kullanıcı PiP'te uygulama çubuğunu ve denetimleri görür — istenen deneyim bu
   değil. Doğru çözüm ya yerel (Kotlin) bir oynatıcı yüzeyi ya da yukarıda elenen
   `better_player_plus` bağımlılığıdır. İkisi de bu fazın kapsamıyla orantısız; **yapılmadı ve
   nedeni kayıtlı**.
2. **Çevrimdışı indirme YAPILMADI.** Mevcut mimarinin desteklediği şey dürüstçe şudur: videolar
   ağdan akıtılır (`VideoPlayerController.networkUrl`), platformun medya yığını kendi geçici
   önbelleğini tutar; **uygulama düzeyinde kalıcı bir indirme yönetimi yoktur.** Gerçek indirme,
   boyut gösterimi ve silme yüzeyi gerektirir; asıl değerini E12'nin gerçek çekim içeriğiyle
   kazanacağı için oraya bırakıldı.
3. **Parlaklık/ses hareketleri yapılmadı.** Kapsamda sayılmıştı; go_router geri hareketi ve
   sayfa kaydırmasıyla çakışma riski taşıyor ve 9 saniyelik içerikte ölçülebilir bir fayda
   sağlamıyor. Atlama, hız ve tam ekran hareket yerine **açık düğmelerle** verildi.
4. **İçerik hâlâ iki kısa animasyon.** 8–9 sn'lik `parallel-park` ve `right-of-way`. Oynatıcı
   uzun içerik için tasarlandı ama bugün elde ölçülebilecek uzun materyal yok — gerçek çekim
   müfredatı E12'nin işi. Dört video hâlâ dürüstçe "planlanıyor".
5. **`wakelock` yok** — uzun video gelene kadar ekran kilidi uzatılmıyor (bkz. §1 notu).

## 7. Build

- **APK (release):** temiz → **69,9 MiB** (E10'da 69,5). Artış yalnız koddan; E11 varlık eklemedi.
- **iOS:** N/A — macOS yok.

## Next phase prerequisites

E12 (Video Content Production) için oynatıcı hazır: bölüm, altyazı, yer imi ve ilerleme
altyapısının tamamı içerikten bağımsız çalışıyor. E12 yeni video eklediğinde ek kod gerekmez —
yalnız içerik + VTT + bölüm verisi. E11'den devreden değerlendirme: `wakelock_plus` ve çevrimdışı
indirme, gerçek uzunlukta içerik geldiğinde yeniden ele alınacak.
