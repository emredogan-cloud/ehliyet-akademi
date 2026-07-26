import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/premium/products.dart';
import 'billing_gateway.dart';
import 'iap_service.dart';

/// Beta Faz 3 — mevcut `in_app_purchase` yolunun [BillingGateway] uygulaması.
///
/// **BU SINIF MEVCUT MANTIĞI DEĞİŞTİRMEZ.** `IapService` dosyasına tek satır dokunulmadı; burası
/// yalnız onu ortak sözleşmeye çeviren bir SARMALAYICIDIR. Böylece RevenueCat eklenirken çalışan
/// ödeme yolu sökülmemiş olur (yol haritasının Faz 3 için koyduğu kritik kısıt).
///
/// SUNUCU KÖPRÜSÜ: [BillingServerBridge.clientReceipt] — Play `purchaseToken`'ı istemciden alınır ve
/// `POST /api/iap/validate` ile sunucuda doğrulanır. Yetkinin tek kaynağı sunucudur.
class PlayBillingGateway implements BillingGateway {
  PlayBillingGateway({IapService? service}) : _iap = service ?? IapService();

  final IapService _iap;

  /// `queryProducts()` sonucundan gelen mağaza detayları — satın alma bu haritadan yapılır.
  final Map<String, ProductDetails> _details = {};

  @override
  String get name => 'in_app_purchase';

  /// Bu yol her zaman kullanılabilir: gizli anahtar gerektirmez. Mağazanın gerçekten açık olup
  /// olmadığı ayrı bir sorudur → [available].
  @override
  bool get isConfigured => true;

  @override
  BillingServerBridge get serverBridge => BillingServerBridge.clientReceipt;

  @override
  Future<bool> available() async {
    try {
      return await _iap.available();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BillingProduct>> products() async {
    try {
      final details = await _iap.queryProducts();
      _details
        ..clear()
        ..addAll(details);
      return [
        for (final d in details.values)
          BillingProduct(
            storeProductId: d.id,
            priceLabel: d.price,
            title: d.title,
            // Mevcut katalog tek seferlik/ömür boyu tek ürün taşıyor (`buyNonConsumable`).
            period: BillingPeriod.lifetime,
          ),
      ];
    } catch (_) {
      // Mağaza yok / sorgu başarısız → dürüst boş liste; ekran "mağaza kullanılamıyor" gösterir.
      return const [];
    }
  }

  @override
  Future<BillingResult> purchase(BillingProduct product) async {
    final details = _details[product.storeProductId];
    if (details == null) {
      return const BillingFailure('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
    }
    try {
      await _iap.buy(details);
      // `in_app_purchase` akışı ASENKRONDUR: sonuç satın alma akışından (listen) gelir. Burada
      // yalnız akışın başlatıldığı bildirilir; sahiplik `onPurchase` ile sunucuda doğrulanır.
      return const BillingSuccess([]);
    } catch (_) {
      return const BillingFailure('Satın alma başlatılamadı.');
    }
  }

  @override
  Future<BillingResult> restore() async {
    try {
      await _iap.restore();
      // Geri yüklenen satın almalar da satın alma akışından (listen) gelir.
      return const BillingSuccess([]);
    } catch (_) {
      return const BillingFailure('Satın almalar geri yüklenemedi.');
    }
  }

  /// `in_app_purchase` bir yetki/yaşam döngüsü kaydı TUTMAZ — sahiplik SUNUCUDAN türetilir
  /// (`GET /api/purchases`). Bu yüzden burada dürüstçe boş liste döner; uydurma bir yaşam döngüsü
  /// durumu üretilmez. Ödeme ekranı yetkiyi `entitlementsProvider` üzerinden okur.
  @override
  Future<List<EntitlementFacts>> entitlementFacts() async => const [];

  @override
  Future<Set<String>> entitlements() async => const {};

  @override
  void listen(Future<void> Function(BillingPurchase) onPurchase) {
    _iap.listen((pd) async {
      await onPurchase(
        BillingPurchase(
          storeProductId: pd.productID,
          purchaseToken: pd.verificationData.serverVerificationData,
        ),
      );
    });
  }

  @override
  void dispose() => _iap.dispose();
}

/// Katalogdaki tek premium ürünün mağaza kimliği — ödeme ekranı hangi ürünü arayacağını bilsin diye.
String get primaryStoreProductId => premiumProduct.storeProductId;
