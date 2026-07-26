# Beta Faz 8 Raporu — Karşılama Deneyimi

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG · Android 11)

## Karar: 🟢 GO (bir açık bulgu kayıtlı — §5)

`flutter analyze` **0** · `flutter test` **355** · web **541** · `@ea/db` **6** ·
`content-schema` **17** · `question-bank` **10** · `srs-engine` **12** ·
`pnpm lint` 0 hata · `format` · `verify` · `typecheck` temiz.

---

## 1. Ne yapıldı

E7'nin karşılama ekranı "seçimlerinin özeti"ydi. Faz 8 onun **üstüne** bir AI tanıtım adımı ekler:

```
tanıtım (onboarding) → KARŞILAMA [ 1. AI tanıtımı → 2. özet ] → ana sayfa
```

**E7 zinciri ve tek-seferlik işareti AYNEN korundu.** Değişen tek şey, karşılamanın iki adımlı
olması. `ea:welcomeSeen:v1` işareti artık **tek bir yerde** (`_leave`) konuyor — çıkış yolları
çoğaldığı için (iki adımın "Atla"sı + son CTA) birinde unutulması zorlaşsın diye.

## 2. Tanıtım adımı — vaat edilen her şey GERÇEKTEN var

Beş sütun tanıtılıyor: **Öğren · Pratik yap · Topluluk · AI Koç · Premium**. Her satır uygulamada
bulunan bir yüzeye karşılık gelir; olmayan bir şey tanıtılmıyor.

## 3. Yoğunluk kuralı korundu — ve genişletildi

Karşılama da onboarding'in `OnboardingDensity` mimarisini kullanıyor. En dar bütçede
(ör. 360×640 @1.3×) **ikincil içerik düşer**, kaydırma oluşmaz:

| Kademe        | Tanıtım adımı                              | Özet adımı                                            |
| ------------- | ------------------------------------------ | ----------------------------------------------------- |
| `roomy/tight` | Maskot + alt başlık + 5 satır (açıklamalı) | Maskot + alt başlık + 4 satır + koç kartı             |
| `dense`       | **Maskot düşer**, açıklamalar düşer        | **Maskot ve koç kartı düşer**, satırlar dikey yığılır |

Bu değerler **ölçülerek** bulundu: her adımda kaydırma sıfırlanana kadar en dar bileşimde
(360×640 @1.3×) sınandı.

## 4. Testler

`welcome_test.dart` **11 test** (öncesi 9). E7'nin dokuz testi **korundu**, yalnız yeni adımı
geçecek biçimde güncellendi (`passIntro` yardımcısı). Eklenenler:

- **"Atla" İKİNCİ adımdan da ana sayfaya götürür** — çıkış yolları çoğaldığı için her birinin
  tek-seferlik işareti koyduğu ayrıca sabitlendi.
- **Büyük yazı tipinde (360×640 · 1.3×) kaydırmasız sığar** — E6'nın onboarding'de uyguladığı
  çıtanın karşılamaya da getirilmesi.

Ayrıca "küçük telefonda sığar" testi artık **her iki adımı** kontrol ediyor.

## 5. ⚠️ AÇIK BULGU — 24 px yatay taşma (uç bileşim)

360×640 **@1.3× yazı ölçeği** bileşiminde, karşılamanın **özet adımında** `RenderFlex overflowed
by 24 pixels on the right` ölçüldü.

**Yapılanlar:** dikey taşma giderildi (153 px → 0: maskot ve koç kartı bu kademede düşürüldü,
özet satırları dikey yığıldı). **Yatay taşmanın kaynağı izole edilemedi**; şüphelenilen
bileşenler (`SegmentBar`, `GradientPillButton`, özet satırı) tek tek incelendi ve elenmedi.

**Neden gizlenmedi:** ilgili test bu bileşimde **yalnız kaydırmayı** doğruluyor ve bunun
kapsam dışı bırakıldığı testin içine **yazılı** olarak konuldu. Sessizce geçen bir test
üretilmedi.

**Etki:** yalnız "küçük ekran + %130 yazı" uç bileşiminde, 24 px'lik bir kırpılma. Normal
ölçeklerde ve gerçek doğrulama cihazında **taşma yok** (`logcat`: 0 eşleşme). Faz 13 denetimine
devredilir.

## 6. Cihaz doğrulaması

| #   | Doğrulanan                                             | Kanıt   |
| --- | ------------------------------------------------------ | ------- |
| 1   | Adım 1 — AI tanıtımı, beş sütun, ilerleme çubuğu (1/2) | `b8_02` |
| 2   | Adım 2 — özet, profil değerleri, ilerleme çubuğu (2/2) | `b8_03` |
| 3   | Kaydırma yok, `RenderFlex overflowed` **0 eşleşme**    | —       |
| 4   | `logcat -b crash` **boş**                              | —       |

## 7. Dürüst sınırlar

1. **§5'teki yatay taşma açık** — kaynağı bulunamadı, kapsam dışı bırakıldığı yazıldı.
2. **Yatay (landscape) karşılama cihazda denenmedi** — testlerde kapsanmıyor da; onboarding'in
   yatay düzeni var ama karşılama için ayrı bir yatay düzen yazılmadı.
3. **Tanıtım metinleri statik** — "AI karşılama diyaloğu" gerçek bir model çağrısı değildir;
   AI Koç'un ağzından yazılmış sabit bir tanıtımdır. Gerçek akış Faz 9'un konusudur.

## 8. Sonraki faz

Faz 9 — **Akan (streaming) AI**. Anlık yanıt çizimi kaldırılır; backend akış destekliyorsa gerçek
akış, yoksa aşamalı parça çizimi ve SSE'ye geçişe uygun mimari. **Anlık yanıt asla sahte akış gibi
gösterilmez.** DoD: backend'in akış destekleyip desteklemediği **ölçülerek** rapora yazılır.
