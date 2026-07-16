/**
 * Senaryo öğrenme içeriği (Program 2 · Faz 8 · ADR-015).
 * Deklaratif kuş-bakışı sahneler + karar grafı: karar → sonuç → açıklama.
 * Test kapıları: graf tutarlı (tüm next'ler çözülür), çıkmaz yok, ≥6 senaryo.
 */

export interface SceneCar {
  x: number;
  y: number;
  rot?: number;
  kind: 'ego' | 'other' | 'priority' | 'ambulance';
}

export interface SceneSpec {
  /** Yol dikdörtgenleri (420×240 tuval). */
  roads: Array<{ x: number; y: number; w: number; h: number }>;
  /** Şerit çizgileri. */
  dashes?: Array<{ x: number; y: number; w: number; h: number }>;
  /** Durma çizgisi. */
  stopLine?: { x: number; y: number; w: number; h: number };
  /** Yaya geçidi (zebra) alanı. */
  crossing?: { x: number; y: number; w: number; h: number };
  cars: SceneCar[];
  ped?: { x: number; y: number };
  /** Sahneye küçük işaret rozeti (Faz 6 parametrik sistemi). */
  sign?: { signId: string; x: number; y: number };
}

export interface ScenarioOption {
  text: string;
  verdict: 'safe' | 'risky';
  explain: string;
  /** Verilirse akış bu adıma geçer; yoksa senaryo biter. */
  next?: string;
}

export interface ScenarioStep {
  id: string;
  scene: SceneSpec;
  prompt: string;
  options: ScenarioOption[];
}

export interface Scenario {
  id: string;
  title: string;
  description: string;
  start: string;
  steps: ScenarioStep[];
  relatedLessonSlug?: string;
}

// Ortak sahne parçaları
const CROSS_ROADS = [
  { x: 0, y: 85, w: 420, h: 70 },
  { x: 175, y: 0, w: 70, h: 240 },
];
const H_ROAD = [{ x: 0, y: 85, w: 420, h: 70 }];

