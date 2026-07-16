/**
 * Etkileşimli medya içeriği (Program 2 · Faz 2).
 * Hotspot sahneleri, önce/sonra karşılaştırmaları ve adım adım akışlar —
 * hepsi asset-manifest'teki premium görsellere bağlanır (test kapısı).
 */

export interface Hotspot {
  /** Yüzde koordinatlar (0–100, görselin sol-üst köşesine göre). */
  x: number;
  y: number;
  title: string;
  text: string;
}

export interface HotspotScene {
  id: string;
  asset: string; // asset-manifest kimliği
  intro: string;
  spots: Hotspot[];
}

export const HOTSPOT_SCENES: HotspotScene[] = [
  {
    id: 'engine-bay-tour',
    asset: 'engine-bay',
    intro: 'Noktalara dokunarak motor bölmesindeki kontrol noktalarını keşfet.',
    spots: [
      {
        x: 19,
        y: 33,
        title: 'Soğutma Suyu Deposu',
        text: 'Seviye MIN–MAX arasında olmalı. Motor sıcakken kapağı asla açma — yanma riski.',
      },
      {
        x: 27,
        y: 57,
        title: 'Yağ Çubuğu',
        text: 'Motor soğukken çek, sil, tekrar batır; seviye MIN–MAX arasında olmalı.',
      },
      {
        x: 61,
        y: 76,
        title: 'Cam Suyu Kapağı',
        text: 'Mavi kapak cam suyunundur. Kışın antifrizli cam suyu kullan.',
      },
      {
        x: 70,
        y: 47,
        title: 'Akü',
        text: 'Elektrik enerjisini depolar; kutup başları temiz ve sıkı olmalı. Takviyede bağlantı sırasına dikkat.',
      },
    ],
  },
  {
    id: 'pedals-tour',
    asset: 'pedals',
    intro: 'Manuel araçta pedal düzenini noktalara dokunarak öğren.',
    spots: [
      {
        x: 24,
        y: 58,
        title: 'Debriyaj',
        text: 'En solda; YALNIZ sol ayakla kullanılır. Vites değişimi ve kalkışta kavrama noktası kritik.',
      },
      {
        x: 50,
        y: 56,
        title: 'Fren',
        text: 'Ortada; sağ ayakla kullanılır. Kademeli ve erken frenleme güvenli sürüşün temelidir.',
      },
      {
        x: 76,
        y: 58,
        title: 'Gaz',
        text: 'En sağda; sağ ayakla kullanılır. Ayak topuğu yerde, bilekle hassas kontrol.',
      },
    ],
  },
];

export interface CompareScene {
  id: string;
  beforeAsset: string;
  afterAsset: string;
  beforeLabel: string;
  afterLabel: string;
  caption: string;
}

export const COMPARE_SCENES: CompareScene[] = [
  {
    id: 'tyre-wear',
    beforeAsset: 'tyre',
    afterAsset: 'tyre-worn',
    beforeLabel: 'Sağlıklı diş',
    afterLabel: 'Aşınmış diş',
    caption:
      'Kaydırıcıyı sürükleyerek karşılaştır: yasal sınır 1,6 mm — orta bant düzleşmişse lastik değişmelidir.',
  },
];

export interface FlowStep {
  asset: string;
  title: string;
  text: string;
}

export interface StepFlowScene {
  id: string;
  title: string;
  steps: FlowStep[];
}

export const STEP_FLOWS: StepFlowScene[] = [
  {
    id: 'pre-drive-check',
    title: 'Sürüş Öncesi Kontrol Turu',
    steps: [
      {
        asset: 'inspection-points',
        title: '1 · Araç çevresi',
        text: 'Araca binmeden çevresini dolaş: altında sızıntı, önünde/arkasında engel var mı?',
      },
      {
        asset: 'tyre',
        title: '2 · Lastikler',
        text: 'Diş derinliği ve şişkinlik/kesik kontrolü; gözle basınç değerlendirmesi.',
      },
      {
        asset: 'engine-bay',
        title: '3 · Sıvı seviyeleri',
        text: 'Motor yağı, soğutma suyu, fren hidroliği ve cam suyu — hepsi aralıkta olmalı.',
      },
      {
        asset: 'headlights',
        title: '4 · Işıklar',
        text: 'Kısa/uzun far, sinyaller ve fren lambaları çalışıyor mu? (Gerekirse yardım al.)',
      },
      {
        asset: 'seat',
        title: '5 · Koltuk & direksiyon',
        text: 'Koltuğu pedallara göre ayarla; direksiyona bilek mesafeni kontrol et.',
      },
      {
        asset: 'mirrors',
        title: '6 · Aynalar',
        text: 'İç ve dış aynaları koltuk ayarından SONRA ayarla; kör noktayı unutma.',
      },
      {
        asset: 'seat-belt',
        title: '7 · Emniyet kemeri',
        text: 'Kemeri köprücük kemiği üzerinden tak; kıvrılmadığından emin ol. Şimdi hazırsın.',
      },
    ],
  },
];

/** Ders → etkileşimli medya eşlemesi (ders sayfası render eder; test kapısı doğrular). */
export const LESSON_MEDIA: Record<string, { hotspots?: string; compare?: string; steps?: string }> =
  {
    'motor-temel': { hotspots: 'engine-bay-tour' },
    'debriyaj-rampa': { hotspots: 'pedals-tour' },
    'arac-hazirlik': { steps: 'pre-drive-check', compare: 'tyre-wear' },
  };

export function hotspotSceneById(id: string): HotspotScene | undefined {
  return HOTSPOT_SCENES.find((s) => s.id === id);
}
export function compareSceneById(id: string): CompareScene | undefined {
  return COMPARE_SCENES.find((s) => s.id === id);
}
export function stepFlowById(id: string): StepFlowScene | undefined {
  return STEP_FLOWS.find((s) => s.id === id);
}
