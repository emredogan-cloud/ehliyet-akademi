#!/usr/bin/env python3
"""
Resmî trafik levhalarını VEKTÖR olarak tek tek çıkarır ve uygulamanın `assets/signs/` klasörüne
normalize edilmiş SVG olarak yazar. (Evolution Faz E1 · Phase Group 1 — Real Traffic Signs.)

NEDEN BU YOL: kaynak posterler gerçek vektör PDF'lerdir ve levha geometrisi Karayolları Trafik
Yönetmeliği ile belirlenmiş RESMÎ standart sembollerdir. Elle yeniden çizmek yerine resmî
geometriyi çıkarıp KENDİ varlık hattımıza normalize ederiz: yayıncının dosyası olduğu gibi
yeniden yayımlanmaz — levha tek tek ayrıştırılır, poster çerçevesi/etiket metni atılır, renk ve
koordinatlar sadeleştirilir, 0..100 kare viewBox'ımıza oturtulur.

İKİ RESMÎ KAYNAK:
  duseyisaretleme.pdf  KGM 2020 "Karayolları Standart Trafik İşaret Levhaları" — BİRİNCİL kaynak.
  Pano.pdf             İBB "Trafik İşaret ve Levhaları" — YEDEK kaynak.
KGM posterinin bazı piktogramları InDesign ŞEFFAFLIK DÜZLEŞTİRMESİ ile binlerce ince üçgene
parçalanmıştır (kaynağın kendisinde, dönüştürücüde değil). Bu levhalarda temiz eğrileri olan İBB
posteri kullanılır; diğer her şeyde bakanlık posteri esastır.

GİRDİ (repoda DEĞİL — .gitignore'da; yerel referans):  <repo>/duseyisaretleme.pdf, <repo>/Pano.pdf
ÇIKTI (repoda İZLENİR):  apps/mobile/assets/signs/<kod>.svg · lib/core/official_signs.dart
                         apps/mobile/tool/official_signs_index.json (kaynak/eleme kaydı)

KULLANIM:
  python3 apps/mobile/tool/extract_official_signs.py             # eşlenen levhaları üret
  python3 apps/mobile/tool/extract_official_signs.py --all       # posterdeki bütün kodlar
  python3 apps/mobile/tool/extract_official_signs.py --sheet     # görsel doğrulama sayfası (HTML)

GEREKSİNİM: poppler-utils (pdftotext/pdftoppm/pdftocairo) + Pillow.
NOT: Deterministik ve yeniden çalıştırılabilir. Varlıklar repoda olduğu için normal geliştirme
akışında çalıştırmaya gerek yoktur; kaynak poster değişirse yeniden üretilir.
"""

from __future__ import annotations

import argparse
import collections
import json
import os
import re
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
OUT = os.path.join(MOBILE, 'assets', 'signs')

POSTERS = [
    dict(key='kgm', pdf=os.path.join(REPO, 'duseyisaretleme.pdf')),
    dict(key='ibb', pdf=os.path.join(REPO, 'Pano.pdf')),
]

RENDER_DPI = 150  # görünür levha kutusunu ölçmek için sayfa taraması
PAD_PT = 0.8  # kutu payı (kenar yumuşatma pikselleri kesilmesin)
BAND_GAP_PX = 8  # levhayı etiketten/komşudan ayıran boşluk eşiği
FLATTEN_LIMIT = 60  # bu sayıdan çok yol = düzleştirilmiş kaynak → yedek postere geç
MAX_PATHS = 420  # bu kadar parçadan sonrası ağır düzleştirme: levha alınmaz, parametrik çizici devrede
# İç piktogramı gerçekten olmayan resmî levhalar (boş kabuk doğru sonuçtur).
EMPTY_OK = {'TT-5', 'TT-1', 'B-26', 'B-27'}
# Görsel doğrulamada elenen levhalar: otomatik kutu/kaynak seçimi bu kodlarda hatalı sonuç
# veriyor (kaynak posterin yerleşim istisnaları). Uygulama bu işaretlerde kendi vektör glif
# çizicisini kullanır — bozuk bir resmî varlık yayımlamaktansa doğru olan budur.
DROP = {
    'T-1a': 'kutu tespiti bu levhada kayıyor (satır başı istisnası) — parametrik glif kullanılır',
    'TT-33a': 'kaynakta ağır düzleştirilmiş, çizim bozuk — parametrik glif kullanılır',
    'TT-35g': 'kaynakta ağır düzleştirilmiş, çizim bozuk — parametrik glif kullanılır',
    'TT-21': 'yükseklik değeri ("3m50") kaynakta eksik çıkıyor — parametrik glif kullanılır',
}

