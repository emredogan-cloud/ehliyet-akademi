/**
 * Premium görsel varlık manifesti (Program 2 · Faz 1).
 * Tek doğru kaynak: her varlığın kimliği, Türkçe başlık/alt metni, lisansı ve boyutları.
 * Dosyalar: apps/web/public/assets/vehicle/<id>.webp (üretim: scripts/assets/generate.mjs).
 *
 * Lisans notu: "ai-generated" = OpenAI Images API ile bu proje için üretilmiş, markasız,
 * plakasız, metin içermeyen fotogerçekçi eğitim görseli; kullanım hakkı projeye aittir.
 */

export type AssetLicense = 'ai-generated' | 'cc0' | 'cc-by' | 'own-photo';

export interface VisualAsset {
  id: string;
  /** Görsel dosya yolu (public köküne göre). */
  src: string;
  title: string;
  /** Erişilebilirlik: anlamlı Türkçe alternatif metin. */
  alt: string;
  width: number;
  height: number;
  license: AssetLicense;
  /** Atıf gereken lisanslarda kaynak/atıf metni. */
  attribution?: string;
  tags: string[];
}

const W = 1536;
const H = 1024;

function asset(id: string, title: string, alt: string, tags: string[]): VisualAsset {
  return {
    id,
    src: `/assets/vehicle/${id}.webp`,
    title,
    alt,
    width: W,
    height: H,
    license: 'ai-generated',
    tags,
  };
}

