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

## Toplam

- **API-üretimi (bütçe bekliyor):** A1–A4 (4 fotogerçekçi görsel).
- **Elde SVG (bloke değil, hemen yapılabilir):** A5, A6 (ikon + stat sanatı).
- Üretim hattı hazır; id'ler `catalog.mjs`'e eklendiğinde tek komut yeterli.
