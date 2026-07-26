# Tasarım kaynak dosyaları (yayınlanmaz)

Buradaki dosyalar **kaynak master'lardır**; hiçbir sayfa bunlara bağlanmaz ve `public/` altında
olmadıkları için CDN'e/dağıtıma da girmezler.

- `new_icon.png` (1254×1254) — uygulama ikonunun master'ı. `icon-512.png`, `icon-192.png` ve
  `apple-touch-icon.png` bundan üretildi (FINAL SPRINT P2).
- `new_icon-lemonsqueezy.png` (1024×1024) — LemonSqueezy ürün görseli; mağaza paneline **elle
  yüklenmek** için tutuluyor (bkz. RELEASE_BLOCKER_RESOLUTION_REPORT.md).

**Neden `public/` değil:** Evolution Faz E13 varlık denetiminde bu iki dosyanın (2,4 MB) hiçbir
yerden referanslanmadığı hâlde her dağıtımla birlikte yayınlandığı görüldü. Master'lar korunmalı
ama yayınlanmamalı — bu yüzden `public/` dışına taşındılar.
