#!/usr/bin/env python3
"""
Mekanik görsel kütüphanesi: kontakt sayfalarındaki parçaları tek tek keser, arka planı şeffaf
yapar ve optimize WebP olarak `assets/mech/` altına yazar. (Evolution Faz E2/E3 · Phase Group 2.)

GİRDİ (repoda DEĞİL — .gitignore'da; yerel referans):
  <repo>/apps/assets/mekanik assets/*.png   (11 sayfa, 1536×1024, koyu lacivert zemin)

ÇIKTI (repoda İZLENİR):
  apps/mobile/assets/mech/<id>.webp   +   lib/core/mech_assets.dart (üretilmiş katalog)

KULLANIM:
  python3 apps/mobile/tool/extract_mech_assets.py --detect   # yalnız tespit + doğrulama sayfası
  python3 apps/mobile/tool/extract_mech_assets.py            # kes, anahtarla, WebP yaz, katalog üret

YÖNTEM: zemin tek renk (≈ #000C21) → eşikle nesne maskesi; bağlantılı bileşenler = parçalar.
Kesilen parça, KENARDAN yayılan zemin bölgesi bulunarak şeffaflaştırılır (nesnenin içindeki koyu
pikseller korunur — parçaların çoğu siyah plastik), kırpılır, boyutlanır ve WebP'ye yazılır.

GEREKSİNİM: Pillow.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile

try:
    from PIL import Image
except ImportError:  # pragma: no cover - araç betiği
    sys.exit('Pillow gerekli:  pip install Pillow')

HERE = os.path.dirname(os.path.abspath(__file__))
MOBILE = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(MOBILE))
SRC = os.path.join(REPO, 'apps', 'assets', 'mekanik assets')
OUT = os.path.join(MOBILE, 'assets', 'mech')

BG_TOLERANCE = 60  # zeminden bu kadar farklı piksel = nesne (yumuşak gölgeler zemin sayılır)
SCALE = 4  # bağlantılı bileşen analizi bu ölçekte yapılır (hız)
MIN_AREA_SMALL = 24  # küçük ölçekte bu alandan küçük bileşenler gürültü
MERGE_GAP = 3  # küçük ölçekte bu kadar yakın bileşenler tek parça (çift eldiven vb.)
ROW_OVERLAP = 40  # satır ayrımı: önceki satırın altına bu kadar giren kutu aynı satırdadır
MIN_SIDE = 26  # bundan küçük lekeler gürültü
MAX_DIM = 440  # çıktı en büyük kenarı (uygulamada en büyük kullanım ~200 logical px)
QUALITY = 80
KEY_LOW = 16  # bu uzaklığın altı tam şeffaf (düz zemin)
KEY_HIGH = 58  # bu uzaklığın üstü zemin sayılmaz (nesne kenarı)

# Sayfa → parça kimlikleri (SOLDAN SAĞA, YUKARIDAN AŞAĞIYA okuma sırası).
# Marka logolu varyantlar bilinçli olarak ALINMAZ: aynı parçanın markasız hâli her sayfada var
# (üçüncü taraf ticari marka taşımamak için). Atlanan yuvalar `None` ile işaretlenir.
# Birbirine değdiği için tek kutu olarak algılanan parçalar: kutunun İÇİNDEKİ oransal alt
# dikdörtgenler (x0, y0, x1, y1). Görsel doğrulama sayfasına bakılarak belirlendi.
SPLITS: dict[tuple[str, int], list[tuple[float, float, float, float]]] = {
    ('A-sınıfı-mekanikler-2.png', 0): [(0.0, 0.0, 0.42, 1.0), (0.42, 0.0, 1.0, 1.0)],
    ('D-sınıfı-mekanikler-1.png', 5): [
        (0.0, 0.0, 0.34, 0.56),
        (0.0, 0.56, 0.34, 1.0),
        (0.34, 0.0, 1.0, 1.0),
    ],
    ('D-sınıfı-mekanikler-2.png', 2): [(0.0, 0.0, 1.0, 0.46), (0.0, 0.46, 1.0, 1.0)],
}

SHEETS: dict[str, list[str | None]] = {
    'B-sınıfı-kaput-altı-mekanikleri.png': [
        'battery-12v', None, None, None,  # 3 marka logolu akü varyantı atlanır
        'engine-block', None, None, 'engine-v6',  # 2 marka logolu motor atlanır
        'dipstick-oil', 'dipstick-max', 'washer-cap', 'coolant-tank', 'fuse-box',
    ],
    # DİKKAT: sıra, çizim sırası değil TESPİT sırasıdır (yoğun ızgarada satır ayrımı bazı
    # kutuları öne alıyor). Kimlikler --detect kutu koordinatlarına bakılarak doğrulandı.
    'B-sınıfı-araç-içi-butonlar.png': [
        # 1. sıra — silecek kolları, far kumandaları, dörtlü flaşör
        'wiper-stalk-int', 'hazard-button-round', 'wiper-stalk-speed', 'wiper-stalk-rear',
        'headlight-knob-auto', 'headlight-knob-manual', 'headlight-knob-fog',
        'hazard-button-rocker',
        # 2. sıra — klima kumandaları
        'ac-button', 'climate-temp-knob', 'climate-fan-knob', 'climate-flow-knob',
        'climate-recirc-knob', 'climate-maxac-knob', 'rear-defrost-knob', 'maxac-button',
        # 3. sıra — sürüş yardımcıları ve kilitler
        'park-sensor-button', 'start-stop-off-button', 'esp-off-button',
        'central-unlock-button', 'boot-release-button', 'fuel-flap-button',
        'rear-fog-slider', 'central-lock-button',
        # 4. sıra — ısıtmalar, ayna ve koltuk ayarı
        'seat-heater-button', 'seat-back-heater-button', 'steering-heater-button',
        'rear-defrost-button', 'front-defrost-button',
        'mirror-adjust-knob', 'mirror-fold-switch', 'seat-adjust-switch',
        # 5. sıra — soketler ve marş düğmesi
        'blank-panel', 'usb-c-socket', 'usb-a-socket', 'socket-12v',
        'usb-charge-socket', 'usb-dual-socket', 'engine-start-stop',
    ],
    'B-sınıfı.png': [
        'brake-fluid-reservoir', 'oil-filler-cap', 'air-filter-box',
        'radiator', 'tow-eye', 'wheel-chock',
    ],
    'B-sınıfı-bagaj-içi-ekipmanlar.png': [
        'warning-triangle', 'spare-wheel', 'scissor-jack',
        'wheel-wrench', 'fire-extinguisher', 'first-aid-kit',
    ],
    'A-sınıfı-mekanikler-1.png': [
        'moto-kill-switch', 'moto-start-switch', 'moto-turn-switch', 'moto-horn-switch',
        'moto-clutch-lever', 'moto-brake-lever',
        'moto-ignition', 'moto-cluster',
    ],
    'A-sınıfı-mekanikler-2.png': [
        'moto-chain', 'moto-exhaust', 'moto-fork', 'moto-brake-reservoir',
        'moto-oil-sight-glass', 'moto-helmet', 'moto-gloves', 'moto-hiviz-vest',
    ],  # 0. kutu zincir+egzozu birlikte yakalıyor → SPLITS ile ayrılır
    'A-sınıfı-mekanikler-eksikler.png': [
        'moto-front-wheel', 'moto-battery', 'moto-gear-lever',
        'moto-brake-pedal', 'moto-knee-guard', None, 'moto-mirror',  # dizlik çifti ayrı algılanır
    ],
    'D-sınıfı-mekanikler-1.png': [
        'bus-tachograph', 'bus-brake-valves', 'bus-air-gauges',
        'bus-door-panel', 'bus-air-suspension',
        'bus-retarder-stalk', 'bus-speed-knob', 'bus-steering-wheel',
    ],
    'D-sınıfı-mekanikler-2.png': [
        'bus-air-tank', 'bus-wheel-chock',
        'bus-battery-24v', 'bus-fire-extinguisher',
        'bus-emergency-hammer', 'bus-twin-wheel',
    ],
    'D-sınıfı-mekanikler-eksikler.png': [
        'bus-emergency-door-release', 'bus-battery-isolator', 'bus-first-aid-kit',
        'bus-coolant-reservoir', 'bus-dipstick', 'bus-exhaust-brake-switch',
    ],
}


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def _runs(flags: list[bool], gap: int, min_len: int) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    cur, blank = None, 0
    for i, v in enumerate(flags):
        if v:
            cur = [i, i] if cur is None else [cur[0], i]
            blank = 0
        elif cur is not None:
            blank += 1
            if blank >= gap:
                if cur[1] - cur[0] + 1 >= min_len:
                    out.append((cur[0], cur[1]))
                cur, blank = None, 0
    if cur is not None and cur[1] - cur[0] + 1 >= min_len:
        out.append((cur[0], cur[1]))
    return out


def object_mask(img: Image.Image) -> Image.Image:
    """Zeminden yeterince farklı pikseller = nesne (1-bit maske)."""
    rgb = img.convert('RGB')
    bg = rgb.getpixel((3, 3))
    px = rgb.load()
    w, h = rgb.size
    mask = Image.new('L', (w, h), 0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) > BG_TOLERANCE:
                mp[x, y] = 255
    return mask


def detect(path: str) -> list[tuple[int, int, int, int]]:
    """Sayfadaki parçaların sınır kutuları, OKUMA SIRASINDA (satır satır, soldan sağa).

    Satır/sütun bantlaması yetmiyor (gölgeler ve düzensiz yerleşim bantları birleştiriyor) →
    BAĞLANTILI BİLEŞEN etiketlemesi yapılır; birbirine yakın bileşenler (bir eldiven çifti, iki
    parçalı bir kumanda) tek parça sayılacak şekilde birleştirilir.
    """
    img = Image.open(path)
    mask = object_mask(img)
    small = mask.resize((mask.width // SCALE, mask.height // SCALE), Image.BILINEAR).point(
        lambda v: 255 if v > 40 else 0
    )
    w, h = small.size
    px = small.load()

    parent = list(range(w * h))

    def find(a: int) -> int:
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a: int, b: int) -> None:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    for y in range(h):
        for x in range(w):
            if not px[x, y]:
                continue
            i = y * w + x
            if x and px[x - 1, y]:
                union(i, i - 1)
            if y and px[x, y - 1]:
                union(i, i - w)
            if y and x and px[x - 1, y - 1]:
                union(i, i - w - 1)
            if y and x + 1 < w and px[x + 1, y - 1]:
                union(i, i - w + 1)

    comps: dict[int, list[int]] = {}
    for y in range(h):
        for x in range(w):
            if not px[x, y]:
                continue
            r = find(y * w + x)
            b = comps.get(r)
            if b is None:
                comps[r] = [x, y, x, y, 1]
            else:
                b[0] = min(b[0], x)
                b[1] = min(b[1], y)
                b[2] = max(b[2], x)
                b[3] = max(b[3], y)
                b[4] += 1

    boxes = [b[:4] for b in comps.values() if b[4] >= MIN_AREA_SMALL]

    # yakın bileşenleri birleştir (çift eldiven, iki parçalı kumanda vb.)
    merged = True
    while merged:
        merged = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                a, b = boxes[i], boxes[j]
                if (
                    a[0] - MERGE_GAP <= b[2]
                    and b[0] - MERGE_GAP <= a[2]
                    and a[1] - MERGE_GAP <= b[3]
                    and b[1] - MERGE_GAP <= a[3]
                ):
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                    boxes.pop(j)
                    merged = True
                    break
            if merged:
                break

    full = [
        (b[0] * SCALE, b[1] * SCALE, (b[2] + 1) * SCALE, (b[3] + 1) * SCALE)
        for b in boxes
        if (b[2] - b[0] + 1) * SCALE >= MIN_SIDE and (b[3] - b[1] + 1) * SCALE >= MIN_SIDE
    ]
    # okuma sırası: y-merkezine göre satırlara ayır, satır içinde x'e göre sırala
    full.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows: list[list[tuple[int, int, int, int]]] = []
    for box in full:
        cy = (box[1] + box[3]) / 2
        if rows and cy <= max(b[3] for b in rows[-1]) - ROW_OVERLAP:
            rows[-1].append(box)
        else:
            rows.append([box])
    out: list[tuple[int, int, int, int]] = []
    for row in rows:
        out.extend(sorted(row, key=lambda b: b[0]))

    sheet = os.path.basename(path)
    if any(k[0] == sheet for k in SPLITS):
        expanded: list[tuple[int, int, int, int]] = []
        for i, b in enumerate(out):
            parts = SPLITS.get((sheet, i))
            if not parts:
                expanded.append(b)
                continue
            bw, bh = b[2] - b[0], b[3] - b[1]
            for fx0, fy0, fx1, fy1 in parts:
                expanded.append(
                    (
                        int(b[0] + fx0 * bw),
                        int(b[1] + fy0 * bh),
                        int(b[0] + fx1 * bw),
                        int(b[1] + fy1 * bh),
                    )
                )
        out = expanded
    return out


def key_and_save(src: str, box: tuple[int, int, int, int], dest: str, tmp: str) -> int:
    """Parçayı kes → zemini şeffaflaştır → kırp → boyutla → WebP.

    ANAHTARLAMA: basit "fuzz'lu flood-fill" burada ÇALIŞMAZ — parçaların çoğu siyah plastik ve
    zemin de koyu lacivert; tolerans yükseltilince nesnenin içi yeniyor, düşürülünce zemin
    kalıyor. Bunun yerine: (1) zemin rengine uzaklık haritası, (2) KENARDAN yayılan bağlantılı
    zemin bölgesi (nesnenin içindeki koyu pikseller kenara bağlı olmadığı için korunur),
    (3) yalnız zemine bağlı piksellerde YUMUŞAK alfa → kenar yumuşatma korunur.
    """
    pad = 10
    img = Image.open(src).convert('RGB')
    crop = img.crop(
        (
            max(0, box[0] - pad),
            max(0, box[1] - pad),
            min(img.width, box[2] + pad),
            min(img.height, box[3] + pad),
        )
    )
    w, h = crop.size
    px = crop.load()
    bg = crop.getpixel((0, 0))

    dist = [[abs(px[x, y][0] - bg[0]) + abs(px[x, y][1] - bg[1]) + abs(px[x, y][2] - bg[2]) for x in range(w)] for y in range(h)]

    # kenardan yayılan zemin bölgesi (BFS)
    is_bg = [[False] * w for _ in range(h)]
    stack = [(x, y) for x in range(w) for y in (0, h - 1) if dist[y][x] <= KEY_HIGH]
    stack += [(x, y) for y in range(h) for x in (0, w - 1) if dist[y][x] <= KEY_HIGH]
    for x, y in stack:
        is_bg[y][x] = True
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not is_bg[ny][nx] and dist[ny][nx] <= KEY_HIGH:
                is_bg[ny][nx] = True
                stack.append((nx, ny))

    alpha = Image.new('L', (w, h), 255)
    ap = alpha.load()
    span = max(1, KEY_HIGH - KEY_LOW)
    for y in range(h):
        for x in range(w):
            if is_bg[y][x]:
                d = dist[y][x]
                ap[x, y] = 0 if d <= KEY_LOW else min(255, int((d - KEY_LOW) * 255 / span))

    out = crop.convert('RGBA')
    out.putalpha(alpha)
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    out.thumbnail((MAX_DIM, MAX_DIM), Image.LANCZOS)
    out.save(dest, 'WEBP', quality=QUALITY, method=6, alpha_quality=100)
    return os.path.getsize(dest)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--detect', action='store_true', help='yalnız tespit + doğrulama sayfası')
    args = ap.parse_args()

    if not os.path.isdir(SRC):
        sys.exit(f'Kaynak klasör yok: {SRC}\n(referans girdi; .gitignore kapsamında)')
    os.makedirs(OUT, exist_ok=True)

    report: dict[str, dict] = {}
    written, total_bytes = 0, 0
    catalog: dict[str, str] = {}

    with tempfile.TemporaryDirectory() as tmp:
        for sheet, ids in SHEETS.items():
            path = os.path.join(SRC, sheet)
            if not os.path.exists(path):
                sys.exit(f'Sayfa yok: {path}')
            boxes = detect(path)
            report[sheet] = {'detected': len(boxes), 'expected': len(ids)}
            status = 'OK' if len(boxes) == len(ids) else 'UYUŞMUYOR'
            print(f'{sheet}: {len(boxes)} parça (beklenen {len(ids)}) — {status}')
            if args.detect or len(boxes) != len(ids):
                continue
            for name, box in zip(ids, boxes):
                if name is None:  # marka logolu varyant — atlanır
                    continue
                dest = os.path.join(OUT, f'{name}.webp')
                total_bytes += key_and_save(path, box, dest, tmp)
                catalog[name] = f'assets/mech/{name}.webp'
                written += 1

    if args.detect:
        make_sheet(report)
        return 0

    if len(catalog) != sum(1 for ids in SHEETS.values() for i in ids if i):
        print('UYARI: bazı sayfalar atlandı — tespit sayısı manifest ile uyuşmuyor.')
    print(f'yazıldı: {written} varlık · toplam {total_bytes / 1024:.0f} KB')
    write_dart(catalog)
    with open(os.path.join(HERE, 'mech_assets_index.json'), 'w', encoding='utf-8') as fh:
        json.dump({'sheets': report, 'assets': catalog}, fh, ensure_ascii=False, indent=2, sort_keys=True)
    return 0


def write_dart(catalog: dict[str, str]) -> None:
    lines = [
        '// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.',
        '// Kaynak: apps/mobile/tool/extract_mech_assets.py (Evolution Faz E2).',
        '//',
        '// Mekanik görsel kütüphanesi: araç sistemleri, kaput altı, kabin kumandaları, bagaj',
        '// ekipmanları; B / A / D sınıfları. Şeffaf zeminli WebP.',
        '',
        '/// Parça kimliği → varlık yolu.',
        'const Map<String, String> kMechAsset = {',
    ]
    lines += [f"  '{k}': '{v}'," for k, v in sorted(catalog.items())]
    lines += [
        '};',
        '',
        '/// Bu parçanın görseli var mı?',
        'String? mechAsset(String id) => kMechAsset[id];',
        '',
    ]
    dest = os.path.join(MOBILE, 'lib', 'core', 'mech_assets.dart')
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(lines))
    print(f'dart kataloğu: {len(catalog)} parça → {os.path.relpath(dest, REPO)}')


def make_sheet(report: dict[str, dict]) -> None:
    """Tespit edilen kutuları kaynak sayfa üstünde numaralandırarak HTML'e döker."""
    cells = []
    for sheet in SHEETS:
        path = os.path.join(SRC, sheet)
        boxes = detect(path)
        img = Image.open(path)
        items = []
        for i, b in enumerate(boxes):
            crop = img.crop(b).convert('RGB')
            crop.thumbnail((120, 120))
            tmp_png = os.path.join(tempfile.gettempdir(), f'mech-{abs(hash((sheet, i)))}.png')
            crop.save(tmp_png)
            items.append(f'<figure><img src="file://{tmp_png}"><figcaption>{i}</figcaption></figure>')
        cells.append(f'<h2>{sheet} — {len(boxes)}/{len(SHEETS[sheet])}</h2><main>{"".join(items)}</main>')
    html = (
        '<!doctype html><meta charset="utf-8"><title>Mekanik parçalar</title><style>'
        'body{background:#0b1220;color:#cbd5e1;font:12px system-ui;margin:16px}'
        'h2{font-size:14px;margin:18px 0 6px}'
        'main{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:8px}'
        'figure{margin:0;text-align:center}img{max-width:120px;border-radius:8px}'
        '</style>' + ''.join(cells)
    )
    dest = os.path.join(tempfile.gettempdir(), 'mech_assets_sheet.html')
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print('doğrulama sayfası:', dest)


if __name__ == '__main__':
    raise SystemExit(main())
