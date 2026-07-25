#!/usr/bin/env python3
"""
Gösterge paneli ikaz ışıkları: 10×6 ızgaradaki 60 ikonu tek tek keser, şeffaflaştırır ve
`assets/dash/` altına WebP olarak yazar. (Evolution Faz E3 · Phase Group 2.)

GİRDİ (repoda DEĞİL — .gitignore'da):
  <repo>/apps/assets/mekanik assets/B-sınıfı-gösterge-işaretleri.png  (1536×1024)

ÇIKTI (repoda İZLENİR):
  apps/mobile/assets/dash/<id>.webp   +   lib/core/dash_assets.dart (üretilmiş katalog)

KULLANIM:
  python3 apps/mobile/tool/extract_dash_icons.py --detect   # ızgara tespiti + doğrulama sayfası
  python3 apps/mobile/tool/extract_dash_icons.py            # kes, anahtarla, yaz, katalog üret

YÖNTEM: sayfada ikon satırları ile İNGİLİZCE ALT YAZI satırları dönüşümlü. Mürekkep bantlarından
yüksek olanlar (yazılardan kalın) ikon satırıdır; her ikon satırı 10 eşit sütuna bölünür ve hücre
mürekkebine kırpılır. Anahtarlama `extract_mech_assets` ile aynı (kenardan yayılan zemin + yumuşak
alfa) — neon parlama yumuşakça sönümlenir.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_mech_assets import (  # noqa: E402  (araç betiği — aynı klasörden paylaşılan yardımcılar)
    MOBILE,
    REPO,
    SRC,
    Image,
    _runs,
    key_and_save,
    object_mask,
)

SHEET = os.path.join(SRC, 'B-sınıfı-gösterge-işaretleri.png')
OUT = os.path.join(MOBILE, 'assets', 'dash')

COLS = 10
ROWS = 6
ICON_BAND_MIN_H = 50  # ikon bantları en az bu kadar kalın
BAND_GAP = 10

# 60 ikaz ışığı — ızgara sırasıyla (soldan sağa, yukarıdan aşağıya).
# id · Türkçe ad · anlam · hafıza ipucu · önem (kirmizi | sari | bilgi)
LIGHTS: list[tuple[str, str, str, str, str]] = [
    ('fren-uyari', 'Fren Sistemi Uyarısı', 'El freni çekili veya fren hidroliği düşük ya da fren sisteminde arıza var.', 'Ünlem + daire = frenle ilgili; kırmızıysa güvenli yerde DUR.', 'kirmizi'),
    ('aku-sarj', 'Akü / Şarj Uyarısı', 'Şarj sistemi aküyü beslemiyor; alternatör veya kayış arızası olabilir.', 'Akü resmi: motor çalışırken yanıyorsa şarj yok demektir.', 'kirmizi'),
    ('yag-basinci', 'Yağ Basıncı Uyarısı', 'Motor yağ basıncı düştü; motor zarar görebilir.', 'Yağdanlık damlıyor = basınç yok; motoru HEMEN durdur.', 'kirmizi'),
    ('motor-arizasi', 'Motor Arıza Lambası', 'Motor kontrol sisteminde arıza var; egzoz/yakıt sistemi etkilenmiş olabilir.', 'Motor silueti = "check engine"; yanıp sönüyorsa hız kesip servise git.', 'sari'),
    ('kizdirma-bujisi', 'Kızdırma Bujisi (dizel)', 'Dizel motorda kızdırma bujileri ısınıyor; sönmeden marş yapılmaz.', 'Kıvrık teller = kızdırma; sönünce çalıştır.', 'sari'),
    ('hararet', 'Motor Sıcaklığı Yüksek', 'Motor aşırı ısındı; soğutma sistemi yetersiz kalıyor.', 'Termometre dalgada = hararet; kenara çek, soğumadan kapağı AÇMA.', 'kirmizi'),
    ('sogutma-suyu', 'Soğutma Suyu Düşük', 'Radyatör/genleşme kabındaki soğutma suyu seviyesi azaldı.', 'Kap + dalga = sıvı seviyesi; soğukken tamamla.', 'kirmizi'),
    ('hava-yastigi', 'Hava Yastığı Uyarısı', 'SRS hava yastığı sisteminde arıza var; kazada açılmayabilir.', 'Oturan kişi + top = hava yastığı.', 'kirmizi'),
    ('emniyet-kemeri', 'Emniyet Kemeri Uyarısı', 'Sürücü veya yolcunun kemeri takılı değil.', 'Kemer takılı figür = kemeri bağla.', 'kirmizi'),
    ('kapi-acik', 'Kapı Açık Uyarısı', 'Bir kapı veya bagaj tam kapanmamış.', 'Kapıları açık araç kuşbakışı = kapı açık.', 'kirmizi'),
    ('abs', 'ABS Uyarısı', 'Kilitlenmeyi önleyici fren sistemi devre dışı; frenler çalışır ama tekerlek kilitlenebilir.', 'Daire içinde ABS yazısı; fren gücü durur, ABS durur.', 'sari'),
    ('cekis-kontrol', 'Çekiş Kontrolü (TCS)', 'Çekiş kontrol sistemi çalışıyor veya arızalı; zeminde patinaj var.', 'Kayan araç + izler = tutunma kaybı.', 'sari'),
    ('esp', 'Elektronik Denge Kontrolü (ESP)', 'Denge kontrol sistemi devrede ya da arızalı.', 'Kayan araç = savrulma kontrolü; kapalıysa dikkatli sür.', 'sari'),
    ('lastik-basinci', 'Lastik Basıncı (TPMS)', 'Bir veya birden fazla lastikte basınç düşük.', 'Ünlemli lastik kesiti = havası eksik.', 'sari'),
    ('yakit-az', 'Yakıt Az', 'Depodaki yakıt rezerve düştü; kalan menzil sınırlıdır, ilk istasyonda doldur.', 'Pompa simgesi; ibrenin yanındaki ok depo kapağının yönünü gösterir.', 'sari'),
    ('cam-suyu', 'Cam Suyu Az', 'Cam yıkama suyu deposu boşalmak üzere.', 'Cam + fışkıran su = yıkama suyu.', 'sari'),
    ('fren-sistemi', 'Fren Sistemi (genel)', 'Fren sisteminde genel bir uyarı var; balata veya hidrolik kontrol edilir.', 'Sarı daire + ünlem = fren sistemi kontrolü.', 'sari'),
    ('el-freni', 'El Freni Çekili', 'Park freni devrede; kalkmadan önce indir.', 'Daire içinde P = park freni.', 'sari'),
    ('auto-hold', 'Otomatik Fren Tutma', 'Auto Hold devrede; durunca araç frende tutulur.', 'AUTO HOLD yazısı; gaz verince kendiliğinden bırakır.', 'sari'),
    ('yokus-inis', 'Yokuş İniş Kontrolü', 'Dik inişte hızı sabit tutan sistem devrede.', 'Eğimde araç = iniş kontrolü.', 'sari'),
    ('sol-sinyal', 'Sol Sinyal', 'Sol dönüş/şerit değişikliği sinyali yanıyor.', 'Yeşil ok yönü = sinyal yönü.', 'bilgi'),
    ('sag-sinyal', 'Sağ Sinyal', 'Sağ dönüş/şerit değişikliği sinyali yanıyor.', 'Yeşil ok yönü = sinyal yönü.', 'bilgi'),
    ('dortlu-flasor', 'Dörtlü Flaşör', 'Her iki sinyal birlikte yanıyor; arıza veya tehlike bildirimi.', 'Çift ok = dörtlü flaşör.', 'bilgi'),
    ('on-sis-farlari', 'Ön Sis Farları', 'Ön sis farları açık; yalnız görüş 50 metrenin altındayken kullanılır.', 'Düz çizgili far + eğik çizgi = ön sis.', 'bilgi'),
    ('arka-sis-farlari', 'Arka Sis Farları', 'Arka sis lambası açık; açık havada arkadakini kör eder.', 'Dalgalı çizgiyi kesen far = arka sis.', 'bilgi'),
    ('uzun-far', 'Uzun Hüzmeli Far', 'Uzun far açık; karşıdan araç gelince kısa fara geç.', 'Düz ışınlar = uzun far (mavi).', 'bilgi'),
    ('kisa-far', 'Kısa Hüzmeli Far', 'Kısa hüzmeli (yakın) far açık; yerleşim yeri içinde ve karşıdan araç gelirken kullanılır.', 'Aşağı eğik ışınlar = kısa far.', 'bilgi'),
    ('gunduz-farlari', 'Gündüz Sürüş Farları', 'Gündüz sürüş lambaları yanıyor.', 'DRL: gündüz görünürlük ışığı.', 'bilgi'),
    ('park-lambasi', 'Park Lambası', 'Park (konum) lambaları açık; aracın duruşta görünür olmasını sağlar, yol aydınlatmaz.', 'İki yana ışık = park lambası.', 'bilgi'),
    ('hiz-sabitleyici', 'Hız Sabitleyici Aktif', 'Cruise control devrede; ayarlanan hız korunuyor.', 'Kadran + ok = sabit hız.', 'bilgi'),
    ('adaptif-hiz', 'Adaptif Hız Sabitleyici', 'Öndeki araca göre mesafe koruyan hız sabitleyici devrede.', 'Araç + kadran = mesafeli sabit hız.', 'bilgi'),
    ('serit-takip', 'Şerit Takip Uyarısı', 'Sinyal vermeden şeritten çıkıldı.', 'Şerit çizgileri arasında araç = şeritten sapma.', 'sari'),
    ('kor-nokta', 'Kör Nokta Uyarısı', 'Yan veya arka kör noktada araç var; şerit değiştirme bu anda tehlikelidir.', 'Yandaki araç işareti = kör nokta.', 'sari'),
    ('carpisma-uyarisi', 'Çarpışma Uyarısı', 'Öndeki araca çarpışma riski algılandı; hemen hızını kes ve mesafeyi aç.', 'Araç + patlama = çarpışma riski.', 'kirmizi'),
    ('ileri-mesafe', 'Öne Mesafe Uyarısı', 'Öndeki araca takip mesafesi çok kısaldı.', 'Dalgalar + araç = mesafe algısı.', 'sari'),
    ('arka-capraz', 'Arka Çapraz Trafik Uyarısı', 'Geri çıkarken yandan gelen araç var.', 'Arkadan çapraz dalga = geri manevra uyarısı.', 'sari'),
    ('park-sensoru', 'Park Sensörü Uyarısı', 'Park sensörü yakında engel algıladı; sesli uyarı sıklaştıkça mesafe azalıyordur.', 'P + dalga = mesafe uyarısı.', 'sari'),
    ('start-stop', 'Start/Stop Sistemi', 'Motor durakta otomatik susuyor; fren bırakılınca çalışır.', 'Daire içinde A = otomatik.', 'bilgi'),
    ('start-stop-kapali', 'Start/Stop Kapalı', 'Otomatik durdurma devre dışı bırakıldı.', 'A + OFF = sistem kapalı.', 'sari'),
    ('diferansiyel-kilidi', 'Diferansiyel Kilidi', 'Diferansiyel kilidi devrede; düşük tutuşta çekiş sağlar.', 'Aks + kilit = diferansiyel.', 'sari'),
    ('guvenlik-alarmi', 'Güvenlik Alarmı', 'Alarm sistemi devrede veya tetiklendi.', 'Kilit + araç = güvenlik.', 'kirmizi'),
    ('immobilizer', 'İmmobilizer Uyarısı', 'Anahtar tanınmadı; motor çalışmayabilir.', 'Anahtar simgesi = immobilizer.', 'kirmizi'),
    ('hidrolik-direksiyon', 'Direksiyon Sistemi Uyarısı', 'Hidrolik/elektrikli direksiyon desteğinde arıza var; direksiyon ağırlaşır.', 'Direksiyon + ünlem = destek yok.', 'kirmizi'),
    ('sanziman-sicakligi', 'Şanzıman Sıcaklığı', 'Şanzıman yağı aşırı ısındı; yük altında sürüşe devam edilirse şanzıman zarar görür.', 'Dişli + termometre = şanzıman sıcak.', 'kirmizi'),
    ('sanziman-arizasi', 'Şanzıman Arızası', 'Otomatik şanzımanda arıza algılandı.', 'Dişli + ünlem = şanzıman arızası.', 'kirmizi'),
    ('yag-seviyesi', 'Motor Yağ Seviyesi Düşük', 'Motor yağ seviyesi azaldı; basınç uyarısından farklıdır.', 'Yağdanlık + dalga = seviye düşük.', 'kirmizi'),
    ('alternator', 'Alternatör Uyarısı', 'Alternatör üretim yapmıyor; akü boşalır.', 'Motor + artı/eksi = şarj üretimi.', 'kirmizi'),
    ('aku-sicakligi', 'Akü Sıcaklığı', 'Akü sıcaklığı normalin dışında.', 'Akü + termometre.', 'kirmizi'),
    ('dpf', 'Partikül Filtresi (DPF)', 'Dizel partikül filtresi doldu; rejenerasyon gerekir.', 'Kutu + noktalar = kurum filtresi.', 'sari'),
    ('katalitik', 'Katalitik Konvertör Uyarısı', 'Katalitik konvertör aşırı ısındı veya arızalı.', 'Egzoz gövdesi + ısı.', 'kirmizi'),
    ('kar-modu', 'Kar Modu', 'Kaygan zemin sürüş modu devrede.', 'Kar tanesi = kışlık mod.', 'bilgi'),
    ('bilgi-mesaji', 'Bilgi Mesajı', 'Gösterge ekranında okunması gereken bir bilgi var.', 'Daire içinde i = bilgi.', 'bilgi'),
    ('eko-mod', 'ECO Modu', 'Yakıt tasarrufu (ECO) modu devrede; gaz tepkisi ve klima gücü yumuşatılır.', 'Yaprak = ekonomik sürüş.', 'bilgi'),
    ('spor-mod', 'SPOR Modu', 'Spor sürüş modu devrede; tepkiler sertleşir.', 'Gösterge panelinde SPORT yazısı belirir.', 'bilgi'),
    ('serit-koruma', 'Şeritte Tutma Aktif', 'Şeritte tutma desteği direksiyona müdahale ediyor.', 'Direksiyon + ünlem yeşil = destek aktif.', 'bilgi'),
    ('adaptif-far', 'Adaptif Far Sistemi', 'Farlar viraja/karşı araca göre hüzmeyi ayarlıyor.', 'Eğik ışın çizgileri = adaptif hüzme.', 'bilgi'),
    ('far-seviye', 'Far Seviye Ayarı', 'Far yükseklik ayarı değiştirildi.', 'Far + yukarı/aşağı ok.', 'bilgi'),
    ('romork-cekme', 'Römork Çekme Modu', 'Römork/karavan çekme modu devrede.', 'Römork silueti.', 'bilgi'),
    ('servis-zamani', 'Periyodik Bakım Zamanı', 'Bakım aralığı doldu; servise gitme zamanı.', 'İngiliz anahtarı = bakım.', 'sari'),
    ('hava-filtresi', 'Hava Filtresi Uyarısı', 'Hava filtresi tıkandı; performans ve yakıt tüketimi etkilenir.', 'Petek desen = filtre.', 'sari'),
]

SEVERITY = {'kirmizi': 'Kırmızı — dur ve kontrol et', 'sari': 'Sarı — dikkat, en kısa sürede kontrol', 'bilgi': 'Bilgi — sistem aktif'}


def icon_bands(mask: Image.Image) -> list[tuple[int, int]]:
    """Sayfa ikon/altyazı bantları hâlinde DÖNÜŞÜMLÜ; çift indisliler ikon satırlarıdır.
    (Yalnız yüksekliğe bakmak yetmiyor: iki satırlık bir altyazı bandı ikon kadar kalın olabiliyor.)"""
    rows = [any(mask.crop((0, y, mask.width, y + 1)).getdata()) for y in range(mask.height)]
    bands = _runs(rows, BAND_GAP, 6)
    icons = bands[0::2]
    if any(b[1] - b[0] + 1 < ICON_BAND_MIN_H for b in icons):
        raise SystemExit(f'ikon bandı beklenenden ince: {icons}')
    return icons


def cells(path: str) -> list[tuple[int, int, int, int]]:
    """60 ikonun sınır kutuları (ızgara sırasıyla)."""
    img = Image.open(path)
    mask = object_mask(img)
    bands = icon_bands(mask)
    if len(bands) != ROWS:
        raise SystemExit(f'ikon satırı sayısı beklenenden farklı: {len(bands)} (beklenen {ROWS})')
    col_w = img.width / COLS
    boxes: list[tuple[int, int, int, int]] = []
    for by0, by1 in bands:
        band = mask.crop((0, by0, mask.width, by1 + 1))
        for c in range(COLS):
            x0, x1 = int(c * col_w), int((c + 1) * col_w)
            cell = band.crop((x0, 0, x1, band.height))
            bb = cell.getbbox()
            if bb is None:
                raise SystemExit(f'boş hücre: satır {by0}, sütun {c}')
            boxes.append((x0 + bb[0], by0 + bb[1], x0 + bb[2], by0 + bb[3]))
    return boxes


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--detect', action='store_true')
    args = ap.parse_args()
    if not os.path.exists(SHEET):
        sys.exit(f'Kaynak yok: {SHEET}\n(referans girdi; .gitignore kapsamında)')
    os.makedirs(OUT, exist_ok=True)

    boxes = cells(SHEET)
    print(f'ikon: {len(boxes)} (beklenen {ROWS * COLS}) · içerik kaydı: {len(LIGHTS)}')
    if len(boxes) != len(LIGHTS):
        sys.exit('ızgara ile içerik listesi uyuşmuyor')
    if args.detect:
        return 0

    total = 0
    catalog: dict[str, str] = {}
    with tempfile.TemporaryDirectory() as tmp:
        for (lid, *_), box in zip(LIGHTS, boxes):
            dest = os.path.join(OUT, f'{lid}.webp')
            total += key_and_save(SHEET, box, dest, tmp)
            catalog[lid] = f'assets/dash/{lid}.webp'
    print(f'yazıldı: {len(catalog)} ikon · {total / 1024:.0f} KB')

    lines = [
        '// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.',
        '// Kaynak: apps/mobile/tool/extract_dash_icons.py (Evolution Faz E3).',
        '//',
        '// Gösterge paneli ikaz ışıkları — şeffaf zeminli WebP ikonlar.',
        '',
        '/// İkaz ışığı kimliği → varlık yolu.',
        'const Map<String, String> kDashAsset = {',
    ]
    lines += [f"  '{k}': '{v}'," for k, v in sorted(catalog.items())]
    lines += ['};', '', '/// Bu ikaz ışığının ikonu var mı?', 'String? dashAsset(String id) => kDashAsset[id];', '']
    dest = os.path.join(MOBILE, 'lib', 'core', 'dash_assets.dart')
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(lines))
    print(f'dart kataloğu: {len(catalog)} ikon → {os.path.relpath(dest, REPO)}')

    write_content()
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'dash_icons_index.json'), 'w', encoding='utf-8') as fh:
        json.dump({'count': len(catalog), 'severity': SEVERITY}, fh, ensure_ascii=False, indent=2)
    return 0


def write_content() -> None:
    """İçerik listesini Dart'a üretir — tek kaynak bu betiktir, elle iki yerde tutulmaz."""
    def esc(t: str) -> str:
        return t.replace('\\', '\\\\').replace("'", "\\'")

    lines = [
        '// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.',
        '// Kaynak: apps/mobile/tool/extract_dash_icons.py (Evolution Faz E3).',
        '',
        "import '../../core/dash_assets.dart';",
        '',
        '/// İkaz ışığının GEREKTİRDİĞİ EYLEM düzeyi (ikonun rengiyle çoğu zaman örtüşür,',
        '/// ama sınıflandırma öğretim amaçlıdır: ne yapmam gerekiyor?).',
        'enum DashSeverity {',
        '  /// Dur ve kontrol et — sürüşe devam motoru/güvenliği riske atar.',
        '  kirmizi,',
        '',
        '  /// Dikkat — en kısa sürede kontrol ettir, ama güvenle devam edebilirsin.',
        '  sari,',
        '',
        '  /// Bilgi — bir sistem açık/aktif, arıza değil.',
        '  bilgi;',
        '',
        '  String get label => switch (this) {',
        "    DashSeverity.kirmizi => 'Dur ve kontrol et',",
        "    DashSeverity.sari => 'Dikkat — kontrol ettir',",
        "    DashSeverity.bilgi => 'Bilgi — sistem aktif',",
        '  };',
        '}',
        '',
        '/// Gösterge panelindeki bir ikaz ışığı.',
        'class DashLight {',
        '  const DashLight(this.id, this.name, this.meaning, this.tip, this.severity);',
        '  final String id;',
        '  final String name;',
        '  final String meaning;',
        '  final String tip;',
        '  final DashSeverity severity;',
        '',
        '  /// İkon varlığı (üretilmiş katalogdan).',
        '  String? get asset => dashAsset(id);',
        '}',
        '',
        '/// 60 ikaz ışığı — gösterge paneli sırasıyla.',
        'const List<DashLight> kDashLights = [',
    ]
    for lid, name, meaning, tip, sev in LIGHTS:
        lines.append(
            f"  DashLight('{lid}', '{esc(name)}', '{esc(meaning)}', '{esc(tip)}', DashSeverity.{sev}),"
        )
    lines += ['];', '']
    dest = os.path.join(MOBILE, 'lib', 'domain', 'content', 'dash_lights.dart')
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(lines))
    print(f'dart içeriği: {len(LIGHTS)} ışık → {os.path.relpath(dest, REPO)}')


if __name__ == '__main__':
    raise SystemExit(main())
