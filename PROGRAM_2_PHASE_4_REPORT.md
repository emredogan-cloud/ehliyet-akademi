# PROGRAM 2 · FAZ 4 RAPORU — Video Öğrenme

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI** (mimari + özgün ilk içerik; gerçek çekim dış bağımlılık)_

## Özet

Eksiksiz video öğrenme mimarisi kuruldu **ve** ilk iki özgün video yayınlandı: ADR-012 animasyon
sahnelerimiz kare kare render edilip gerçek MP4/WebM videolara dönüştürüldü. Oynatıcı; bölümler,
senkron transkript, WebVTT altyazı, yer imleri, hız kontrolü ve klavye kısayolları taşıyor.
Gerçek çekim müfredatı dürüstçe "çekim planlanıyor" olarak listeleniyor — sahte video yok.

## ADR-013 — Barındırma kararı

Native HTML5 `<video>` + **self-host statik dosyalar**; üçüncü taraf istek yok (gizlilik + CSP
değişmeden). YouTube varsayılan olarak reddedildi (izleme riski); Mux/Stream ölçek yolu olarak
belgelendi. Açık kodek erişilebilirliği için her video **MP4 (H.264) + WebM (VP9)** çift format.

## Video üretim hattı (özgün içerik)

`apps/web/scripts/render-video.mjs`: animasyon sahnesi → Web Animations API ile kare dondurma
(`currentTime`) → Playwright ekran görüntüsü → ffmpeg birleştirme → MP4 + WebM + poster.
Üretilen ilk videolar (~16KB!):

| Video                    | Süre | Bölüm | Transkript | Altyazı   |
| ------------------------ | ---- | ----- | ---------- | --------- |
| Paralel Park — Adım Adım | 9 sn | 4     | 4 cue      | TR WebVTT |
| Kavşakta Sağdan Gelen    | 8 sn | 4     | 4 cue      | TR WebVTT |

## Oynatıcı (`components/video/VideoPlayer.tsx`)

- **Bölümler**: çip → `currentTime` atlaması + oynatma
- **Senkron transkript**: `timeupdate` ile aktif cue vurgusu; satıra tıkla → o âna git
- **Yer imleri**: `ea:videoBookmarks:v1` (localStorage), zaman çipleriyle geri dönüş
- **AI özet zemini**: `summarizeTranscript` — transkriptten deterministik özet (halüsinasyonsuz)
- Hız 0.75–1.5×, WebVTT altyazı (`<track>`), klavye: boşluk oynat/duraklat, ←/→ 5 sn
- `/videolar` sayfası + kenar çubuğu "Videolar" bağlantısı; planlanan müfredat rozetli

## Doğrulama

| Kapı       | Sonuç                                                                                                                                                    |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Birim      | **162/162** (video kataloğu: dosyalar diskte, VTT başlığı, cue sıralaması, planned dürüstlüğü)                                                           |
| e2e        | **56/56** (yeni: bölüm çipleri + transkript + yer imi + planned rozetleri)                                                                               |
| CI         | **Yeşil** (`c8cad0f`)                                                                                                                                    |
| Production | /videolar canlı; mp4/webm/vtt doğru content-type ile servis; bölüm atlama + altyazı + transkript senkronu gerçek tarayıcıda çalıştı; **0 konsol hatası** |

## Düzeltilen sorunlar (dürüst kayıt)

1. **CI lint**: render betiğindeki `page.evaluate` içi `document` node-lint'e takıldı → `/* global document */`.
2. **CI e2e**: yeni "Video Dersler" menü etiketi, kabuk testinin `/Dersler/` regex'iyle çakıştı →
   etiket "Videolar" yapıldı. Ders çıkarımı: **push öncesi TAM e2e süiti** (yalnız visual değil).
3. Playwright Chromium'un H.264 içermemesi öngörülüp WebM (VP9) varyantı eklendi.

## Dış bağımlılık (kullanıcı kararı)

Gerçek çekim videolar (sınav yürüyüşü, gerçek araç kontrolü, rampa pedal kamerası, sık hatalar)
stüdyo/araç çekimi gerektirir. Mimari hazır: dosyaları `public/videos/`e koyup katalogda
`status:'available'` yapmak yeterli.

## Sonraki faz

**Faz 5 — AI Görsel Öğrenme**: görsel quiz, AI yanıtlarına görsel kart iliştirme, görsel SRS,
ADR-014 (vizyon mimarisi, gizlilik-öncelikli).