CODE_RE = re.compile(r'\(([A-ZÇĞİÖŞÜ]{1,2}-\d+[a-zçğıöşü.]*)\)')
WORD_RE = re.compile(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>')
PATH_RE = re.compile(r'<path\b[^>]*?/>', re.S)
ATTR_RE = re.compile(r'([\w-]+)="([^"]*)"')
NUM_RE = re.compile(r'-?\d+(?:\.\d+)?')
RGB_RE = re.compile(r'rgb\(\s*([\d.]+)%\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*\)')
MATRIX_RE = re.compile(r'matrix\(([^)]*)\)')

# ——— Uygulama işareti (content/signs.ts id) → resmî levha kodu ———
# Yalnız resmî karşılığı BİREBİR olan işaretler eşlenir. Sayı-parametrik levhalar (azami/asgari
# hız, mesafe) ve resmî karşılığı olmayanlar mevcut parametrik çizicide kalır — UNMAPPED_REASON.
SIGN_MAP: dict[str, str] = {
    # — Tehlike uyarı (üçgen) —
    'tehlikeli-viraj-sag': 'T-1a',
    'tehlikeli-viraj-sol': 'T-1b',
    'devamli-viraj': 'T-2a',
    'egimli-inis': 'T-3a',
    'dik-cikis': 'T-3b',
    'yol-daralmasi': 'T-4a',
    'sagdan-daralma': 'T-4b',
    'soldan-daralma': 'T-4c',
    'deniz-kiyisi': 'T-6',
    'kasisli-yol': 'T-7',
    'tumsek': 'T-7',  # resmî standartta ayrı "tümsek" levhası yok → kasisli yol (T-7)
    'kaygan-yol': 'T-8',
    'gevsek-malzeme': 'T-9',
    'dusen-kaya': 'T-10',
    'yaya-geciti-tehlike': 'T-11',
    'okul-gecidi': 'T-12',
    'bisiklet-gecebilir': 'T-13',
    'ehli-hayvan': 'T-14a',
    'vahsi-hayvan': 'T-14b',
    'yol-calismasi': 'T-15',
    'is-makinesi-cikabilir': 'T-15',  # çalışma bölgesi varyantı — aynı resmî levha
    'isikli-isaret-yaklasim': 'T-16',
    'alcak-ucus': 'T-17',
    'yandan-ruzgar': 'T-18',
    'iki-yonlu-trafik': 'T-19',
    'gecici-iki-yonlu': 'T-19',  # çalışma bölgesi varyantı — aynı resmî levha
    'serit-daralmasi-gecici': 'T-4a',  # çalışma bölgesi varyantı — aynı resmî levha
    'dikkat': 'T-20',
    'kontrolsuz-kavsak': 'T-21',
    'anayol-tali-kavsak': 'T-22a',
    'donel-kavsak-yaklasim': 'T-24',
    'hemzemin-gecit': 'T-25',
    'gizli-buzlanma': 'T-37',
    'tramvay-hatti': 'T-39',
    # — Öncelik —
    'yol-ver': 'TT-1',
    'dur': 'TT-2',
    'dar-gecit-oncelik': 'TT-3',
    'dar-gecit-onceligi-sende': 'B-37',
    'ana-yol': 'B-38',
    'ana-yol-sonu': 'B-39',
    # — Yasaklayıcı / kısıtlayıcı (kırmızı halka) —
    'tasit-giremez': 'TT-5',
    'otomobil-giremez': 'TT-6',
    'motosiklet-giremez': 'TT-7',
    'bisiklet-giremez': 'TT-8',
    'kamyon-giremez': 'TT-10a',
    'otobus-giremez': 'TT-10b',
    'yaya-giremez': 'TT-12',
    'at-arabasi-giremez': 'TT-13',
    'el-arabasi-giremez': 'TT-14',
    'traktor-giremez': 'TT-15',
    'genislik-siniri': 'TT-20',
    'yukseklik-siniri': 'TT-21',
    'uzunluk-siniri': 'TT-22',
    'aks-yuku-siniri': 'TT-23',
    'agirlik-siniri': 'TT-24',
    'takip-mesafesi': 'TT-25',
    'donus-yasak-sag': 'TT-26a',
    'donus-yasak-sol': 'TT-26b',
    'u-donusu-yasak': 'TT-26c',
    'sollama-yasak': 'TT-27',
    'gumruk-dur': 'TT-31',
    'tum-yasaklarin-sonu': 'TT-32',
    'hiz-siniri-sonu': 'TT-33a',
    'sollama-yasagi-sonu': 'TT-34a',
    'asgari-hiz-sonu': 'TT-41b',
    'zincir-mecburi': 'TT-42a',
    'park-yasak': 'P-1',
    'duraklama-yasak': 'P-2',
    # — Mecburiyet (mavi daire) —
    'saga-mecburi': 'TT-35a',
    'sola-mecburi': 'TT-35b',
    'ileri-mecburi': 'TT-35c',
    'saga-donus-mecburi': 'TT-35g',
    'sola-donus-mecburi': 'TT-35h',
    'sagdan-gidin': 'TT-36a',
    'donel-mecburi': 'TT-37',
    'bisiklet-yolu': 'TT-38a',
    'yaya-yolu': 'TT-39a',
    # — Bilgi —
    'yaya-gecidi-bilgi': 'B-14a',
    'okul-gecidi-bilgi': 'B-14b',
    'hastane': 'B-15',
    'tek-yon': 'B-16a',
    'cikmaz-yol': 'B-17',
    'otoyol-baslangic': 'B-18',
    'otoyol-sonu': 'B-19',
    'motorlu-tasit-yolu': 'B-20',
    'otobus-duragi': 'B-22',
    'ilk-yardim': 'B-23',
    'tamirhane': 'B-24',
    'telefon': 'B-25',
    'akaryakit': 'B-26',
    'otel': 'B-27',
    'lokanta': 'B-28',
    'cesme': 'B-30',
    'kamp-yeri': 'B-33',
    'polis': 'B-41',
    'tunel': 'B-49a',
    'tramvay-duragi': 'B-59',
    # — Park —
    'park-yeri-bilgi': 'P-3a',
    'park-serbest': 'P-3a',
}

# Bilinçli olarak parametrik çizicide bırakılanlar (rapor + INDEX.json için).
UNMAPPED_REASON: dict[str, str] = {
    'azami-hiz-20': 'sayı-parametrik (resmî TT-29a tek bir sabit hız değeri taşır)',
    'azami-hiz-30': 'sayı-parametrik',
    'azami-hiz-40': 'sayı-parametrik',
    'azami-hiz-50': 'sayı-parametrik',
    'azami-hiz-60': 'sayı-parametrik',
    'azami-hiz-70': 'sayı-parametrik',
    'azami-hiz-80': 'sayı-parametrik',
    'azami-hiz-90': 'sayı-parametrik',
    'azami-hiz-100': 'sayı-parametrik',
    'azami-hiz-110': 'sayı-parametrik',
    'azami-hiz-120': 'sayı-parametrik',
    'asgari-hiz-30': 'sayı-parametrik (resmî TT-41a tek bir sabit değer taşır)',
    'asgari-hiz-40': 'sayı-parametrik',
    'asgari-hiz-50': 'sayı-parametrik',
    'otoyol-cikisi-300m': 'sayı-parametrik mesafe levhası',
    'park-yasagi-sonu': 'KGM standart posterinde ayrı "park yasağı sonu" levhası yok',
    'devlet-yolu': 'yön levhası ailesi (B-1x) tekil piktogram değil, tam panel',
    'otoyol-cikisi': 'otoyol çıkış levhaları tam yeşil panel (B-5x) — tekil piktogram yok',
    'havalimani': 'posterde havalimanı yalnız kavşak yön paneli içinde (B-6)',
    'taksi-duragi': 'KGM standart posterinde taksi durağı levhası yok',
    'engelli-parki': 'posterde yalnız yatay işaretleme olarak var (dikey levha yok)',
    'park-saat-sinirli': 'süre sınırlı park levhası posterde yok',
}


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ——————————————————————————— 1) poster metin düzeni ———————————————————————————


