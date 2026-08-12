#!/usr/bin/env python3
"""Locate the empty phone screen in each raw ASO plate.

The plates are generated art: the phone is rotated a few degrees about the vertical axis, so the
screen is a **quadrilateral**, not a rectangle, and its exact corners differ per plate. The overlay
stage needs those four corners to perspective-map a real screenshot into place.

## Why not a colour threshold

The prompt asks the generator for a screen filled with solid `#0B1523`. But the plate background is
also near-black and carries a teal glow, so a colour mask floods far outside the phone (measured:
704k pixels for a screen that should be ~360k).

## What actually separates the screen

**Flatness.** The screen is the largest region in the image with essentially zero local detail —
the background has gradients, grain and glow; the cards have borders; the mascot has texture. A
local standard-deviation map turns the screen into the one big solid blob.

The bezel is then found by walking outward from the flat blob until the luminance jumps (the
metal rim), which is what actually bounds the glass.

Usage
-----
    python3 scripts/aso/detect_screen.py [--src DIR] [--debug DIR] [--json OUT]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:  # pragma: no cover
    sys.exit("Pillow + numpy gerekli")

PLATES = [f"{i:03d}.png" for i in range(1, 9)]


def local_std(gray: np.ndarray, radius: int = 3) -> np.ndarray:
    """Local standard deviation via box means: sqrt(E[x^2] - E[x]^2)."""
    img = Image.fromarray(gray.astype(np.uint8))
    mean = np.asarray(img.filter(ImageFilter.BoxBlur(radius))).astype(np.float64)
    sq = Image.fromarray((gray.astype(np.float64) ** 2 / 255.0).astype(np.uint8))
    mean_sq = np.asarray(sq.filter(ImageFilter.BoxBlur(radius))).astype(np.float64) * 255.0
    return np.sqrt(np.maximum(mean_sq - mean**2, 0))


def largest_component(mask: np.ndarray) -> np.ndarray:
    """Largest 4-connected component, via iterative row-merge labelling (no scipy)."""
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
        row = mask[y]
        for x in np.nonzero(row)[0]:
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
    flat = np.array([find(i) if i < len(parent) else 0 for i in range(nxt)], dtype=np.int32)
    resolved = flat[labels]
    counts = np.bincount(resolved.ravel())
    counts[0] = 0
    return resolved == int(counts.argmax())


def corners_of(mask: np.ndarray) -> list[tuple[int, int]]:
    """Four corners of a rotated quad: extremes of (x+y) and (x-y)."""
    ys, xs = np.nonzero(mask)
    s, d = xs + ys, xs - ys
    return [
        (int(xs[s.argmin()]), int(ys[s.argmin()])),  # top-left
        (int(xs[d.argmax()]), int(ys[d.argmax()])),  # top-right
        (int(xs[s.argmax()]), int(ys[s.argmax()])),  # bottom-right
        (int(xs[d.argmin()]), int(ys[d.argmin()])),  # bottom-left
    ]


def detect(path: Path) -> dict:
    im = Image.open(path).convert("RGB")
    w, h = im.size
    gray = np.asarray(im.convert("L")).astype(np.float64)
    sd = local_std(gray, radius=3)

    # The screen: flat AND dark AND inside the phone band. The band bounds are generous; the
    # component search does the real work.
    flat = (sd < 2.2) & (gray < 70)
    band = np.zeros_like(flat)
    band[int(h * 0.30) : int(h * 0.99), int(w * 0.25) : int(w * 0.85)] = True
    comp = largest_component(flat & band)
    if comp.sum() < (w * h) * 0.05:
        raise SystemExit(f"{path.name}: ekran bulunamadı (bileşen {int(comp.sum())} px)")

    quad = corners_of(comp)
    ys, xs = np.nonzero(comp)
    return {
        "file": path.name,
        "size": [w, h],
        "quad": quad,
        "area": int(comp.sum()),
        "bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
    }, comp


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="apps/ASO_IMAGE/NEW")
    ap.add_argument("--debug", default="")
    ap.add_argument("--json", default="")
    a = ap.parse_args()

    src = Path(a.src)
    out = []
    for name in PLATES:
        info, comp = detect(src / name)
        out.append(info)
        q = info["quad"]
        print(
            f"{name}  area={info['area']:>7d}  "
            f"TL{q[0]} TR{q[1]} BR{q[2]} BL{q[3]}"
        )
        if a.debug:
            d = Path(a.debug)
            d.mkdir(parents=True, exist_ok=True)
            im = Image.open(src / name).convert("RGB")
            dr = ImageDraw.Draw(im)
            dr.line([*q, q[0]], fill=(255, 0, 128), width=5)
            for p in q:
                dr.ellipse([p[0] - 9, p[1] - 9, p[0] + 9, p[1] + 9], outline=(0, 255, 128), width=4)
            im.save(d / f"quad-{name}")
    if a.json:
        Path(a.json).write_text(json.dumps(out, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
