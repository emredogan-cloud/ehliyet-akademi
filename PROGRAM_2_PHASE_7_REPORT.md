# PROGRAM 2 · FAZ 7 RAPORU — Araç Bilgisi Genişletmesi

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

Araç kütüphanesi **34 → 70 bileşene** çıktı (hedef ≥70 ✓). 36 yeni bileşenin her biri
**kontrol adımları (2–4 sıralı) + sık hata + premium görsel** taşıyor; 70 bileşenin tümü kendi
**detay sayfasına** kavuştu; `/arac` TR-normalize **arama** kazandı. Görsel quiz havuzu
otomatik 153 → 186 öğeye büyüdü.

## Teslim edilenler

- **33 yeni premium fotogerçekçi görsel** (filtreler, kayışlar, fren disk/balata, süspansiyon,
  rot başı, aks körüğü, katalitik, park sensörü, geri kamera, ISOFIX, zincir, basınç ölçümü,
  takviye kablosu…) — insan-gözü QC'den geçti.
- **Katalog 70 bileşen** — `VehiclePart` şemasına geriye dönük uyumlu `inspection[]` + `mistake`
  alanları; 36 yeni bileşen teknik-doğru içerikle (triger kopması→ağır hasar; takviye sırası;
  takoz iniş yönüne; basınç soğuk lastikte; katalitik kuru ot yangın riski…).
- **70 detay sayfası `/arac/[id]`** — foto/şema + kontrol adımları kartı + sık hata callout'u +
  bankadan grounded sorular + quiz/ders bağları.
- **Aranabilir galeri** — TR-normalize arama, sistem başına sayaçlar, premium boş durum.

## Dış bağımlılık olayı (dürüst kayıt)

- Üretimin son 3 görselinde **OpenAI faturalandırma sert limiti** aşıldı
  (`billing_hard_limit_reached`): fire-extinguisher, warning-triangle-road, child-lock.
  **Dürüst geri dönüş**: bu 3 bileşen için özgün **çizim şemaları** eklendi (VehicleFigure);
  manifest'ten foto kayıtları çıkarıldı. Bütçe açıldığında `--only` bayrağıyla tek komutla
  yeniden üretilebilir (kullanıcı aksiyonu).
- **jump-cables** görselinin arka planındaki araçta VW logosu tespit edildi → yeniden üretim
  bütçe nedeniyle mümkün olmadığından **ffmpeg delogo** ile logo kaldırıldı; sonuç QC'den geçti.

## Doğrulama

| Kapı       | Sonuç                                                                                                                  |
| ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| Birim      | **178/178** (yeni: ≥70, kontrol adımı kapsaması ≥30, foto-manifest çözünürlüğü, grounded sözleşme)                     |
| e2e        | **60/60** (yeni: arama süzme + detay sayfası + kontrol adımları)                                                       |
| CI         | **Yeşil** (`238fee4`)                                                                                                  |
| Production | /arac + 70 detay sayfası canlı; timing-belt sayfası tarayıcıyla doğrulandı; vitrin istatistiği 70; **0 konsol hatası** |

## Sonraki faz

**Faz 8 — Harita & Senaryo Öğrenme**: senaryo motoru (karar → sonuç → açıklama) + ≥6 özgün
kuş-bakışı senaryo + ADR-015 (Street View gelecek yolu).
