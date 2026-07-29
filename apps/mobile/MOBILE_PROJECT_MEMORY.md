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
