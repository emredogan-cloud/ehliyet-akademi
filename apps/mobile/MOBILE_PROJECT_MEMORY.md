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
