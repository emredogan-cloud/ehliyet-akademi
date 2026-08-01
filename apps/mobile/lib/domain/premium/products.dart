// Premium ürün kataloğu + yetenek (capability) modeli.
//
// Ürün Evrimi v1.1 · Faz 10 — katalog TEK üründen ÜÇ pakete çıktı:
//   Haftalık 50 TL (abonelik) · Aylık 200 TL (abonelik) · Ömür Boyu 479,99 TL (tek seferlik)
//
// GERİYE UYUMLULUK — ömür boyu paketin kimliği `komple-ehliyet` OLARAK KALDI. Bu kimlikle
// satın alma yapmış kullanıcılar var; kimliği değiştirmek onları premium'suz bırakırdı.
// Değişen yalnız fiyat ve başlık. Yeni abonelikler ayrı kimliklerle eklendi.

/// Faturalandırma dönemi.
///
/// TEK TANIM — hem katalog (bizim ne sattığımız) hem mağaza yanıtı (sağlayıcının ne bildirdiği)
/// bunu kullanır. Önceden `data/premium/billing_gateway.dart` içinde ayrı bir kopyası vardı;
/// iki ayrı enum aynı şeyi anlatınca ikisini karşılaştırmak imkânsızlaşıyordu. Tanım ALAN
/// katmanında durur, veri katmanı buradan alır (bağımlılık yönü doğru olsun diye).
///
/// SIRA ÖNEMLİ: [activeProduct] "en iyi paket"i sıra numarasıyla seçer — sona doğru daha iyi.
enum BillingPeriod {
  /// Sağlayıcı bir dönem bildirmedi. Katalogda ASLA bulunmaz; yalnız mağaza yanıtında olabilir.
  unknown,
  weekly,
  monthly,
  yearly,

  /// Tek seferlik satın alma; yenilenmez.
  lifetime;

  bool get isSubscription => this != BillingPeriod.lifetime && this != BillingPeriod.unknown;

  /// Fiyatın yanında görünen dönem eki. Ömür boyu için ek yoktur.
  String? get suffix => switch (this) {
    BillingPeriod.weekly => '/hafta',
    BillingPeriod.monthly => '/ay',
    BillingPeriod.yearly => '/yıl',
    BillingPeriod.lifetime || BillingPeriod.unknown => null,
  };
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.priceMinor,
    required this.period,
    required this.blurb,
    required this.features,
    required this.capabilities,
    this.highlight = false,
  });

  final String id;
  final String title;

  /// Fiyat KURUŞ cinsinden (479,99 TL = 47999). Tam sayı tutulur ki kayan nokta yuvarlaması
  /// fiyatı 479,98 göstermesin.
  final int priceMinor;

  final BillingPeriod period;
  final String blurb;
  final List<String> features;
  final List<String> capabilities;

  /// "Önerilen" kart — arayüzde daha büyük ve vurgulu çizilir.
  final bool highlight;

  /// Play Store ürün kimliği (yönetilen/abonelik). Sunucu `productId` ile `_`↔`-` köprüsü.
  String get storeProductId => id.replaceAll('-', '_');

  /// YEDEK fiyat etiketi.
  ///
  /// GERÇEK fiyat her zaman mağazadan gelir (para birimi, ülke, vergi, indirim orada belirlenir).
  /// Bu etiket yalnız mağaza yanıt vermediğinde gösterilir. Kataloğu ekrana fiyat kaynağı yapmak
  /// RC 1.0.0'da düzeltilmiş bir kusurdu; tekrarlanmamalı.
  String get fallbackPriceLabel {
    final lira = priceMinor ~/ 100;
    final kurus = priceMinor % 100;
    final amount = kurus == 0
        ? '$lira'
        : '$lira,${kurus.toString().padLeft(2, '0')}';
    return '₺$amount${period.suffix ?? ''}';
  }
}

/// Ömür boyu paketin kimliği. TARİHSEL: eski tek-ürün modelinden gelir, değiştirilemez.
const String kPremiumProductId = 'komple-ehliyet';
const String kWeeklyProductId = 'premium-haftalik';
const String kMonthlyProductId = 'premium-aylik';

/// Premium'un açtığı tüm yetenekler. Üç paket de AYNI yetenekleri açar — fark yalnız süredir.
const List<String> kAllCapabilities = [
  'teori-premium',
  'direksiyon-premium',
  'sinirsiz-deneme',
  'soru-bankasi-tam',
  'ai-sinirsiz',
  'video-tam',
];

const List<String> _kFeatures = [
  'Tüm konulara sınırsız erişim',
  'Sınırsız deneme sınavı',
  'Sınırsız AI Koç desteği',
  'Tüm video dersler',
  'Kişisel çalışma planı',
];

/// Ürün kataloğu. SIRA ÖNEMLİ: ekranda soldan sağa / yukarıdan aşağıya bu sırayla çizilir.
const List<Product> products = [
  Product(
    id: kWeeklyProductId,
    title: 'Haftalık',
    priceMinor: 5000,
    period: BillingPeriod.weekly,
    blurb: 'Kısa sürede sınava girecekler için.',
    features: _kFeatures,
    capabilities: kAllCapabilities,
  ),
  Product(
    id: kMonthlyProductId,
    title: 'Aylık',
    priceMinor: 20000,
    period: BillingPeriod.monthly,
    blurb: 'Rahat bir tempoyla çalışmak için.',
    features: _kFeatures,
    capabilities: kAllCapabilities,
  ),
  Product(
    id: kPremiumProductId,
    title: 'Ömür Boyu',
    priceMinor: 47999,
    period: BillingPeriod.lifetime,
    blurb: 'Bir kez öde, süre dolmasın.',
    features: _kFeatures,
    capabilities: kAllCapabilities,
    highlight: true,
  ),
];

/// Önerilen paket — ekranda en büyük kart.
Product get recommendedProduct => products.firstWhere((p) => p.highlight);

/// Ömür boyu paket. Eski `premiumProduct` adının karşılığı; çağrı yerleri korunsun diye durur.
Product get premiumProduct => productById(kPremiumProductId)!;

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

/// Premium sahibi mi — herhangi bir bilinen paket tam premium demektir.
bool isPremium(List<String> owned) => owned.any((id) => productById(id) != null);

/// Sahip olunan paketlerden EN İYİSİ (ömür boyu > aylık > haftalık). Arayüz "Premium Aktif"
/// rozetinin altında hangi paketin sürdüğünü söylemek için kullanır.
Product? activeProduct(List<String> owned) {
  Product? best;
  for (final id in owned) {
    final p = productById(id);
    if (p == null) continue;
    if (best == null || p.period.index > best.period.index) best = p;
  }
  return best;
}

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
bool canAccessVideo({required int index, required List<String> owned}) =>
    index == 0 || isPremium(owned);

/// Herhangi bir yetenek/ders için önerilen ürün.
Product productForCapability(String cap) => recommendedProduct;

Product productForLesson(String slug) => recommendedProduct;
