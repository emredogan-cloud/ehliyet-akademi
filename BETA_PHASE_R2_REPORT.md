# Beta Faz R2 — Onboarding adım sayfalarının doluluğu

**Durum:** ✅ Tamamlandı · **Kapsam:** `apps/mobile` (onboarding adım düzeni)
**Yerine geçtiği:** Faz 6'nın eksik kalan kısmı (yalnız karşılama sayfası çözülmüştü)

---

## A. Geri bildirim ve teşhis

> "Faz 6 yalnız ilk onboarding sayfasını çözdü. Kalan sayfalar ekranın yaklaşık yarısını boş
> bırakıyor. Bu tamamlanmış DEĞİL."

Geri bildirim doğruydu ve nedeni tek bir cümleyle özetlenebilir: **doluluk hiçbir yerde
ölçülmüyordu.**

Faz 6 iki kapı bırakmıştı — `maxScrollExtent == 0` (kaydırma yok) ve kahraman görselin çizilen
genişliği. İkisi de **yarı boş bir sayfayı geçirir**: içerik sığıyorsa kaydırma sıfırdır, görsel
de yalnız karşılama sayfasında ölçülüyordu. Adım sayfalarında ise:

| Kusur                                          | Kök neden                                                                                    |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Adım 1 ve 3'te görsel hiç yoktu                | O adımlarda `hero` **hiç tanımlanmamıştı**                                                   |
| Görsel tanımlı adımlarda da çizilmiyordu       | Gerçek cihazda gövde 648 px → `tight` kademe; görsel **yalnız `roomy`** kademede çiziliyordu |
| İçerik ekranın ortasında toplanıyordu          | `CenteredScroll` artan boşluğu **ortalıyordu** → üstte ve altta iki büyük delik              |
| Küçük telefonda (360×640) adımların altı boştu | `dense` kademede görsel **hiçbir koşulda** çizilmiyordu                                      |

---

## B. Yapılanlar

### 1. Eksik görseller tanımlandı

Adım 1 (`onbWheel`) ve adım 3 (`onbTablet`) artık kahraman görsel bildiriyor. Böylece dört adımın
dördü de illüstrasyon taşıyor.

### 2. `heroFitsTight` (boolean) → `tightHeroFactor` (oran)

Tek bir "sığar/sığmaz" anahtarı, gövdesi biraz dolu olan adımda görseli **tamamen** düşürüyordu.
Oran, her adıma **kalan boşluğu kadar** görsel vermeyi mümkün kılar.

### 3. `dense` kademede de görsel — ama yazıya göre düzeltilmiş bütçeyle

`dense` kademe hem 360×640 @1,0× (gövde 492 px) hem de 360×640 @1,3× (gövde 508 px) ölçüsünü
kapsıyor. Birincisinde görsele yer **var**, ikincisinde **yok** (73 px taşıyor). Ayrım piksel
değil, **yazı ölçeğine bölünmüş** yükseklik:

```dart
final effective = h / (MediaQuery.textScalerOf(context).scale(14) / 14);
// 640 @1,0× → 492 (yeter) · 640 @1,3× → 391 (yetmez) · eşik ölçümle 450
```

### 4. `CenteredScroll.distribute` — artan boşluk **dağıtılır**, ortalanmaz

`MainAxisAlignment.spaceBetween`. İçerik ESNETİLMEZ (kart ve tipografi büyümez); yalnız artan
boşluğun **yeri** değişir. İçerik sığmadığında `spaceBetween` zaten `start` gibi davranır →
kaydırma davranışı ve `maxScrollExtent == 0` kapısı aynen korunur.

### 5. ADIM düzeni için `roomy` eşiği yükseltildi (gerileme düzeltmesi)

Görseli büyütürken **kendi eklediğim bir gerilemeyi** yeni bir kapı yakaladı: 393×851 (jest
gezinme) ölçüsünde gövde 719 px → `densityFor` bunu `roomy` sayıyor, ama roomy tipografisi +
kompakt olmayan koç kartı tek başına ≈641 px tutuyor. Kalan 78 px görselin **taban ölçüsüne bile**
yetmiyor ve düzen **234 px taşıyordu**.

Yani bu boyda "ferah" kademe, ferah olmak için yeterince yer bırakmıyor. Adımlar telefon
boylarında artık `tight` kademesinde kalır; `roomy` gerçekten geniş gövdeler (tablet) içindir.

---

## C. Ölçüm — kapının kendisi

