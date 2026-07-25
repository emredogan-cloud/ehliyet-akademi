# Evolution Phase 7 Report — Welcome Experience

**Phase Group 5 · Welcome Experience.** _Prepared: 2026-07-25 · Existing architecture preserved ·
device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

Kişiselleştirme artık doğrudan Ana Sayfa'ya düşmüyor: arada, koç eşliğinde bir **karşılama anı** var.
Ekran seçilen **ehliyet sınıfı · hazırlanılan sınav · çalışma temposu · günlük hedefi** kaydedilmiş
`StudyProfile`'dan okuyup gösteriyor, **tam olarak bir kez** çıkıyor ve yumuşak bir geçişle Ana
Sayfa'ya bağlanıyor. `flutter analyze` 0 · `flutter test` **154** (+9) · backend değişmedi.

## Completed work

1. **`domain/onboarding/welcome_controller.dart`** — `ea:welcomeSeen:v1` tek seferlik işaret;
   `onboardingSeen` ile birebir aynı desen (main()'de senkron okuma + provider override → flaş yok).
2. **`features/onboarding/welcome_screen.dart`** — süzülen koç maskotu, "Her şey hazır!" başlığı,
   **4 satırlık profil özeti**, koç içgörü kartı ve sabit CTA.
3. **Yönlendirme zinciri** (`app/router.dart`) — tek yerde, yukarıdan aşağıya:
   `tanıtım → karşılama → ana sayfa`. Tamamlanmış bir adıma geri dönülmek istenirse ileriye taşınır.
4. **Geçiş** — `/welcome` için `CustomTransitionPage` (solma + hafif ölçek); hareket azaltma açıkken
   geçiş uygulanmaz.
5. **Paylaşılan bileşenler ayrıştırıldı** — `widgets/centered_scroll.dart` ve
   `widgets/onboarding_density.dart` (E6'da onboarding ekranının içindeydi) artık karşılama ekranı
   tarafından da kullanılıyor.
6. **`test/welcome_test.dart`** — 9 yeni test.

## Architecture & decisions

**Preserved:** Riverpod · go_router · `StudyProfile` · E6'nın yoğunluk/kaydırmasızlık disiplini.
**Yeni paket yok, backend değişmedi, yeni depolama yok** (tek bir bool anahtarı).

- **"Atla" karşılamayı da atlar.** Kişiselleştirmeyi atlayan kullanıcıya, seçmediği değerleri özetleyen
  bir ekran göstermek yanıltıcı olurdu. Bu yüzden `OnboardingScreen._finish(completed: false)` her iki
  işareti birden koyar. Tamamlayan kullanıcı ise karşılamayı görür — çünkü özet onun gerçek seçimidir.
- **Özet değerleri yeniden hesaplanmaz.** Ekran `studyProfileProvider`'ı okur; `sessionSize`,
  `paceLabel`, `focus.title` gibi alanlar uygulamanın başka yerlerde kullandığı ALANLARIN ta kendisidir.
  Böylece "ekranda yazan" ile "uygulamanın kullandığı" ayarın ayrışması yapısal olarak imkânsız —
  bir testle de sabitlendi (A · Motosiklet / e-Sınav (Trafik) / Yoğun tempo / 25 soru).
- **Zincir tek bir `redirect` içinde, sıralı.** İki ayrı yönlendirme kuralı (tanıtım + karşılama) ayrı
  ayrı yazılsaydı birbirini iptal eden döngüler kolayca doğardı. Kural: sırayla ilk tamamlanmamış adıma
  gönder; hepsi tamamsa tanıtım/karşılama yollarını ana sayfaya çevir. Altı ayrı test bu sırayı sabitler.
- **Tek seferlik işaret `markSeen()` içinde korumalı** (`if (state) return;`) — "Başla" ve "Atla"
  yollarının ikisi de aynı fonksiyonu çağırır, çift yazma olmaz.
- **E6'nın kaydırmasızlık ölçütü karşılamaya da uygulandı.** Ekran `CenteredScroll` + `densityFor`
  kullanır; 360×640'ta kaydırma payının sıfır olduğu testle doğrulanır.

## Screens & flows

**Karşılama ekranı:** süzülen koç maskotu → "Her şey hazır!" → "Planını sana göre kurduk. İstediğin
zaman Profil'den değiştirebilirsin." → dört özet satırı (Ehliyet sınıfın · Hazırlandığın sınav ·
Çalışma tempon · Günlük hedefin) → koç içgörü kartı → **"Çalışmaya başla"**. Sağ üstte sessiz bir
"Atla"; ikisi de aynı sonuca gider (ekran tek seferliktir, zorlamaz).

**Akış:** ilk açılış → tanıtım (6 adım) → **karşılama** → Ana Sayfa. İkinci açılış → doğrudan Ana Sayfa.

## Tests executed

- `flutter analyze` — **0 issues**.
- `flutter test` — **154 passed** (145 önce, **+9**):
  - **Zincir (6):** tanıtım tamamlanınca ana sayfa DEĞİL karşılama gelir; karşılamadan devam edilince
    ana sayfaya geçilir; tanıtımdaki **"Atla" karşılamayı da atlar**; tanıtımı görmüş ama karşılamayı
    görmemiş kullanıcı karşılamaya iner; **ikinci açılışta karşılama gösterilmez**; karşılamadaki
    "Atla" da ana sayfaya götürür.
  - **Özet doğruluğu (2):** kullanıcının gerçekten seçtiği değerler (A sınıfı + yalnız e-Sınav +
    1 haftadan az → **A · Motosiklet / e-Sınav (Trafik) / Yoğun tempo / 25 soru**) ve varsayılan
    seçimlerle beklenen özet.
  - **Düzen (1):** 360×640'ta kaydırma payı sıfır, taşma yok, CTA görünür.
- `pumpApp` **`welcomeSeen`** parametresi eklendi (varsayılan `true`) → mevcut 145 test zincirden
  etkilenmedi, yalnız E7 testleri `false` verip zinciri yürütüyor.
- Web/backend bu fazda **değişmedi**.

## Build

`flutter build apk --debug` temiz. Yeni varlık yok. iOS — **N/A (Linux'ta macOS yok)**.

## Device validation (`AYXSUKIVJVPZ7HPZ` · Redmi M1908C3JGG · Android 11)

`pm clear` ile veri sıfırlandı, akış baştan yürütüldü (kanıt `e7_01`–`e7_04`):

- Tanıtımda **A · Motosiklet** seçildi, adımlar tamamlandı, "Koç ile Başla" ile karşılamaya geçildi.
- **Karşılama ekranı** koç maskotu, "Her şey hazır!" başlığı ve özet tablosuyla göründü:
  **Ehliyet sınıfın: A · Motosiklet** · Hazırlandığın sınav: e-Sınav + Direksiyon · Çalışma tempon:
  Düzenli tempo · Günlük hedefin: 20 soru — **seçimlerle birebir aynı**.
- "Çalışmaya başla" → Ana Sayfa; plan "Akıllı çalışma oturumu (20 soru)".
- **Force-stop + yeniden açılış → doğrudan Ana Sayfa** (karşılama tekrar çıkmadı) → tek seferlik
  işaret kalıcı.
- Kaydırma, taşma veya kırpılmış metin yok.

## Honest limitations

- **Geçiş "shared axis" değil, solma + hafif ölçek.** Material'ın paylaşılan eksen geçişi için ek bir
  animasyon bağımlılığı (`animations` paketi) gerekirdi; roadmap'in "doğal bir geçiş" amacı mevcut
  `AppMotion` token'larıyla, paket eklemeden karşılandı. Fark bilinçli ve burada yazılıdır.
- **Karşılama içeriği statiktir** — özet dışında kişiselleştirilmiş bir metin (ör. sınıfa göre farklı
  motivasyon cümlesi) yoktur; ekrandaki koç kartı zaten adıma özel içgörü gösteriyor.
- **Yalnız ileri yönlü zincir vardır.** Karşılamadan tanıtıma geri dönülemez; kullanıcı seçimlerini
  Profil'den değiştirir (ekranda da bu yazıyor). Geri dönüş eklemek, tek seferlik işaretin anlamını
  bozardı.
- **Yatay düzen için ayrı bir yerleşim yazılmadı.** Karşılama tek sütunludur; yatayda içerik sığmazsa
  (E6'daki gibi) kırpmak yerine kaydırır. Yatay kaydırmasızlık yalnız onboarding adımlarında test
  edilmiştir — karşılama için 360×640 dikey ölçü test edilir.
- Karşılama işareti yalnız yereldir (`SharedPreferences`); cihaz değiştiren kullanıcı karşılamayı
  yeniden görür. Sunucuya taşımak, hesapsız (misafir) kullanıcıyı dışarıda bırakırdı.

## Next phase prerequisites

**E8 — Community Foundation (Profiles · XP · Leaderboards).** Bu, programın **en büyük backend
fazıdır** ve E4'e bağlıdır (tamam). Gerekenler hazır: Bearer kimlik doğrulama, `@ea/db` Drizzle şeması
ve idempotent bootstrap DDL deseni, `/api/state` senkron yolu, gamification (XP/rozet) hesapları
mobilde zaten var. Roadmap'in şartları hatırlatılır: **katılım varsayılan KAPALI (opt-in)**, foto
yükleme YOK (bütün bir moderasyon/PII sınıfını ortadan kaldırır), **rapor + engelle daha ilk fazda**,
sunucu tarafında XP artışı sınırlandırılmış (anti-hile) ve gerçek zamanlılık iddia edilmeden
ETag/kısa yoklama. Her yeni uç nokta için PGlite entegrasyon testi gerekir.
