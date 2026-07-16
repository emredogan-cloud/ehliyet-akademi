# ASSET GENERATION PLAN — Program 3 UI

_Ehliyet Akademi · 2026-07-16_

> **Neden plan?** OpenAI faturalandırma **sert limiti** Program 2 Faz 7'de aşıldı
> (`billing_hard_limit_reached`). Üretim şu an bloke; bu dosya her asseti **tek çalıştırmada**
> üretilebilecek kalitede tanımlar. Bütçe açılınca:
> `node scripts/assets/generate.mjs --only <id[,id...]> --quality high` (hattı Program 2'den mevcut;
> yeni id'ler `scripts/assets/catalog.mjs`'e eklenecek). Dosyalar isimlendirmeye uygun
> konduğunda uygulama **otomatik bağlanır** (manifest kimliği = dosya adı).
>
> **Politika:** markasız, plakasız, okunabilir metin/logo YOK, KVKK-dostu (tanınabilir kişi yüzü yok).
> Üretilene dek UI, mevcut SVG/premium fotoğraflarla eksiksiz çalışır (geçici çözüm sütunu).

| Alan              | Değer                                                       |
| ----------------- | ----------------------------------------------------------- |
| Üretim aracı      | OpenAI `gpt-image-1` (mevcut `scripts/assets/generate.mjs`) |
| Varsayılan boyut  | 1536×1024 (hero/banner), 1024×1024 (kare ikon/avatar)       |
| Varsayılan format | WebP (fotoğraf), SVG (ikon — elde çizilecek, API değil)     |
| Kaydedilecek kök  | `apps/web/public/assets/ui/` (yeni)                         |

## Assetler

### A1 · landing-hero

- **Dosya adı:** `landing-hero.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP · **Transparent:** Hayır · **Ekran:** 001/002 landing hero
- **Prompt:** `Cinematic dusk coastal highway curving toward a glowing modern city skyline; a sleek dark sedan and a small white car driving away from camera; subtle teal-cyan glowing light trails along the lane; photorealistic, moody blue hour lighting, high detail. No brand logos, no license plates, no readable text.`
- **Negative:** `text, watermark, brand logo, license plate, people faces, cartoon`
- **Geçici çözüm:** mevcut `components/marketing/HeroArt.tsx` (özgün SVG yol sahnesi).
- **Notlar:** İşaret overlay'leri (DUR/50/üçgen) kod tarafında `TrafficSign` ile eklenir.

### A2 · panel-hero-car

- **Dosya adı:** `panel-hero-car.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1024×1024
- **Format:** WebP (şeffaf tercih) · **Transparent:** Evet (mümkünse) · **Ekran:** 003 panel hero banner
- **Prompt:** `A sleek modern car rendered in profile with cyan-teal glowing energy rings and light trails swirling around it, dark transparent background, premium automotive product render, subtle shield glow. No logos, no plate, no text.`
- **Negative:** `text, logo, plate, background clutter`
- **Geçici çözüm:** teal gradient + `TrafficSign`/SVG kalkan kompozisyonu.

### A3 · learn-decor-city

- **Dosya adı:** `learn-decor-city.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** 004/006 başlık dekoru
- **Prompt:** `Minimal faded night city skyline silhouette with a small teal car, traffic light and a warning-sign pole, soft cyan glow, mostly transparent dark background, subtle decorative illustration style.`
- **Negative:** `text, logo, plate, bright colors, busy detail`
- **Geçici çözüm:** hafif SVG silüet (mevcut çizim dili).

### A4 · ai-coach-avatar

- **Dosya adı:** `ai-coach-avatar.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1024×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** 003/020 AI Koç
- **Prompt:** `Friendly rounded robot mascot head, glossy dark body with purple-to-blue gradient glow, cyan eyes, floating, transparent background, clean 3D mascot render, approachable.`
- **Negative:** `text, logo, human face, weapon`
- **Geçici çözüm:** mevcut 🤖 emoji + mor gradient daire.

### A5 · category-icons (SET — SVG, API değil)

- **Dosya adı:** `apps/web/components/ui/icons/*.tsx` (elde çizilen SVG) · **Boyut:** 24/32/48
- **Format:** SVG (inline React) · **Transparent:** Evet · **Ekran:** 003/004 daire ikonlar
- **Üretim:** API DEĞİL — mevcut özgün SVG çizim dilimizle (Program 1/2 glyph sistemi genişletilir).
- **Kapsam:** ders/özellik kategori ikonları (hedef, beyin, kronometre, kitap, araç, kalkan, yaprak,
  belge, ay/gece, yaya, ilk yardım haçı, akciğer…), her biri renkli daire zemin token'lı.
