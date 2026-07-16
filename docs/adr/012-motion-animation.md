# ADR-012 — Hareket & Animasyon Teknolojisi (Program 2 · Faz 3)

**Statü:** Kabul edildi (2026-07-16)

## Bağlam

Program 2 Faz 3, "anlatan animasyon" ister: park manevraları, kavşak öncelik senaryoları,
araç muayene sekansları. Kısıtlar:

- **CSP**: `default-src 'self'`; dış CDN/script yok (Sprint 5 güvenlik sertleştirmesi).
- **PWA/offline**: animasyon varlıkları offline çalışmalı, hafif olmalı.
- **Erişilebilirlik**: `prefers-reduced-motion` desteği + oynat/duraklat kontrolü zorunlu.
- **Üretim aracı gerçeği**: Lottie (After Effects) ve Rive (Rive editörü) profesyonel
  yazım araçları gerektirir; bu ortamda bu araçlar yok. Eldeki güçlü yetenek: **özgün SVG
  sahne üretimi** (Program 1'de kanıtlandı) + CSS/Web animasyonu.

## Değerlendirme

| Seçenek                       | Bundle               | Offline/CSP | Yazım maliyeti                            | Karar                    |
| ----------------------------- | -------------------- | ----------- | ----------------------------------------- | ------------------------ |
| Lottie (lottie-web)           | ~60KB+ player + JSON | uyumlu      | AE gerektirir → üretilemez                | ❌                       |
| Rive (@rive-app)              | ~80KB + .riv         | uyumlu      | Rive editörü gerektirir → üretilemez      | ❌                       |
| Motion (motion.dev)           | ~18KB+               | uyumlu      | JS-hafif ama SVG sahneyi yine biz çizeriz | ❌ (gereksiz bağımlılık) |
| **Özgün SVG + CSS keyframes** | **0 ek bağımlılık**  | mükemmel    | Tamamen elimizde                          | ✅                       |

## Karar

**Özgün SVG sahneler + CSS keyframe animasyonu**, `animation-play-state` ile oynat/duraklat,
`key` yeniden-montajıyla baştan oynatma. Kurallar:

1. Her animasyon kuş-bakışı **özgün SVG sahnesi** (yol, şeritler, araçlar) — telifsiz.
2. Hareket yalnız `transform` (translate/rotate) — GPU-dostu, layout tetiklemez.
3. `prefers-reduced-motion: reduce` → animasyon kapalı; sahne SON konumda statik gösterilir
   ve adım metinleri her zaman görünür (bilgi kaybı yok).
4. Oynat/Duraklat/Baştan düğmeleri klavye erişilebilir; süreler 6–10 sn döngü.
5. Yeni runtime bağımlılığı YOK.

## Sonuçlar

- Lottie/Rive kapısı kapanmadı: ileride profesyonel tasarım varlıkları gelirse CMS medya
  kütüphanesi `lottie` türünü zaten destekliyor (Sprint 2); oynatıcı o gün eklenir.
- Animasyon başına maliyet düşük; işaret/araç görsel sistemleriyle stil bütünlüğü korunur.