def read_words(pdf: str, tmp: str) -> list[dict]:
    """Poster metnini konumlarıyla okur; varsa "hayalet" (ikinci, ötelenmiş) katmanı atar."""
    out_html = os.path.join(tmp, os.path.basename(pdf) + '.bbox.html')
    run(['pdftotext', '-bbox', pdf, out_html])
    raw = open(out_html, encoding='utf-8', errors='replace').read()
    words = [
        dict(x0=float(a), y0=float(b), x1=float(c), y1=float(d), t=e, i=i)
        for i, (a, b, c, d, e) in enumerate(WORD_RE.findall(raw))
    ]
    by_text: dict[str, list[dict]] = collections.defaultdict(list)
    for w in words:
        by_text[w['t']].append(w)
    offsets: collections.Counter = collections.Counter()
    for group in by_text.values():
        if len(group) == 2:
            a, b = sorted(group, key=lambda w: (w['y0'], w['x0']))
            offsets[(round(b['x0'] - a['x0'], 1), round(b['y0'] - a['y0'], 1))] += 1
    ghosts: set[int] = set()
    if offsets:
        (dx, dy), hits = offsets.most_common(1)[0]
        if hits >= 30 and (abs(dx) > 0.5 or abs(dy) > 0.5):
            for group in by_text.values():
                for w in group:
                    for v in group:
                        if v is not w and abs((w['x0'] - v['x0']) - dx) < 0.6 and abs((w['y0'] - v['y0']) - dy) < 0.6:
                            ghosts.add(w['i'])
    return [w for w in words if w['i'] not in ghosts]


