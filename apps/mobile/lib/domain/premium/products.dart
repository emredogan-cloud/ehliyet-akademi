// Premium ürün kataloğu + yetenek (capability) modeli — web `lib/products.ts` + `lib/entitlements.ts`
// birebir Dart limanı. Tek-seferlik satın alma (abonelik YOK); sahiplik = ürün id listesi.
// Saf + test edilebilir.

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.priceTRY,
    required this.blurb,
    required this.features,
    required this.capabilities,
    this.highlight = false,
  });
  final String id;
  final String title;
  final int priceTRY;
  final String blurb;
  final List<String> features;
  final List<String> capabilities;
  final bool highlight;

  /// Play Store ürün kimliği (yönetilen, tek-seferlik). Sunucu `productId` ile `_`↔`-` köprüsü.
  String get storeProductId => id.replaceAll('-', '_');
}

/// Web `PRODUCTS` kataloğu (fiyatlar TRY, tek seferlik ömür boyu).
const List<Product> products = [
  Product(
    id: 'premium-teori',
    title: 'Premium Teori Paketi',
    priceTRY: 249,
    blurb: 'Tüm premium dersler + tam soru bankası.',
    features: ['İleri premium dersler', 'Tam soru bankası erişimi', 'Reklamsız çalışma'],
    capabilities: ['teori-premium', 'soru-bankasi-tam'],
  ),
  Product(
    id: 'premium-direksiyon',
    title: 'Premium Direksiyon Paketi',
    priceTRY: 199,
    blurb: 'Direksiyon (uygulama) için premium dersler.',
    features: ['Park & manevra dersleri', 'Kavşak uygulama dersleri'],
    capabilities: ['direksiyon-premium'],
  ),
  Product(
    id: 'simulator-paketi',
    title: 'Gelişmiş Simülatör Paketi',
    priceTRY: 149,
    blurb: 'Sınırsız deneme sınavı.',
    features: ['Günlük deneme sınırı yok', 'İstediğin kadar dene'],
    capabilities: ['sinirsiz-deneme'],
  ),
  Product(
    id: 'premium-soru-bankasi',
    title: 'Premium Soru Bankası',
    priceTRY: 129,
    blurb: 'Tam soru bankası erişimi.',
    features: ['Tüm soru koleksiyonları', 'Zor sorular + görsel sorular'],
    capabilities: ['soru-bankasi-tam'],
  ),
  Product(
    id: 'komple-b',
    title: 'Komple B Ehliyet Paketi',
    priceTRY: 449,
    blurb: 'Her şey dahil — en avantajlı paket.',
    features: [
      'Tüm premium dersler',
      'Sınırsız deneme sınavı',
      'Tam soru bankası',
      'Sınırsız AI Koç',
    ],
    capabilities: [
      'teori-premium',
      'direksiyon-premium',
      'sinirsiz-deneme',
      'soru-bankasi-tam',
      'ai-sinirsiz',
    ],
    highlight: true,
  ),
];

Product? productById(String id) {
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
}

/// Play Store ürün kimliğinden ürün (ör. `komple_b` → `komple-b`).
Product? productByStoreId(String storeId) {
  for (final p in products) {
    if (p.storeProductId == storeId) return p;
  }
  return null;
}

/// Sahip olunan ürünlerin sağladığı yetenekler.
Set<String> capabilitiesOf(List<String> owned) {
  final caps = <String>{};
  for (final id in owned) {
    final p = productById(id);
    if (p != null) caps.addAll(p.capabilities);
  }
  return caps;
}

bool hasCapability(List<String> owned, String cap) => capabilitiesOf(owned).contains(cap);

/// Ders → gereken yetenek (web `LESSON_CAPABILITY`). Yalnız bu 3 ders gerçekte kilitli.
const Map<String, String> lessonCapability = {
  'park-manevra': 'direksiyon-premium',
  'kavsak-uygulama': 'direksiyon-premium',
  'sollama-serit': 'teori-premium',
};

/// Bir derse erişilebilir mi? premium değilse serbest; eşlenmemiş premium ders güvenli-varsayılan açık.
bool canAccessLesson({required String slug, required bool premium, required List<String> owned}) {
  if (!premium) return true;
  final cap = lessonCapability[slug];
  if (cap == null) return true; // premium işaretli ama eşlenmemiş → açık
  return hasCapability(owned, cap);
}

/// Yetenek için en ucuz ürün (yoksa komple paket).
Product productForCapability(String cap) {
  Product? cheapest;
  for (final p in products) {
    if (p.capabilities.contains(cap)) {
      if (cheapest == null || p.priceTRY < cheapest.priceTRY) cheapest = p;
    }
  }
  return cheapest ?? productById('komple-b')!;
}

/// Ders için önerilen ürün (dersin yeteneğini sağlayan en ucuz).
Product productForLesson(String slug) {
  final cap = lessonCapability[slug];
  return cap == null ? productById('komple-b')! : productForCapability(cap);
}
