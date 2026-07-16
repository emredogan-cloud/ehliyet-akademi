# PROGRAM 2 · FAZ 6 RAPORU — Trafik İşareti Genişletmesi

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

İşaret sistemi **42 → 121 özgün işarete** genişledi (hedef ≥120 ✓) ve her işaret artık kendi
**detay sayfasına** sahip: anlam, hafıza tekniği, sık hata, "Karıştırma! Farkı gör"
karşılaştırmaları ve bankadan grounded ilgili sorular. Görsel quiz havuzu otomatik olarak
76 → 153 öğeye büyüdü.

## Teslim edilenler

- **Piktogram motoru 26 → 59 özgün glyph** (rüzgar tulumu, tünel, düşen kaya, kıyı, alçak uçuş,
  tramvay, kamyon, motosiklet, traktör, el/at arabası, geyik, zincir, U-dönüş, dönüş okları,
  telefon, tamirhane, akaryakıt, otel, lokanta, çeşme, kamp, otobüs, öncelik okları, çıkmaz yol,
  yasak-sonu çizgileri, kar tanesi…). `GLYPH_IDS` dışa aktarımı test kapısı oldu; uzun
  `glyphText` için uyarlanabilir yazı boyutu (GÜMRÜK taşması düzeltildi).
- **Katalog 121 işaret / 8 kategori** — tehlike 29, yasak 35, mecburiyet 14, bilgi 21, park 6,
  otoyol 5, geçici 5, öncelik 6. Her giriş: mevzuata-uygun anlam, özgün hafıza ipucu, sınav
  önemi, sık hata, ilgili ders, arama anahtar kelimeleri. (Telif: standart şekil/renk serbest;
  piktogramlar kendi çizimimiz; metinler kendi ifademiz.)
- **Detay sayfaları `/isaretler/[id]`** — 121 statik sayfa: büyük işaret + anlam + hafıza/hata
  callout'ları + **karıştırılan çift karşılaştırmaları** (6 küratörlü çift: DUR/Yol Ver,
  viraj/dönüş yasağı, yaya uyarı/bilgi, park/duraklama, daralma/iki yön, azami/asgari hız) +
  **bankadan grounded sorular** (kökte işaret adı/anahtar kelime eşleşmesi) + quiz/ders bağları.
- **Galeri** kartlarından detaya bağlantı; sayaçlar ve vitrin istatistiği otomatik 121 oldu.

## Doğrulama

| Kapı       | Sonuç                                                                                                             |
| ---------- | ----------------------------------------------------------------------------------------------------------------- |
| Birim      | **174/174** (yeni kapılar: ≥120, benzersiz id, glyph çözünürlüğü, eğitim alanları, çift bütünlüğü, grounded soru) |
| e2e        | **59/59** (yeni: detay sayfası + karşılaştırma + galeri ≥120)                                                     |
| CI         | **Yeşil** (`797d3d7`)                                                                                             |
| Production | 121 işaret canlı; detay sayfaları (dur, kamyon-giremez) 200; vitrin istatistiği 121; görsel QC yapıldı            |

## Düzeltilen sorunlar (dürüst kayıt)

1. **GÜMRÜK metin taşması** — halka içindeki uzun `glyphText` için uyarlanabilir font boyutu.
2. **Eşleyici sıralaması** — katalog büyüyünce "rampa" anahtar kelimesi "el freni" bileşen adını
   limitten düşürdü → sıralama işaret-adı > bileşen-adı > anahtar-kelime yapıldı (birim test yakaladı).
3. Katalog ajanının istediği ama olmayan glyph'ler (açılan köprü, T-kavşak varyantları) rapora
   not edildi — Faz 9 genişletmesinde eklenebilir.

## Sonraki faz

**Faz 7 — Araç Bilgisi Genişletmesi**: 34 → ≥70 bileşen; premium foto dalgası (Faz 1 hattı);
muayene adımları + bileşen-quiz bağları.