export const VISUAL_ASSETS: VisualAsset[] = [
  // Motor bölmesi
  asset(
    'engine-bay',
    'Motor Bölmesi',
    'Kaputu açık bir otomobilin motor bölmesinin genel görünümü',
    ['motor-bolmesi', 'bakim']
  ),
  asset('battery', 'Akü', 'Motor bölmesindeki araç aküsü ve kutup başları', [
    'motor-bolmesi',
    'elektrik',
  ]),
  asset('dipstick', 'Yağ Çubuğu', 'Motor yağ seviyesini kontrol etmek için çekilen yağ çubuğu', [
    'motor-bolmesi',
    'yag',
    'kontrol',
  ]),
  asset(
    'coolant',
    'Soğutma Suyu Deposu',
    'Motor bölmesindeki yarı saydam soğutma suyu genleşme deposu',
    ['motor-bolmesi', 'sogutma']
  ),
  asset(
    'brake-fluid',
    'Fren Hidroliği Deposu',
    'Motor bölmesindeki fren hidroliği deposu ve kapağı',
    ['motor-bolmesi', 'fren']
  ),
  asset('washer', 'Cam Suyu Deposu', 'Mavi kapaklı cam yıkama suyu deposu ağzı', [
    'motor-bolmesi',
    'gorus',
  ]),
  asset('fuse-box', 'Sigorta Kutusu', 'Kapağı açılmış araç sigorta kutusu ve renkli sigortalar', [
    'motor-bolmesi',
    'elektrik',
  ]),
  // Gösterge & kumandalar
  asset('dashboard', 'Gösterge Paneli', 'Hız ve devir göstergeleriyle araç gösterge paneli', [
    'kabin',
    'gosterge',
  ]),
  asset('warning-lights', 'İkaz Lambaları', 'Kontak açıkken yanan gösterge paneli ikaz lambaları', [
    'kabin',
    'gosterge',
    'ikaz',
  ]),
  asset(
    'dashboard-buttons',
    'Konsol Düğmeleri',
    'Orta konsoldaki dörtlü flaşör ve diğer kumanda düğmeleri',
    ['kabin', 'kumanda']
  ),
  asset('steering', 'Direksiyon', 'Sürücü koltuğundan direksiyon simidinin görünümü', [
    'kabin',
    'kumanda',
  ]),
  asset(
    'steering-controls',
    'Direksiyon Kumandaları',
    'Direksiyon simidi üzerindeki kumanda tuşları ve kollar',
    ['kabin', 'kumanda']
  ),
  asset('turn-signal-stalk', 'Sinyal Kolu', 'Direksiyonun solundaki sinyal ve far kumanda kolu', [
    'kabin',
    'kumanda',
    'sinyal',
  ]),
  asset('wiper-controls', 'Silecek Kumandası', 'Direksiyonun sağındaki silecek kumanda kolu', [
    'kabin',
    'kumanda',
    'gorus',
  ]),
  asset('light-switch', 'Far Anahtarı', 'Far ve sis lambası kumandası döner anahtar', [
    'kabin',
    'kumanda',
    'aydinlatma',
  ]),
  // Aydınlatma (dış)
  asset('headlights', 'Farlar', 'Alacakaranlıkta yanan araç ön farı', ['dis', 'aydinlatma']),
  asset('fog-lights', 'Sis Farları', 'Ön tampondaki yanan sis farı, sisli ortam', [
    'dis',
    'aydinlatma',
  ]),
  // Aynalar & koltuk & kemer
  asset('mirrors', 'Yan Ayna', 'Araç yan aynasında arkadaki yolun görünümü', ['kabin', 'gorus']),
  asset('mirror-adjust', 'Ayna Ayar Düğmesi', 'Kapı kolçağındaki elektrikli ayna ayar kumandası', [
    'kabin',
    'kumanda',
    'gorus',
  ]),
  asset('seat', 'Sürücü Koltuğu', 'Açık kapıdan sürücü koltuğu ve direksiyon görünümü', [
    'kabin',
    'pozisyon',
  ]),
  asset(
    'seat-controls',
    'Koltuk Ayar Kumandaları',
    'Koltuğun yanındaki ayar kolu ve yükseklik pompası',
    ['kabin', 'pozisyon']
  ),
  asset('seat-belt', 'Emniyet Kemeri', 'Emniyet kemerini takan bir sürücünün yakın görünümü', [
    'kabin',
    'guvenlik',
  ]),
  // Pedallar & vites & el freni
  asset('pedals', 'Pedallar', 'Manuel araçta debriyaj, fren ve gaz pedalları', [
    'kabin',
    'kumanda',
  ]),
  asset('gearbox', 'Manuel Vites', 'Manuel vites kolu ve vites şeması topuzu', [
    'kabin',
    'kumanda',
    'vites',
  ]),
  asset('automatic-gearbox', 'Otomatik Vites', 'Otomatik şanzıman vites seçici kolu', [
    'kabin',
    'kumanda',
    'vites',
  ]),
  asset('handbrake', 'El Freni', 'Orta konsoldaki el freni kolu', ['kabin', 'kumanda', 'fren']),
  // Dış & lastikler
  asset('tyre', 'Lastik', 'Lastik diş derinliği ve yanak yakın görünümü', ['dis', 'lastik']),
  asset('tyre-worn', 'Aşınmış Lastik', 'Diş derinliği azalmış, aşınmış lastik yakın görünümü', [
    'dis',
    'lastik',
    'guvenlik',
  ]),
  asset('wheel-bolts', 'Bijonlar', 'Bijon anahtarıyla sökülen tekerlek bijonları', [
    'dis',
    'lastik',
    'bakim',
  ]),
  asset('spare-wheel', 'Stepne', 'Bagaj altındaki stepne yuvasında yedek lastik', ['dis', 'bakim']),
  asset('jack', 'Kriko', 'Aracı kaldırma noktasından kaldıran makas kriko', ['dis', 'bakim']),
  asset('boot', 'Bagaj', 'Açık bagaj ve düzenli bagaj alanı', ['dis', 'depolama']),
  // Muayene & park & acil durum
  asset('inspection-points', 'Sürüş Öncesi Kontrol', 'Sürüş öncesi lastiği kontrol eden sürücü', [
    'muayene',
    'kontrol',
  ]),
  asset(
    'parking-reference',
    'Park Referansı',
    'Kaldırım kenarına paralel park etmiş araç, arkadan görünüm',
    ['muayene', 'park']
  ),
  asset(
    'emergency-kit',
    'Acil Durum Ekipmanı',
    'Reflektör üçgen, reflektif yelek ve ilk yardım çantası',
    ['guvenlik', 'acil']
  ),
  // ——— Program 2 · Faz 7 — araç bilgisi genişletmesi (36 varlık) ———
  asset('wiper-blade', 'Silecek Lastiği', 'Ön cam silecek lastiğinin yakın görünümü', [
    'dis',
    'gorus',
    'bakim',
  ]),
  asset('isofix', 'ISOFIX Bağlantısı', 'Arka koltuktaki ISOFIX çocuk koltuğu bağlantı noktaları', [
    'kabin',
    'guvenlik',
  ]),
  asset('climate-controls', 'Klima Kumandası', 'Kalorifer ve klima döner kumanda paneli', [
    'kabin',
    'kumanda',
  ]),
  asset('window-switches', 'Cam Kumandaları', 'Kapı kolçağındaki elektrikli cam düğmeleri', [
    'kabin',
    'kumanda',
  ]),
  asset('fuel-cap', 'Yakıt Depo Kapağı', 'Açık yakıt dolum kapağı ve depo ağzı', ['dis', 'yakit']),
  asset('exhaust', 'Egzoz', 'Araç arkasındaki egzoz çıkışı', ['dis', 'motor']),
  asset('suspension', 'Süspansiyon & Amortisör', 'Helezon yay ve amortisör (teker sökülü)', [
    'dis',
    'bakim',
  ]),
  asset('brake-disc', 'Fren Diski', 'Jant arkasında görünen fren diski ve kaliper', [
    'dis',
    'fren',
  ]),
  asset('brake-pads', 'Fren Balatası', 'Yeni fren balataları yakın görünüm', [
    'dis',
    'fren',
    'bakim',
  ]),
  asset('timing-belt', 'Triger Kayışı', 'Motorun triger kayışı ve dişlileri', [
    'motor-bolmesi',
    'bakim',
  ]),
  asset('alternator', 'Alternatör', 'Motor üzerindeki alternatör ve kayışı', [
    'motor-bolmesi',
    'elektrik',
  ]),
  asset('serpentine-belt', 'V Kayışı', 'Motor yardımcı sistem kayışı ve kasnaklar', [
    'motor-bolmesi',
    'bakim',
  ]),
  asset('radiator-fan', 'Radyatör Fanı', 'Radyatör arkasındaki soğutma fanı', [
    'motor-bolmesi',
    'sogutma',
  ]),
  asset('cabin-filter', 'Polen Filtresi', 'Değiştirilen polen (kabin) filtresi', [
    'kabin',
    'bakim',
  ]),
  asset('air-filter', 'Hava Filtresi', 'Açık kutusunda motor hava filtresi', [
    'motor-bolmesi',
    'bakim',
  ]),
  asset('oil-filter', 'Yağ Filtresi', 'Motor yağ filtresi kartuşu', ['motor-bolmesi', 'bakim']),
  asset('spark-plug', 'Buji', 'Yeni bir buji yakın görünüm', ['motor-bolmesi', 'bakim']),
  asset('car-key', 'Anahtar & İmmobilizer', 'Uzaktan kumandalı araç anahtarı', [
    'kabin',
    'guvenlik',
  ]),
  asset('obd-port', 'OBD Arıza Soketi', 'Direksiyon altındaki OBD-II soketi', ['kabin', 'bakim']),
  asset('tow-rope', 'Çekme Halatı', 'Sarılı çekme halatı ve kancaları', ['guvenlik', 'acil']),
  asset('wheel-chock', 'Takoz', 'Tekerleğin arkasına yerleştirilmiş takoz', ['guvenlik', 'bakim']),
  asset('snow-chain-fitting', 'Zincir Takma', 'Lastiğe takılmış kar zinciri', ['dis', 'guvenlik']),
  asset('alloy-wheel', 'Jant & Sibop', 'Alaşım jant ve sibop yakın görünümü', ['dis', 'lastik']),
  asset('tyre-pressure', 'Lastik Basıncı Ölçümü', 'Sibopta lastik basıncı ölçen el', [
    'dis',
    'lastik',
    'kontrol',
  ]),
  asset('tie-rod', 'Rot Başı', 'Direksiyon rot başı mafsalı (liftte)', ['dis', 'bakim']),
  asset('cv-axle', 'Aks Körüğü', 'Ön aks CV mafsal körüğü', ['dis', 'bakim']),
  asset('catalytic', 'Katalitik Konvertör', 'Araç altındaki katalitik konvertör', ['dis', 'motor']),
  asset('park-sensor', 'Park Sensörü', 'Arka tampondaki park sensörleri', ['dis', 'guvenlik']),
  asset('rear-camera', 'Geri Görüş Kamerası', 'Bagaj kolu yanındaki geri görüş kamerası', [
    'dis',
    'guvenlik',
  ]),
  asset('windshield-chip', 'Cam Çatlağı', 'Ön camdaki taş izi çatlak', ['dis', 'gorus']),
  asset('oil-cap', 'Yağ Dolum Kapağı', 'Motor yağı dolum kapağı', ['motor-bolmesi', 'yag']),
  asset('temp-gauge', 'Hararet Göstergesi', 'Gösterge panelindeki hararet ibresi', [
    'kabin',
    'gosterge',
  ]),
  asset('jump-cables', 'Takviye Kablosu', 'Kırmızı-siyah akü takviye kabloları', [
    'guvenlik',
    'acil',
    'elektrik',
  ]),
];

const BY_ID = new Map(VISUAL_ASSETS.map((a) => [a.id, a]));

export function visualAssetById(id: string): VisualAsset | undefined {
  return BY_ID.get(id);
}

/**
 * Ders → premium görsel eşlemesi (ders sayfasındaki foto şeridi).
 * Anahtar = ders slug'ı; değer = varlık kimlikleri (manifest'te var olmalı — test kapısı).
 */
export const LESSON_PHOTOS: Record<string, string[]> = {
  'arac-hazirlik': ['seat', 'mirrors', 'seat-belt', 'inspection-points'],
  'motor-temel': ['engine-bay', 'dipstick', 'battery', 'brake-fluid'],
  'gosterge-ikaz': ['dashboard', 'warning-lights', 'coolant'],
  'isik-gece': ['headlights', 'fog-lights', 'light-switch'],
  'debriyaj-rampa': ['pedals', 'gearbox', 'handbrake'],
  'park-manevra': ['parking-reference', 'mirrors'],
};
