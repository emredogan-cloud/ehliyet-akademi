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

import { GENERATED_VIDEOS } from './videos.generated';

/**
 * Bir animasyon videosunun ortak alanlarını üretilmiş veriden doldurur (Evolution Faz E12).
 * Süre, bölümler ve transkript videoyu çizen sahneden gelir → katalog videodan SAPAMAZ.
 */
function animated(
  id: string,
  title: string,
  description: string,
  relatedLessonSlug?: string
): VideoContent {
  const g = GENERATED_VIDEOS[id];
  if (!g)
    throw new Error(`videos.generated.ts içinde '${id}' yok — render-video.mjs çalıştırıldı mı?`);
  return {
    id,
    title,
    description,
    status: 'available',
    src: `/videos/${id}.mp4`,
    srcWebm: `/videos/${id}.webm`,
    poster: `/videos/${id}-poster.jpg`,
    captions: `/videos/${id}.tr.vtt`,
    duration: g.duration,
    chapters: g.chapters,
    transcript: g.transcript,
    relatedLessonSlug,
  };
}

export const VIDEOS: VideoContent[] = [
  // ── Manevra seti (özgün animasyon) ────────────────────────────────────────
  animated(
    'parallel-park',
    'Paralel Park — Adım Adım (Animasyon)',
    'İki araç arasına geri geri paralel park manevrasının kuş bakışı, adım etiketli anlatımı.',
    'park-manevra'
  ),
  animated(
    'l-park',
    'L Park / Dik Park — Adım Adım (Animasyon)',
    'Park cebine dik girişin referans noktalarıyla, adım adım kuş bakışı anlatımı.',
    'park-manevra'
  ),
  animated(
    'u-turn',
    'U Dönüşü — Adım Adım (Animasyon)',
    'Tek hamlede güvenli U dönüşünün kontrol, sinyal ve direksiyon sırasıyla anlatımı.',
    'sollama-serit'
  ),
  animated(
    'reverse-25m',
    '25 Metre Geri Gidiş — Adım Adım (Animasyon)',
    'Şeritten çıkmadan, kontrollü geri gidişin başlangıç ve bitiş çizgileriyle anlatımı.',
    'park-manevra'
  ),
  animated(
    'hill-start',
    'Yokuşta Kalkış — Adım Adım (Animasyon)',
    'El freni, kavrama noktası ve gaz sırasının şematik anlatımı; aracın geri kaymadan kalkışı. ' +
      'Pedal kamerasıyla gerçek çekim ayrıca planlanıyor.',
    'debriyaj-rampa'
  ),
  animated(
    'common-mistakes',
    'Sık Yapılan 3 Manevra Hatası (Animasyon)',
    'Çizgiyi aşarak durmak, dönüşü fazla geniş almak ve aynaya bakmadan geri gitmek — ' +
      'her hatanın yanında doğrusu gösterilir.',
    'sinav-strateji'
  ),
  animated(
    'right-of-way',
    'Kavşakta Sağdan Gelen — Adım Adım (Animasyon)',
    'Işıksız eşit kavşakta sağdan gelene yol vermenin adım etiketli anlatımı.',
    'kavsak-oncelik'
  ),

  // ── Gerçek çekim gerektiren müfredat — dürüstçe "planlanıyor" ─────────────
  // Bunlar animasyonla DÜRÜSTÇE öğretilemez: biri gerçek sınav güzergâhını, diğeri gerçek araç
  // parçalarının görünümünü gerektirir. Şematik bir animasyon burada yanıltıcı olurdu.
  {
    id: 'exam-walkthrough',
    title: 'Direksiyon Sınavı Yürüyüşü (Gerçek Çekim — planlanıyor)',
    description:
      'Gerçek sınav güzergâhında baştan sona örnek sürüş ve değerlendirme anları. ' +
      'Gerçek çekim gerektirir; hazır olduğunda eklenecek.',
    status: 'planned',
    relatedLessonSlug: 'sinav-strateji',
  },
  {
    id: 'vehicle-inspection',
    title: 'Sürüş Öncesi Araç Kontrolü (Gerçek Çekim — planlanıyor)',
    description:
      'Kaput altı ve araç çevresi kontrollerinin gerçek araç üzerinde gösterimi. ' +
      'Parçaların tanınması için Araç Tekniği bölümündeki gerçek fotoğraf kütüphanesi bugün de kullanılabilir.',
    status: 'planned',
    relatedLessonSlug: 'arac-hazirlik',
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
