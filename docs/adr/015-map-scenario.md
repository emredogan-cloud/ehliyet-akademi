# ADR-015 — Harita & Senaryo Öğrenme Mimarisi (Program 2 · Faz 8)

**Statü:** Kabul edildi (2026-07-16)

## Bağlam

Faz 8 konum-tabanlı/mekânsal öğrenme ister: kavşak düzenleri, dönel kavşak, şerit seçimi,
yaya geçidi, dar geçit gibi **karar anlarını** mekân üzerinde öğretmek. Kısıtlar: CSP
`default-src 'self'` (dış tile/script yok), PWA/offline, gizlilik (konum verisi toplamayız),
telif (harita görselleri lisanslıdır).

## Değerlendirme

| Seçenek                                           | Offline/CSP      | Gizlilik     | Telif            | Eğitsel odak                             | Karar                                                |
| ------------------------------------------------- | ---------------- | ------------ | ---------------- | ---------------------------------------- | ---------------------------------------------------- |
| Google Street View                                | ❌ dış istek     | izleme riski | lisans kısıtları | gerçekçi ama kontrolsüz                  | 🔜 yalnız gelecekte, açık rızayla (ayrı entegrasyon) |
| MapLibre + OSM tile                               | ❌ tile sunucusu | orta         | ODbL atıf        | gerçek şehir, ama karar anı kurgulanamaz | ❌                                                   |
| **Özgün kuş-bakışı SVG sahneler + senaryo grafı** | ✅ mükemmel      | ✅ veri yok  | ✅ %100 özgün    | karar anı tam kontrol                    | ✅                                                   |

## Karar

1. **Deklaratif sahne DSL'i** (`SceneSpec`): yol/şerit/zebra/araç/yaya/işaret öğeleri JSON ile
   tanımlanır; `SceneCanvas` özgün SVG olarak çizer (ADR-012 sahne diliyle tutarlı; işaretler
   Faz 6 parametrik sistemden gelir).
2. **Senaryo grafı**: `Scenario = adımlar(DAG)`; her adım sahne + soru + seçenekler; seçenek
   `verdict (safe/risky)` + öğretici açıklama + opsiyonel `next` adım taşır. Motor puanlar;
   çıkmaz/kopuk adım test kapısıyla yasaktır.
3. **Gerçek kişisel rota/konum verisi YOK** — senaryolar geneldir (KVKK-dostu).
4. **Street View geleceği**: gerçekçi görüntü istenirse ayrı bir ADR ile, yalnız kullanıcı
   etkileşimiyle yüklenen, rıza-kapılı bir dış bileşen olarak eklenir (CSP istisnası o gün
   değerlendirilir). Bu fazın mimarisi buna kapı bırakır (senaryo adımına `media` alanı eklenebilir).

## Sonuçlar

- Sıfır dış bağımlılık; senaryo üretim maliyeti düşük (JSON + mevcut çizim dili).
- Aynı motor Faz 9'da pratik senaryo içeriğiyle beslenecek.