- **Geçili çözüm:** mevcut emoji ikonlar (çalışır; SVG'ler kademeli değiştirir).

### A6 · progress/stat art (SVG)

- **Format:** SVG (inline) · **Ekran:** 003 stat kartları, ilerleme halkaları
- **Üretim:** elde SVG (halka progress, alev/streak, kupa). Geçici: mevcut emoji/`MasteryRadar`.

### A7 · lesson-hero

- **Dosya adı:** `lesson-hero.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** dersler(004/005) + ders detay(030/031) başlık
- **Prompt:** `Faded night city skyline with a teal-lit road, traffic light and a small car and a warning-sign pole, soft cyan glow, mostly transparent dark background, decorative header illustration.`
- **Negative:** `text, logo, plate, busy detail` · **Geçici:** SVG silüet (mevcut çizim dili).

### A8 · signs-hero

- **Dosya adı:** `signs-hero.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** isaretler(006/007) başlık
- **Prompt:** `A cluster of blank glowing road-sign poles (triangle, circle, octagon shapes, no symbols) along a faded teal-lit road at dusk, transparent dark background, decorative.`
- **Negative:** `text, readable sign symbols, logo, plate` · **Geçici:** `TrafficSign` SVG kompozisyonu.

### A9 · vehicle-hero

- **Dosya adı:** `vehicle-hero.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** arac(+[id]) başlık
- **Prompt:** `Exploded-style faded illustration of a modern car with subtle cyan highlight lines pointing to engine bay, wheels and cabin, transparent dark background, technical yet clean.`
- **Negative:** `text, logo, plate, brand` · **Geçici:** mevcut premium araç fotoğrafı.

### A10 · progress-hero

- **Dosya adı:** `progress-hero.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** ilerleme(021/022) + calisma-plani başlık
- **Prompt:** `Abstract upward-trending glowing teal graph and floating trophy/medal shapes over a dark transparent background, motivational, clean, subtle particles.`
- **Negative:** `text, logo, people` · **Geçici:** SVG grafik + emoji.

### A11 · aicoach-hero

- **Dosya adı:** `aicoach-hero.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** ai-koc(020) başlık/boş durum
- **Prompt:** `Friendly rounded robot mascot (purple-blue gradient glow, cyan eyes) beside floating chat bubbles and knowledge cards, transparent dark background, approachable.`
- **Negative:** `text, human face, weapon, logo` · **Geçici:** A4 avatar + 🤖.

### A12 · premium-banner

- **Dosya adı:** `premium-banner.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1536×1024
- **Format:** WebP · **Transparent:** Hayır · **Ekran:** fiyatlandirma(028) + sidebar Premium kartı
- **Prompt:** `Premium subscription banner: glowing golden crown and shield with soft teal and amber light rays over a deep navy gradient, elegant, no text.`
- **Negative:** `text, logo, plate, people` · **Geçici:** amber/teal gradient + 👑.

### A13 · empty-illustration

- **Dosya adı:** `empty-illustration.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1024×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** tüm boş durumlar (`EmptyState`)
- **Prompt:** `Minimal friendly illustration of an empty road with a small signpost and a magnifying glass, soft teal accents, transparent dark background, calm.`
- **Negative:** `text, logo, clutter` · **Geçici:** mevcut `EmptyState` emoji + daire.

### A14 · loading-illustration

- **Dosya adı:** `loading-illustration.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1024×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** ağır yükleme durumları
- **Prompt:** `Minimal loading illustration: a stylized spinning steering wheel or road loop with teal glow, transparent dark background, simple.`
- **Negative:** `text, logo` · **Geçici:** mevcut `.skeleton` shimmer (yeterli; illüstrasyon opsiyonel).

### A15 · error-404

- **Dosya adı:** `error-404.webp` · **Klasör:** `apps/web/public/assets/ui/` · **Boyut:** 1024×1024
- **Format:** WebP (şeffaf) · **Transparent:** Evet · **Ekran:** `not-found.tsx` / `error.tsx`
- **Prompt:** `Friendly 404 illustration: a small car at a dead-end road sign under a starry night, soft teal glow, transparent dark background, no numerals rendered as text.`
- **Negative:** `readable text, logo, plate` · **Geçici:** SVG çıkmaz-yol işareti + "404" metni koda gömülü.

## Toplam

- **API-üretimi (bütçe bekleyen, planlı):** A1–A4, A7–A15 (fotogerçekçi/illüstrasyon hero + görseller).
- **Elde SVG (bloke değil, hemen yapılabilir):** A5, A6 (ikon + stat sanatı).
- **KURAL:** Hiçbir asset geliştirmeyi bloke etmez — her ekran mevcut asset / eşdeğer / temiz
  placeholder ile eksiksiz çalışır; bütçe açılınca id'ler `scripts/assets/catalog.mjs`'e eklenip
  `node scripts/assets/generate.mjs --only <id...> --quality high` ile tek komutta üretilip
  placeholder'lar değiştirilir (manifest kimliği = dosya adı → otomatik bağlanır).
