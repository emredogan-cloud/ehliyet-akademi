# PROGRAM 2 · FAZ 2 RAPORU — Etkileşimli Medya

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

Statik premium fotoğraflar **aktif öğrenme yüzeylerine** dönüştü: keşfet (hotspot), karşılaştır
(önce/sonra), sırayla uygula (adım akışı), yakınlaş-incele (zoom). Tümü klavye erişilebilir ve
gerçek tarayıcıda production üzerinde doğrulandı.

## Teslim edilen bileşenler (`components/media/`)

| Bileşen             | İşlev                                                      | Erişilebilirlik                                                 |
| ------------------- | ---------------------------------------------------------- | --------------------------------------------------------------- |
| `Hotspots`          | Foto üzerinde keşif noktaları → açıklama balonu            | Gerçek butonlar (Tab/Enter), `aria-expanded`, Escape kapatır    |
| `CompareSlider`     | Önce/sonra karşılaştırma (sağlıklı/aşınmış lastik)         | Kontrol native `<input type=range>` → klavye + dokunmatik doğal |
| `StepFlow`          | Fotoğraflı sıralı prosedür (7 adımlı sürüş öncesi kontrol) | Buton navigasyonu, ilerleme metni `1/7`                         |
| `ZoomImage`         | Tam ekran incele: tekerlek/buton zoom + sürükle pan        | `role=dialog` + `aria-modal`, Escape/backdrop kapatır           |
| `LessonInteractive` | Ders → medya eşlemesini render eden sarmalayıcı            | —                                                               |

## İçerik (`content/interactive-media.ts`)

- **Motor bölmesi turu** (4 nokta: soğutma suyu, yağ çubuğu, cam suyu, akü) — koordinatlar
  gerçek fotoğraf üzerinde **piksel-doğrulamalı** (tarayıcıda ızgara-krokiyle kontrol edildi;
  yanlış konumdaki "hava filtresi" etiketi tespit edilip akü konumuna düzeltildi — dürüst kayıt).
- **Pedal turu** (3 nokta: debriyaj/fren/gaz — pedallara oturduğu görsel olarak doğrulandı).
- **Lastik aşınması karşılaştırması** — yeni üretilen `tyre-worn` varlığı (QC'den geçti) ile
  sağlıklı/aşınmış diş; 1,6 mm yasal sınır vurgusu.
- **Sürüş Öncesi Kontrol Turu** — 7 adım (çevre → lastik → sıvılar → ışıklar → koltuk →
  ayna → kemer), tamamı premium fotoğraflarla.
- Bütünlük testleri: varlıklar çözülür, koordinatlar 0–100 aralığında, ders eşlemeleri geçerli.

## Entegrasyon

- **motor-temel** dersi: motor bölmesi hotspot turu
- **debriyaj-rampa** dersi: pedal hotspot turu
- **arac-hazirlik** dersi: 7 adımlı kontrol akışı + lastik karşılaştırması
- **/arac**: "İnteraktif keşif" bölümü — motor bölmesi turu + yakınlaştırılabilir sigorta kutusu

## 360° görüntüleyici fizibilitesi (ertelendi — gerekçe)

Sprite-sequence 360° için 24–36 **kare-tutarlı** görüntü gerekir; AI üretimi kareler arası
birebir tutarlılığı garanti edemez, gerçek çekim bu fazın kapsamı dışındadır. Karar: 360°,
gerçek ürün fotoğrafçılığı yapıldığında yeniden değerlendirilecek (roadmap'te not düşüldü).
Zoom + hotspot birleşimi aynı öğrenme ihtiyacının büyük bölümünü karşılıyor.

## Doğrulama

| Kapı            | Sonuç                                                                               |
| --------------- | ----------------------------------------------------------------------------------- |
| Birim           | **156/156** yeşil (4 yeni etkileşimli-medya bütünlük testi)                         |
| e2e             | **54/54** yeşil (3 yeni: hotspot aç/Escape · adım akışı + kaydırıcı · zoom overlay) |
| CI              | **Yeşil** (`6c3d06e`)                                                               |
| Production      | Adım akışı ilerletildi, kaydırıcı çalıştı, hotspotlar açıldı — **0 konsol hatası**  |
| Erişilebilirlik | Hotspot=buton, slider=native range, zoom=dialog+Escape, akış=buton                  |
| Hareket         | Hotspot nabız animasyonu `prefers-reduced-motion` ile kapanır                       |

## Düzeltilen sorunlar (dürüst kayıt)

1. Build, tanımsız ESLint kuralına verilen `eslint-disable` yorumuyla kırıldı → yorum kaldırıldı.
2. Hotspot "Akü" noktası önce küçük bir depo üzerine denk geliyordu → tarayıcıda ızgaralı
   krokiyle gerçek akü bloğu (70,47) doğrulanıp taşındı.
3. Yerel e2e'de admin testleri uzun ömürlü manuel sunucuda düşüyor (ilk-kullanıcı-admin
   bootstrap'ı taze DB ister) — Playwright'ın kendi sunucusuyla yeşil; operasyonel not alındı.

## Sonraki faz

**Faz 3 — Hareket & Animasyon**: ADR-012 teknoloji kararı + animasyonlu park/muayene/trafik
senaryoları (reduced-motion güvenli).
