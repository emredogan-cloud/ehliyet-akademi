/**
 * Ürün kataloğu — TEK-SEFERLİK satın alma modeli (ROADMAP Faz 16, 2026-07-15 ürün kararı).
 * Abonelik YOK: bir kez öde, kalıcı erişim. Fiyatlar web-first (TRY).
 */

export type ProductId =
  | 'premium-teori'
  | 'premium-direksiyon'
  | 'simulator-paketi'
  | 'premium-soru-bankasi'
  | 'komple-b'
  // Mobil uygulamanın premium paketleri (web paywall'da gösterilmez; yalnız mobil IAP doğrulaması).
  // ÜÇÜ DE burada olmak zorunda: `anyProductById` bilinmeyen kimliğe 404 döner ve kullanıcı
  // ödeme yaptığı hâlde hiçbir hak kaydı oluşmaz (yayın öncesi denetim bulgusu N1).
  | 'premium-haftalik'
  | 'premium-aylik'
  | 'komple-ehliyet';

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
      // "Geçme garantisi kapsamı" 10 Ağustos 2026'da KALDIRILDI: bu bir SONUÇ GARANTİSİDİR.
      // Play'in Yanlış Beyan politikası ve 6502 sayılı Tüketicinin Korunması Hakkında Kanun
      // açısından savunulamaz — uygulama sınavı geçireceğini taahhüt edemez.
      'Tüm premium derslere kalıcı erişim',
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

/** Üç mobil paketin ortak özellik listesi — mobil kataloğun `_kFeatures` karşılığı. */
const MOBILE_PREMIUM_FEATURES: string[] = [
  'Tüm konulara sınırsız erişim',
  'Sınırsız deneme sınavı',
  'Sınırsız AI Koç desteği',
  'Tüm video dersler',
  'Kişisel çalışma planı',
];

/** Üç paket de AYNI yetenekleri açar — fark yalnız süredir (mobil `kAllCapabilities`). */
const MOBILE_PREMIUM_CAPABILITIES: Capability[] = [
  'teori-premium',
  'direksiyon-premium',
  'sinirsiz-deneme',
  'soru-bankasi-tam',
  'ai-sinirsiz',
];

/**
 * Mobil uygulamanın premium paketleri. Web paywall'da GÖSTERİLMEZ (PRODUCTS'a eklenmez); yalnız
 * mobil IAP doğrulaması sunucu-taraflı katalogda tanısın diye ayrı tutulur.
 *
 * ## 10 Ağustos 2026 — İKİ ABONELİK EKLENDİ (yayın öncesi denetim bulgusu N1)
 *
 * Bu liste yalnız `komple-ehliyet` içeriyordu; oysa mobil katalog ÜÇ paket satıyor
 * (`apps/mobile/lib/domain/premium/products.dart`). `anyProductById()` haftalık ve aylık için
 * `undefined` döndüğü için `/api/iap/validate` **404 "Ürün bulunamadı."** yanıtı veriyordu:
 * kullanıcı Google'a ödeme yapıyor, sunucuda hiçbir hak kaydı oluşmuyordu. Yerel erişim yine de
 * açıldığı için (`grantFromStore` önce cihaza yazar) hata fark edilmemişti — ama çapraz cihaz
 * senkronu ve geri yükleme çalışmıyordu.
 *
 * ## Fiyatlar
 *
 * `priceTRY` **kayıt amaçlıdır** ve mağaza fiyatını yansıtmalıdır; kullanıcıya gösterilen fiyat
 * her zaman Play'den okunur (`paywall_screen.dart`). Ömür boyu paket 399 yazıyordu, mağaza
 * 479,99 tahsil ediyordu — her satın alma veritabanına YANLIŞ fiyatla yazılıyordu (bulgu N2).
 */
export const MOBILE_PRODUCTS: Product[] = [
  {
    id: 'premium-haftalik',
    title: 'Premium — Haftalık',
    priceTRY: 50,
    blurb: 'Kısa sürede sınava girecekler için haftalık abonelik.',
    features: MOBILE_PREMIUM_FEATURES,
    capabilities: MOBILE_PREMIUM_CAPABILITIES,
  },
  {
    id: 'premium-aylik',
    title: 'Premium — Aylık',
    priceTRY: 200,
    blurb: 'Rahat bir tempoyla çalışmak için aylık abonelik.',
    features: MOBILE_PREMIUM_FEATURES,
    capabilities: MOBILE_PREMIUM_CAPABILITIES,
  },
  {
    id: 'komple-ehliyet',
    title: 'Komple Ehliyet Paketi',
    priceTRY: 480,
    blurb:
      'Tüm dersler, sınırsız deneme, sınırsız AI Koç ve premium içerik — tek pakette, ömür boyu.',
    features: MOBILE_PREMIUM_FEATURES,
    capabilities: MOBILE_PREMIUM_CAPABILITIES,
    highlight: true,
  },
];

/**
 * Ürün türü — doğrulama hangi Play API'sine gideceğini buradan bilir.
 *
 * Abonelikler `purchases.subscriptionsv2.get`, tek seferlik ürünler `purchases.products.get`
 * ucuna sorulur. Yanlış uç 404 döner ve geçerli bir satın alma reddedilirdi.
 */
export type MobileProductKind = 'subscription' | 'product';

const MOBILE_PRODUCT_KIND: Record<string, MobileProductKind> = {
  'premium-haftalik': 'subscription',
  'premium-aylik': 'subscription',
  'komple-ehliyet': 'product',
};

/** Ürün abonelik mi, tek seferlik mi? Bilinmeyen kimlik için `null`. */
export function mobileProductKind(id: string): MobileProductKind | null {
  return MOBILE_PRODUCT_KIND[id] ?? null;
}

/**
 * Sunucu ürün kimliğini Play Store kimliğine çevir (`komple-ehliyet` → `komple_ehliyet`).
 * Mobil taraftaki `storeProductId` ile birebir aynı kural (`products.dart:67`).
 */
export function storeProductIdOf(id: string): string {
  return id.replaceAll('-', '_');
}

/** Web + mobil kataloglarında ürün arar (mobil IAP doğrulaması mobil ürünleri de tanımalı). */
export function anyProductById(id: string): Product | undefined {
  return productById(id) ?? MOBILE_PRODUCTS.find((p) => p.id === id);
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
