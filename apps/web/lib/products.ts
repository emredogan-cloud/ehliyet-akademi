/**
 * Ürün kataloğu — TEK-SEFERLİK satın alma modeli (ROADMAP Faz 16, 2026-07-15 ürün kararı).
 * Abonelik YOK: bir kez öde, kalıcı erişim. Fiyatlar web-first (TRY).
 */

export type ProductId =
  'premium-teori' | 'premium-direksiyon' | 'simulator-paketi' | 'premium-soru-bankasi' | 'komple-b';

/** Paketlerin açtığı yetenekler. */
export type Capability =
  'teori-premium' | 'direksiyon-premium' | 'sinirsiz-deneme' | 'soru-bankasi-tam' | 'ai-sinirsiz';

export interface Product {
  id: ProductId;
  title: string;
  priceTRY: number;
  blurb: string;
  features: string[];
  capabilities: Capability[];
  highlight?: boolean;
}

export const PRODUCTS: Product[] = [
  {
    id: 'premium-teori',
    title: 'Premium Teori Paketi',
    priceTRY: 249,
    blurb: '4 dersin tüm premium içeriği + tam soru bankası.',
    features: ['Tüm teori dersleri', 'Tam soru bankası erişimi', 'Yanlış-havuzu analitiği'],
    capabilities: ['teori-premium', 'soru-bankasi-tam'],
  },
  {
    id: 'premium-direksiyon',
    title: 'Premium Direksiyon Paketi',
    priceTRY: 199,
    blurb: 'Direksiyon (pratik) sınavının tüm premium içeriği.',
    features: ['Pratik sınav dersleri', 'Pratik simülatör senaryoları', 'Hata çizelgesi koçluğu'],
    capabilities: ['direksiyon-premium'],
  },
  {
    id: 'simulator-paketi',
    title: 'Gelişmiş Simülatör Paketi',
    priceTRY: 149,
    blurb: 'Sınırsız e-Sınav denemesi + gelişmiş senaryolar.',
    features: ['Sınırsız deneme sınavı', 'Gerçek format (50/45dk)', 'Ders bazlı analiz'],
    capabilities: ['sinirsiz-deneme'],
  },
  {
    id: 'premium-soru-bankasi',
    title: 'Premium Soru Bankası',
    priceTRY: 129,
    blurb: 'Genişletilmiş banka + akıllı tekrar (SRS) tam sürüm.',
    features: ['Genişletilmiş soru havuzu', 'SRS tam sürüm', 'Konu bazlı derinlik'],
    capabilities: ['soru-bankasi-tam'],
  },
  {
    id: 'komple-b',
    title: 'Komple B Ehliyet Paketi',
    priceTRY: 449,
    blurb: 'Hepsi bir arada — ömür boyu erişim (Lifetime Unlock).',
    features: [
      'Yukarıdaki her şey dahil',
      'AI açıklamalar sınırsız',
      'Gelecek içerik güncellemeleri dahil',
      'Geçme garantisi kapsamı',
    ],
    capabilities: [
      'teori-premium',
      'direksiyon-premium',
      'sinirsiz-deneme',
      'soru-bankasi-tam',
      'ai-sinirsiz',
    ],
    highlight: true,
  },
];

export function productById(id: string): Product | undefined {
  return PRODUCTS.find((p) => p.id === id);
}

/** Sahip olunan ürünlerden yetenek kümesi türet (saf — test edilebilir). */
export function capabilitiesOf(owned: string[]): Set<Capability> {
  const caps = new Set<Capability>();
  for (const id of owned) {
    const p = productById(id);
    if (p) for (const c of p.capabilities) caps.add(c);
  }
  return caps;
}

export function hasCapability(owned: string[], cap: Capability): boolean {
  return capabilitiesOf(owned).has(cap);
}

/** Yetenek → kullanıcıya gösterilecek "kilidi açıldı" etiketi + ikon (premium başarı açılışı). */
export const CAPABILITY_FEATURE: Record<Capability, { icon: string; label: string }> = {
  'ai-sinirsiz': { icon: 'bot', label: 'AI Koç: Sınırsız Kişisel Analiz' },
  'sinirsiz-deneme': { icon: 'target', label: 'Sınırsız Deneme Sınavı' },
  'soru-bankasi-tam': { icon: 'book', label: 'Tam Soru Bankası Erişimi' },
  'teori-premium': { icon: 'gradcap', label: 'Tüm Premium Teori Dersleri' },
  'direksiyon-premium': { icon: 'car', label: 'Premium Direksiyon İçeriği' },
};

/**
 * Sahip olunan ürünlerden AÇILAN GERÇEK özellik listesi (premium başarı açılışında gösterilir).
 * Sadece entitlement'ın gerçekten etkinleştirdiği yetenekler — placeholder metin YOK.
 */
export function unlockedFeatures(owned: string[]): Array<{ icon: string; label: string }> {
  const order: Capability[] = [
    'ai-sinirsiz',
    'sinirsiz-deneme',
    'soru-bankasi-tam',
    'teori-premium',
    'direksiyon-premium',
  ];
  const caps = capabilitiesOf(owned);
  return order.filter((c) => caps.has(c)).map((c) => CAPABILITY_FEATURE[c]);
}