def label_rows(words: list[dict]) -> list[list[dict]]:
    """Resmî kodları etiket SATIRLARINA böler ve her satır için levha şeridini (sy0..sy1) verir.

    `cx` = kodun kendi etiket satırının merkezi (yalnız sütun sayısı tutmadığında yedek eşleme
    için kullanılır; etiket ikinci satıra kayabildiğinden birincil ölçüt DEĞİLDİR).
    """
    codes = sorted((w for w in words if CODE_RE.fullmatch(w['t'])), key=lambda w: (w['y0'], w['x0']))
    rows: list[list[dict]] = []
    for c in codes:
        if rows and abs(c['y0'] - rows[-1][0]['y0']) <= 5:
            rows[-1].append(c)
        else:
            rows.append([c])

    out: list[list[dict]] = []
    prev_bottom = 0.0
    for row in rows:
        row.sort(key=lambda w: w['x0'])
        top = min(c['y0'] for c in row)
        bottom = max(
            w['y1'] for w in words if top - 1 <= w['y0'] <= top + 26
        )
        items = []
        for i, c in enumerate(row):
            nxt = row[i + 1]['x0'] if i + 1 < len(row) else 1e9
            line = [w for w in words if abs(w['y0'] - c['y0']) < 2 and c['x0'] - 0.5 <= w['x0'] < nxt - 0.5]
            items.append(
                dict(
                    code=CODE_RE.fullmatch(c['t']).group(1),
                    cx=(min(w['x0'] for w in line) + max(min(w['x1'], nxt) for w in line)) / 2,
                    sy0=max(prev_bottom + 2, top - 150),
                    sy1=top - 1.5,
                )
            )
        if items and items[0]['sy0'] > items[0]['sy1'] - 25:
            for it in items:
                it['sy0'] = max(0.0, it['sy1'] - 150)
        out.append(items)
        prev_bottom = bottom
    return out


# ——————————————————————————— 2) görünür levha kutusu ———————————————————————————


def _runs(has_ink: list[bool], gap: int) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    cur, blank = None, 0
    for i, v in enumerate(has_ink):
        if v:
            cur = [i, i] if cur is None else [cur[0], i]
            blank = 0
        elif cur is not None:
            blank += 1
            if blank >= gap:
                out.append((cur[0], cur[1]))
                cur, blank = None, 0
    if cur is not None:
        out.append((cur[0], cur[1]))
    return out


