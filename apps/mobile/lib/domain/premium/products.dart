// Premium ürün kataloğu + yetenek (capability) modeli. TEK premium ürün: "Komple Ehliyet Paketi"
// (399 TL, tek-seferlik / ömür boyu). Sahiplik = ürün id listesi; tek ürün her şeyi açar.
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

/// TEK premium ürünün kimliği.
const String kPremiumProductId = 'komple-ehliyet';

/// Premium'un açtığı tüm yetenekler.
const List<String> kAllCapabilities = [
  'teori-premium',
  'direksiyon-premium',
  'sinirsiz-deneme',
  'soru-bankasi-tam',
  'ai-sinirsiz',
  'video-tam',
];

/// Ürün kataloğu — TEK ürün (tek seferlik ömür boyu). Fiyat 399 TL.
const List<Product> products = [
  Product(
    id: kPremiumProductId,
    title: 'Komple Ehliyet Paketi',
    priceTRY: 399,
    blurb: 'Tüm potansiyelini aç — her şey tek pakette, ömür boyu.',
    features: [
      'Tüm konulara sınırsız erişim',
      'Sınırsız deneme sınavı',
      'Sınırsız AI Koç desteği',
      'Tüm video dersler',
      'Kişisel çalışma planı',
    ],
    capabilities: kAllCapabilities,
    highlight: true,
  ),
];

/// Premium paket (tek ürün).
Product get premiumProduct => products.first;

Product? productById(String id) {
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
}

/// Play Store ürün kimliğinden ürün (ör. `komple_ehliyet` → `komple-ehliyet`).
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

/// Premium sahibi mi — tek ürün modelinde herhangi bir bilinen satın alma tam premium demektir.
bool isPremium(List<String> owned) => owned.any((id) => productById(id) != null);

/// Ders → gereken premium (web `LESSON_CAPABILITY`). Yalnız bu 3 ders gerçekte kilitli; premium
/// paketi hepsini açar.
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

/// Video derslere erişim — ilk video ücretsiz önizleme, gerisi premium.
bool canAccessVideo({required int index, required List<String> owned}) => index == 0 || isPremium(owned);

/// Herhangi bir yetenek/ders için önerilen ürün (tek ürün modeli → premium paket).
Product productForCapability(String cap) => premiumProduct;

Product productForLesson(String slug) => premiumProduct;
