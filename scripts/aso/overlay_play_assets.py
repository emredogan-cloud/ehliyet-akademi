#!/usr/bin/env python3
"""BİNDİR aşaması — gerçek ekran görüntüsü + Türkçe tipografi.

    ÜRET → DENETLE → [BİNDİR] → ONAR → NORMALLEŞTİR → DOĞRULA → DIŞA AKTAR
                      ^^^^^^^
                      bu betik

Ham plakalar TASARIM GEREĞİ metinsizdir ve telefon ekranları boştur: üreteç Türkçe aksanları
doğru çizemiyor ve boş ekran, uydurma bir arayüzü yapısal olarak imkânsız kılıyor. Bu betik iki
eksiği kapatır:

  1. `SCREENS/` altındaki **gerçek cihaz ekran görüntüsünü** telefonun ekranına perspektifle oturtur
  2. `copy_deck.json` içindeki Türkçe metni ölçülmüş kutulara dizer

## Geometri neden ölçülüyor, varsayılmıyor

Plakalar üreteçle yapıldığı için kart ve ekran konumları komuttaki ölçülerle birebir aynı değil
(ölçüldü: telefon bandı şartnamedeki y 601–1455 yerine y 567–1291). Bu yüzden her kutu
**görüntüden** bulunur:

* **Ekran**: en büyük "düz" (yerel standart sapması ~0) koyu bölge. Renk eşiği işe yaramıyor —
  arka plan da neredeyse siyah ve teal bir parıltı taşıyor.
* **Kartlar**: kartların 1 px'lik keskin kenarlığı var; yatay/dikey gradyan tepe noktaları kart
  sınırlarını verir. Parıltı gradyanı yumuşaktır ve bu testten geçmez.

Kullanım
--------
    python3 scripts/aso/overlay_play_assets.py [--src DIR] [--screens DIR] [--out DIR]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:  # pragma: no cover
    sys.exit("Pillow + numpy gerekli")

ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = Path.home() / ".cache/ehliyet-play-tools/prefix/usr/share/fonts/truetype/dejavu"

# Marka paleti — apps/mobile/lib/core/theme/tokens.dart
INK = (5, 11, 22)
TEXT_1 = (233, 241, 247)
TEXT_2 = (150, 170, 188)
ACCENT = (45, 226, 199)
AMBER = (245, 176, 66)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


# ─────────────────────────── geometri ölçümü ───────────────────────────


def local_std(gray: np.ndarray, radius: int = 3) -> np.ndarray:
    img = Image.fromarray(gray.astype(np.uint8))
    mean = np.asarray(img.filter(ImageFilter.BoxBlur(radius))).astype(np.float64)
    sq = Image.fromarray((gray.astype(np.float64) ** 2 / 255.0).astype(np.uint8))
    mean_sq = np.asarray(sq.filter(ImageFilter.BoxBlur(radius))).astype(np.float64) * 255.0
    return np.sqrt(np.maximum(mean_sq - mean**2, 0))


def largest_component(mask: np.ndarray) -> np.ndarray:
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    parent: list[int] = [0]

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a: int, b: int) -> None:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[max(ra, rb)] = min(ra, rb)

    nxt = 1
    for y in range(h):
        for x in np.nonzero(mask[y])[0]:
            up = labels[y - 1, x] if y > 0 else 0
            left = labels[y, x - 1] if x > 0 else 0
            if up and left:
                labels[y, x] = min(up, left)
                union(up, left)
            elif up or left:
                labels[y, x] = up or left
            else:
                labels[y, x] = nxt
                parent.append(nxt)
                nxt += 1
    if nxt == 1:
        return np.zeros_like(mask)
    flat = np.array([find(i) for i in range(nxt)], dtype=np.int32)
    resolved = flat[labels]
    counts = np.bincount(resolved.ravel())
    counts[0] = 0
    return resolved == int(counts.argmax())


def screen_quad(im: Image.Image) -> list[tuple[int, int]]:
    w, h = im.size
    gray = np.asarray(im.convert("L")).astype(np.float64)
    flat = (local_std(gray, 3) < 2.2) & (gray < 70)
    band = np.zeros_like(flat)
    band[int(h * 0.30) : int(h * 0.99), int(w * 0.25) : int(w * 0.85)] = True
    comp = largest_component(flat & band)
    ys, xs = np.nonzero(comp)
    s, d = xs + ys, xs - ys
    return [
        (int(xs[s.argmin()]), int(ys[s.argmin()])),
        (int(xs[d.argmax()]), int(ys[d.argmax()])),
        (int(xs[s.argmax()]), int(ys[s.argmax()])),
        (int(xs[d.argmin()]), int(ys[d.argmin()])),
    ]



def bright_screen_quad(im: Image.Image, exclude) -> list[tuple[int, int]] | None:
    """İkinci (açık temalı) telefonun BEYAZ ekranı.

    008 plakası iki telefon çizer: koyu tema önde, açık tema arkada. Koyu ekranı bulan "düz ve
    KOYU" ölçütü ikincisini göremez, çünkü o ekran beyazdır. Beyaz bırakılırsa varlık yarım
    görünür — üstelik o karenin kendi güven şeridi "KOYU VE AÇIK TEMA" diyor, yani boş beyaz
    ekran kendi iddiasını yalanlar.
    """
    w, h = im.size
    gray = np.asarray(im.convert("L")).astype(np.float64)
    flat = (local_std(gray, 3) < 3.0) & (gray > 170)
    band = np.zeros_like(flat)
    band[int(h * 0.30) : int(h * 0.95), int(w * 0.25) : int(w * 0.98)] = True
    # Ön telefonun camını dışla ki iki bölge birleşmesin.
    ex = Image.new("L", (w, h), 0)
    ImageDraw.Draw(ex).polygon(exclude, fill=255)
    band &= np.asarray(ex) == 0
    comp = largest_component(flat & band)
    if comp.sum() < (w * h) * 0.01:
        return None
    ys, xs = np.nonzero(comp)
    sm, df = xs + ys, xs - ys
    return [
        (int(xs[sm.argmin()]), int(ys[sm.argmin()])),
        (int(xs[df.argmax()]), int(ys[df.argmax()])),
        (int(xs[sm.argmax()]), int(ys[sm.argmax()])),
        (int(xs[df.argmin()]), int(ys[df.argmin()])),
    ]


def _peaks(sig: np.ndarray, sigma: float = 3.0, gap: int = 6) -> list[int]:
    thr = sig.mean() + sigma * sig.std()
    idx = [i for i, v in enumerate(sig) if v > thr]
    if not idx:
        return []
    out, cur = [], [idx[0]]
    for i in idx[1:]:
        if i - cur[-1] <= gap:
            cur.append(i)
        else:
            out.append(sum(cur) // len(cur))
            cur = [i]
    out.append(sum(cur) // len(cur))
    return out


def card_boxes(im: Image.Image, quad, quad2=None) -> dict:
    """Left column (3), right column (2) and the bottom strip (3 cells), measured."""
    a = np.asarray(im.convert("L")).astype(float)
    h, w = a.shape
    gy = np.abs(np.diff(a, axis=0))
    gx = np.abs(np.diff(a, axis=1))

    left_x1 = min(p[0] for p in quad)
    # İkinci telefon varsa sağ sütun ONUN da sağından başlamalı; aksi hâlde kenar tespiti
    # ikinci telefonun gövdesini kart sanıyor ve metin telefonun üstüne yazılıyordu.
    right_x0 = max(p[0] for p in quad)
    if quad2:
        right_x0 = max(right_x0, max(p[0] for p in quad2))
    # The side cards live BESIDE the phone. The bottom trust strip sits below it and is taller
    # than a card (measured: 203 px vs 176 px), so a naive "keep the N tallest bands" picked the
    # strip and dropped a real card — leaving one card blank and pushing its text onto the strip.
    # Clamping the search to the phone band removes the ambiguity at the source.
    phone_top = min(p[1] for p in quad)
    phone_bottom = max(p[1] for p in quad)

    def column(x0: int, x1: int, want: int) -> list[tuple[int, int, int, int]]:
        ys = [y for y in _peaks(gy[:, x0:x1].mean(axis=1)) if phone_top - 60 <= y <= phone_bottom + 20]
        # 78, not 90: plate 005 puts the mascot in the upper left, which squeezes its three cards
        # into the lower corner at ~95 px each — the shortest is 89 px and a 90 px floor silently
        # dropped it, leaving that plate with two cards and one unplaced string.
        bands = [(ys[i], ys[i + 1]) for i in range(len(ys) - 1) if ys[i + 1] - ys[i] >= 78]
        if not bands:
            return []
        bands.sort(key=lambda b: b[1] - b[0], reverse=True)
        # Drop stragglers well shorter than the tallest real card (gaps between cards can pair
        # into a plausible-looking but empty band).
        tallest = bands[0][1] - bands[0][0]
        bands = [b for b in bands if (b[1] - b[0]) >= tallest * 0.55]
        bands = sorted(bands[:want])
        boxes = []
        for y0, y1 in bands:
            xs = _peaks(gx[y0 + 8 : y1 - 8, x0 - 30 : x1 + 30].mean(axis=0), 2.0)
            if len(xs) >= 2:
                bx0, bx1 = x0 - 30 + xs[0], x0 - 30 + xs[-1]
            else:
                bx0, bx1 = x0, x1
            # Kartın GERÇEK sol kenarı telefonun ARKASINDA kalabiliyor (plaka sanatında telefon
            # kartın üstüne çiziliyor). Oraya yazmak metnin ilk harfini telefona gömüyordu —
            # 008'de "Katılmazsan" → "atılmazsan". Metin kutusu görünür alandan başlatılır.
            bx0 = max(bx0, x0)
            boxes.append((bx0, y0, bx1, y1))
        return boxes

    left = column(max(int(w * 0.05), 8), max(left_x1 - 25, 40), 3)
    right = column(min(right_x0 + 25, w - 40), int(w * 0.96), 2)

    # Bottom strip: below the phone, full width, split by two thin dividers.
    phone_bottom = max(p[1] for p in quad)
    sy = _peaks(gy[phone_bottom + 10 :, int(w * 0.1) : int(w * 0.9)].mean(axis=1), 2.5)
    strip = None
    if len(sy) >= 2:
        y0, y1 = phone_bottom + 10 + sy[0], phone_bottom + 10 + sy[-1]
        sx = _peaks(gx[y0 + 8 : y1 - 8, :].mean(axis=0), 2.0)
        if len(sx) >= 4:
            edges = [sx[0], *[x for x in sx[1:-1]], sx[-1]]
            strip = (y0, y1, edges)
    return {"left": left, "right": right, "strip": strip, "quad": quad}


# ─────────────────────────── bindirme ───────────────────────────


def perspective_coeffs(dst, src):
    """PIL's PERSPECTIVE wants the INVERSE map (output → input)."""
    m = []
    for (x, y), (u, v) in zip(dst, src):
        m.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        m.append([0, 0, 0, x, y, 1, -v * x, -v * y])
    A = np.asarray(m, dtype=np.float64)
    B = np.asarray([c for p in src for c in p], dtype=np.float64)
    return np.linalg.solve(A, B)


