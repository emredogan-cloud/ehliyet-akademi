# Beta Faz 10 — Kabin kumandaları detay sayfaları

**Durum:** ✅ Tamamlandı · **Kapsam:** `apps/mobile` (Öğren → Kabin Kumandaları)

---

## A. Faz öncesi durum

Kabin Kumandaları listesi 39 gerçek araç içi fotoğrafı gösteriyordu ama **kartlar hiçbir yere
gitmiyordu**: `_ControlCard` içinde `onTap` yoktu. Kullanıcının elinde 62 px'lik bir küçük resim
ve tek satır açıklama kalıyordu.

Yol haritasının şartı: mekanik kütüphanesiyle **aynı kalitede** detay sayfası — büyük görsel,
zoom, açıklama, ipuçları, öğrenme kartları.

---

## B. Kalite çıtası kopyalanmadı, HİZALANDI

Çıta olarak `vehicle_detail_screen.dart` alındı; yeni sayfa **aynı bölüm sırasını ve aynı
bileşenleri** kullanır (görsel → başlık + grup → açıklama → `AppCallout` ipucu → `AppCallout` hata
→ numaralı adım kartı). Böylece iki kütüphane arasında gezen kullanıcı yeni bir düzen öğrenmek
zorunda kalmaz.

---

## C. İçerik — 39 kumandanın tamamı

Detay sayfası ancak gösterecek bir şey varsa "aynı kalitede" olur. `CabinControl` modeli
genişletildi:

| Alan      | Zorunlu? | Neden                                                                                           |
| --------- | -------- | ----------------------------------------------------------------------------------------------- |
| `tip`     | ✅       | Detayın var oluş sebebi: listedeki cümlenin **tekrarı değil**, yeni bilgi                       |
| `steps`   | ✅ (≥2)  | "Nasıl kullanılır" öğrenme kartı                                                                |
| `mistake` | ➖       | Yalnız **gerçekten** bir hata varsa. Her kumandaya zorla hata uydurmak uyarıyı değersizleştirir |

39 kumandanın **tamamı** için ipucu ve adımlar yazıldı; 19'unda gerçek bir "sık yapılan hata"
vardı ve yalnız onlara eklendi.

Örnek (ESP):

> **İpucu:** ESP savrulmayı önler ve normal sürüşte KAPATILMAZ; yalnız çamur veya karda tekerleğin
> dönmesi gerektiğinde geçici kapatılır.
> **Hata:** ESP kapalıyken normal yolda sürmek: kaygan zeminde savrulma riski belirgin biçimde artar.

---

## D. Zoom — neden şart

Bu görseller gerçek araç içi fotoğraflardır ve ayırt edici ayrıntı (sembolün üstündeki minik yazı,
kademe çizgileri: `MIST–OFF–INT–LO–HI`) küçük ölçekte **okunamaz**. Tanımayı öğreten bir
kütüphanede ayrıntıyı gizlemek, kütüphanenin amacını boşa çıkarır.

- `InteractiveViewer` (parmakla yakınlaştırma, 1×–4×)
- **çift dokunuş** ile 2,5× — dokunulan nokta merkeze alınır, tekrar çift dokunuşta sıfırlanır
- durum yazısı, yakınlaştırılmışken "sürükleyerek gez" olarak değişir

---

## E. Ölçüm — ve bir ölçüm sınırı

### Testler (11)

| Grup             | Ölçtüğü                                                                                                                                                                                                            |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| İçerik bütünlüğü | her kumandada ≥40 karakter ipucu · ≥2 adım · her adım cümle · **ipucu açıklamanın kopyası değil** · hata alanı doluysa anlamlı · görsel kimlikleri tekil                                                           |
| Detay yüzeyi     | listeden karta dokununca detay açılır · `InteractiveViewer` var · **çift dokunuş gerçekten yakınlaştırır ve geri alır** · ipucu/adım/hata çizilir · hatası olmayanda uyarı **çizilmez** · bilinmeyen kimlik çökmez |

```
flutter analyze → 0 · flutter test → 383 (+11)
cihaz (AYXSUKIVJVPZ7HPZ): liste → detay açıldı · büyük görsel, ipucu ve hata kartı göründü
RenderFlex overflowed / EXCEPTION CAUGHT → 0
```

### Dürüst ölçüm sınırı

**Çift dokunuş cihazda `adb` ile tetiklenemedi.** Sebep uygulamada değil, araçta: her
`adb shell input tap` cihazda ayrı bir süreç başlatır ve iki dokunuş arasındaki gerçek aralık
Flutter'ın çift dokunuş penceresini (~300 ms) aşar. Üç farklı deneme (ayrı çağrılar, tek kabukta
art arda, üç hızlı dokunuş) görselde **0 piksel** değişiklik üretti.

Bu yüzden davranış **widget testiyle** doğrulandı: çift dokunuş sonrası durum yazısının
değiştiği, ikinci çift dokunuşta eski hâline döndüğü ölçüldü. Test aynı zamanda gerçek bir riski
kapatıyor: `InteractiveViewer` kendi jest tanıyıcısını kurar ve üstüne konan `GestureDetector`
jest arenasını kaybedip **sessizce çalışmayabilirdi**.

Cihazdaki parmakla yakınlaştırma `InteractiveViewer`'ın standart davranışıdır ve ayrıca
sınanmamıştır.

---

## F. Değişen dosyalar

| Dosya                                                 | Değişiklik                                                                                              |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `lib/domain/content/vehicle_visuals.dart`             | `CabinControl` genişletildi (`tip`, `steps`, `mistake`) · 39 kumandanın içeriği · `cabinControlByAsset` |
| `lib/features/learn/cabin_control_detail_screen.dart` | **yeni** — detay sayfası + zoom'lu görsel                                                               |
| `lib/features/learn/cabin_controls_screen.dart`       | kart artık detayı açar (+ chevron)                                                                      |
| `lib/app/router.dart`                                 | `/learn/cabin/:asset`                                                                                   |
| `test/cabin_control_detail_test.dart`                 | **yeni** — 11 test                                                                                      |
