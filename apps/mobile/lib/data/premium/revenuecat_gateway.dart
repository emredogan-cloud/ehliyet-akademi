import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'billing_gateway.dart';

/// Beta Faz 3 — RevenueCat'in [BillingGateway] uygulaması.
///
/// YAPILANDIRMA: beş değer derleme zamanında `--dart-define` ile verilir (bkz.
/// `apps/mobile/.env.example` ve `ENV_TEMPLATE.md` §2). **Hiçbiri zorunlu değildir.**
/// `REVENUECAT_PUBLIC_KEY` verilmezse [isConfigured] false olur, bu ağ geçidi hiç seçilmez ve
/// uygulama mevcut `in_app_purchase` yolunda çalışmaya devam eder — **çökme yok**.
///
/// SUNUCU KÖPRÜSÜ — ÖNEMLİ: RevenueCat Flutter SDK'sı ham Play `purchaseToken`'ını **sunmaz**
/// (`StoreTransaction` yalnız `transactionIdentifier` taşır). Bu yüzden bu yol, mevcut
/// `POST /api/iap/validate` ucunu **yeniden kullanamaz**; RevenueCat'te doğru sunucu köprüsü
/// **webhook**'tur (RevenueCat → sunucumuz). Bu, [BillingServerBridge.revenueCatWebhook] ile
/// açıkça bildirilir ve `BETA_PHASE_3_REPORT.md`'de gerekçesiyle yazılıdır.
class RevenueCatGateway implements BillingGateway {
  RevenueCatGateway({
    String? publicKey,
    String? entitlementId,
    String? monthlyProductId,
    String? yearlyProductId,
    String? projectId,
  }) : _publicKey = publicKey ?? const String.fromEnvironment('REVENUECAT_PUBLIC_KEY'),
       entitlementId =
           entitlementId ??
           const String.fromEnvironment('REVENUECAT_ENTITLEMENT', defaultValue: 'premium'),
       monthlyProductId =
           monthlyProductId ?? const String.fromEnvironment('REVENUECAT_MONTHLY_PRODUCT'),
       yearlyProductId =
           yearlyProductId ?? const String.fromEnvironment('REVENUECAT_YEARLY_PRODUCT'),
       projectId = projectId ?? const String.fromEnvironment('REVENUECAT_PROJECT_ID');

  final String _publicKey;

  /// Uygulamanın sorduğu tek yetki. Ömür boyu paket de, aylık/yıllık abonelik de **aynı** yetkiyi
  /// açar → ürün modeli değişse bile uygulama kodu değişmez (`REVENUECAT_SETUP.md` §0).
  final String entitlementId;

  /// Aylık/yıllık abonelik ürün kimlikleri. Ürün sahibi ömür boyu modelde kalırsa **boş kalır** ve
  /// kod bunu dürüstçe karşılar — abonelik paketi hiç gösterilmez.
  final String monthlyProductId;
  final String yearlyProductId;

  /// Teşhis/kayıt amaçlı; akışta kullanılmaz.
  final String projectId;

  bool _configured = false;

  /// Offerings'ten gelen paketler — satın alma buradan yapılır (mağaza kimliğine göre).
  final Map<String, Package> _packages = {};

  CustomerInfoUpdateListener? _listener;

  @override
  String get name => 'revenuecat';

  @override
  bool get isConfigured => _publicKey.isNotEmpty;

  @override
  BillingServerBridge get serverBridge => BillingServerBridge.revenueCatWebhook;

