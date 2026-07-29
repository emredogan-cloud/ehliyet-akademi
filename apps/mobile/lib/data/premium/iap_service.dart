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
  ///
  /// Faz 2 — [onError] EKLENDİ. Eskiden yalnız `purchased`/`restored` işleniyor, `error` sessizce
  /// düşürülüyordu. Play'in "bu ürüne zaten sahipsin" yanıtı da bir `error` olayıdır; yutulduğu
  /// için kullanıcı düğmeye basıyor ve HİÇBİR ŞEY olmuyordu.
  void listen(
    Future<void> Function(PurchaseDetails) onPurchased, {
    Future<void> Function(IAPError error)? onError,
  }) {
    _sub ??= _iap.purchaseStream.listen((purchases) async {
      for (final pd in purchases) {
        if (pd.status == PurchaseStatus.purchased || pd.status == PurchaseStatus.restored) {
          await onPurchased(pd);
        } else if (pd.status == PurchaseStatus.error && pd.error != null) {
          await onError?.call(pd.error!);
        }
        // Tamamlama HER KOŞULDA: işlenmemiş bir işlem Play tarafında "beklemede" kalır ve
        // sonraki satın alma denemesi de aynı yerde takılır.
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

/// Play'in "bu ürüne zaten sahipsin" yanıtı mı?
///
/// `in_app_purchase` bu durumu Android'de [IAPError] içinde taşır; kod/metin sürümler arasında
/// değişebildiği için üç alana birden bakılır. Yanlış pozitif ZARARSIZDIR: sonucu bir geri yükleme
/// denemesidir ve geri yükleme her koşulda güvenlidir (idempotent).
bool isAlreadyOwnedError(IAPError e) {
  final haystack = '${e.code} ${e.message} ${e.details}'.toLowerCase();
  return haystack.contains('itemalreadyowned') ||
      haystack.contains('item_already_owned') ||
      haystack.contains('already owned');
}

final iapServiceProvider = Provider<IapService>((ref) {
  final s = IapService();
  ref.onDispose(s.dispose);
  return s;
});