def ink_boxes(pdf: str, rows: list[list[dict]], tmp: str) -> dict[str, tuple[float, float, float, float]]:
    """Her etiket satırı için levha ŞERİDİNİ bulur ve şeritteki mürekkep sütunlarını satırdaki
    kodlarla soldan sağa eşler.

    Etiket metninden yatay merkez ÇIKARILMAZ: uzun/iki satıra kayan etiketler komşu sütuna
    taşabiliyor (Pano'da doğrulandı). Levhalar görsel olarak birbirinden ayrık olduğu için
    sütun kümeleri güvenilir; sayı tutmazsa kodun kendi etiket satırına en yakın sütuna düşülür.
    """
    page = os.path.join(tmp, os.path.basename(pdf) + '.page')
    run(['pdftoppm', '-png', '-r', str(RENDER_DPI), '-singlefile', pdf, page])
    img = Image.open(page + '.png').convert('L')
    scale = RENDER_DPI / 72.0
    boxes: dict[str, tuple[float, float, float, float]] = {}

    for row in rows:
        y0, y1 = row[0]['sy0'], row[0]['sy1']
        py0, py1 = int(y0 * scale), int(y1 * scale)
        if py1 - py0 < 6:
            continue
        # Şeridi SATIRIN KOD ARALIĞIYLA sınırla: sayfa çerçevesi ve kenar renk bantları
        # (her ikisi de posterlerde var) yoksa bant/sütun tespitini tamamen bozuyor.
        cxs = [c['cx'] for c in row]
        pitch = (max(cxs) - min(cxs)) / max(1, len(cxs) - 1) if len(cxs) > 1 else 120.0
        px0 = max(0, int((min(cxs) - pitch * 0.75) * scale))
        px1 = min(img.width, int((max(cxs) + pitch * 0.75) * scale))
        if px1 - px0 < 8:
            continue
        strip = img.crop((px0, py0, px1, py1)).point(lambda v: 255 if v < 245 else 0)
        if strip.getbbox() is None:
            continue
        bands = _runs([any(strip.crop((0, y, strip.width, y + 1)).getdata()) for y in range(strip.height)], BAND_GAP_PX)
        if not bands:
            continue
        by0, by1 = bands[-1]  # etiketlerin hemen üstündeki levha bandı
        band = strip.crop((0, by0, strip.width, by1 + 1))
        groups = _runs([any(band.crop((x, 0, x + 1, band.height)).getdata()) for x in range(band.width)], BAND_GAP_PX)
        if not groups:
            continue

        if len(groups) == len(row):
            pairs = list(zip(row, groups))
        else:  # kod okunamamış / sütunlar birleşmiş — koda en yakın sütunu seç.
            # (Tekil atama denendi ve REDDEDİLDİ: bir satırın tamamını kaydırabiliyor.)
            pairs = [
                (c, min(groups, key=lambda g: abs((px0 + (g[0] + g[1]) / 2) / scale - c['cx'])))
                for c in row
            ]

        row_boxes: dict[str, tuple[float, float, float, float]] = {}
        for code_word, (bx0, bx1) in pairs:
            # sütunu ŞERİDİN TAMAMI boyunca alıp kendi içinde dikey bantlara ayır: satır bandı
            # üstteki satıra yapışmış olabiliyor (sütun-içi boşluk her zaman var).
            col = strip.crop((bx0, 0, bx1 + 1, strip.height))
            col_bands = _runs([any(col.crop((0, y, col.width, y + 1)).getdata()) for y in range(col.height)], BAND_GAP_PX)
            cy0, cy1 = col_bands[-1] if col_bands else (by0, by1)
            sub = col.crop((0, cy0, col.width, cy1 + 1)).getbbox()
            if sub is None:
                continue
            row_boxes[code_word['code']] = (
                (px0 + bx0 + sub[0]) / scale - PAD_PT,
                (py0 + cy0 + sub[1]) / scale - PAD_PT,
                (px0 + bx0 + sub[2]) / scale + PAD_PT,
                (py0 + cy0 + sub[3]) / scale + PAD_PT,
            )

        # Satır tutarlılık denetimi: aynı satırdaki levhalar benzer boyuttadır. Ortancadan
        # çok sapan kutu, eşleşmenin kaydığını gösterir → o levha bu kaynaktan alınmaz.
        areas = sorted((b[2] - b[0]) * (b[3] - b[1]) for b in row_boxes.values())
        if areas:
            med = areas[len(areas) // 2]
            for code, b in row_boxes.items():
                area = (b[2] - b[0]) * (b[3] - b[1])
                if 0.35 * med <= area <= 3.0 * med:
                    boxes[code] = b
    return boxes


# ——————————————————————————— 3) sayfa vektörleri ———————————————————————————


def _bake(d: str, matrix: list[float] | None) -> tuple[str, tuple[float, float, float, float]] | None:
    """Yol koordinatlarını (varsa) dönüşüm matrisiyle çarpar; sonuç + sınır kutusu döner."""
    nums = NUM_RE.findall(d)
    if len(nums) < 4:
        return None
    vals = [float(n) for n in nums]
    if matrix:
        a, b, c, dd, e, f = matrix
        for i in range(0, len(vals) - 1, 2):
            x, y = vals[i], vals[i + 1]
            vals[i], vals[i + 1] = a * x + c * y + e, b * x + dd * y + f
    xs, ys = vals[0::2], vals[1::2]
    k = min(len(xs), len(ys))
    bbox = (min(xs[:k]), min(ys[:k]), max(xs[:k]), max(ys[:k]))
    if matrix:
        it = iter(vals)
        d = NUM_RE.sub(lambda _m: f'{next(it):.4f}', d)
    return d, bbox


def page_paths(pdf: str, tmp: str, boxes: dict[str, tuple[float, float, float, float]]) -> dict[str, list[dict]]:
    """Sayfayı BİR KEZ SVG'ye çevirir (koordinatlar sayfa uzayında) ve her yolu, tamamen içinde
    kaldığı levha kutusuna dağıtır. Poster çerçevesi/etiketler hiçbir kutuya sığmaz → düşer."""
    svg_path = os.path.join(tmp, os.path.basename(pdf) + '.page.svg')
    run(['pdftocairo', '-svg', pdf, svg_path])
    raw = open(svg_path, encoding='utf-8', errors='replace').read()
    items = sorted(boxes.items(), key=lambda kv: kv[1][0])
    starts = [v[0] for _, v in items]
    out: dict[str, list[dict]] = collections.defaultdict(list)
    import bisect

    for m in PATH_RE.finditer(raw):
        chunk = m.group()
        if 'clip-rule' in chunk:
            continue
        attrs = dict(ATTR_RE.findall(chunk))
        d = attrs.get('d')
        if not d:
            continue
        matrix = None
        if 'transform' in attrs:
            mm = MATRIX_RE.search(attrs['transform'])
            if not mm:
                continue
            matrix = [float(v) for v in NUM_RE.findall(mm.group(1))]
            if len(matrix) != 6:
                continue
        baked = _bake(d, matrix)
        if baked is None:
            continue
        d, bb = baked
        # yolun tamamen içinde kaldığı kutuyu bul (x0'a göre ikili arama ile daralt)
        j = bisect.bisect_right(starts, bb[0] + 0.5)
        for idx in range(max(0, j - 3), min(len(items), j + 1)):
            code, (x0, y0, x1, y1) = items[idx]
            if bb[0] >= x0 - 1 and bb[2] <= x1 + 1 and bb[1] >= y0 - 1 and bb[3] <= y1 + 1:
                out[code].append(dict(attrs=attrs, d=d, bbox=bb))
                break
    return out


# ——————————————————————————— 4) normalizasyon ———————————————————————————


def _hex(match: re.Match[str]) -> str:
    r, g, b = (round(float(match.group(i)) * 255 / 100) for i in (1, 2, 3))
    return f'#{r:02x}{g:02x}{b:02x}'


def _fmt(v: float) -> str:
    s = f'{v:.2f}'.rstrip('0').rstrip('.')
    if s in ('', '-0', '-', '0'):
        return '0'
    if s.startswith('0.'):
        return s[1:]
    if s.startswith('-0.'):
        return '-' + s[2:]
    return s


def _retarget(d: str, ox: float, oy: float, side: float) -> str:
    """Yol verisini 0..100 kare viewBox'a taşır ve en kısa gösterimle yazar.
    pdftocairo yalnız MUTLAK M/L/C/Z üretir (doğrulandı)."""
    k = 100.0 / side
    out: list[str] = []
    last = ''
    for cmd, body in re.findall(r'([MLCZ])([^MLCZ]*)', d):
        if cmd == 'Z':
            out.append('Z')
            last = ''
            continue
        nums = [float(n) for n in NUM_RE.findall(body)]
        pts = [
            _fmt((nums[i] - ox) * k) + ',' + _fmt((nums[i + 1] - oy) * k)
            for i in range(0, len(nums) - 1, 2)
        ]
        if not pts:
            continue
        out.append((cmd if cmd != last else ' ') + ' '.join(pts))
        last = cmd
    return ''.join(out).strip()


KEEP_ATTRS = (
    'fill-rule',
    'fill',
    'fill-opacity',
    'stroke',
    'stroke-width',
    'stroke-linecap',
    'stroke-linejoin',
    'stroke-miterlimit',
)


def _outer_subpath(d: str) -> str:
    """Yolun İLK alt-yolu = dış kontur (üçgen/daire/dikdörtgen gövdesi)."""
    parts = re.split(r'(?=M)', d)
    first = next((p for p in parts if p.strip().startswith('M')), '')
    first = first.split('Z')[0].strip()
    return first + 'Z' if first else ''


def build_svg(paths: list[dict], box: tuple[float, float, float, float]) -> str:
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    side = max(w, h)
    ox, oy = x0 - (side - w) / 2, y0 - (side - h) / 2
    scale = 100.0 / side
    body: list[str] = []

    # Resmî posterlerde levhaların BEYAZ zemini çizilmez — sayfanın beyazı görünür; bazı
    # piktogramlar da "delik" (knockout) olarak bırakılır. Uygulamada levha koyu yüzeylerin
    # üstünde durduğu için dış konturun beyaz bir kopyasını en alta ekleriz.
    if paths:
        biggest = max(paths, key=lambda p: (p['bbox'][2] - p['bbox'][0]) * (p['bbox'][3] - p['bbox'][1]))
        outer = _outer_subpath(biggest['d'])
        if outer:
            body.append(f'<path d="{_retarget(outer, ox, oy, side)}" fill="#ffffff"/>')

    # Düzleştirilmiş kaynaklarda aynı renkte BİNLERCE ince üçgen art arda gelir. Ardışık ve
    # STİLİ AYNI yolları tek bir <path> içinde birleştiririz: boyama sırası korunur, geometri
    # birebir aynı kalır, çizim çağrısı sayısı (dolayısıyla render maliyeti) çöker.
    # Yalnız ARDIŞIK ve stili aynı yollar birleştirilir; DÜZLEŞTİRİLMİŞ kaynakta HİÇ
    # birleştirilmez. (Birleştirme denendi ve düzleştirilmiş levhalarda REDDEDİLDİ: komşu
    # üçgenler ters yönde sarıldığından nonzero dolgu kuralında birbirini siliyor ve levha
    # bozuluyor. Ağır düzleştirilmiş levhalar MAX_PATHS ile elenir.)
    merged: list[dict] = []
    flattened = len(paths) > FLATTEN_LIMIT
    for p in paths:
        style = tuple(p['attrs'].get(k) for k in KEEP_ATTRS)
        can_merge = (
            not flattened
            and merged
            and merged[-1]['style'] == style
            and p['attrs'].get('fill-rule') != 'evenodd'
        )
        if can_merge:
            merged[-1]['d'] += p['d']
        else:
            merged.append(dict(attrs=p['attrs'], d=p['d'], style=style))

    for p in merged:
        attrs = p['attrs']
        out = [f'd="{_retarget(p["d"], ox, oy, side)}"']
        for key in KEEP_ATTRS:
            if key not in attrs:
                continue
            val = RGB_RE.sub(_hex, attrs[key])
            if (key == 'fill-opacity' and val == '1') or (key == 'fill-rule' and val == 'nonzero'):
                continue
            if key == 'stroke-width':
                val = _fmt(float(val) * scale)
            out.append(f'{key}="{val}"')
        body.append('<path ' + ' '.join(out) + '/>')
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">' + ''.join(body) + '</svg>'


# ——————————————————————————— 5) ana akış ———————————————————————————


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--all', action='store_true', help='posterdeki bütün kodları çıkar')
    ap.add_argument('--sheet', action='store_true', help='görsel doğrulama HTML sayfası üret')
    args = ap.parse_args()

    for poster in POSTERS:
        if not os.path.exists(poster['pdf']):
            sys.exit(f"Kaynak PDF yok: {poster['pdf']}\n(referans girdi; .gitignore kapsamında)")
    os.makedirs(OUT, exist_ok=True)
    wanted_codes = set(SIGN_MAP.values())

    with tempfile.TemporaryDirectory() as tmp:
        harvest: dict[str, dict[str, tuple[list[dict], tuple]]] = {}
        for poster in POSTERS:
            pdf, key = poster['pdf'], poster['key']
            boxes = ink_boxes(pdf, label_rows(read_words(pdf, tmp)), tmp)
            if not args.all:
                boxes = {c: b for c, b in boxes.items() if c in wanted_codes}
            grouped = page_paths(pdf, tmp, boxes)
            harvest[key] = {c: (grouped[c], boxes[c]) for c in boxes if grouped.get(c)}
            print(f'{key}: {len(boxes)} kutu · {len(harvest[key])} levhada vektör bulundu')

        codes = sorted(set().union(*(set(h) for h in harvest.values())))
        written, sources, stats, dropped = 0, {}, [], []
        for code in codes:
            options = {k: h[code] for k, h in harvest.items() if code in h}
            # EKSİKSİZLİK ÖLÇÜTÜ: levhanın İÇ piktogramı vektör olarak var mı? (Posterlerin
            # bazılarında piktogram gömülü RASTER'dır; o kaynakta yalnız üçgen/halka kabuğu
            # kalır.) İç ayrıntısı olmayan aday KULLANILMAZ — uygulama kendi vektör glif
            # çizicisine düşer (rasterleştirme yok).
            def detail(item: tuple[list[dict], tuple]) -> int:
                paths, (x0, y0, x1, y1) = item
                area = max(1e-6, (x1 - x0) * (y1 - y0))
                return sum(
                    1
                    for p in paths
                    if (p['bbox'][2] - p['bbox'][0]) * (p['bbox'][3] - p['bbox'][1]) <= 0.35 * area
                )

            if code in DROP:
                dropped.append((code, DROP[code]))
                continue
            usable = {k: v for k, v in options.items() if detail(v) >= 1 or code in EMPTY_OK}
            if not usable:
                dropped.append((code, 'iç piktogram kaynakta vektör değil (gömülü raster)'))
                continue
            chosen_key, chosen = min(usable.items(), key=lambda kv: len(kv[1][0]))
            if len(chosen[0]) > MAX_PATHS:
                dropped.append((code, f'{len(chosen[0])} parça — her iki kaynak da düzleştirilmiş'))
                continue
            svg = build_svg(*chosen)
            with open(os.path.join(OUT, f'{code.lower()}.svg'), 'w', encoding='utf-8') as fh:
                fh.write(svg)
            written += 1
            sources[code] = chosen_key
            stats.append((len(svg), len(chosen[0]), code, chosen_key))

        stats.sort(reverse=True)
        total = sum(s[0] for s in stats)
        print(f'yazıldı: {written} levha · toplam {total / 1024:.1f} KB')
        print('kaynak dağılımı:', collections.Counter(sources.values()).most_common())
        print('en büyük 5:', [f'{s[2]}({s[3]}) {s[0] / 1024:.1f}KB {s[1]}p' for s in stats[:5]])
        missing = sorted(wanted_codes - set(sources))
        if missing:
            print('çıkarılamayan kodlar:', missing)
        if dropped:
            print('bütçe dışı:', dropped)

        with open(os.path.join(HERE, 'official_signs_index.json'), 'w', encoding='utf-8') as fh:
            json.dump(
                {
                    'mapped': len(SIGN_MAP),
                    'codes': sorted(sources),
                    'sources': sources,
                    'dropped': dict(dropped),
                    'unmapped': UNMAPPED_REASON,
                },
                fh,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
        write_dart_binding(sources)
        if args.sheet:
            make_sheet(sorted(sources))
    return 0


def write_dart_binding(sources: dict[str, str]) -> None:
    """Uygulama tarafındaki bağlamayı ÜRETİR: işaret id'si → resmî levha varlığı."""
    pairs = sorted((sid, code) for sid, code in SIGN_MAP.items() if code in sources)
    lines = [
        '// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.',
        '// Kaynak: apps/mobile/tool/extract_official_signs.py (Evolution Faz E1).',
        '//',
        '// Uygulamadaki trafik işareti → RESMÎ levha vektörü (KGM 2020 / İBB standart posterleri).',
        '// Burada olmayan işaretler parametrik `TrafficSignView` çizicisiyle çizilir:',
        '// sayı-parametrik levhalar (hız/ağırlık/mesafe), resmî karşılığı olmayanlar ve',
        '// kaynak posterde vektör olarak temiz çıkarılamayan birkaç levha.',
        '',
        '/// İşaret id → `assets/signs/<kod>.svg`.',
        'const Map<String, String> kOfficialSignAsset = {',
    ]
    lines += [f"  '{sid}': 'assets/signs/{code.lower()}.svg'," for sid, code in pairs]
    lines += [
        '};',
        '',
        '/// Bu işaretin resmî levha vektörü var mı?',
        'String? officialSignAsset(String signId) => kOfficialSignAsset[signId];',
        '',
    ]
    dest = os.path.join(MOBILE, 'lib', 'core', 'official_signs.dart')
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(lines))
    print(f'dart bağlaması: {len(pairs)} işaret → {os.path.relpath(dest, REPO)}')


def make_sheet(codes: list[str]) -> None:
    """Üretilen bütün levhaları tek HTML sayfasında dizer — tarayıcıda görsel doğrulama için."""
    cells = []
    for code in codes:
        svg = open(os.path.join(OUT, f'{code.lower()}.svg'), encoding='utf-8').read()
        cells.append(f'<figure><div class="s">{svg}</div><figcaption>{code}</figcaption></figure>')
    html = (
        '<!doctype html><meta charset="utf-8"><title>Resmî levhalar</title><style>'
        'body{background:#0b1220;color:#cbd5e1;font:12px system-ui;margin:16px}'
        'main{display:grid;grid-template-columns:repeat(auto-fill,minmax(104px,1fr));gap:10px}'
        'figure{margin:0;text-align:center}.s{background:#111a2e;border-radius:10px;padding:6px}'
        '.s svg{width:88px;height:88px;display:block;margin:auto}figcaption{margin-top:4px}'
        '</style><main>' + ''.join(cells) + '</main>'
    )
    dest = os.path.join(tempfile.gettempdir(), 'official_signs_sheet.html')
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print('doğrulama sayfası:', dest)


if __name__ == '__main__':
    raise SystemExit(main())