`test/onboarding_fill_test.dart` (yeni, 3 test) iki şeyi ölçer:

1. **Yayılım** — ilerleme çubuğunun üstünden CTA'nın altına: ekranın **≥ %85'i**.
2. **En büyük boşluk** — ardışık iki içerik bloğu arasındaki en büyük açıklık: **≤ %17**.

İkincisi olmadan birincisi yeterli değildir: içerik yukarıda ve aşağıda toplanıp ortada kocaman
bir delik bırakabilir. "Sırıtan boşluk olmasın" şartı ancak bu ölçüyle korunur.

**Sonuçlar (üç ölçü × dört adım):**

| Ölçü               | Yayılım | En büyük boşluk (önce → sonra) |
| ------------------ | ------- | ------------------------------ |
| 360×640 · adım 1   | %94,1   | %17,2 → **%5,2**               |
| 360×640 · adım 2   | %94,1   | %23,0 → **%8,2**               |
| 360×640 · adım 3   | %94,1   | %25,5 → **%12,8**              |
| 360×640 · adım 4   | %94,1   | %15,5 → **%13,7**              |
| 393×780 · adım 1–4 | %95,2   | **%8,4 – %12,4**               |
| 393×851 · adım 1–4 | %95,6   | **%10,7 – %15,6**              |

> Yol haritası şartı %85–95'ti; ölçülen yayılım %94,1–95,6.

Kaydırmasızlık kapısına **393×851 (jest gezinme)** ölçüsü de eklendi — bu ölçü daha önce hiç
sınanmamıştı ve gerileme tam orada saklanıyordu.

---

## D. Dürüst sınırlar

1. **Adım 3'te orta kademede görsel YOK.** Ölçüldü: 393×780'de gövde 648 px, içerik 570 px →
   yalnız 78 px boşluk kalıyor; 0,16 oranlı görsel (104 px + 16 px ara) düzeni **42 px taşırıyor**.
   Görselin taban ölçüsü 72 px olduğu için daha küçüğü de anlamlı yer kazandırmıyor. Bu adımın
   **kartları zaten illüstrasyon taşıdığı** için sayfa yine dolu görünüyor (cihazda ~%94).
2. **Test yazı tipi (Ahem) gerçek yazıdan uzun yer kaplar.** Bu yüzden testteki boşluklar cihazdaki
   boşluklardan **küçük** çıkar; kapı eşikleri buna göre değil, **ölçülen en kötü değerin hemen
   üstüne** kondu (%17). Gevşek eşik gerilemeyi yakalamaz.
3. **İlk ölçüm yanlıştı ve düzeltildi.** Adım 3'ün seçenek bloğunu iki kartın _başlık metniyle_
   sınırlamıştım; sonuç "%32 boşluk" gibi görünüyordu. Blok, kartların **kendisiyle**
   (`GlowCard` kutuları) ölçülünce gerçek değer %12,4 çıktı. Rapordaki tüm sayılar düzeltilmiş
   ölçümdür.
4. **PageView komşu sayfaları ağaçta tutar.** Ölçüm filtresi olmadan başka bir sayfanın kutusu
   hesaba karışıyor ve sonuç **sessizce yanlış** çıkıyordu (ilk denemede negatif boşluklar). Test
   yalnız ekrandaki örnekleri ölçer.

---

## E. Kapılar

```
flutter analyze            → 0 sorun
flutter test               → 366 test (+4: 3 doluluk + 1 jest-gezinme kaydırma kapısı)
flutter build apk --release→ 79,5 MB
cihaz (AYXSUKIVJVPZ7HPZ, Android 11) → 4 adımın 4'ü de tam sayfa
  RenderFlex overflowed / EXCEPTION CAUGHT → 0
kanıt: r2c_01…r2c_04 ekran görüntüleri
```

---

## F. Değişen dosyalar

| Dosya                                                  | Değişiklik                                                                        |
| ------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `lib/features/onboarding/onboarding_screen.dart`       | eksik görseller · `tightHeroFactor` · `dense` görsel bütçesi · adım `roomy` eşiği |
| `lib/features/onboarding/widgets/centered_scroll.dart` | `distribute` (artan boşluk dağıtılır)                                             |
| `test/onboarding_fill_test.dart`                       | **yeni** — doluluk kapısı (yayılım + en büyük boşluk)                             |
| `test/onboarding_experience_test.dart`                 | 393×851 kaydırmasızlık ölçüsü eklendi                                             |
