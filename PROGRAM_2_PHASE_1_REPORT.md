# PROGRAM 2 · FAZ 1 RAPORU — Premium Görsel Varlık Kütüphanesi

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

Platformun görsel omurgası "hafif çizim"den **premium fotogerçekçi eğitim görseline** taşındı.
**34 premium görsel** üretildi, insan gözüyle kalite denetiminden geçirildi, metaverili manifestle
uygulamaya entegre edildi. Araç kütüphanesi **21 → 34 bileşene** çıktı; `/arac` foto-öncelikli
kartlara dönüştü; 6 ders premium fotoğraf şeridi kazandı.

## Kaynak araştırması ve karar (dürüst kayıt)

Roadmap önceliği: (1) açık lisanslı gerçek fotoğraf → (2) AI-üretimi fotogerçekçi görsel.

- **Açık lisans taraması (Wikimedia Commons API)**: "car engine bay", "oil dipstick check",
  "brake fluid reservoir", "car pedals clutch" sorguları test edildi. Sonuçlar: klasik/antika
  araçlar, oyuncaklar, motosikletler, marka logolu ve tutarsız kalitede kullanıcı fotoğrafları.
  **"Premium + tutarlı + modern + markasız" çıtasını karşılamıyor.**
- **Karar**: `OPENAI_API_KEY` ile **gpt-image-1** üretimi (high kalite, 1536×1024, WebP@85)
  birincil yol seçildi — tutarlı stil, marka/plaka riski yok, lisans belirsizliği yok.
  Açık lisans yolu manifest şemasında (`cc0`/`cc-by` + attribution) desteklenmeye devam ediyor.

## Üretim hattı (pipeline)

- `scripts/assets/catalog.mjs` — 34 varlığın kimlik/başlık/alt/etiket/prompt kataloğu.
  Ortak stil: eğitim el kitabı fotoğrafı, markasız modern araç, plaka yok, logo yok, yüz yok.
- `scripts/assets/generate.mjs` — OpenAI Images API; eşzamanlılık 3, 429/5xx yeniden deneme,
  mevcut dosyayı atlama, `--only/--force/--quality/--dry` bayrakları. Sır `.env`den okunur,
  asla loglanmaz/commit edilmez.

## Kalite denetimi (insan gözüyle, gerçek tarayıcıda)

Tüm 34 görsel kontak-sayfada tek tek incelendi:

- **2 görsel REDDEDİLDİ ve yeniden üretildi**: `fog-lights` (ön ızgarada VW logosu) ve
  `emergency-kit` (kadrajda markalı minyatür araç). Prompt'lar sıkılaştırıldı (rozet kadraj dışı /
  yalnız 3 nesne düz yerleşim); yeniden üretim ikisi de temiz.
- Kabul edilen istisnalar (bilinçli): `automatic-gearbox` P-R-N-D-L ve `wiper-controls`
  INT/LOW/HIGH — işlevsel standart harfler (marka değil, eğitsel değer taşır);
  `steering` üzerindeki "AIRBAG" — yasal standart ibare.
- Sonuç: **34/34 markasız, plakasız, fotogerçekçi, eğitsel olarak doğru.**

## Manifest + bileşenler + entegrasyon

- `content/asset-manifest.ts` — tip güvenli manifest: id/src/başlık/**Türkçe alt metin**/boyut/
  **lisans**/etiketler; `visualAssetById()`; `LESSON_PHOTOS` ders eşlemesi.
- `components/ui/AssetImage.tsx` — next/image: **lazy + responsive (`sizes`) + erişilebilir**
  figure/figcaption; manifest dışı kimlikte hiçbir şey basmaz.
- `components/LessonPhotos.tsx` — ders foto şeridi (mobilde yatay kaydırmalı, scroll-snap).
- **Araç kütüphanesi 21 → 34 parça**: 13 yeni foto-öncelikli bileşen (emniyet kemeri, bagaj,
  acil durum ekipmanı, ikaz lambaları, konsol düğmeleri, direksiyon/sinyal/silecek kumandaları,
  ayna/koltuk ayarları, otomatik vites, farlar, sis farları). Kırık ders bağlantısı düzeltildi
  (`seritler-donusler` → `sollama-serit`) + kalıcı test kapısı eklendi.
- `/arac` — foto-öncelikli kartlar + `<details>` içinde çizim şeması (şeması olanlarda);
  yeni `vehicle-grid` (240px+ sütun) ile premium sunum.
- **6 ders** premium foto şeridi kazandı: arac-hazirlik, motor-temel, gosterge-ikaz,
  isik-gece, debriyaj-rampa, park-manevra.

## Doğrulama

| Kapı                | Sonuç                                                                                                                                                                                              |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Birim testleri      | **152/152** yeşil (manifest bütünlüğü: benzersiz id, dosya mevcut, WEBP sihirli bayt, <400KB bütçe, ders eşlemesi çözülür; araç: şema VEYA foto zorunlu, foto→manifest, ders bağlantıları çözülür) |
| e2e (Playwright)    | **51/51** yeşil (2 yeni: /arac foto kartları + şema aç/kapa; ders foto şeridi)                                                                                                                     |
| CI (GitHub Actions) | **Yeşil** (`b870ae6`) — bir lint hatası (`c50a99d`) anında düzeltildi                                                                                                                              |
| Production          | **Canlı + gerçek tarayıcıyla doğrulandı** — /arac premium kartlar, motor-temel foto şeridi, **0 konsol hatası**                                                                                    |
| Performans          | WebP, ort. ~160KB/dosya (hepsi <400KB), lazy + responsive `sizes`, Vercel image optimizer devrede                                                                                                  |
| Erişilebilirlik     | Her görselde anlamlı Türkçe `alt`; figure/figcaption; foto şeridi `role="group"`                                                                                                                   |

## Canlıda bulunan ve düzeltilen sorunlar (dürüst kayıt)

1. **CI lint hatası** — üretim betiğinde kullanılmayan parametre → `c50a99d` ile düzeltildi.
2. **Fotoğraflar 110px render ediliyordu** — `/arac` dar `sign-grid`i kullanıyordu; özel
   `vehicle-grid` (240px+) eklendi → `b870ae6`. Production'da yeniden doğrulandı.
3. **Yanlışlıkla oluşan Vercel projesi** — deploy yanlış dizinden çalışınca oluşan "apps"
   projesi tespit edilip **silindi**; doğru projeden yeniden deploy edildi.

## Maliyet notu

34 × gpt-image-1 (high, 1536×1024) + 2 yeniden üretim ≈ **~9 USD** tek seferlik üretim maliyeti.
Pipeline tekrarlanabilir; Faz 6–7 genişlemeleri aynı hattı kullanacak.

## Sonraki faz

**Faz 2 — Etkileşimli Medya**: hotspot, zoom, önce/sonra karşılaştırma, adım adım muayene akışı —
bu fazın premium fotoğrafları üzerine inşa edilecek.
