"""
Faz 9 — ödeme ekranının hero görseli.

GİRDİ (repoda DEĞİL — .gitignore'da):
  <repo>/apps/assets/interface-assets/025-assets.png   (1536×1024, RGBA)

ÇIKTI (repoda İZLENİR):
  apps/mobile/assets/img/paywall_hero.webp

KULLANIM:
  python3 apps/mobile/tool/extract_paywall_hero.py

NEDEN YALNIZ 025 SEVK EDİLİYOR — projedeki kural (bkz. `lib/core/assets.dart` ve `auth_screen.dart`
sınıf notu): **sanat rasterdır, MOCKUP widget'tır.** Referans ödeme ekranının dört parçası var:
  · 025 → taç madalyonu + araç + şerit: GERÇEK SANAT. Widget'la yeniden çizilemez → sevk edilir.
  · 026 → özellik şeridi (dört sütun, neon simge + başlık + alt metin): MOCKUP → widget.
  · 027 → onay listesi + telefon render'ı: MOCKUP → widget. Telefon render'ı ayrıca uygulamanın
    ESKİ bir hâlini gösteriyor; raster olarak sevk edilseydi ilk arayüz değişikliğinde yalan olurdu.
  · 028 → fiyat bloğu + satın alma düğmesi: MOCKUP → widget. Fiyatın raster olması ayrıca
    KABUL EDİLEMEZ; fiyat mağazadan gelir ve ülkeye göre değişir.

İŞLEM: alt %6 kırpılır (kaynakta boş yol zemini), 1080 px genişliğe indirilir ve WebP'ye çevrilir.
Şeffaflık KORUNUR: hero koyu zemine oturuyor ve kenarları yumuşak.
"""

from __future__ import annotations

import os
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit('Pillow gerekli:  pip install Pillow')

HERE = os.path.dirname(os.path.abspath(__file__))
MOBILE = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(MOBILE))
SRC = os.path.join(REPO, 'apps', 'assets', 'interface-assets', '025-assets.png')
OUT = os.path.join(MOBILE, 'assets', 'img', 'paywall_hero.webp')

TARGET_WIDTH = 1080
BOTTOM_CROP = 0.06
QUALITY = 88


def main() -> int:
    if not os.path.exists(SRC):
        sys.exit(f'kaynak yok: {SRC}')

    im = Image.open(SRC).convert('RGBA')
    w, h = im.size
    im = im.crop((0, 0, w, int(h * (1 - BOTTOM_CROP))))

    scale = TARGET_WIDTH / im.width
    im = im.resize((TARGET_WIDTH, round(im.height * scale)), Image.LANCZOS)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    im.save(OUT, 'WEBP', quality=QUALITY, method=6)
    print(f'yazıldı: {os.path.relpath(OUT, REPO)}  {im.size}  {os.path.getsize(OUT) // 1024} KB')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
