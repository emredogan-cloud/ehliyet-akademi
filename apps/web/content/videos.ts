/**
 * Video öğrenme kataloğu (Program 2 · Faz 4 · ADR-013).
 * Dürüstlük: `available` videolar %100 özgün (kendi animasyonlarımızdan render edildi);
 * gerçek çekim gerektirenler `planned` olarak açıkça işaretlenir — sahte video yayınlanmaz.
 */

export interface VideoChapter {
  /** Saniye. */
  t: number;
  title: string;
}

export interface TranscriptCue {
  /** Başlangıç saniyesi. */
  t: number;
  text: string;
}

export interface VideoContent {
  id: string;
  title: string;
  description: string;
  status: 'available' | 'planned';
  /** available ise zorunlu alanlar: */
  src?: string;
  /** Açık kodek varyantı (VP9) — lisanslı kodek içermeyen tarayıcılar için. */
  srcWebm?: string;
  poster?: string;
  captions?: string; // WebVTT yolu
  duration?: number; // sn
  chapters?: VideoChapter[];
  transcript?: TranscriptCue[];
  relatedLessonSlug?: string;
}

export const VIDEOS: VideoContent[] = [
  {
    id: 'parallel-park',
    title: 'Paralel Park — Adım Adım (Animasyon)',
    description:
      'İki araç arasına geri geri paralel park manevrasının kuş bakışı animasyonlu anlatımı.',
    status: 'available',
    src: '/videos/parallel-park.mp4',
    srcWebm: '/videos/parallel-park.webm',
    poster: '/videos/parallel-park-poster.jpg',
    captions: '/videos/parallel-park.tr.vtt',
    duration: 9,
    chapters: [
      { t: 0, title: 'Yaklaş ve hizalan' },
      { t: 2.7, title: 'Geri + sağa kır' },
      { t: 5.4, title: 'Sola çevir, düzelt' },
      { t: 7.4, title: 'Ortala ve bitir' },
    ],
    transcript: [
      { t: 0, text: 'Boşluğun yanından geç, öndeki araçla hizalan.' },
      { t: 2.7, text: 'Geri viteste direksiyonu sağa kır — arka boşluğa girsin.' },
      { t: 5.4, text: 'Araç yaklaşık 45 derece olunca direksiyonu sola çevir, düzelt.' },
      { t: 7.4, text: 'Araçlar arasında ortala; tekerlekleri düzelt.' },
    ],
    relatedLessonSlug: 'park-manevra',
  },
  {
    id: 'right-of-way',
    title: 'Kavşakta Sağdan Gelen — Adım Adım (Animasyon)',
    description: 'Işıksız eşit kavşakta sağdan gelene yol vermenin animasyonlu anlatımı.',
    status: 'available',
    src: '/videos/right-of-way.mp4',
    srcWebm: '/videos/right-of-way.webm',
    poster: '/videos/right-of-way-poster.jpg',
    captions: '/videos/right-of-way.tr.vtt',
    duration: 8,
    chapters: [
      { t: 0, title: 'Yaklaş ve tara' },
      { t: 2.2, title: 'Çizgide dur' },
      { t: 5, title: 'Öncelik sağdakinin' },
      { t: 6.5, title: 'Kontrollü geç' },
    ],
    transcript: [
      { t: 0, text: 'Kavşağa yaklaşırken yavaşla; sol-ileri-sağ tara.' },
      { t: 2.2, text: 'Sağdan gelen araç var — kavşak çizgisinde dur.' },
      { t: 5, text: 'Sağdan gelen güvenle geçsin.' },
      { t: 6.5, text: 'Yol boşalınca kontrollü geç.' },
    ],
    relatedLessonSlug: 'kavsak-oncelik',
  },
  // Gerçek çekim gerektiren müfredat — dürüstçe "planlanıyor"
  {
    id: 'exam-walkthrough',
    title: 'Direksiyon Sınavı Yürüyüşü (Gerçek Çekim)',
    description: 'Gerçek sınav güzergâhında baştan sona örnek sürüş ve değerlendirme anları.',
    status: 'planned',
    relatedLessonSlug: 'sinav-strateji',
  },
  {
    id: 'vehicle-inspection',
    title: 'Sürüş Öncesi Araç Kontrolü (Gerçek Çekim)',
    description: 'Kaput altı ve araç çevresi kontrollerinin gerçek araç üzerinde gösterimi.',
    status: 'planned',
    relatedLessonSlug: 'arac-hazirlik',
  },
  {
    id: 'hill-start',
    title: 'Rampada Kalkış (Gerçek Çekim)',
    description: 'El freni + kavrama noktası koordinasyonunun pedal kamerasıyla gösterimi.',
    status: 'planned',
    relatedLessonSlug: 'debriyaj-rampa',
  },
  {
    id: 'common-mistakes',
    title: 'Sınavda En Sık 10 Hata (Gerçek Çekim)',
    description: 'Adayların en sık elendiği anların örnek sürüşlerle anlatımı.',
    status: 'planned',
    relatedLessonSlug: 'sinav-strateji',
  },
];

export function videoById(id: string): VideoContent | undefined {
  return VIDEOS.find((v) => v.id === id);
}

export function availableVideos(): VideoContent[] {
  return VIDEOS.filter((v) => v.status === 'available');
}

/**
 * Deterministik transkript özeti (AI-destekli özet zemini — halüsinasyonsuz).
 * İlk cümle + her bölümün ilk cue'su birleştirilir; grounded AI hattına bağlanabilir.
 */
export function summarizeTranscript(v: VideoContent, maxItems = 4): string[] {
  if (!v.transcript || v.transcript.length === 0) return [];
  return v.transcript.slice(0, maxItems).map((c) => c.text);
}
