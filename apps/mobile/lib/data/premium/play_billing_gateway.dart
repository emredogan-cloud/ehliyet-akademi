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
/// `POST /api/iap/validate` ile sunucuda doğrulanır. Sunucu ÇAPRAZ CİHAZ senkronunun kaynağıdır;
/// erişimin açılması ona bağlı DEĞİLDİR (Faz 2 — bkz. `StorePurchaseStore`).
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

  /// Faz 2 — "Satın Alımı Geri Yükle" ARTIK GERÇEKTEN SONUÇ DÖNDÜRÜR.
  ///
  /// KÖK NEDEN (eski davranış): `restorePurchases()` çağrılıyor ve HEMEN `BillingSuccess([])`
  /// dönülüyordu. Geri yüklenen satın almalar ise satın alma AKIŞINDAN, birkaç yüz milisaniye
  /// sonra geliyordu. Ödeme ekranı bu boş sonucu alıp sahipliği o anda okuyor ve — henüz hiçbir
  /// şey gelmediği için — "Geri yüklenecek bir satın alma bulunamadı" diyordu. Yani geri yükleme
  /// çalışıyordu; ekran ONU BEKLEMİYORDU.
  ///
  /// Düzeltme: akıştan gelen `restored` olayları toplanır ve sonuç ONLARLA döner. Bekleme
  /// sınırlıdır ([_restoreWindow]) — mağaza sessiz kalırsa kullanıcı süresiz beklemez; o durumda
  /// boş liste döner ve ekran dürüst "bulunamadı" der.
  @override
  Future<BillingResult> restore() async {
    final collector = <BillingPurchase>[];
    _restoreCollector = collector;
    try {
      await _iap.restore();
    } catch (_) {
      _restoreCollector = null;
      return const BillingFailure('Satın almalar geri yüklenemedi.');
    }

    // Akış tek seferde gelmeyebilir: ilk olaydan sonra kısa bir sessizlik penceresi beklenir.
    final deadline = DateTime.now().add(_restoreWindow);
    var lastCount = -1;
    var quietRounds = 0;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (collector.length != lastCount) {
        lastCount = collector.length;
        quietRounds = 0;
      } else if (collector.isNotEmpty && ++quietRounds >= 3) {
        break; // bir şeyler geldi ve ~450 ms'dir yenisi yok → bitti say.
      }
    }
    _restoreCollector = null;
    return BillingSuccess(List.unmodifiable(collector));
  }

  /// Geri yükleme sırasında akıştan gelenleri toplayan geçici sepet (yoksa toplama yapılmaz).
  List<BillingPurchase>? _restoreCollector;

  /// Geri yükleme için beklenecek en uzun süre. Mağaza yanıtı tipik olarak <1 sn'de gelir;
  /// 6 sn, yavaş ağda bile yeterli ve kullanıcıyı kilitlemeyecek kadar kısa.
  static const _restoreWindow = Duration(seconds: 6);

  /// `in_app_purchase` bir yetki/yaşam döngüsü kaydı TUTMAZ — sahiplik SUNUCUDAN türetilir
  /// (`GET /api/purchases`). Bu yüzden burada dürüstçe boş liste döner; uydurma bir yaşam döngüsü
  /// durumu üretilmez. Ödeme ekranı yetkiyi `entitlementsProvider` üzerinden okur.
  @override
  Future<List<EntitlementFacts>> entitlementFacts() async => const [];

  @override
  Future<Set<String>> entitlements() async => const {};

  @override
  void listen(
    Future<void> Function(BillingPurchase) onPurchase, {
    Future<void> Function(BillingFailure)? onError,
  }) {
    _iap.listen(
      (pd) async {
        final purchase = BillingPurchase(
          storeProductId: pd.productID,
          purchaseToken: pd.verificationData.serverVerificationData,
        );
        // Geri yükleme sürüyorsa sonucu ONA da yaz; ekran boş liste görmesin.
        _restoreCollector?.add(purchase);
        await onPurchase(purchase);
      },
      onError: (e) async {
        // "Zaten sahipsin" bir ÇIKMAZ DEĞİL: satın alma gerçekten var demektir. Doğru davranış
        // kullanıcıya hata göstermek değil, geri yüklemeyi tetiklemektir — bunu çağıran yapar.
        if (isAlreadyOwnedError(e)) {
          await onError?.call(const BillingFailure(_alreadyOwnedMessage, alreadyOwned: true));
          return;
        }
        await onError?.call(BillingFailure(e.message.isEmpty ? 'Satın alma tamamlanamadı.' : e.message));
      },
    );
  }

  @override
  void dispose() => _iap.dispose();
}

/// "Zaten sahipsin" durumunda kullanıcıya gösterilecek metin. Ekran bunu görünce geri yüklemeyi
/// KENDİSİ tetikler; kullanıcıdan bir şey yapması istenmez.
const String _alreadyOwnedMessage = 'Bu paketi zaten satın almışsın — erişimin geri getiriliyor…';

/// Katalogdaki tek premium ürünün mağaza kimliği — ödeme ekranı hangi ürünü arayacağını bilsin diye.
String get primaryStoreProductId => premiumProduct.storeProductId;