  /// SDK'yı bir kez kur. Anahtar geçersizse burada **fırlatmaz**; false döner ve çağıran dürüst bir
  /// "kullanılamıyor" durumu gösterir.
  Future<bool> _ensureConfigured() async {
    if (_configured) return true;
    if (!isConfigured) return false;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_publicKey));
      _configured = true;
      return true;
    } catch (_) {
      // Geçersiz anahtar / eklenti yok / platform desteklemiyor → uygulama ÇÖKMEZ.
      return false;
    }
  }

  @override
  Future<bool> available() async {
    if (!await _ensureConfigured()) return false;
    try {
      return await Purchases.canMakePayments();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BillingProduct>> products() async {
    if (!await _ensureConfigured()) return const [];
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current ?? offerings.all.values.firstOrNull;
      if (offering == null) return const [];

      _packages.clear();
      final out = <BillingProduct>[];
      for (final pkg in offering.availablePackages) {
        final product = pkg.storeProduct;
        _packages[product.identifier] = pkg;
        out.add(
          BillingProduct(
            storeProductId: product.identifier,
            priceLabel: product.priceString,
            title: product.title,
            period: _periodOf(pkg),
          ),
        );
      }
      return out;
    } catch (_) {
      // Ağ yok / offering tanımlı değil / anahtar reddedildi → dürüst boş liste.
      return const [];
    }
  }

  /// Paket türünü yansız [BillingPeriod]'a çevir. Ürün kimliği eşleşmesi, RevenueCat'te paket türü
  /// `custom` bırakılmış kurulumlar için yedek yoldur.
  BillingPeriod _periodOf(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.lifetime:
        return BillingPeriod.lifetime;
      case PackageType.monthly:
        return BillingPeriod.monthly;
      case PackageType.annual:
        return BillingPeriod.yearly;
      default:
        final id = pkg.storeProduct.identifier;
        if (monthlyProductId.isNotEmpty && id == monthlyProductId) return BillingPeriod.monthly;
        if (yearlyProductId.isNotEmpty && id == yearlyProductId) return BillingPeriod.yearly;
        return BillingPeriod.unknown;
    }
  }

  @override
  Future<BillingResult> purchase(BillingProduct product) async {
    if (!await _ensureConfigured()) {
      return const BillingFailure('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
    }
    final pkg = _packages[product.storeProductId];
    if (pkg == null) {
      return const BillingFailure('Ürün bulunamadı. Ödeme ekranını yenileyip tekrar dene.');
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      return BillingSuccess([
        BillingPurchase(
          storeProductId: result.storeTransaction.productIdentifier,
          // RevenueCat ham Play token'ını sunmaz → istemci makbuzu köprüsü yoktur (sınıf notu).
          entitlements: result.customerInfo.entitlements.active.keys.toSet(),
        ),
      ]);
    } on PlatformException catch (e) {
      return _mapError(e);
    } catch (_) {
      return const BillingFailure('Satın alma tamamlanamadı.');
    }
  }

  @override
  Future<BillingResult> restore() async {
    if (!await _ensureConfigured()) {
      return const BillingFailure('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
    }
    try {
      final info = await Purchases.restorePurchases();
      final active = info.entitlements.active;
      return BillingSuccess([
        for (final e in active.values)
          BillingPurchase(
            storeProductId: e.productIdentifier,
            entitlements: active.keys.toSet(),
          ),
      ]);
    } on PlatformException catch (e) {
      return _mapError(e);
    } catch (_) {
      return const BillingFailure('Satın almalar geri yüklenemedi.');
    }
  }

  @override
  Future<List<EntitlementFacts>> entitlementFacts() async {
    if (!await _ensureConfigured()) return const [];
    try {
      final info = await Purchases.getCustomerInfo();
      return [for (final e in info.entitlements.all.values) _factsOf(e)];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Set<String>> entitlements() async {
    final facts = await entitlementFacts();
    return {
      for (final f in facts)
        if (f.isActive) f.identifier,
    };
  }

  static EntitlementFacts _factsOf(EntitlementInfo e) => EntitlementFacts(
    identifier: e.identifier,
    isActive: e.isActive,
    willRenew: e.willRenew,
    expiresAt: e.expirationDate,
    billingIssueDetectedAt: e.billingIssueDetectedAt,
    unsubscribeDetectedAt: e.unsubscribeDetectedAt,
  );

  @override
  void listen(Future<void> Function(BillingPurchase) onPurchase) {
    if (!isConfigured || _listener != null) return;
    void handler(CustomerInfo info) {
      final active = info.entitlements.active;
      if (active.isEmpty) return;
      final ids = active.keys.toSet();
      for (final e in active.values) {
        onPurchase(BillingPurchase(storeProductId: e.productIdentifier, entitlements: ids));
      }
    }

    _listener = handler;
    try {
      Purchases.addCustomerInfoUpdateListener(handler);
    } catch (_) {
      _listener = null;
    }
  }

  /// RevenueCat hata kodunu kullanıcıya gösterilecek dürüst bir sonuca çevir.
  ///
  /// **Vazgeçme HATA DEĞİLDİR** — Faz 2'deki Google girişi kalıbının aynısı.
  static BillingResult _mapError(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    return switch (code) {
      PurchasesErrorCode.purchaseCancelledError => const BillingCancelled(),
      PurchasesErrorCode.productAlreadyPurchasedError => const BillingFailure(
        'Bu ürüne zaten sahipsin. "Geri yükle" ile erişimini getirebilirsin.',
      ),
      PurchasesErrorCode.paymentPendingError => const BillingFailure(
        'Ödemen beklemede. Onaylandığında erişimin otomatik açılacak.',
      ),
      PurchasesErrorCode.purchaseNotAllowedError => const BillingFailure(
        'Bu cihazda satın almaya izin verilmiyor.',
      ),
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError => const BillingFailure(
        'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      ),
      PurchasesErrorCode.productNotAvailableForPurchaseError ||
      PurchasesErrorCode.storeProblemError => const BillingFailure(
        'Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.',
      ),
      // Yapılandırma/kimlik hataları kullanıcının düzeltebileceği şeyler değildir → tek, sade mesaj.
      _ => const BillingFailure('Satın alma tamamlanamadı.'),
    };
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener == null) return;
    _listener = null;
    try {
      Purchases.removeCustomerInfoUpdateListener(listener);
    } catch (_) {
      // Kurulmamış SDK'da kaldırma başarısız olabilir; uygulamayı engellemez.
    }
  }
}
