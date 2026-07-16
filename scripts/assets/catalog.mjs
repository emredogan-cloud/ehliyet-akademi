/**
 * Program 2 · Faz 1 — Premium görsel varlık kataloğu.
 * Her varlık: kimlik, Türkçe başlık/alt metin, etiketler ve fotogerçekçi üretim prompt'u.
 * Kural: marka/logo YOK, plaka YOK, okunabilir metin YOK (AI metni bozar + TR olmalı).
 */

const STYLE =
  'Professional automotive education photograph for a driving school handbook. ' +
  'Modern unbranded European compact car. Clean, neutral composition, soft diffused ' +
  'daylight, sharp focus, photorealistic, high detail. No brand logos, no license ' +
  'plates, no readable text or letters, no watermarks, no people faces.';

/** @type {Array<{id:string,title:string,alt:string,tags:string[],prompt:string}>} */
export const ASSETS = [
  // ── Motor bölmesi ────────────────────────────────────────────────
  {
    id: 'engine-bay',
    title: 'Motor Bölmesi',
    alt: 'Kaputu açık bir otomobilin motor bölmesinin genel görünümü',
    tags: ['motor-bolmesi', 'bakim'],
    prompt: `Open hood of a car showing the full engine bay from above at a slight angle: engine cover, battery, fluid reservoirs and belts visible. ${STYLE}`,
  },
  {
    id: 'battery',
    title: 'Akü',
    alt: 'Motor bölmesindeki araç aküsü ve kutup başları',
    tags: ['motor-bolmesi', 'elektrik'],
    prompt: `Close-up of a car battery installed in the engine bay, both terminal posts and clamps clearly visible, clean condition. ${STYLE}`,
  },
  {
    id: 'dipstick',
    title: 'Yağ Çubuğu',
    alt: 'Motor yağ seviyesini kontrol etmek için çekilen yağ çubuğu',
    tags: ['motor-bolmesi', 'yag', 'kontrol'],
    prompt: `A hand in a casual sleeve pulling the bright yellow engine oil dipstick out of a car engine to check the oil level, engine bay background softly blurred. ${STYLE}`,
  },
  {
    id: 'coolant',
    title: 'Soğutma Suyu Deposu',
    alt: 'Motor bölmesindeki yarı saydam soğutma suyu genleşme deposu',
    tags: ['motor-bolmesi', 'sogutma'],
    prompt: `Close-up of the translucent coolant expansion tank in a car engine bay with pink coolant visible at the level marks, cap on top. ${STYLE}`,
  },
  {
    id: 'brake-fluid',
    title: 'Fren Hidroliği Deposu',
    alt: 'Motor bölmesindeki fren hidroliği deposu ve kapağı',
    tags: ['motor-bolmesi', 'fren'],
    prompt: `Close-up of the brake fluid reservoir in a car engine bay, small translucent tank with a yellow cap near the firewall, fluid level visible. ${STYLE}`,
  },
  {
    id: 'washer',
    title: 'Cam Suyu Deposu',
    alt: 'Mavi kapaklı cam yıkama suyu deposu ağzı',
    tags: ['motor-bolmesi', 'gorus'],
    prompt: `Close-up of the windscreen washer fluid filler neck with its blue cap open in a car engine bay, a hand pouring washer fluid from a container. ${STYLE}`,
  },
  {
    id: 'fuse-box',
    title: 'Sigorta Kutusu',
    alt: 'Kapağı açılmış araç sigorta kutusu ve renkli sigortalar',
    tags: ['motor-bolmesi', 'elektrik'],
    prompt: `Open fuse box in a car engine bay with rows of small colorful blade fuses and relays visible, cover lifted. ${STYLE}`,
  },
  // ── Gösterge & kumandalar ────────────────────────────────────────
  {
    id: 'dashboard',
    title: 'Gösterge Paneli',
    alt: 'Hız ve devir göstergeleriyle araç gösterge paneli',
    tags: ['kabin', 'gosterge'],
    prompt: `Driver's view of a modern car instrument cluster with analog speedometer and tachometer dials and a small central display, ignition on, dashboard softly lit. ${STYLE}`,
  },
  {
    id: 'warning-lights',
    title: 'İkaz Lambaları',
    alt: 'Kontak açıkken yanan gösterge paneli ikaz lambaları',
    tags: ['kabin', 'gosterge', 'ikaz'],
    prompt: `Close-up of a car instrument cluster at ignition-on self test with several red and amber warning indicator lamps glowing, shallow depth of field emphasising the glowing symbols. ${STYLE}`,
  },
  {
    id: 'dashboard-buttons',
    title: 'Konsol Düğmeleri',
    alt: 'Orta konsoldaki dörtlü flaşör ve diğer kumanda düğmeleri',
    tags: ['kabin', 'kumanda'],
    prompt: `Close-up of a car center console button panel featuring the red triangle hazard warning button and other rocker switches. ${STYLE}`,
  },
  {
    id: 'steering',
    title: 'Direksiyon',
    alt: 'Sürücü koltuğundan direksiyon simidinin görünümü',
    tags: ['kabin', 'kumanda'],
    prompt: `Straight-on view of a modern car steering wheel from the driver seat, dashboard behind, both stalks visible, clean unbranded center pad. ${STYLE}`,
  },
  {
    id: 'steering-controls',
    title: 'Direksiyon Kumandaları',
    alt: 'Direksiyon simidi üzerindeki kumanda tuşları ve kollar',
    tags: ['kabin', 'kumanda'],
    prompt: `Close-up of a car steering wheel spoke with multifunction control buttons and the two control stalks behind the wheel. ${STYLE}`,
  },
  {
    id: 'turn-signal-stalk',
    title: 'Sinyal Kolu',
    alt: 'Direksiyonun solundaki sinyal ve far kumanda kolu',
    tags: ['kabin', 'kumanda', 'sinyal'],
    prompt: `Close-up of the left indicator stalk behind a car steering wheel, a hand about to flick it, dashboard softly blurred. ${STYLE}`,
  },
  {
    id: 'wiper-controls',
    title: 'Silecek Kumandası',
    alt: 'Direksiyonun sağındaki silecek kumanda kolu',
    tags: ['kabin', 'kumanda', 'gorus'],
    prompt: `Close-up of the right windscreen wiper control stalk behind a car steering wheel showing its rotary speed collar. ${STYLE}`,
  },
  {
    id: 'light-switch',
    title: 'Far Anahtarı',
    alt: 'Far ve sis lambası kumandası döner anahtar',
    tags: ['kabin', 'kumanda', 'aydinlatma'],
    prompt: `Close-up of a car headlight rotary control switch on the dashboard with pictogram positions, finger turning the dial. ${STYLE}`,
  },
  // ── Aydınlatma (dış) ─────────────────────────────────────────────
  {
    id: 'headlights',
    title: 'Farlar',
    alt: 'Alacakaranlıkta yanan araç ön farı',
    tags: ['dis', 'aydinlatma'],
    prompt: `Front three-quarter close-up of a car headlight glowing at dusk on a quiet street, beam pattern faintly visible in the air. ${STYLE}`,
  },
  {
    id: 'fog-lights',
    title: 'Sis Farları',
    alt: 'Ön tampondaki yanan sis farı, sisli ortam',
    tags: ['dis', 'aydinlatma'],
    prompt: `Extreme close-up of only the lower corner of a car front bumper with the round fog lamp glowing in light fog, misty atmosphere; tight framing on the fog lamp and bumper texture only, the grille and any emblem are OUT of frame, completely badge-free bodywork. ${STYLE}`,
  },
  // ── Aynalar & koltuk & kemer ─────────────────────────────────────
  {
    id: 'mirrors',
    title: 'Yan Ayna',
    alt: 'Araç yan aynasında arkadaki yolun görünümü',
    tags: ['kabin', 'gorus'],
    prompt: `Car door side mirror seen from the driver position reflecting the road behind, window frame in soft focus. ${STYLE}`,
  },
  {
    id: 'mirror-adjust',
    title: 'Ayna Ayar Düğmesi',
    alt: 'Kapı kolçağındaki elektrikli ayna ayar kumandası',
    tags: ['kabin', 'kumanda', 'gorus'],
    prompt: `Close-up of the electric side mirror adjustment joystick control on a car door armrest, finger adjusting it. ${STYLE}`,
  },
  {
    id: 'seat',
    title: 'Sürücü Koltuğu',
    alt: 'Açık kapıdan sürücü koltuğu ve direksiyon görünümü',
    tags: ['kabin', 'pozisyon'],
    prompt: `Driver seat of a car seen through the open door, steering wheel and pedals visible, clean fabric upholstery. ${STYLE}`,
  },
  {
    id: 'seat-controls',
    title: 'Koltuk Ayar Kumandaları',
    alt: 'Koltuğun yanındaki ayar kolu ve yükseklik pompası',
    tags: ['kabin', 'pozisyon'],
    prompt: `Close-up of manual seat adjustment controls on the side of a car driver seat: sliding bar and height pump lever, hand operating the lever. ${STYLE}`,
  },
  {
    id: 'seat-belt',
    title: 'Emniyet Kemeri',
    alt: 'Emniyet kemerini takan bir sürücünün yakın görünümü',
    tags: ['kabin', 'guvenlik'],
    prompt: `Hands fastening a car seat belt buckle with a click, torso view only, interior softly lit. ${STYLE}`,
  },
  // ── Pedallar & vites & el freni ──────────────────────────────────
  {
    id: 'pedals',
    title: 'Pedallar',
    alt: 'Manuel araçta debriyaj, fren ve gaz pedalları',
    tags: ['kabin', 'kumanda'],
    prompt: `Footwell of a manual transmission car showing all three pedals clutch brake accelerator from the driver perspective, clean rubber pads. ${STYLE}`,
  },
  {
    id: 'gearbox',
    title: 'Manuel Vites',
    alt: 'Manuel vites kolu ve vites şeması topuzu',
    tags: ['kabin', 'kumanda', 'vites'],
    prompt: `Close-up of a manual gear lever with a classic H-pattern shift knob in a car center console, hand resting on it. ${STYLE}`,
  },
  {
    id: 'automatic-gearbox',
    title: 'Otomatik Vites',
    alt: 'Otomatik şanzıman vites seçici kolu',
    tags: ['kabin', 'kumanda', 'vites'],
    prompt: `Close-up of an automatic transmission selector lever in a car center console with position indicator gate. ${STYLE}`,
  },
  {
    id: 'handbrake',
    title: 'El Freni',
    alt: 'Orta konsoldaki el freni kolu',
    tags: ['kabin', 'kumanda', 'fren'],
    prompt: `Close-up of a handbrake lever between the front seats of a car, hand pulling it up. ${STYLE}`,
  },
  // ── Dış & lastikler ──────────────────────────────────────────────
  {
    id: 'tyre',
    title: 'Lastik',
    alt: 'Lastik diş derinliği ve yanak yakın görünümü',
    tags: ['dis', 'lastik'],
    prompt: `Close-up of a car tyre showing tread depth grooves and sidewall, wheel arch above, daylight. ${STYLE}`,
  },
  {
    id: 'wheel-bolts',
    title: 'Bijonlar',
    alt: 'Bijon anahtarıyla sökülen tekerlek bijonları',
    tags: ['dis', 'lastik', 'bakim'],
    prompt: `Close-up of a cross wrench loosening the wheel bolts of a car wheel, hub and bolts clearly visible. ${STYLE}`,
  },
  {
    id: 'spare-wheel',
    title: 'Stepne',
    alt: 'Bagaj altındaki stepne yuvasında yedek lastik',
    tags: ['dis', 'bakim'],
    prompt: `Spare wheel sitting in its recess under the lifted boot floor of a car, jack and tool kit beside it. ${STYLE}`,
  },
  {
    id: 'jack',
    title: 'Kriko',
    alt: 'Aracı kaldırma noktasından kaldıran makas kriko',
    tags: ['dis', 'bakim'],
    prompt: `Scissor jack lifting a car at the correct sill jacking point, wheel slightly off the ground, driveway setting. ${STYLE}`,
  },
  {
    id: 'boot',
    title: 'Bagaj',
    alt: 'Açık bagaj ve düzenli bagaj alanı',
    tags: ['dis', 'depolama'],
    prompt: `Open boot of a compact car showing a clean cargo area with a small organized box and warning triangle stored at the side. ${STYLE}`,
  },
  // ── Muayene & park & acil durum ─────────────────────────────────
  {
    id: 'inspection-points',
    title: 'Sürüş Öncesi Kontrol',
    alt: 'Sürüş öncesi lastiği kontrol eden sürücü',
    tags: ['muayene', 'kontrol'],
    prompt: `A driver crouching beside a car checking the front tyre during a pre-drive walkaround inspection, seen from behind at an angle so the face is not visible. ${STYLE}`,
  },
  {
    id: 'parking-reference',
    title: 'Park Referansı',
    alt: 'Kaldırım kenarına paralel park etmiş araç, arkadan görünüm',
    tags: ['muayene', 'park'],
    prompt: `Rear three-quarter view of a car neatly parallel parked close to the kerb on a quiet street, gap to the kerb clearly visible. ${STYLE}`,
  },
  {
    id: 'emergency-kit',
    title: 'Acil Durum Ekipmanı',
    alt: 'Reflektör üçgen, reflektif yelek ve ilk yardım çantası',
    tags: ['guvenlik', 'acil'],
    prompt: `Flat lay of exactly three objects on a plain neutral surface, photographed straight from above: a folded red warning triangle, a folded high-visibility yellow reflective vest, and a red first aid pouch with a plain white cross. Nothing else in the frame — absolutely no car, no vehicle, no people. ${STYLE}`,
  },
];

export const OUT_DIR = 'apps/web/public/assets/vehicle';
export const SIZE = '1536x1024';
