# Beta Faz 11 — Ders sayfası yeniden tasarımı

**Durum:** ✅ Tamamlandı · **Kapsam:** `apps/mobile` (Öğren → Dersler → ders detayı)

---

## A. Faz öncesi durum

Sayfa doğrudan üç küçük çiple başlıyordu (konu · süre · premium), ardından başlık ve özet
geliyordu. **Görsel giriş noktası yoktu**, ilerleme göstergesi yoktu, zorluk bilgisi yoktu ve
hiyerarşi düzdü: her bölüm aynı ağırlıkta görünüyordu.

---

## B. Yapılanlar

### 1. Hero kartı

Konu etiketi → **büyük başlık** → künye çipleri (süre · zorluk · premium) → konu illüstrasyonu.
Göz artık önce görsele, sonra konuya, sonra başlığa iniyor.

### 2. Zorluk — **türetilir, veriye elle yazılmaz**

19 dersin her birine elle "zorluk" etiketi yazmak, kaynağı olmayan bir iddia üretmek olurdu ve
ilk içerik güncellemesinde bayatlardı. Bunun yerine dersin **kendi ölçülebilir özellikleri**
kullanılır:

```
puan = dakika/5 + bölüm sayısı + hata sayısı
<6 → Kolay · <10 → Orta · üstü → Zor
```

Kural saf bir fonksiyondadır (`lesson_meta.dart`) ve testle sabitlenmiştir: deterministik ve
**monoton** (yük arttıkça zorluk azalmaz).

### 3. Okuma ilerlemesi — uydurma "tamamlandı" değil

Ders okuma durumu hiçbir yerde saklanmıyor. Olmayan bir veriyi varmış gibi göstermek yerine
**gerçekten ölçülebilen** şey gösterilir: sayfanın ne kadarının geride kaldığı. Kural yine saf:

- `maxScrollExtent == 0` (içerik ekrana sığıyor) → ilerleme **1**. `0` dönmek kısa derste çubuğu
  hep boş bırakırdı; bu, yanlış bir "hiç okumadın" sinyali olurdu.
- Değer 0..1 aralığına sıkışır.

### 4. Konu illüstrasyonu

Ders başına özel görsel üretilmedi; **konu başına** tutarlı bir maskot kullanıldı. Test, beş
konunun beş **ayrı** görsel kullandığını doğrular — yoksa görsel bilgi taşımazdı.

### 5. Hareket — ve erişilebilirlik

Hero'ya 420 ms'lik yumuşak bir giriş (opaklık + 14 px kayma) eklendi. Sistem "animasyonları
azalt" diyorsa animasyon **hiç kurulmaz** (`TweenAnimationBuilder` ağaca girmez) — E13
erişilebilirlik kuralı. Test bunu doğrudan ölçüyor.

---

## C. Ölçüm

| Test grubu             | Ölçtüğü                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| Zorluk (saf)           | kolay/orta/zor eşikleri · **deterministik** · **monoton**                                           |
| Okuma ilerlemesi (saf) | sığan içerikte 1 · orantı · 0..1 sıkıştırma                                                         |
| Konu görseli           | her konunun görseli var ve konular **ayrışıyor**                                                    |
| Yüzey                  | hero'da süre + zorluk görünür · ilerleme çubuğu var · **hareket azaltıldığında animasyon kurulmaz** |

```
flutter analyze → 0 · flutter test → 395 (+12)
cihaz (AYXSUKIVJVPZ7HPZ): hero · "8 dk" · "Orta" · illüstrasyon · hedef kartı göründü
RenderFlex overflowed / EXCEPTION CAUGHT → 0
```

---

## D. Tasarım token'ları korundu

Yeni yüzeyde sabit renk yoktur; tüm renkler paletten gelir (`design_tokens_test.dart` bunu zaten
zorunlu kılıyor). Zorluk tonu da palete bağlıdır: kolay → `green`, orta → `accent`, zor → `red`.

---

## E. Değişen dosyalar

| Dosya                                          | Değişiklik                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| `lib/domain/content/lesson_meta.dart`          | **yeni** — zorluk · okuma ilerlemesi · konu görseli (saf kurallar) |
| `lib/features/learn/lesson_detail_screen.dart` | hero kartı · okuma çubuğu · gövde `StatefulWidget`                 |
| `test/lesson_page_test.dart`                   | **yeni** — 12 test                                                 |
