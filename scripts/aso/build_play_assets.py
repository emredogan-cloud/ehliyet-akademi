#!/usr/bin/env python3
"""Ham ASO plakalarını Play'in teknik biçimine NORMALLEŞTİR.

    ÜRET → DENETLE → [BİNDİR] → ONAR → NORMALLEŞTİR → DOĞRULA → DIŞA AKTAR
                       ^^^^^^^
                       bu aşama HENÜZ YAPILMADI (aşağıya bakın)

Bu betik boru hattının **NORMALLEŞTİRME** aşamasıdır: alfa düzleştirme, 1080×1920'e yeniden
örnekleme, sRGB, üst veri temizliği. Belirlenimcidir — aynı girdi her çalıştırmada bayt bayt aynı
çıktıyı verir.

## ÖNEMLİ: çıktı YÜKLEMEYE HAZIR DEĞİLDİR

Ham plakalar TASARIM GEREĞİ metinsizdir ve telefon ekranları boştur (bkz. ASO_PROMPT_LIBRARY.html
§0 — Türkçe aksanları üreteçe çizdirmemek ve uydurma arayüzü yapısal olarak engellemek için).
Yüklemeye hazır bir varlık için iki şey daha gerekir:

  1. Telefon ekranına GERÇEK cihaz ekran görüntüsünün perspektifle bindirilmesi
  2. Türkçe tipografinin (başlık, kartlar, güven şeridi) ölçülmüş kutulara dizilmesi

Bu iki adım tamamlanmadan çıktı Play'e YÜKLENMEZ. Bu yüzden betik `PLAY_READY/` dizini
ÜRETMEZ — yalnız `NORMALIZED/` üretir ve yanına neden yüklenemeyeceğini yazan bir not koyar.
Yüklenebilir görünen bir klasör üretmek, birinin onu yüklemesiyle sonuçlanırdı.

Kullanım
--------
    python3 scripts/aso/build_play_assets.py [--src DIZIN] [--out DIZIN]
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit("Pillow gerekli:  pip install pillow")

# Marka tuvali — alfa BUNUN üzerine düzleştirilir, beyaza değil.
# Beyaza düzleştirmek koyu varlıkların kenarlarında açık bir saçak bırakırdı.
CANVAS = (5, 11, 22)  # #050B16 — uygulamanın koyu tema zemini (tokens.dart)

PHONE_TARGET = (1080, 1920)
ICON_TARGET = (512, 512)
FEATURE_TARGET = (1024, 500)


def flatten(im: Image.Image) -> Image.Image:
    """Alfayı marka tuvali üzerine düzleştir ve RGB döndür."""
    if im.mode in ("RGBA", "LA", "PA") or "transparency" in im.info:
        rgba = im.convert("RGBA")
        bg = Image.new("RGB", rgba.size, CANVAS)
        bg.paste(rgba, mask=rgba.split()[-1])
        return bg
    return im.convert("RGB")


def cover_crop(im: Image.Image, target: tuple[int, int]) -> Image.Image:
    """Hedef orana KAPLA-KIRP ile getir, sonra hedef boyuta ölçekle.

    Kapla-kırp seçildi (sığdır-kutula değil): kutulama kenarlarda bant bırakır ve Play karuselinde
    tutarsız görünür. Kırpma merkezden yapılır; kompozisyonlar merkez ağırlıklı tasarlandığı için
    kenardan kaybedilen şey zemin parıltısıdır.
    """
    tw, th = target
    sw, sh = im.size
    scale = max(tw / sw, th / sh)
    nw, nh = round(sw * scale), round(sh * scale)
    resized = im.resize((nw, nh), Image.LANCZOS)
    left, top = (nw - tw) // 2, (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def save_clean(im: Image.Image, dest: Path) -> None:
    """Üst veri olmadan, sıkıştırılmış olarak yaz.

    `optimize=True` + varsayılan PNG yazıcısı, Pillow'un bıraktığı yardımcı yığınları da
    üretmez. exiftool bu ortamda yok; PNG yolunda Pillow zaten EXIF yazmıyor.
    """
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, format="PNG", optimize=True)


def classify(p: Path) -> str:
    n = p.name.lower()
    if "icon" in n:
        return "icon"
    if "feature" in n or "grafi" in n:
        return "feature"
    if p.stem[:3].isdigit():
        return "phone"
    # BİNDİR aşamasının çıktısı `phone-01-tr-TR` biçiminde adlandırılır; ham plakalar ise
    # `001`…`008`. Normalleştirici her ikisini de kabul etmeli, aksi hâlde bindirilmiş set
    # sessizce "sınıflandırılamadı" diye atlanır ve NORMALIZED boş kalır.
    if n.startswith("phone-"):
        return "phone"
    return "other"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="apps/ASO_IMAGE/NEW")
    ap.add_argument("--out", default="apps/ASO_IMAGE/NORMALIZED")
    args = ap.parse_args()

    src, out = Path(args.src), Path(args.out)
    if not src.is_dir():
        print(f"kaynak dizin yok: {src}", file=sys.stderr)
        return 1

    # Çıktı her çalıştırmada SIFIRDAN üretilir — eski bir dosyanın hayatta kalması,
    # doğrulanmış sanılan bir varlığın aslında eski olması demektir.
    if out.exists():
        for old in out.glob("*.png"):
            old.unlink()

    produced: list[tuple[str, str]] = []
    phone_index = 0

    for p in sorted(src.glob("*.png")):
        kind = classify(p)
        if kind == "other":
            print(f"atlandı (sınıflandırılamadı): {p.name}")
            continue
        # `backup-` ön ekli dosyalar yedek; sete girmez.
        if p.name.startswith("backup-"):
            print(f"atlandı (yedek): {p.name}")
            continue

        im = flatten(Image.open(p))
        if kind == "phone":
            phone_index += 1
            im = cover_crop(im, PHONE_TARGET)
            dest = out / f"phone-{phone_index:02d}-tr-TR.png"
        elif kind == "icon":
            im = cover_crop(im, ICON_TARGET)
            dest = out / "app-icon-512.png"
        else:
            im = cover_crop(im, FEATURE_TARGET)
            dest = out / "feature-graphic-1024x500.png"

        save_clean(im, dest)
        produced.append((p.name, dest.name))

    # selfcheck — yazdığımızı yeniden ÖLÇ. Sessiz kısmi başarı en kötü sonuçtur.
    problems: list[str] = []
    for _, name in produced:
        f = out / name
        im = Image.open(f)
        if im.mode != "RGB":
            problems.append(f"{name}: mod {im.mode}")
        expected = {
            "phone": PHONE_TARGET,
            "icon": ICON_TARGET,
            "feature": FEATURE_TARGET,
        }[classify(f) if classify(f) != "other" else "phone"]
        if im.size != expected:
            problems.append(f"{name}: boyut {im.size} != {expected}")

    (out / "BU_KLASOR_YUKLENMEZ.txt").write_text(
        "BU KLASÖRDEKİ DOSYALAR GOOGLE PLAY'E YÜKLENMEZ.\n"
        "\n"
        "Teknik olarak Play'in biçim kurallarına uygundurlar (1080x1920, RGB, alfasız) ama\n"
        "İÇERİK OLARAK EKSİKTİRLER:\n"
        "\n"
        "  · telefon ekranları BOŞ — gerçek cihaz ekran görüntüsü henüz bindirilmedi\n"
        "  · üzerlerinde HİÇ METİN YOK — Türkçe tipografi henüz dizilmedi\n"
        "\n"
        "Bu iki adım tamamlanmadan yüklenirlerse mağaza sayfası boş telefonlar gösterir.\n"
        "Ayrıntı: ASO_FINAL_VALIDATION_REPORT.md ve ASO_PROMPT_LIBRARY.html §7.\n",
        encoding="utf-8",
    )

    for a, b in produced:
        digest = hashlib.md5((out / b).read_bytes()).hexdigest()[:12]
        print(f"{a:24s} → {b:28s} md5={digest}")

    if problems:
        print("\nSELFCHECK KALDI:", file=sys.stderr)
        for x in problems:
            print("  " + x, file=sys.stderr)
        return 1

    print(f"\n{len(produced)} varlık normalleştirildi → {out}")
    print("UYARI: bu klasör yüklemeye hazır DEĞİLDİR (metin ve ekran bindirmesi eksik).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
