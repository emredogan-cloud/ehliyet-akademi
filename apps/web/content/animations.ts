/**
 * Eğitsel animasyon kataloğu (Program 2 · Faz 3 · ADR-012).
 * Sahnelerin kimlikleri components/anim/scenes.tsx içindeki SVG sahnelerle birebirdir.
 * Adım metinleri her zaman görünür — reduced-motion durumunda bilgi kaybı olmaz.
 */

export interface AnimationMeta {
  id: string;
  title: string;
  description: string;
  /** Animasyon döngü süresi (sn) — CSS ile senkron. */
  duration: number;
  steps: string[];
}

export const ANIMATIONS: AnimationMeta[] = [
  {
    id: 'parallel-park',
    title: 'Paralel Park',
    description: 'İki araç arasına geri geri paralel park manevrası (kuş bakışı).',
    duration: 9,
    steps: [
      'Boşluğun yanından geç, öndeki araçla hizalan',
      'Geri viteste direksiyonu sağa kır — arka boşluğa girsin',
      'Araç ~45° olunca direksiyonu sola çevir, düzelt',
      'Araçlar arasında ortala; tekerlekleri düzelt',
    ],
  },
  {
    id: 'perpendicular-park',
    title: 'Dik Park',
    description: 'Park cebine 90° dik park manevrası (kuş bakışı).',
    duration: 8,
    steps: [
      'Cebe uzak şeritten yaklaş, cebi erken gözle',
      'Cep hizasını biraz geçince direksiyonu kır',
      'Geniş kavisle cebe dön; aynalardan çizgileri izle',
      'Cebin ortasında dik dur; tekerlekleri düzelt',
    ],
  },
  {
    id: 'right-of-way',
    title: 'Kavşakta Sağdan Gelen',
    description: 'Işıksız eşit kavşakta sağdan gelene yol verme (kuş bakışı).',
    duration: 8,
    steps: [
      'Kavşağa yaklaşırken yavaşla, sol-ileri-sağ tara',
      'Sağdan gelen araç var → kavşak çizgisinde dur',
      'Sağdan gelen güvenle geçsin',
      'Yol boşalınca kontrollü geç',
    ],
  },
  {
    id: 'emergency-yield',
    title: 'Ambulansa Yol Açma',
    description: 'Geçiş üstünlüğü olan araca güvenle yol açma (kuş bakışı).',
    duration: 8,
    steps: [
      'Siren/tepe lambasını fark et — panik yok',
      'Sinyal ver, güvenle sağa yanaş ve yavaşla',
      'Ambulans soldan geçsin; ani manevra yapma',
      'Geçtikten sonra güvenle şeridine dön',
    ],
  },
];

/** Ders → animasyon eşlemesi (test kapısı: ders + animasyon kimlikleri çözülmeli). */
export const LESSON_ANIMS: Record<string, string[]> = {
  'park-manevra': ['parallel-park', 'perpendicular-park'],
  'kavsak-oncelik': ['right-of-way'],
  'kavsak-uygulama': ['right-of-way'],
  'trafik-adabi': ['emergency-yield'],
};

export function animationById(id: string): AnimationMeta | undefined {
  return ANIMATIONS.find((a) => a.id === id);
}
