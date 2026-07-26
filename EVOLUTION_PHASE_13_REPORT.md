# Evolution Phase 13 Report — Polish, Asset Optimization & Final Report

**Phase Group 8 · Kapanış.** _Prepared: 2026-07-26 · device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

`flutter analyze` **0** · `flutter test` **267** (+2) · web **484** · `@ea/db` **6** ·
lint/format temiz · release APK, split-APK ve AAB üretildi.

## 1. Varlık denetimi — ölçülmüş sonuçlar

### 1.1 En önemli bulgu: sorun varlıklarda değil, ABI'lerde

APK'nın içi tek tek ölçüldü:

| Bileşen                             |   Boyut | Pay     |
| ----------------------------------- | ------: | ------- |
| Yerel kütüphaneler (Flutter engine) | 63,2 MB | **%90** |
| Uygulama varlıkları (`assets/`)     |  4,2 MB | %6      |
| `res/` + font/shader + diğer        |  4,5 MB | %4      |
| **Toplam (evrensel APK)**           | 69,9 MB |         |

63,2 MB'ın tamamı **üç ABI'nin yan yana paketlenmesinden** geliyor:

| ABI           | Yerel kod |
| ------------- | --------: |
| `arm64-v8a`   |   21,3 MB |
| `armeabi-v7a` |   19,2 MB |
| `x86_64`      |   22,7 MB |

Bir kullanıcı bunlardan **yalnız birini** kullanır. Ölçülen gerçek çıktılar:

| Artefakt                      |   Boyut | Kullanıcının indirdiği |
| ----------------------------- | ------: | ---------------------- |
| Evrensel APK                  | 69,9 MB | 69,9 MB                |
| `app-arm64-v8a-release.apk`   | 27,9 MB | **27,9 MB**            |
| `app-armeabi-v7a-release.apk` | 25,8 MB | 25,8 MB                |
| `app-release.aab` (Play)      | 57,3 MB | Play böler → ~28 MB    |

**Sonuç: kullanıcının indirdiği boyut %60 küçülüyor** ve bu, tek bir varlığa dokunmadan
elde ediliyor. Play Store zaten AAB istiyor; yayın artefaktı olarak AAB üretiliyor.

### 1.2 Varlıkların kendisi

