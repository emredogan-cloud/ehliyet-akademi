# PROGRAM 2 · FAZ 8 RAPORU — Harita & Senaryo Öğrenme

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

Mekân-tabanlı öğrenme katmanı kuruldu: **deklaratif kuş-bakışı sahne DSL'i + karar grafı
motoru + 7 özgün sürüş senaryosu** (`/senaryolar`). Kullanıcı sahneyi görür, kararını verir,
kararın güvenli/riskli olduğunu ve NEDENİNİ öğrenir; senaryo sonunda güvenli karar skoru alır.

## ADR-015 — Harita kararı

Google Street View (dış istek + izleme + lisans) ve MapLibre/OSM (tile sunucusu; karar anı
kurgulanamaz) yerine **özgün kuş-bakışı SVG sahneler** seçildi: CSP/offline/gizlilik/telif
tamamı temiz; karar anı tamamen kurgulanabilir. Street View, ileride rıza-kapılı ayrı bir
bileşen olarak eklenebilir (mimari kapı bırakıldı). Kişisel konum/rota verisi YOK.

## Teslim edilenler

- **`SceneSpec` DSL'i** — yol/şerit/durma çizgisi/zebra/araç(ego-diğer-öncelikli-ambulans)/
  yaya/işaret rozeti JSON ile tanımlanır; `SceneCanvas` özgün SVG çizer (ADR-012 sahne diliyle
  tutarlı; işaret rozetleri Faz 6 parametrik sisteminden — katalog testle doğrulanır).
- **Karar grafı motoru** — `ScenarioRunner`: adım → seçenek → `safe/risky` + öğretici açıklama →
  `next` adım veya özet (güvenli karar skoru, ilgili derse bağlantı). `validateScenarioGraph`
  çıkmaz/kopuk adımı yasaklar (test kapısı).
- **7 özgün senaryo**: sağdan gelen (2 adım), dönel kavşak girişi, tali yoldan çıkış (2 adım),
  arkadan ambulans, yaya geçidinde bekleyen yaya, dar geçit önceliği, okul bölgesi hız kararı.
- **`/senaryolar`** — sahne önizlemeli kartlar + koşucu; kenar çubuğunda "Senaryolar".

## Doğrulama

| Kapı       | Sonuç                                                                                                          |
| ---------- | -------------------------------------------------------------------------------------------------------------- |
| Birim      | **183/183** (5 yeni: graf bütünlüğü, güvenli-seçenek zorunluluğu, ayrışık seçenekler, işaret/ders çözünürlüğü) |
| e2e        | **61/61** (yeni: tam akış — kart → 2 adımlı senaryo → 2/2 özet → çıkış)                                        |
| CI         | **Yeşil** (`ce04870`)                                                                                          |
| Production | /senaryolar canlı (200); yerel gerçek tarayıcıda kart + koşucu görsel doğrulandı                               |

## Sonraki faz

**Faz 9 — Büyük İçerik Genişletmesi**: soru bankası 534 → **1500+** (dalgalar halinde, kalite
denetimli), ders derinleştirme, senaryo içerik artışı, bank yükleme performans stratejisi.
