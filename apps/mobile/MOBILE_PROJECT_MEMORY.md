---

## Büyük Ürün Güncellemesi (12 faz) — TAMAMLANDI (2026-07-29)

`1d5a1da` → `39791ca` · 12 commit · 106 dosya · +10.099/−520.
`flutter analyze` 0 · `flutter test` **530** (404'ten) · web 602 · monorepo 9/9 · CI+Mobile CI+CodeQL ✓
· gerçek cihaz (Redmi 8A) 8/8. Ayrıntı: `MAJOR_UPDATE_REPORT.md`.

### En pahalı ders: semptomun altındaki sebep

Misafir satın alma hatası "Play zaten sahipsin diyor" diye bildirilmişti. Gerçek sebep bambaşkaydı:
sahiplik YALNIZ sunucudan türetiliyordu (oturum şart), uygulama ise misafir kullanımına açıktı.
Misafir → satın al → `/api/iap/validate` **401** → istisna → hak verilmez → kilitli. "Zaten
sahipsin" bir sonuçtu.
**KURAL: bir ödeme hatası bildirildiğinde önce "hak NEREDEN geliyor" sorulmalı; mağazanın hata
metni son halkadır, ilk halka değil.**

Aynı desen geri yüklemede: `restore()` mağazayı beklemeden boş sonuç dönüyordu, sonuç akıştan yüz
ms sonra geliyordu. **Geri yükleme çalışıyordu; ekran onu beklemiyordu.**

### Cihaz doğrulaması testin göremediğini gördü

`integration_test` eklendi (CI'daki `flutter test` yalnız `test/` koşar; etkilenmez). İki hata
yalnız orada göründü:
1. Koç işareti baloncuğunda **sarı çift alt çizgi** — bindirme `Scaffold`'un üstünde, `Material`
   atası yok. Widget testleri sessizdi: metin BULUNUYORDU, yalnız yanlış çiziliyordu.
2. Altı sekme etiketinin 360 dp'de sığması — test yazı tipi (Ahem) farklı ölçüyor.
**KURAL: "metin bulundu" ile "metin doğru çizildi" ayrı iddialardır; ikincisi cihazda doğrulanır.**

### Başarım ölçümünde üç yanlış yaklaşım

`60 FPS` iddiası için sırasıyla denendi ve bırakıldı — gerekçeleri `integration_test`'in başında
yazılı: (a) mutlak kare süresi + eşik → aynı kod 9–40 ms ortanca verdi (cihaz yükü); (b)
`totalSpan` → boşta geçen süreyi sayıyor, duragan hâli canlıdan 30 ms yavaş gösterdi; (c)
canlı/duragan farkı → duragan ağaç yeterli kare üretmiyor, taban ölçülemiyor.
**Bugün: canlı zeminde temiz karenin `buildDuration + rasterDuration` p10 değeri — 12 koşuda
5,2–6,4 ms.** Cihaz saturasyondayken tek okuma 22,6 ms'e çıkabildiği için test gerekirse ikinci
tur koşup iyisini alıyor.
**KURAL: alt segment cihazda mutlak kare süresi bir kapı olamaz; dış yük kareyi yalnız
yavaşlatabildiği için dağılımın ALT ucu ölçülmeli.**

### Cilalama ölçüldü, tahmin edilmedi

`test/polish_audit_test.dart` altı yüzeyi dört zorlayıcı koşulda tarıyor (320 dp · 1,3× yazı ·
1024 dp tablet · açık tema) ve **20 gerçek kusur** buldu — en önemlisi `GradientPillButton`:
uygulamanın her yerindeki birincil düğme uzun etiketle taşıyordu.
**Kendi ölçüm hatam:** dokunma hedefleri başta `InkWell`'in render kutusuyla ölçüldü ve yanlış
alarm verdi (`IconButton`'ın dalgası 42 dp ama hedefi `MaterialTapTargetSize.padded` ile 48 dp).
**KURAL: erişilebilirlik elle ölçülmez; `meetsGuideline(androidTapTargetGuideline)` kullanılır.**

### Şema serbest bırakılırsa veri bozulur

1562 sorunun 39'u üç, 13'ü beş şıklıydı. Kök neden `options: z.array(...).min(2).max(5)` idi.
`.length(4)` yapıldı; kural artık şemada, veri kümesinde ve istemcide (`isWellFormedQuestion`).
**KURAL: bir alanın "genellikle şöyle" olması yetmez — kural şemaya yazılmazsa er geç ihlal edilir.**

### Karanlık desen sınırı

Referans tasarımlar üstü çizili eski fiyat, geri sayım ve yıldızlı puanlama istiyordu. Üçü de
**gerçek veriye bağlandı**: kampanya `--dart-define` ile gelir ve varsayılan KAPALIDIR; yıldızlar
hiçbir yere kaydedilmez ve puana göre yol AYRILMAZ (Play filtrelemeyi yasaklar).
**KURAL: tasarım bir şey gösteriyorsa arkasında gerçek bir şey olmalı; yoksa gösterilmez.**

---

## E13 — Cila, varlık optimizasyonu ve kapanış — TAMAMLANDI (2026-07-26)

**Yapıldı:** varlık denetimi (ölçümlü), tutarlılık geçişi, erişilebilirlik geçişi, açık tema
paritesi, release artefaktları, `MOBILE_EVOLUTION_FINAL_REPORT.md`.
`flutter analyze` 0 · `flutter test` **267** (+2) · web 484 · @ea/db 6.

**En önemli bulgu — sorun varlıklarda değildi:** APK'nın **%90'ı (63,2 MB) yerel kütüphaneler** ve
bunun tamamı **üç ABI'nin yan yana paketlenmesinden** geliyor. Ölçülen gerçek çıktılar: evrensel
APK 69,9 MB · **arm64 APK 27,9 MB** · AAB 57,3 MB (Play böler → ~28 MB). Yani kullanıcının
indirdiği boyut, tek bir varlığa dokunmadan **%60 küçülüyor**.
**KURAL: APK boyutu tartışılırken önce `unzip -l` ile içerik dökülmeli; varlık optimizasyonuna
girişmeden önce yerel kütüphane/ABI payı ölçülmeli.**

**Bulunan gerçek tema hatası:** premium "altın" tonu dört dosyada sabit yazılmıştı ve **koyu
temanın** değeri donmuştu; `brand.dart` ise açık temanınkini sabitlemişti. Palet ikisini zaten
`accent` olarak taşıyordu → **açık temada premium yüzeyleri yanlış altınla çiziliyordu.** Hepsi
`context.palette.accent`'e çevrildi (sabit renk 10 → 4).

**Kalıcı koruma:** `test/design_tokens_test.dart` kaynağı tarıyor; sabit renk eklenirse test
kırılır, gerçekten temadan bağımsız olması gereken renk **gerekçesiyle** izin listesine eklenir.
İkinci test ölü istisna birikmesini engelliyor. Test yazılır yazılmaz benim gözden kaçırdığım bir
dosyayı daha buldu. **KURAL: disiplin kuralları insan dikkatine değil teste bağlanmalı.**

**Erişilebilirlik:** 26 IconButton tarandı, 1'inin ipucu yoktu (giriş ekranı parola göster/gizle) →
eklendi. 26/26 etiketli.

**Ölçülemeyen, dürüstçe:** kare düzeyinde jank. `dumpsys gfxinfo` Flutter için `Total frames: 0`
döndürüyor (Flutter HWUI hattını atlar); `SurfaceFlinger --latency` iki katman için de sıfır verdi.
Gerçek kare profili `--profile` derlemesi + DevTools ister — doğrulanan release artefaktından
farklı bir derleme. **Uydurma jank yüzdesi yazılmadı.** Ölçülen: soğuk açılış **451 ms**.

**Yanlış çıkan ilk varsayım:** `public/ui/*.png` (11 MB) "kazanç" sanıldı; `git rm` başarısız olunca
`.gitignore`'da olduğu görüldü — depoya da dağıtıma da hiç girmiyormuş. **KURAL: "şu kadar kazandık"
demeden önce dosyanın gerçekten takipli/yayınlanıyor olduğu doğrulanmalı.**

**Gerçek kazanç:** iki ikon master'ı (2,4 MB) referanssız olduğu hâlde `public/` altındaydı →
`apps/web/design-sources/` altına taşındı. Yayınlanan web varlıkları 20 MB → **17 MB**.

**PROGRAM KAPANDI (E1–E13).** Yayın öncesi iki iş kaldı ve ikisi de onay bekliyor:
(a) üretim veritabanındaki doğrulama artıklarının temizlenmesi, (b) LemonSqueezy ürün görselinin
mağaza paneline elle yüklenmesi.

---

# Beta Hazırlık Sprinti (Faz 1–11) — 31 Temmuz 2026

`cdb9774` → `c90338c` · 11 commit · 94 dosya · +9.430 / −256
Mobil test **530 → 888** · web **603 → 633** · `flutter analyze` 0

Ayrıntı: `BETA_READINESS_REPORT.md` (ana) · `BILLING_AUDIT.md` · `PLAY_DATA_SAFETY.md`

## Kalıcı mühendislik dersleri

Bunlar bu sprintte **pahalıya öğrenildi**; tekrar etmemek için buradalar.

### 1. Test ikilisi, gerçeğin SÖZLEŞMESİNDEN ayrılırsa test yalan söyler

Ödeme ekranında "vazgeçince düğme sonsuza kadar döner" hatası, testler yeşilken vardı.
Sahte ağ geçidi `purchase()`'tan doğrudan `BillingCancelled` dönüyordu; gerçek ağ geçidi
`BillingSuccess([])` dönüp sonucu AKIŞTAN gönderiyor. Sahte, gerçeğin kırık olduğu yolu hiç
kullanmıyordu.

**Kural:** bir sahte yazarken "gerçek ne DÖNDÜRÜR" değil, "gerçek ne ZAMAN ve NEREDEN bildirir"
sorusu sorulur. Asenkron bir sözleşmeyi senkron bir sahteyle taklit etmek, tam da o asenkronluktan
doğan hataları görünmez kılar.

### 2. Tek cihazda doğrulama yetmez — Android sürümü davranışı değiştirir

`BoxConstraints has a negative minimum height`: Redmi 8A'da (Android 11) HİÇ olmuyor,
Redmi Note 11R'de (Android 13) HER açılışta oluyordu. Sistem çubuğu yerleşirken gelen kısa
yükseklik cihaza ve sürüme göre değişiyor.

Aynı şekilde giriş ekranındaki `clamp(alt > üst)` çökmesi yalnız ≥1024 dp'de (tablet) oluyor.

**Kural:** en az iki farklı Android sürümü; genişlik/yazı ölçeği/yön matrisi otomatik taranmalı.

### 3. "Ölçemiyorsan ölçüyormuş gibi yapma"

Başarım labı ilk yazımda `dumpsys gfxinfo` ile jank okuyordu ve `frameP90 = 4950 ms` üretiyordu.
`4950` bir kare süresi değil, histogramın SON KOVASININ ETİKETİ. Kök neden: `gfxinfo` Android'in
kendi çizim sistemini (HWUI) ölçer; **Flutter HWUI'yi kullanmaz**, bu yüzden bir Flutter
uygulaması için her zaman 0 kare bildirir.

**Kural:** bir metrik makul görünüyor diye doğru değildir. Ölçüm aracının ölçtüğü şeyin, ölçmek
istediğin şey olduğu doğrulanmalı. Doğru kaynak uygulama içindeki `FrameTiming`'dir.

### 4. `null` ile boş liste AYNI ŞEY DEĞİLDİR

`fetchOwned()` hem "sunucu cevap verdi, hiçbir şeyin yok" hem "sunucuya sorulamadı" durumunu `[]`
ile temsil ediyordu. Sonuç: iade tespiti imkânsızdı, çünkü "iade edildi" ile "misafirim" ayırt
edilemiyordu.

**Kural:** "bilgi yok" ile "bilgi: hiçbir şey yok" ayrı tiplerle temsil edilir. Karıştırıldığında
yanlış yön, ödenmiş bir hakkı silmek olur.

### 5. Ölçüm, ölçtüğü şeyin en kırılgan parçasına bağlanmamalı

`AppVersion.load()` cevapsız bir platform kanalında HİÇ TAMAMLANMIYORDU (hata da fırlatmıyor).
Analitik bağlamı sürümü beklediği için hiçbir olay gönderilemiyordu — sürüm etiketi gibi
tamamen ikincil bir alan, bütün ölçümü durduruyordu.

**Kural:** ikincil bir alanın alınamaması, birincil işi bloke edemez. Zaman sınırı koy.

### 6. Riverpod: `dispose()` içinde `ref` KULLANILMAZ

`ref.read` sökülmekte olan bir widget'ta yasaktır. Gereken örnek `initState`'te alanda yakalanır.

### 7. go_router özel şema: `scheme://host/yol` — host ATLANAMAZ

`ehliyetakademi://davet/<KOD>` yazıldığında `Uri.parse` "davet"i HOST sayar ve yol boşalır;
go_router yalnız `uri.path` ile eşleştirdiği için hiçbir rota tutmaz. Doğrusu
`ehliyetakademi://app/davet/<KOD>`.

### 8. `StatefulShellRoute.indexedStack` bütün dalları ağaçta tutar

`scrollUntilVisible`, alan belirtilmediğinde bulduğu İLK `Scrollable`'ı sürükler — bu, görünen
dalın listesi olmak zorunda değil. Testlerde gezinme metinle değil, **rota üzerinden** yapılmalı.

### 9. "Çevrimdışı-öncelik" depolamada değil, GECİKMEDE ölçülür

Önbellek doluyken bile ağ beklenirse kullanıcı zaman aşımı kadar (12 sn) bekler. Önbellek varsa
ANINDA dönülür, tazeleme arka planda yapılır.

### 10. Boş yönetim ekranı EKLENMEZ

Kampanya/ödül/bayrak yönetimi için arkalarında mekanizma olmadığı için ekran eklenmedi. Olmayan
bir yeteneği varmış gibi göstermek, sahibi yanlış bir güvene sokar.

## Cihaz politikası

`apps/mobile/tool/deploy.sh` politikayı KODDA taşır: birincil Huawei ANE-LX1 → yedek Redmi Note
11R. Başka cihaza SESSİZCE geçmez; ikisi de yoksa hata verir ("cihazda doğrulandı" cümlesi
sahibin kastettiği cihazı anlatmalı).

İmza uyuşmazlığında önce kaldırıp yeniden kurar — **kaldırma sonrası bekleme ve ikinci deneme
şart**: hemen yapılan kurulum sessizce başarısız olup cihazı "uygulama hiç kurulu değil" hâlinde
bırakıyordu.

## Başarım taban çizgisi

`apps/mobile/tool/perf-baseline.json` — ANE-LX1/Android 9, release, 3 koşu medyanı:
soğuk 759 ms · sıcak 154 ms · PSS 64,9 MB · APK arm64 31 MB · kare p10 11,87 ms (bütçe 12).
`tool/perf_lab.sh` gerilemede exit 1 verir; kapının gerçekten kırılabildiği doğrulandı.
