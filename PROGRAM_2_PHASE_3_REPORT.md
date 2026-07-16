# PROGRAM 2 · FAZ 3 RAPORU — Hareket & Animasyon

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

Hareket sistemi "beliriş"ten **anlatan animasyona** yükseltildi: 4 özgün eğitsel animasyon
(paralel park, dik park, kavşakta sağdan gelen, ambulansa yol açma) tamamı kuş-bakışı özgün
SVG sahneler üzerinde, oynat/duraklat/baştan kontrolleriyle ve reduced-motion güvencesiyle canlıda.

## ADR-012 — Teknoloji kararı

Lottie / Rive / Motion / özgün SVG+CSS değerlendirildi (`docs/adr/012-motion-animation.md`).
**Karar: özgün SVG + CSS keyframes** — sıfır yeni bağımlılık, CSP/PWA/offline uyumlu ve
üretim aracı gerçekliğine dürüst (Lottie/Rive profesyonel yazım aracı ister; bu ortamda yok;
gelecekte varlık gelirse CMS `lottie` medya türü kapıyı açık tutuyor). ADR indeksi 007–012 ile
tamamlandı (önceden eksikti).

## Teslim edilenler

- **`components/anim/scenes.tsx`** — 4 özgün sahne (paylaşılan kuş-bakışı araç glifi; renk dili:
  ego=yeşil, diğer=gri, öncelikli=amber, ambulans=beyaz+kırmızı şerit + **yanıp sönen tepe lambası**).
- **`components/anim/AnimPlayer.tsx`** — oynat/duraklat (`animation-play-state`), baştan
  (remount), süre `--anim-dur` ile CSS'e bağlanır; açıklama + **adım listesi her zaman görünür**.
- **`components/anim/LessonAnimations.tsx`** + `content/animations.ts` — ders eşlemesi:
  park-manevra (paralel + dik), kavsak-oncelik & kavsak-uygulama (sağdan gelen),
  trafik-adabi (ambulans); bütünlük testleri.
- **CSS keyframes** (globals.css) — hareket yalnız `transform`; GPU-dostu; duraklatma
  `animation-play-state`; `prefers-reduced-motion` → animasyon kapalı + **bilgilendirici statik
  poz** (ör. kavşakta "yol verme ânı") → bilgi kaybı yok.

## Doğruluk denetimi (dürüst kayıt)

- **Manevra fiziği düzeltildi**: sağa geri paralel parkta burun YUKARI döner (90°→66°→90°);
  ilk taslaktaki ters yön (90°→115°) yayına girmeden düzeltildi.
- 4 animasyonun tümü gerçek tarayıcıda **kare kare izlenerek** doğrulandı: ego çizgide duruyor,
  sağdan gelen önce geçiyor; araçlar ambulans için sağa yanaşıyor; park yörüngeleri gerçekçi.

## Doğrulama

| Kapı            | Sonuç                                                                                  |
| --------------- | -------------------------------------------------------------------------------------- |
| Birim           | **158/158** yeşil (animasyon kataloğu bütünlük testleri dahil)                         |
| e2e             | **55/55** yeşil (yeni: oynat/duraklat/baştan + erişilebilir SVG etiketi + adım sayısı) |
| CI              | **Yeşil** (`f57553d`)                                                                  |
| Production      | Animasyonlar canlı ve akıyor; kontroller çalışıyor; **0 konsol hatası**                |
| Erişilebilirlik | `role=img`+aria-label sahneler; kontroller buton; adımlar metin olarak daima mevcut    |
| Performans      | 0 yeni bağımlılık; yalnız transform animasyonu; bundle büyümesi ≈0                     |

## Sonraki faz

**Faz 4 — Video Öğrenme (mimari)**: ADR-013 + VideoPlayer (bölüm/transkript/yer imi) + şema;
gerçek çekim dış bağımlılık — sahte video yayınlanmaz, Faz 3 animasyonları dürüst alternatif.