def paste_screen(plate: Image.Image, shot: Image.Image, quad) -> Image.Image:
    """Perspective-map the screenshot onto the phone glass."""
    w, h = plate.size
    # Crop the phone's own status/nav bars off the capture: the plate already draws a punch-hole
    # camera, and the device's clock/battery would read as a second, contradictory status bar.
    sw, sh = shot.size
    shot = shot.crop((0, int(sh * 0.033), sw, int(sh * 0.955)))
    sw, sh = shot.size

    coeffs = perspective_coeffs(quad, [(0, 0), (sw, 0), (sw, sh), (0, sh)])
    warped = shot.transform((w, h), Image.PERSPECTIVE, coeffs, Image.BICUBIC)

    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).polygon(quad, fill=255)
    # A 1 px feather hides the resampling stair-step against the bezel.
    mask = mask.filter(ImageFilter.GaussianBlur(0.6))
    out = plate.copy()
    out.paste(warped, (0, 0), mask)
    return out


def wrap(draw, text: str, f, width: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for wd in words:
        t = f"{cur} {wd}".strip()
        if draw.textlength(t, font=f) <= width or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = wd
    if cur:
        lines.append(cur)
    return lines


def draw_card(draw, box, title: str, body: str, scale: float, accent=None) -> None:
    """Fit title + body inside the measured card, shrinking until it actually fits.

    Card heights are not uniform across plates (plate 005's are ~95 px against ~180 px elsewhere,
    because the mascot squeezes that column). A fixed type scale overflowed those cards and spilled
    text onto the artwork, so the size is chosen per card.
    """
    x0, y0, x1, y1 = box
    pad = int(18 * scale)
    inner = (x1 - x0) - 2 * pad
    avail = (y1 - y0) - int(12 * scale)

    for shrink in (1.0, 0.9, 0.8, 0.72, 0.64, 0.56, 0.5):
        ft = font("DejaVuSans-Bold.ttf", max(10, int(21 * scale * shrink)))
        fb = font("DejaVuSans.ttf", max(9, int(18 * scale * shrink)))
        tl = wrap(draw, title, ft, inner)
        bl = wrap(draw, body, fb, inner)
        lh_t = int(ft.size * 1.22)
        lh_b = int(fb.size * 1.34)
        gap = int(8 * scale * shrink)
        total = len(tl) * lh_t + gap + len(bl) * lh_b
        if total <= avail:
            break

    y = y0 + ((y1 - y0) - total) // 2

    for ln in tl:
        draw.text((x0 + pad, y), ln, font=ft, fill=accent or ACCENT)
        y += lh_t
    y += gap
    for ln in bl:
        draw.text((x0 + pad, y), ln, font=fb, fill=TEXT_2)
        y += lh_b


def compose(plate_path: Path, shot_path: Path, spec: dict, out: Path, debug: Path | None) -> None:
    plate = Image.open(plate_path).convert("RGB")
    w, h = plate.size
    scale = w / 1080.0

    quad = screen_quad(plate)
    quad2 = bright_screen_quad(plate, quad) if spec.get("screen2") else None
    boxes = card_boxes(plate, quad, quad2)
    img = paste_screen(plate, Image.open(shot_path).convert("RGB"), quad)
    if quad2:
        shot2 = Image.open(shot_path.parent / spec["screen2"]).convert("RGB")
        img = paste_screen(img, shot2, quad2)
    draw = ImageDraw.Draw(img)

    # ── başlık bloğu (telefonun üstündeki boş alan) ─────────────────────
    head_bottom = min(p[1] for p in quad)
    fe = font("DejaVuSans-Bold.ttf", max(11, int(20 * scale)))
    fh = font("DejaVuSans-Bold.ttf", max(20, int(58 * scale)))
    fs = font("DejaVuSans.ttf", max(11, int(22 * scale)))
    margin = int(56 * scale)

    eyebrow = spec["eyebrow"]
    title = spec["title"]
    support = wrap(draw, spec["support"], fs, w - 2 * margin)

    lh_h = int(fh.size * 1.14)
    lh_s = int(fs.size * 1.38)
    block = fe.size + int(18 * scale) + len(title) * lh_h + int(16 * scale) + len(support) * lh_s
    y = max(int(38 * scale), (head_bottom - block) // 2)

    draw.text((margin, y), eyebrow, font=fe, fill=ACCENT)
    y += fe.size + int(18 * scale)
    for ln in title:
        draw.text((margin, y), ln, font=fh, fill=TEXT_1)
        y += lh_h
    y += int(16 * scale)
    for ln in support:
        draw.text((margin, y), ln, font=fs, fill=TEXT_2)
        y += lh_s

    # ── yan kartlar ────────────────────────────────────────────────────
    for box, (t, b) in zip(boxes["left"], spec["left"]):
        draw_card(draw, box, t, b, scale)
    for i, (box, (t, b)) in enumerate(zip(boxes["right"], spec["right"])):
        amber = spec["id"] in {"04", "07"} and i == 0
        draw_card(draw, box, t, b, scale, AMBER if amber else None)

    # ── güven şeridi ───────────────────────────────────────────────────
    if boxes["strip"]:
        y0, y1, edges = boxes["strip"]
        cells = [(edges[0], edges[len(edges) // 3]), (edges[len(edges) // 3], edges[2 * len(edges) // 3]), (edges[2 * len(edges) // 3], edges[-1])]
        for (cx0, cx1), (t, b) in zip(cells, spec["strip"]):
            draw_card(draw, (cx0, y0, cx1, y1), t, b, scale * 0.86)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)

    if debug:
        debug.mkdir(parents=True, exist_ok=True)
        d = img.copy()
        dd = ImageDraw.Draw(d)
        dd.line([*quad, quad[0]], fill=(255, 0, 128), width=4)
        for bx in boxes["left"] + boxes["right"]:
            dd.rectangle(bx, outline=(0, 255, 128), width=3)
        if boxes["strip"]:
            y0, y1, edges = boxes["strip"]
            dd.rectangle((edges[0], y0, edges[-1], y1), outline=(255, 200, 0), width=3)
        d.save(debug / f"dbg-{out.name}")


def compose_feature(plate_path: Path, spec: dict, out: Path) -> None:
    """Öne çıkan grafik: yalnız marka + tek satırlık kategori tanımı.

    ## Ekran görüntüsü BİLEREK yok

    Şartname bu varlık için nettir: "Ekran görüntüsü değildir, afiş de değildir." İlk denemede
    telefonun ekranına da bir yakalama bindirildi; sonuç hem şartnameye aykırıydı hem de bozuktu —
    bu plakada telefon tuvalin sağ kenarından kırpılıyor, dolayısıyla "en büyük düz koyu bölge"
    artık ekran değil, arka plandaki başka bir alan oluyor ve yakalama havada duran bir dikdörtgene
    oturuyordu. Telefon boş bırakılır.

    ## Marka neden burada diziliyor

    Marka adı ASLA üretece çizdirilmez: bu boru hattının kurulma sebeplerinden biri, önceki bir
    projede markanın görselde `FORMI` diye çıkmış olmasıdır.

    ## Merkezî sessiz alan

    Play, tanıtım videosu varsa oynat düğmesini merkeze bindirir. Bu yüzden metin, 1024×500
    uzayında merkezdeki 250×250 kutunun (x 387–637) SOLUNDA kalacak şekilde sınırlanır; marka
    gerekirse iki satıra sarılır.
    """
    plate = Image.open(plate_path).convert("RGB")
    w, h = plate.size
    img = plate.copy()
    draw = ImageDraw.Draw(img)

    scale = w / 1024.0
    margin = int(64 * scale)
    # Merkezî sessiz alanın sol kenarı 1024 uzayında x=387; metin oraya girmemeli.
    text_right = int(380 * scale)
    avail = text_right - margin

    fb = font("DejaVuSans-Bold.ttf", int(60 * scale))
    ft = font("DejaVuSans.ttf", int(26 * scale))
    brand = wrap(draw, spec["brand"], fb, avail)
    tag = wrap(draw, spec["tagline"], ft, avail)

    lh_b = int(fb.size * 1.12)
    lh_t = int(ft.size * 1.42)
    block = len(brand) * lh_b + int(24 * scale) + len(tag) * lh_t
    y = (h - block) // 2
    for ln in brand:
        draw.text((margin, y), ln, font=fb, fill=TEXT_1)
        y += lh_b
    y += int(24 * scale)
    for ln in tag:
        draw.text((margin, y), ln, font=ft, fill=ACCENT)
        y += lh_t

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="apps/ASO_IMAGE/NEW")
    ap.add_argument("--screens", default="apps/ASO_IMAGE/SCREENS")
    ap.add_argument("--out", default="apps/ASO_IMAGE/COMPOSED")
    ap.add_argument("--debug", default="")
    a = ap.parse_args()

    deck = json.loads((Path(__file__).parent / "copy_deck.json").read_text(encoding="utf-8"))
    src, screens, out = Path(a.src), Path(a.screens), Path(a.out)
    dbg = Path(a.debug) if a.debug else None

    for spec in deck["plates"]:
        dst = out / f"phone-{spec['id']}-tr-TR.png"
        compose(src / spec["plate"], screens / spec["screen"], spec, dst, dbg)
        print(f"  ✓ {dst.name}  ← {spec['plate']} + {spec['screen']}")

    f = deck["feature"]
    dst = out / "feature-graphic.png"
    compose_feature(src / f["plate"], f, dst)
    print(f"  ✓ {dst.name}  ← {f['plate']} (marka + slogan; ekran görüntüsü YOK, şartname gereği)")

    # Simge metin taşımaz ve bindirme gerektirmez; olduğu gibi kopyalanır ki normalleştirme
    # aşaması tek bir dizinden beslensin.
    icon = src / "app_icon.png"
    Image.open(icon).convert("RGBA").save(out / "app-icon.png")
    print("  ✓ app-icon.png  ← app_icon.png (metin yok, bindirme gerekmez)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
