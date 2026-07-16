# ADR-013 — Video Öğrenme Mimarisi (Program 2 · Faz 4)

**Statü:** Kabul edildi (2026-07-16)

## Bağlam

Faz 4, eksiksiz video öğrenme mimarisi ister: sürüş gösterimleri, park eğitimleri, sınav
yürüyüşleri, bölümler, transkript, yer imleri, AI özetleri. Kısıtlar ve gerçekler:

- **Gizlilik-öncelikli platform** (KVKK-dostu, rızasız izleyici yok, CSP `default-src 'self'`).
- **Gerçek çekim video yok** (stüdyo/araç çekimi dış bağımlılık — kullanıcı kararı).
- Dürüstlük ilkesi: "çekilmiş gibi" sahte video YAYINLANMAZ.

## Değerlendirme (barındırma)

| Seçenek                                          | Gizlilik                     | Maliyet           | CSP                      | Karar                      |
| ------------------------------------------------ | ---------------------------- | ----------------- | ------------------------ | -------------------------- |
| YouTube (nocookie dahi)                          | çerez/izleme riski, 3P istek | ücretsiz          | iframe istisnası gerekir | ❌ varsayılan olarak değil |
| Mux/Cloudflare Stream                            | iyi                          | akış başına ücret | connect-src ekleme       | 🔜 ölçek yolu (kapı açık)  |
| **Self-host statik MP4/WebM + native `<video>`** | mükemmel (3P istek yok)      | Vercel static/CDN | değişiklik gerekmez      | ✅                         |

## Karar

1. **Native HTML5 `<video>` + self-host statik dosyalar** (`public/videos/`), üçüncü taraf yok.
2. **Bölümler + transkript + altyazı (WebVTT) + yer imleri** içerik şemasıyla tanımlanır
   (`content/videos.ts`); transkript paneli `timeupdate` ile senkron vurgulanır; yer imleri
   `localStorage` (`ea:videoBookmarks:v1`).
3. **İçerik dürüstlüğü**: video kataloğu `status: 'available' | 'planned'` taşır. Gerçek çekim
   gelene dek `available` içerik yalnız **kendi animasyonlarımızdan render edilen** özgün
   eğitim videolarıdır (ADR-012 sahneleri → ffmpeg). `planned` girdiler arayüzde açıkça
   "çekim planlanıyor" olarak gösterilir.
4. **AI özet**: transkriptten türetilen deterministik özet (`lib` saf fonksiyon, testli) +
   mevcut grounded AI hattına bağlanabilir zemin. Model çağrısı zorunlu değil; halüsinasyon yok.
5. Ölçek yolu: gerçek çekim + izleyici hacmi gelirse Mux/Stream adaptörü eklenir
   (şema değişmez; `src` mutlak URL destekler, CSP `media-src` genişletilir).

## Sonuçlar

- Sıfır üçüncü-taraf isteği; offline (PWA) uyumlu; oynatıcı tamamen bizim kontrolümüzde.
- Video üretim hattı (`apps/web/scripts/render-video.mjs`) animasyon sahnelerini gerçek
  MP4'e çevirir — kataloğun ilk videoları böylece %100 özgün ve telifsiz.
