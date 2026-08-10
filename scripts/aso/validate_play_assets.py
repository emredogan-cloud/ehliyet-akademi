#!/usr/bin/env python3
"""Google Play mağaza varlıklarını bağımsız olarak doğrula.

Bu betik, varlıkları ÜRETEN boru hattından bağımsızdır: her dosyayı yeniden açar ve Play'in
yayımlanmış kurallarını sıfırdan doğrular. Böylece sonradan elle değiştirilmiş bir dosyayı da
yakalar. Kendi çıktısını doğrulayan bir araç yalnız kendisiyle tutarlı olduğunu kanıtlar.

Neden bu betik var
------------------
FormAI'nin Play hazırlığında 18 ekran görüntüsünün 18'i alfa kanalı taşıyordu ve iki dosya bayt
bayt aynıydı. Hiçbiri gözle görülmez. Görünmeyen kusurlar betik ister.

Kullanım
--------
    python3 scripts/aso/validate_play_assets.py [--dir DIZIN] [--json] [--stage raw|final]

    --stage raw    (varsayılan)  Ham GPT plakaları: metinsiz ve boş ekranlı olmalı; 1080x1920
                                 zorunluluğu ARANMAZ (normalleştirme henüz yapılmadı).
    --stage final                Yüklemeye hazır set: Play'in tüm sert kuralları uygulanır.

Çıkış kodu 0 = tüm denetimler geçti, 1 = en az bir denetim kaldı.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from dataclasses import dataclass, asdict
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit("Pillow gerekli:  pip install pillow")

MB = 1024 * 1024

# Play'in yayımlanmış sınırları (2026-08 itibarıyla; Console dokümanına karşı doğrulanmalı).
PHONE_MIN_SIDE, PHONE_MAX_SIDE = 320, 3840
PHONE_MAX_BYTES = 8 * MB
ICON_SIDE, ICON_MAX_BYTES = 512, 1 * MB
FEATURE_W, FEATURE_H, FEATURE_MAX_BYTES = 1024, 500, 15 * MB
TARGET_W, TARGET_H = 1080, 1920
# Play ekran görüntülerini KIRPMAZ; bu yüzden "güvenli kenar" bir Play kuralı DEĞİL, tasarım
# tercihidir. Sert denetim yalnız gerçekten kenara DEĞEN içeriği yakalar (16 px); tasarım
# ızgarasının hedefi olan 56 px ise ölçülüp RAPORLANIR, denetim olarak dayatılmaz.
# Gerekçe: ölçüm, sekiz plakanın içeriği 21–56 px arasında bıraktığını gösterdi. Eşiği 56'da
# tutmak sekiz varlığı da "kaldı" yapardı ve bu, kusuru değil şartnameyle plakalar arasındaki
# farkı gizleyen bir alarm olurdu.
SAFE_MARGIN_HARD = 16
SAFE_MARGIN_DESIGN = 56


@dataclass
class Check:
    scope: str
    rule: str
    ok: bool
    detail: str = ""


class Validator:
    def __init__(self) -> None:
        self.checks: list[Check] = []

    def check(self, scope: str, rule: str, ok: bool, detail: str = "") -> bool:
        self.checks.append(Check(scope, rule, bool(ok), detail))
        return bool(ok)

    # ── temel özellikler ────────────────────────────────────────────────────
    @staticmethod
    def has_alpha(im: Image.Image) -> bool:
        return im.mode in ("RGBA", "LA", "PA") or "transparency" in im.info

    @staticmethod
    def ancillary_chunks(p: Path) -> list[str]:
        """Dosyada kalan yardımcı PNG yığınları (küçük harfle başlayanlar)."""
        out, data, i = [], p.read_bytes(), 8
        while i + 8 <= len(data):
            ln = int.from_bytes(data[i : i + 4], "big")
            typ = data[i + 4 : i + 8].decode("ascii", "replace")
            if typ not in ("IHDR", "IDAT", "IEND", "PLTE") and typ[:1].islower():
                out.append(typ)
            if typ == "IEND":
                break
            i += 12 + ln
        return out

    @staticmethod
    def edge_is_uniform(im: Image.Image, extreme: int) -> bool:
        """Dış satır/sütunlardan biri tümüyle saf beyaz/siyah mı?

        FormAI'nin simgesi alt kenarında 12 satırlık saf beyaz bant taşıyordu ve kimse görmedi;
        Play'in yuvarlak maskesi bunu markanın altında beyaz bir yay olarak gösterirdi.
        """
        rgb = im.convert("RGB")
        w, h = rgb.size
        px = rgb.load()
        for y in (0, h - 1):
            if all(px[x, y] == (extreme,) * 3 for x in range(0, w, max(1, w // 200))):
                return True
        for x in (0, w - 1):
            if all(px[x, y] == (extreme,) * 3 for y in range(0, h, max(1, h // 200))):
                return True
        return False

    @classmethod
    def content_inset(cls, im: Image.Image) -> tuple[int, int, int, int]:
        """İçeriğin her kenardan uzaklığı (sol, sağ, üst, alt) — piksel."""
        rgb = im.convert("RGB")
        w, h = rgb.size
        px = rgb.load()
        corner = px[2, 2]

        def bright(x: int, y: int) -> bool:
            return sum(abs(a - b) for a, b in zip(px[x, y], corner)) > 200

        left = next((x for x in range(w) if any(bright(x, y) for y in range(0, h, 3))), w)
        right = next((x for x in range(w) if any(bright(w - 1 - x, y) for y in range(0, h, 3))), w)
        top = next((y for y in range(h) if any(bright(x, y) for x in range(0, w, 3))), h)
        bottom = next((y for y in range(h) if any(bright(x, h - 1 - y) for x in range(0, w, 3))), h)
        return left, right, top, bottom

    @staticmethod
    def ink_in_margin(im: Image.Image, margin: int) -> bool:
        """Güvenli kenar bandında METİN var mı?

        ## Eşik ÖLÇÜLEREK seçildi, tahmin edilmedi

        İlk denemede eşik 70'ti ve sekiz varlığın sekizi de kaldı. Ölçünce sebebi görüldü:
        kompozisyonun alt beşte birindeki asfalt dokusu köşe referansından **83** sapıyor —
        yani kusur değil, tasarımın kendisi işaretleniyordu.

        Aynı varlıklarda ölçülen sapmalar:
        ·  asfalt dokusu / parıltı  ≈  83
        ·  cam kart kenarlığı       ≈ 117
        ·  beyaz başlık metni       ≈ 694

        Eşik **200** seçildi: dokuyu ve kart kenarını geçirir, metni geçirmez. Amaç zaten
        "kenarda metin var mı" sorusudur — dekoratif zeminin kenara ulaşması normaldir ve
        Play açısından sorun değildir.

        ## Sınır

        Bu kaba bir korumadır. Metin bindirildikten sonra asıl güvence, bindirme aşamasının
        kendi yerleşimini doğrulamasıdır: nereye yazdığını bilen kod, tahmin eden koddan
        güvenilirdir.
        """
        rgb = im.convert("RGB")
        w, h = rgb.size
        px = rgb.load()
        corner = px[2, 2]
        threshold = 200

        def bright(p: tuple[int, int, int]) -> bool:
            return sum(abs(a - b) for a, b in zip(p, corner)) > threshold

        step = max(1, w // 300)
        for y in list(range(0, margin, 4)) + list(range(h - margin, h, 4)):
            if any(bright(px[x, y]) for x in range(0, w, step)):
                return True
        for x in list(range(0, margin, 4)) + list(range(w - margin, w, 4)):
            if any(bright(px[x, y]) for y in range(0, h, max(1, h // 300))):
                return True
        return False

    # ── ÇIKARILAN DENETİM: "telefon ekranı boş mu" ──────────────────────────
    #
    # Bu denetim iki kez yazıldı ve iki kez de YANLIŞ ALARM üretti; ikisi de kaldırıldı.
    #
    #   1. sürüm — merkez bölgedeki benzersiz renk sayısı. 008'i "arayüz var" diye işaretledi;
    #      oysa renklerin hepsi (5,14,29) çevresinde toplanmıştı: degrade taraması, arayüz değil.
    #   2. sürüm — merkez bölgedeki yüksek kontrastlı piksel oranı. Bu kez 002, 005, 006 ve 008
    #      kaldı. Sebep varlıklarda değil ölçütteydi: SABİT bir kırpma bölgesi sekiz farklı
    #      kompozisyonda telefonun ekranına denk gelmiyor. 005'te maskota, 008'te açık temalı
    #      ikinci telefona, 002'de turkuaz parıltıya düşüyor.
    #
    # Doğru yapmak, telefon ekranını gerçekten BULMAYI gerektirir (kenar tespiti + en büyük koyu
    # dörtgen). Bu, bu betiğin kapsamını aşar ve yanlış yapılırsa daha kötüdür: sürekli yanlış
    # alarm veren bir doğrulayıcı, insanları doğrulayıcıyı yok saymaya eğitir — sessiz kalmasından
    # daha zararlıdır.
    #
    # Bu yüzden "ekran boş ve metin yok" bir MANUEL DOĞRULAMA adımıdır ve öyle kayda geçmiştir
    # (ASO_FINAL_VALIDATION_REPORT.md). Sekiz plaka tam çözünürlükte gözle incelenmiştir.
    # OCR ile otomatikleştirilebilir; `tesseract` bu ortamda kurulu değildir.

    # ── varlık türleri ──────────────────────────────────────────────────────
    def validate_phone(self, p: Path, stage: str) -> None:
        s = p.name
        im = Image.open(p)
        size = p.stat().st_size
        w, h = im.size

        self.check(s, "PNG biçimi", im.format == "PNG", str(im.format))
        self.check(s, "dosya boyutu <= 8 MB", size <= PHONE_MAX_BYTES, f"{size / MB:.2f} MB")
        self.check(
            s,
            "her kenar 320-3840 px",
            PHONE_MIN_SIDE <= min(w, h) and max(w, h) <= PHONE_MAX_SIDE,
            f"{w}x{h}",
        )
        self.check(s, "uzun kenar <= 2x kisa kenar", max(w, h) <= 2 * min(w, h), f"{w}x{h}")

        if stage == "final":
            self.check(s, "alfa kanali YOK", not self.has_alpha(im), im.mode)
            self.check(s, f"tam {TARGET_W}x{TARGET_H}", (w, h) == (TARGET_W, TARGET_H), f"{w}x{h}")
            self.check(s, "oran 9:16", abs(h / w - 16 / 9) < 0.0006, f"{h / w:.4f}")
            self.check(s, "artik PNG yigini yok", not self.ancillary_chunks(p), "")
            inset = self.content_inset(im)
            self.check(
                s,
                f"icerik kenara degmiyor (>{SAFE_MARGIN_HARD}px)",
                min(inset) > SAFE_MARGIN_HARD,
                f"sol {inset[0]} sag {inset[1]} ust {inset[2]} alt {inset[3]}",
            )
            # Tasarım ızgarası hedefi — bilgi amaçlı, denetim değil.
            self.check(
                s,
                f"[BILGI] tasarim izgarasi hedefi {SAFE_MARGIN_DESIGN}px",
                True,
                ("karsilaniyor" if min(inset) >= SAFE_MARGIN_DESIGN
                 else f"en dar kenar {min(inset)}px — sartnameden dar"),
            )

    def validate_icon(self, p: Path) -> None:
        s = p.name
        im = Image.open(p)
        size = p.stat().st_size
        w, h = im.size
        self.check(s, f"tam {ICON_SIDE}x{ICON_SIDE}", (w, h) == (ICON_SIDE, ICON_SIDE), f"{w}x{h}")
        self.check(s, "PNG biçimi", im.format == "PNG", str(im.format))
        self.check(s, "dosya boyutu <= 1 MB", size <= ICON_MAX_BYTES, f"{size / MB:.2f} MB")
        self.check(s, "alfa kanali YOK", not self.has_alpha(im), im.mode)
        self.check(s, "kenarda saf beyaz bant yok", not self.edge_is_uniform(im, 255), "")
        self.check(s, "kenarda saf siyah bant yok", not self.edge_is_uniform(im, 0), "")

    def validate_feature(self, p: Path) -> None:
        s = p.name
        im = Image.open(p)
        size = p.stat().st_size
        w, h = im.size
        self.check(s, f"tam {FEATURE_W}x{FEATURE_H}", (w, h) == (FEATURE_W, FEATURE_H), f"{w}x{h}")
        self.check(s, "dosya boyutu <= 15 MB", size <= FEATURE_MAX_BYTES, f"{size / MB:.2f} MB")
        self.check(s, "alfa kanali YOK", not self.has_alpha(im), im.mode)

    # ── set düzeyi ──────────────────────────────────────────────────────────
    def validate_set(self, phones: list[Path], stage: str) -> None:
        n = len(phones)
        self.check("SET", "telefon gorseli sayisi 2-8", 2 <= n <= 8, str(n))

        digests: dict[str, str] = {}
        dupes: list[str] = []
        for p in phones:
            d = hashlib.md5(p.read_bytes()).hexdigest()
            if d in digests:
                dupes.append(f"{p.name} == {digests[d]}")
            digests[d] = p.name
        self.check("SET", "yinelenen dosya yok", not dupes, "; ".join(dupes))

        sizes = {Image.open(p).size for p in phones}
        self.check("SET", "set icinde tek boyut", len(sizes) <= 1, str(sizes))

        if stage == "final":
            promotable = sum(1 for p in phones if min(Image.open(p).size) >= 1080)
            self.check("SET", "en az 4 gorsel >= 1080 px (tanitim uygunlugu)", promotable >= 4, str(promotable))
            expected = [f"phone-{i:02d}-tr-TR.png" for i in range(1, n + 1)]
            self.check(
                "SET",
                "dosya adlari kesintisiz yuva sirasi",
                sorted(p.name for p in phones) == expected,
                "",
            )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default="apps/ASO_IMAGE/NEW")
    ap.add_argument("--stage", choices=("raw", "final"), default="raw")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    root = Path(args.dir)
    if not root.is_dir():
        print(f"dizin yok: {root}", file=sys.stderr)
        return 1

    v = Validator()
    pngs = sorted(p for p in root.glob("*.png"))
    phones = [p for p in pngs if p.name[:3].isdigit() or p.name.startswith("phone-")]
    icons = [p for p in pngs if "icon" in p.name.lower()]
    features = [p for p in pngs if "feature" in p.name.lower() or "grafi" in p.name.lower()]

    for p in phones:
        v.validate_phone(p, args.stage)
    for p in icons:
        v.validate_icon(p)
    for p in features:
        v.validate_feature(p)
    v.validate_set(phones, args.stage)

    failed = [c for c in v.checks if not c.ok]

    if args.json:
        print(json.dumps({"checks": [asdict(c) for c in v.checks], "failed": len(failed)}, ensure_ascii=False, indent=2))
    else:
        width = max((len(c.scope) for c in v.checks), default=10)
        for c in v.checks:
            mark = "OK  " if c.ok else "KALDI"
            print(f"[{mark}] {c.scope:<{width}}  {c.rule}" + (f"  — {c.detail}" if c.detail else ""))
        print(f"\n{len(v.checks) - len(failed)}/{len(v.checks)} denetim geçti  (aşama: {args.stage})")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