export const SCENARIOS: Scenario[] = [
  {
    id: 'sagdan-gelen',
    title: 'Işıksız Kavşak: Sağdan Gelen',
    description: 'Eşit yolların kesiştiği ışıksız kavşağa yaklaşıyorsun; sağdan bir araç geliyor.',
    relatedLessonSlug: 'kavsak-oncelik',
    start: 'yaklas',
    steps: [
      {
        id: 'yaklas',
        scene: {
          roads: CROSS_ROADS,
          stopLine: { x: 150, y: 90, w: 5, h: 60 },
          cars: [
            { x: 100, y: 137, rot: 90, kind: 'ego' },
            { x: 228, y: 205, rot: 0, kind: 'priority' },
          ],
        },
        prompt: 'Işıksız eşit kavşak; sağdan araç geliyor. Ne yaparsın?',
        options: [
          {
            text: 'Yavaşlar, çizgide durur ve sağdan gelene yol veririm',
            verdict: 'safe',
            explain: 'Doğru: ışıksız eşit kavşakta geçiş önceliği sağdan gelenindir.',
            next: 'gecis',
          },
          {
            text: 'Hızlanıp ondan önce kavşağı geçerim',
            verdict: 'risky',
            explain: 'Önceliği zorla almak yan çarpma kazalarının en sık sebebidir.',
            next: 'gecis',
          },
          {
            text: 'Korna çalarak kendi geçişimi bildiririm',
            verdict: 'risky',
            explain: 'Korna öncelik kazandırmaz; kural sağdan gelene yol vermektir.',
            next: 'gecis',
          },
        ],
      },
      {
        id: 'gecis',
        scene: {
          roads: CROSS_ROADS,
          cars: [{ x: 128, y: 137, rot: 90, kind: 'ego' }],
        },
        prompt: 'Sağdan gelen geçti, kavşak boş. Şimdi?',
        options: [
          {
            text: 'Sol-ileri-sağ son kontrolü yapıp kontrollü geçerim',
            verdict: 'safe',
            explain: 'Yol boşaldıktan sonra bile kısa bir tarama güvenli geçişin parçasıdır.',
          },
          {
            text: 'Beklemeye devam ederim; bir araç daha gelebilir',
            verdict: 'risky',
            explain: 'Gereksiz bekleme arkadaki trafiği sıkıştırır; yol boşsa kontrollü geçilir.',
          },
        ],
      },
    ],
  },
  {
    id: 'donel-kavsak',
    title: 'Dönel Kavşak Girişi',
    description: 'Dönel kavşağa yaklaşıyorsun; ada etrafında dönen bir araç var.',
    relatedLessonSlug: 'kavsak-oncelik',
    start: 'giris',
    steps: [
      {
        id: 'giris',
        scene: {
          roads: [
            { x: 0, y: 85, w: 420, h: 70 },
            { x: 175, y: 0, w: 70, h: 120 },
          ],
          cars: [
            { x: 90, y: 137, rot: 90, kind: 'ego' },
            { x: 240, y: 100, rot: 220, kind: 'priority' },
          ],
          sign: { signId: 'donel-kavsak-yaklasim', x: 40, y: 44 },
        },
        prompt: 'Dönel kavşakta ada etrafında dönen araç var. Ne yaparsın?',
        options: [
          {
            text: 'Girişte yavaşlar, dönen araca yol verir, boşlukta girerim',
            verdict: 'safe',
            explain: 'Dönel kavşakta öncelik ada etrafında DÖNEN araçtadır.',
          },
          {
            text: 'Dönen araçtan önce hızla girerim',
            verdict: 'risky',
            explain: 'Dönene yol vermemek dönel kavşak kazalarının başlıca sebebidir.',
          },
          {
            text: 'Tam durup dönen araç uzaklaşana kadar hiç bakmam',
            verdict: 'risky',
            explain: 'Gereksiz tam duruş akışı bozar; uygun boşluğu gözleyip girmek esastır.',
          },
        ],
      },
    ],
  },
  {
    id: 'tali-yol',
    title: 'Tali Yoldan Ana Yola Çıkış',
    description: 'Yol Ver levhalı tali yoldan ana yola çıkacaksın; ana yolda akan trafik var.',
    relatedLessonSlug: 'kavsak-oncelik',
    start: 'bekle',
    steps: [
      {
        id: 'bekle',
        scene: {
          roads: [
            { x: 0, y: 85, w: 420, h: 70 },
            { x: 175, y: 155, w: 70, h: 85 },
          ],
          cars: [
            { x: 210, y: 205, rot: 0, kind: 'ego' },
            { x: 80, y: 120, rot: 90, kind: 'priority' },
            { x: 330, y: 137, rot: 270, kind: 'other' },
          ],
          sign: { signId: 'yol-ver', x: 260, y: 195 },
        },
        prompt: 'Yol Ver levhası var; ana yolda iki yönlü akış sürüyor. Ne yaparsın?',
        options: [
          {
            text: 'Gerekirse durup her iki yönü de kontrol eder, uygun boşluğu beklerim',
            verdict: 'safe',
            explain: 'Tali yoldan çıkan, ana yoldaki TÜM trafiğe yol vermek zorundadır.',
            next: 'cikis',
          },
          {
            text: 'Sağdan gelen yoksa hemen çıkarım; soldan gelen yavaşlar nasılsa',
            verdict: 'risky',
            explain: 'Ana yoldaki araç yavaşlamak zorunda bırakılamaz; öncelik onundur.',
            next: 'cikis',
          },
        ],
      },
      {
        id: 'cikis',
        scene: {
          roads: [
            { x: 0, y: 85, w: 420, h: 70 },
            { x: 175, y: 155, w: 70, h: 85 },
          ],
          cars: [{ x: 210, y: 185, rot: 0, kind: 'ego' }],
        },
        prompt: 'Her iki yön de boş. Sağa dönerek katılacaksın. Sinyal?',
        options: [
          {
            text: 'Sağ sinyali verir, dar kavisle sağ şeride katılırım',
            verdict: 'safe',
            explain:
              'Dönüş yönü sinyalle bildirilir; sağa dönüş dar kavisle kendi şeridine yapılır.',
          },
          {
            text: 'Sinyalsiz çıkarım; nasılsa yol boş',
            verdict: 'risky',
            explain:
              'Sinyal görünmeyen kullanıcılar (yaya, bisikletli) için de verilir; her zaman zorunludur.',
          },
        ],
      },
    ],
  },
  {
    id: 'ambulans',
    title: 'Arkadan Ambulans Yaklaşıyor',
    description: 'Tek yönlü iki şeritli yolda soldasın; arkadan sirenli ambulans geliyor.',
    relatedLessonSlug: 'trafik-adabi',
    start: 'karar',
    steps: [
      {
        id: 'karar',
        scene: {
          roads: H_ROAD,
          dashes: [
            { x: 0, y: 118, w: 30, h: 4 },
            { x: 60, y: 118, w: 30, h: 4 },
            { x: 120, y: 118, w: 30, h: 4 },
            { x: 180, y: 118, w: 30, h: 4 },
            { x: 240, y: 118, w: 30, h: 4 },
            { x: 300, y: 118, w: 30, h: 4 },
            { x: 360, y: 118, w: 30, h: 4 },
          ],
          cars: [
            { x: 220, y: 104, rot: 90, kind: 'ego' },
            { x: 60, y: 104, rot: 90, kind: 'ambulance' },
          ],
        },
        prompt: 'Sirenli ambulans arkanda. Ne yaparsın?',
        options: [
          {
            text: 'Sinyal verip güvenle sağ şeride geçer ve yavaşlarım',
            verdict: 'safe',
            explain: 'Geçiş üstünlüğü olan araca güvenli biçimde yol açmak zorunludur.',
          },
          {
            text: 'Hızlanıp ambulansın önünde yol açmaya çalışırım',
            verdict: 'risky',
            explain: 'Hızlanmak tehlikeyi büyütür; doğru davranış kenara çekilip yavaşlamaktır.',
          },
          {
            text: 'Olduğum şeritte ani fren yaparım',
            verdict: 'risky',
            explain: 'Ani fren ambulansı ve arkadaki trafiği tehlikeye atar; kontrollü yol açılır.',
          },
        ],
      },
    ],
  },
  {
    id: 'yaya-gecidi',
    title: 'Yaya Geçidinde Bekleyen Yaya',
    description:
      'İleride kontrolsüz yaya geçidi var; kenarda geçmek için bekleyen bir yaya duruyor.',
    relatedLessonSlug: 'yaya-gecidi',
    start: 'karar',
    steps: [
      {
        id: 'karar',
        scene: {
          roads: H_ROAD,
          crossing: { x: 250, y: 88, w: 44, h: 64 },
          cars: [{ x: 110, y: 120, rot: 90, kind: 'ego' }],
          ped: { x: 272, y: 74 },
          sign: { signId: 'yaya-gecidi-bilgi', x: 330, y: 50 },
        },
        prompt: 'Geçidin kenarında bekleyen yaya var. Ne yaparsın?',
        options: [
          {
            text: 'Yavaşlar, gerekirse durur, yayaya geçiş hakkını veririm',
            verdict: 'safe',
            explain: 'Kontrolsüz yaya geçidinde geçiş önceliği YAYANINDIR.',
          },
          {
            text: 'Yaya adım atmadıysa hızımı koruyup geçerim',
            verdict: 'risky',
            explain: 'Geçme niyetindeki yayaya öncelik verilir; hız korunarak geçilmez.',
          },
          {
            text: 'Selektör yapıp yayanın beklemesini isterim',
            verdict: 'risky',
            explain: 'Işık/korna yayaya baskı kurmak için kullanılamaz; öncelik yayanın.',
          },
        ],
      },
    ],
  },
  {
    id: 'dar-gecit',
    title: 'Dar Geçit: Karşıdan Gelene Öncelik',
    description:
      'Daralan köprüye yaklaşıyorsun; levha karşı yöne öncelik veriyor ve karşıdan araç geliyor.',
    relatedLessonSlug: 'kavsak-oncelik',
    start: 'karar',
    steps: [
      {
        id: 'karar',
        scene: {
          roads: [
            { x: 0, y: 85, w: 150, h: 70 },
            { x: 150, y: 95, w: 120, h: 50 },
            { x: 270, y: 85, w: 150, h: 70 },
          ],
          cars: [
            { x: 80, y: 120, rot: 90, kind: 'ego' },
            { x: 340, y: 120, rot: 270, kind: 'priority' },
          ],
          sign: { signId: 'dar-gecit-oncelik', x: 120, y: 50 },
        },
        prompt: 'Dar geçit levhası karşı yöne öncelik veriyor; karşıdan araç geldi. Ne yaparsın?',
        options: [
          {
            text: 'Daralmadan önce durur, karşıdan gelen geçtikten sonra girerim',
            verdict: 'safe',
            explain: 'Kırmızı ok tarafındaki sürücü (sen) karşı yöne yol vermek zorundadır.',
          },
          {
            text: 'Ben daha yakınım; hızlanıp önce ben geçerim',
            verdict: 'risky',
            explain: 'Yakınlık öncelik doğurmaz; levha karşı yöne öncelik veriyor.',
          },
        ],
      },
    ],
  },
  {
    id: 'okul-bolgesi',
    title: 'Okul Bölgesinde Hız Kararı',
    description: 'Okul geçidi levhası ve kaldırımda çocuklar var; hız kararını veriyorsun.',
    relatedLessonSlug: 'hiz-takip',
    start: 'karar',
    steps: [
      {
        id: 'karar',
        scene: {
          roads: H_ROAD,
          crossing: { x: 280, y: 88, w: 44, h: 64 },
          cars: [{ x: 90, y: 120, rot: 90, kind: 'ego' }],
          ped: { x: 300, y: 66 },
          sign: { signId: 'okul-gecidi', x: 40, y: 46 },
        },
        prompt: 'Okul geçidi levhası + kaldırımda çocuklar. Hızını nasıl ayarlarsın?',
        options: [
          {
            text: 'Belirgin şekilde yavaşlar, her an durabilecek hızla ilerlerim',
            verdict: 'safe',
            explain: 'Çocuklar öngörülemez; okul bölgesinde hız her an durabilecek düzeye iner.',
          },
          {
            text: 'Yasal sınır 50 ise 50 ile devam ederim',
            verdict: 'risky',
            explain: 'Yasal sınır tavandır; koşullar (çocuklar) hızı daha da düşürmeyi gerektirir.',
          },
          {
            text: 'Kornaya basıp çocukları uyararak hızımı korurum',
            verdict: 'risky',
            explain: 'Korna çocukları ürkütebilir; doğru davranış hızı düşürmektir.',
          },
        ],
      },
    ],
  },
];

export function scenarioById(id: string): Scenario | undefined {
  return SCENARIOS.find((s) => s.id === id);
}

/** Graf bütünlüğü: tüm adım/next kimlikleri çözülür; başlangıç geçerli. */
export function validateScenarioGraph(s: Scenario): string[] {
  const errors: string[] = [];
  const ids = new Set(s.steps.map((st) => st.id));
  if (ids.size !== s.steps.length) errors.push(`${s.id}: adım kimlikleri benzersiz değil`);
  if (!ids.has(s.start)) errors.push(`${s.id}: start '${s.start}' çözülmüyor`);
  for (const st of s.steps) {
    if (st.options.length < 2) errors.push(`${s.id}/${st.id}: en az 2 seçenek gerek`);
    if (!st.options.some((o) => o.verdict === 'safe'))
      errors.push(`${s.id}/${st.id}: güvenli seçenek yok`);
    for (const o of st.options) {
      if (o.next && !ids.has(o.next)) errors.push(`${s.id}/${st.id}: next '${o.next}' çözülmüyor`);
    }
  }
  return errors;
}