| Kapsam                         | Ölçüm                                                      |
| ------------------------------ | ---------------------------------------------------------- |
| Mobil (`apps/mobile/assets`)   | 4,7 MB · 263 dosya · **tamamı WebP/SVG** · en büyük 124 KB |
| Web (git'te takipli `public/`) | 20 MB → **17 MB**                                          |
| WebP dağılımı (web)            | 114 dosya · ortanca 124 KB · ortalama 125 KB               |
| **Yinelenen dosya**            | **0** (içerik hash'i karşılaştırıldı)                      |

**Yapılan:** iki ikon master'ı (`new_icon.png` 1254², `new_icon-lemonsqueezy.png` 1024²; toplam
**2,4 MB**) hiçbir yerden referanslanmadığı hâlde `public/` altında olduğu için her dağıtımla
yayınlanıyordu. `apps/web/design-sources/` altına taşındılar (README'siyle) — master'lar korunuyor
ama artık yayınlanmıyor. Yayınlanan web varlıkları **20 MB → 17 MB**.

**Yapılmayan ve nedeni:**

- `public/ui/*.png` (13 dosya, 11 MB) zaten `.gitignore`'da — depoya da dağıtıma da girmiyor.
  İlk bakışta "11 MB kazanç" gibi göründü; **ölçünce öyle olmadığı görüldü** ve dokunulmadı.
- `assets/vehicle` (11 MB, 68 gerçek fotoğraf) yeniden sıkıştırılmadı: ortamdaki ImageMagick
  webp→webp'te `-quality` bayrağını yok sayıyor (q90/q82/q75 **aynı** baytı üretti); yalnız yeniden
  boyutlandırma kazanç veriyor. Bunlar parça tanıma amaçlı öğretim fotoğrafları ve bu kütüphane
  **APK'ya girmiyor** (mobilin kendi optimize kopyaları var). Doğru araç (`cwebp`) olmadan öğretim
  materyalini bozmak orantısız görüldü.
- `new_icon-lemonsqueezy.png` silinmedi: LemonSqueezy mağaza paneline **elle yüklenmek** için
  duruyor (RELEASE_BLOCKER_RESOLUTION_REPORT.md'de bekleyen iş).

## 2. Tutarlılık geçişi — gerçek bir tema hatası bulundu

Kaynak taramasında `lib/` içinde **10 sabit renk** vardı. En önemlisi: premium "altın" tonu
**dört ayrı dosyada** sabit değer olarak yazılmıştı (`videos_screen`, `paywall_screen`,
`premium_popups`, `onboarding_screen`) ve **koyu temanın** tonu (`0xFFF5A623`) donmuştu.
`brand.dart` ise **açık temanın** tonunu (`0xFFF59E0B`) sabitlemişti.

Palet zaten bu iki değeri `accent` olarak taşıyordu:

```
açık tema  accent: 0xFFF59E0B      koyu tema  accent: 0xFFF5A623
```

Yani **açık temada premium yüzeyleri yanlış altınla çiziliyordu.** Hepsi `context.palette.accent`
ile değiştirildi. Sabit renk sayısı **10 → 4**'e indi; kalan dördü ya `p.brightness` ile dallanan
gölge/zemin renkleri ya da trafik levhasının **mevzuattaki** kırmızısı (temaya göre değişmemeli).

**Kalıcı koruma:** `test/design_tokens_test.dart` artık kaynağı tarıyor. Sabit renk eklenirse test
kırılır; gerçekten temadan bağımsız olması gereken bir renk varsa **gerekçesiyle** izin listesine
eklenmesi gerekir. İkinci bir test, izin listesinde ölü giriş birikmesini engelliyor.

Bu test yazılır yazılmaz benim gözden kaçırdığım bir dosyayı daha buldu
(`lib/core/theme/app_theme.dart` — o da tema-duyarlı, gerekçesiyle eklendi).

## 3. Erişilebilirlik geçişi

26 `IconButton` tarandı: **1 tanesinin ipucu (tooltip) yoktu** — giriş ekranındaki parola
göster/gizle düğmesi. Ekran okuyucu bu düğmeyi anlamlı seslendiremiyordu; her kullanıcının
geçtiği bir ekran. Duruma göre değişen ipucu eklendi (`Parolayı göster` / `Parolayı gizle`).
Sonuç: **26/26 düğme etiketli.**

`Semantics` sarmalayıcıları E8–E12 ekranlarında mevcut (topluluk, sohbet, tartışma, video
denetimleri, onboarding koç kartı).

## 4. Açık tema paritesi — cihazda

| Ekran                 | Sonuç                                                        |
| --------------------- | ------------------------------------------------------------ |
| Profil + Ayarlar      | ✅ kontrast ve ikon tonları doğru                            |
| **Premium / Paywall** | ✅ **düzeltilen altın** açık temanın tonuyla çiziliyor       |
| Öğren merkezi         | ✅                                                           |
| Video oynatıcı (E11)  | ✅ oynatıcı kutusu bilinçli koyu; bölüm listesi açık yüzeyde |
| Video kataloğu (E12)  | ✅ poster + rozetler okunur                                  |

## 5. Başarım — ölçülen ve ÖLÇÜLEMEYEN

**Ölçülen:**

| Ölçüt                        | Değer                                                      |
| ---------------------------- | ---------------------------------------------------------- |
| Soğuk açılış (`am start -W`) | **451 ms** TotalTime · 455 ms WaitTime (LaunchState: COLD) |
| Cihaz                        | Redmi M1908C3JGG · Android 11 · 2019 giriş seviyesi        |

**Ölçülemeyen — dürüstçe:** kare düzeyinde takılma (jank) sayısı **alınamadı**.
`dumpsys gfxinfo` bu uygulama için `Total frames rendered: 0` döndürüyor (Flutter, Android'in
HWUI hattını atlayıp kendi rasterleyicisini kullanır); `SurfaceFlinger --latency` de hem ana
katman hem `SurfaceView` katmanı için sıfır kayıt verdi. Gerçek kare profili için `--profile`
derlemesi + Flutter DevTools zaman çizelgesi gerekir; bu, doğrulanan **release** artefaktından
farklı bir derleme türüdür. **Uydurma jank yüzdesi raporlanmadı.**

## 6. Tests executed

| Kapsam                      | Sonuç                       |
| --------------------------- | --------------------------- |
| `flutter analyze`           | **0 sorun**                 |
| `flutter test`              | **267 geçti** (E13 ile +2)  |
| web `test`                  | **484 geçti**               |
| `@ea/db`                    | **6 geçti**                 |
| `pnpm lint` · `pnpm format` | 0 hata · temiz              |
| Release derlemeleri         | APK · split-APK ×3 · AAB ✅ |

## 7. Honest limitations

1. **Kare düzeyinde başarım ölçülemedi** (§5). Soğuk açılış ölçüldü; akıcılık yalnız gözle
   doğrulandı.
2. **Evrensel APK hâlâ 69,9 MB.** Küçülme, split-APK/AAB dağıtımıyla geliyor; doğrudan APK
   paylaşan biri yine büyük dosya indirir.
3. **`assets/vehicle` yeniden sıkıştırılmadı** (§1.2) — doğru araç ortamda yok.
4. **Cihaz taraması tek cihazda.** İkinci telefon (Android 13) E9'da bağlıydı ama sonra çıkarıldı;
   E13 taraması yalnız Android 11 cihazda yapıldı.
5. **Açık tema paritesi öncelikli ekranlarda doğrulandı**, E8–E10 topluluk ekranları açık temada
   cihazda görülmedi (oturum gerektiriyor); kod düzeyinde token kullandıkları test ile garanti.
