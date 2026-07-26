# Beta R1 Raporu — Karşılama Deneyimi YENİDEN

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `AYXSUKIVJVPZ7HPZ` (Android 11)
**Neden:** ürün sahibi geri bildirimi — **Faz 8 gereksinimi yanlış anladı.**

## Karar: 🟢 GO

`flutter analyze` **0** · `flutter test` **362** · web **541** · lint/format/verify/typecheck temiz.

---

## 1. Yanlış anlaşılan neydi

Faz 8, karşılama **ekranına** bir tanıtım **sayfası** ekledi — yani onboarding sonrası akışı
uzattı. İstenen bu değildi.

**Doğrusu:** kullanıcı onboarding'i bitirir → **Ana Sayfa'ya iner** → Ana Sayfa **göründükten
sonra** ortalanmış premium bir **AI karşılama popup'ı** açılır.

Fark önemli: tanıtım artık bir **engel** değil, bir **karşılama**. Kullanıcı önce ürünü görüyor.

## 2. Geri alınan

Faz 8'in `welcome_screen.dart` ve `welcome_test.dart` değişiklikleri **`git checkout ffdd46e~1`
ile geri alındı**. E7'nin özet ekranı olduğu gibi duruyor (Evolution çıktısı — dokunulmaz).

## 3. Yeni yapı

| Katman | Dosya                                          | Sorumluluk                                  |
| ------ | ---------------------------------------------- | ------------------------------------------- |
| Durum  | `domain/onboarding/ai_welcome_controller.dart` | `ea:aiWelcomeSeen:v1` — tek seferlik işaret |
| Yüzey  | `features/home/widgets/ai_welcome_dialog.dart` | Ortalanmış premium popup                    |
| Tetik  | `features/home/home_screen.dart`               | `addPostFrameCallback` — İLK KARE SONRASI   |

**Neden ayrı bir işaret:** `welcomeSeen` (E7) onboarding sonrası **özet ekranını** temsil eder ve
o zincire aittir. Popup ise Ana Sayfa'da açılır — iki farklı an, iki farklı yaşam döngüsü. Tek
bayrağa bindirilseydi özeti atlayan kullanıcı popup'ı da hiç görmezdi.

**Neden `addPostFrameCallback`:** `build` içinde açmak, ekran daha çizilmeden diyalog göstermek
olurdu. Şart "Ana Sayfa göründükten SONRA" idi; bu, o şartın koddaki karşılığı.

**İşaret TEK yerde konuyor:** popup hangi yolla kapanırsa kapansın (CTA · zemin · geri tuşu)
`markSeen()` çağrılır — bir kapanış yolu unutulursa popup tekrar açılırdı.

## 4. Referanstan alınan — konsept, kod DEĞİL

`/home/emre/Downloads/FormAI-FitnessKoçu` → `premium_welcome_sheet.dart` incelendi.
Alınan **etkileşim konsepti**: karartılmış zemin · parlayan amblem · kısa başlık + alt metin ·
ikon-kutulu özellik satırları · tam genişlik CTA · tek-seferlik kapının **çağıranda** olması.

**Alınmayan:** kodu, renkleri, tipografisi. Bu popup projenin kendi tasarım token'larını kullanır
(`design_tokens_test.dart` sabit renk kullanımını zaten engelliyor). Referans bir alt sayfa
(bottom sheet); istenen **ortalanmış** olduğu için `Dialog` kullanıldı.

## 5. Tanıtılanlar

AI Koç · Öğrenme sistemi · Sana özel öneriler · Topluluk · Premium — **beşi de** uygulamada
gerçekten var olan yüzeyler.

## 6. Testler — +9 (`ai_welcome_test.dart`)

| Küme           | Kapsam                                                                                     |
| -------------- | ------------------------------------------------------------------------------------------ |
| Açılma anı (3) | Ana Sayfa göründükten sonra açılır · görülmüşse açılmaz · **onboarding'e sayfa EKLENMEDİ** |
| İçerik (1)     | Beş tanıtımın hepsi                                                                        |
| Kapanış (3)    | CTA · **zemin dokunuşu** · **geri tuşu** — üçünde de kapanır                               |
| Düzen (2)      | Kısa ekran ve 1.3× yazıda taşma yok                                                        |

`pumpApp`'e `aiWelcomeSeen` parametresi eklendi (**varsayılan `true`**) — mevcut 350+ test Ana
Sayfa'yı popup engellemeden görmeye devam ediyor.

## 7. Cihaz doğrulaması

| #   | Doğrulanan                                        | Kanıt   |
| --- | ------------------------------------------------- | ------- |
| 1   | Ana Sayfa arkada görünür, popup üstünde           | `r1_01` |
| 2   | CTA ile kapanır                                   | `r1_02` |
| 3   | **Uygulama yeniden açılınca GERİ GELMEZ**         | `r1_03` |
| 4   | `RenderFlex overflowed` 0 · `logcat -b crash` boş | —       |

## 8. Dürüst sınırlar

1. **E7'nin özet ekranı korundu** — onboarding → özet → Ana Sayfa → popup. Geri bildirim
   "onboarding'i uzatma" diyordu; özet ekranı Evolution E7'nin çıktısıdır ve dokunulmazlar
   listesindedir, bu yüzden kaldırılmadı. Kaldırılması istenirse ayrı bir karar gerekir.
2. **Popup içeriği statiktir** — gerçek bir model çağrısı değil, AI Koç'un ağzından yazılmış
   sabit tanıtımdır. Gerçek akış Faz 9'un konusu.
