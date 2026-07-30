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
  /// Beta Faz 2 — [onCanceled] ve [onPending] EKLENDİ; onay artık KOŞULLU.
  ///
  /// ## Vazgeçme neden eklendi (gerçek, görünür hata)
  ///
  /// `PurchaseStatus.canceled` sessizce düşürülüyordu. Zincir şöyleydi: `PlayBillingGateway.purchase`
  /// akış asenkron olduğu için hemen `BillingSuccess([])` döner; ödeme ekranı boş sonucu görüp
  /// "sonuç akıştan gelecek" diye BEKLEMEYE geçer. Kullanıcı Play sayfasını kapattığında akıştan
  /// yalnız `canceled` gelir — ve o yutulduğu için ekranın beklemesi HİÇ BİTMEZ. Gerçek cihazda
  /// satın alma düğmesi sonsuza kadar dönüyordu. (Testler yeşildi: sahte ağ geçidi `purchase()`
  /// içinden `BillingCancelled` döndürüyor, yani kırılan yolu hiç kullanmıyordu.)
  ///
  /// ## Onay (acknowledge) neden koşullu oldu
  ///
  /// Eskiden `pendingCompletePurchase` doğruysa **her durumda** `completePurchase` çağrılıyordu.
  /// O alan eklentide `!isAcknowledged` olarak hesaplanır — yani **BEKLEMEDE olan** bir satın alma
  /// için de doğrudur. `completePurchase` ise doğrudan `acknowledgePurchase` çağırır. Sonuç: parası
  /// henüz ALINMAMIŞ bir satın alma onaylanıyordu.
  ///
  /// Google Play Billing kuralı açıktır: bekleyen bir satın alma **onaylanmaz**; onay yalnız durum
  /// `PURCHASED` olduktan sonra verilir. (Bekleyen satın alma nakit ödeme ve operatör faturasında
  /// gerçekleşir; ödeme tamamlandığında Play işlemi akıştan TEKRAR gönderir ve onay o zaman
  /// verilir.)
  void listen(
    Future<void> Function(PurchaseDetails) onPurchased, {
    Future<void> Function(IAPError error)? onError,
    Future<void> Function()? onCanceled,
    Future<void> Function(PurchaseDetails)? onPending,
  }) {
    _sub ??= _iap.purchaseStream.listen((purchases) async {
      for (final pd in purchases) {
        final completed =
            pd.status == PurchaseStatus.purchased || pd.status == PurchaseStatus.restored;
        switch (pd.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await onPurchased(pd);
          case PurchaseStatus.pending:
            await onPending?.call(pd);
          case PurchaseStatus.canceled:
            await onCanceled?.call();
          case PurchaseStatus.error:
            if (pd.error != null) await onError?.call(pd.error!);
        }
        // Onay YALNIZ tamamlanmış satın almalar için. İşlenmemiş bir TAMAMLANMIŞ işlem Play
        // tarafında askıda kalır ve sonraki satın alma denemesi de aynı yerde takılır — bu yüzden
        // burada mutlaka onaylanır. Bekleyen işlem ise onaylanmaz (yukarıdaki gerekçe).
        if (completed && pd.pendingCompletePurchase) {
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
