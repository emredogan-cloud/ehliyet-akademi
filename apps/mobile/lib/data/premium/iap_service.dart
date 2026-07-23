import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/premium/products.dart';

/// Uygulama-içi satın alma (Google Play Billing) sarmalayıcısı. Doğrulama sunucuda
/// (`/api/iap/validate`). NOT: gerçek satın alma yalnız Play Console'da tanımlı ürünler + imzalı,
/// Play'den yüklenmiş yapı ile çalışır (bu Linux geliştirme ortamında test EDİLEMEZ — belgelenmiştir).
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<bool> available() => _iap.isAvailable();

  /// Katalogdaki ürünlerin mağaza detayları (fiyat, id). Mağaza yoksa/ürün tanımlı değilse boş.
  Future<Map<String, ProductDetails>> queryProducts() async {
    final ids = products.map((p) => p.storeProductId).toSet();
    final resp = await _iap.queryProductDetails(ids);
    return {for (final pd in resp.productDetails) pd.id: pd};
  }

  /// Satın alma akışını dinle. Satın alınan/geri yüklenen her ürün [onPurchased] ile doğrulanır.
  void listen(Future<void> Function(PurchaseDetails) onPurchased) {
    _sub ??= _iap.purchaseStream.listen((purchases) async {
      for (final pd in purchases) {
        if (pd.status == PurchaseStatus.purchased || pd.status == PurchaseStatus.restored) {
          await onPurchased(pd);
        }
        if (pd.pendingCompletePurchase) {
          await _iap.completePurchase(pd);
        }
      }
    });
  }

  Future<void> buy(ProductDetails details) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: details));

  Future<void> restore() => _iap.restorePurchases();

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

final iapServiceProvider = Provider<IapService>((ref) {
  final s = IapService();
  ref.onDispose(s.dispose);
  return s;
});
