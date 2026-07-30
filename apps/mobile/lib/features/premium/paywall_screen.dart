import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/analytics_ref.dart';
import '../../core/assets.dart';
import '../../core/config.dart';
import '../../core/observability/error_report.dart';
import '../../core/observability/error_reporter.dart';
import '../../core/theme/tokens.dart';
import '../../data/premium/billing_gateway.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/primitives.dart';
import '../../domain/auth/auth_controller.dart';
import '../../domain/premium/entitlement_status.dart';
import '../../domain/premium/products.dart';
import '../../domain/premium/paywall_offer.dart';
import 'paywall_sections.dart';
import 'premium_popups.dart';


/// Premium paywall — TEK ürün: "Komple Ehliyet Paketi" (399 ₺, tek seferlik / ömür boyu). Satın al +
/// geri yükle. Gerçek satın alma Play Store'a bağlıdır (bu ortamda test edilemez — mağaza
/// kullanılamıyorsa dürüstçe bilgilendirilir; sahiplik/geri yükleme sunucudan çalışır).
///
/// Beta Faz 3: ekran artık somut bir ödeme eklentisine değil, [BillingGateway] soyutlamasına bağlı.
/// Etkin ağ geçidi derleme zamanı anahtarına göre seçilir (RevenueCat varsa o, yoksa mevcut
/// `in_app_purchase` yolu). **Ekran hangisinin etkin olduğunu bilmez** — yalnız sözleşmeyi kullanır.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source = 'unknown'});

  /// Beta Faz 3 — ödeme ekranına HANGİ yüzeyden gelindi (`/premium?from=...`).
  ///
  /// Bu bilgi ekranın kendisinde YOKTUR; yalnız çağıran bilir. Dönüşümü ayıran tek boyut da
  /// budur: Ana Sayfa kartından gelen ile kilitli derste duvara toslayıp gelen aynı kullanıcı
  /// değildir. Gezinme gözlemcisiyle türetmek denendi ve bırakıldı — uygulamanın sekme kabuğunda
  /// bu geçişlerin hiçbiri rota İTMİYOR, dolayısıyla gözlemci kaynağı göremiyor.
  final String source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late final BillingGateway _billing;
  bool _loading = true;
  bool _storeAvailable = false;
  List<BillingProduct> _products = const [];
  bool _busy = false;

  /// Sağlayıcının bildirdiği yaşam döngüsü (iptal / ödemesiz dönem / hesap beklemesi).
  /// `in_app_purchase` yolunda sağlayıcı bu bilgiyi taşımaz → [PremiumLifecycle.none] kalır ve
  /// hiçbir şey gösterilmez (uydurma durum üretilmez).
  PremiumLifecycle _lifecycle = PremiumLifecycle.none;

  Product get _product => premiumProduct;

  /// Kampanya bilgisi (üstü çizili fiyat + geri sayım). Yapılandırılmadıysa ikisi de KAPALI —
  /// gerekçe `PaywallOffer` sınıf notunda.
  final PaywallOffer _offer = PaywallOffer.fromEnvironment();

  /// Mağazadan gelen ürün — yoksa null (mağaza kapalı ya da ürün Play'de tanımlı değil).
  BillingProduct? get _storeProduct {
    for (final p in _products) {
      if (p.storeProductId == _product.storeProductId) return p;
    }
    return _products.isEmpty ? null : _products.first;
  }

  @override
  void initState() {
    super.initState();
    _billing = ref.read(billingGatewayProvider);
    _billing.listen(
      _onPurchase,
      onError: _onStoreError,
      onCancelled: _onStoreCancelled,
      onPending: _onStorePending,
    );
    _loadStore();
    ref.track(AnalyticsEvent.premiumScreenViewed(source: widget.source));
  }

  /// Beta Faz 2 — kullanıcı Play sayfasını KAPATTI.
  ///
  /// KÖK NEDEN: `purchase()` asenkron sözleşme gereği hemen `BillingSuccess([])` döner ve ekran
  /// "sonuç akıştan gelecek" diye beklemeye geçer. Vazgeçme akıştan `canceled` olarak geliyordu
  /// ama `IapService` onu SESSİZCE DÜŞÜRÜYORDU → bekleme hiç bitmiyor, düğme sonsuza kadar
  /// dönüyordu. Sahte ağ geçidi `purchase()` içinden `BillingCancelled` döndürdüğü için testler
  /// bu yolu hiç geçmemişti.
  ///
  /// Vazgeçme HATA DEĞİLDİR: mesaj gösterilmez, yalnız bekleme biter (Faz 2'nin genel kalıbı).
  Future<void> _onStoreCancelled() async {
    if (!mounted) return;
    ref.track(
      AnalyticsEvent.purchaseAbandoned(productId: _product.storeProductId, reason: 'cancelled'),
    );
    setState(() {
      _busy = false;
      _celebrateNextGrant = false;
    });
  }

  /// Beta Faz 2 — satın alma BEKLEMEDE (nakit ödeme / operatör faturası).
  ///
  /// Play bu durumu `PurchaseStatus.pending` ile bildirir ve **para henüz alınmamıştır**. İki kural:
  ///
  /// · **Hak VERİLMEZ.** Ödenmemiş bir satın almaya erişim açmak, ödeme hiç tamamlanmazsa
  ///   geri alınması gereken bir hak yaratır.
  /// · **Kullanıcıya SÖYLENİR.** Sessiz kalmak en kötü seçenek: kullanıcı ödeme talimatını
  ///   vermiştir, uygulamada hiçbir şey değişmemiştir ve "param gitti mi?" diye sorar.
  ///
  /// Ödeme tamamlandığında Play işlemi akıştan TEKRAR gönderir; normal `_onPurchase` yolu işler ve
  /// onay (acknowledge) ancak o zaman verilir.
  Future<void> _onStorePending(BillingPurchase purchase) async {
    if (!mounted) return;
    ref.track(
      AnalyticsEvent.purchaseAbandoned(productId: purchase.storeProductId, reason: 'pending'),
    );
    setState(() {
      _busy = false;
      _celebrateNextGrant = false;
    });
    _snack(
      'Ödemen onay bekliyor. Onaylandığında premium kendiliğinden açılır — '
      'uygulamayı tekrar açman yeterli.',
    );
  }

  /// Faz 2 — mağaza akışından gelen HATA.
  ///
  /// "Bu ürüne zaten sahipsin" bir çıkmaz değildir: satın almanın gerçekten var olduğunun
  /// kanıtıdır. Eski davranışta bu olay hiç dinlenmiyordu; kullanıcı düğmeye basıyor, Play
  /// "zaten sahipsin" diyor ve ekranda HİÇBİR ŞEY olmuyordu. Artık geri yükleme kendiliğinden
  /// tetiklenir — kullanıcıdan bir şey yapması istenmez.
  Future<void> _onStoreError(BillingFailure failure) async {
    if (!mounted) return;
    // "Zaten sahipsin" bir vazgeçme DEĞİLDİR (satın alma zaten var) → terk olarak sayılmaz.
    if (!failure.alreadyOwned) {
      // Beta Faz 4 — mağaza hatası GÖZLEMLENEBİLİR olmalı. Ödeme, kırıldığında kullanıcının
      // şikâyet ETMEDİĞİ ve sessizce vazgeçtiği yerdir; sahadan haber gelmesini beklemek
      // gelir kaybını görmemek demektir.
      ref
          .read(errorReporterProvider)
          .report(
            StateError(failure.message),
            StackTrace.current,
            kind: ErrorKind.store,
            extra: {'gateway': _billing.name, 'product': _product.storeProductId},
          )
          .ignore();
      ref.track(
        AnalyticsEvent.purchaseAbandoned(productId: _product.storeProductId, reason: 'error'),
      );
    }
    setState(() => _busy = false);
    _snack(failure.message);
    if (failure.alreadyOwned) await _restore(silent: true);
  }

  Future<void> _loadStore() async {
    try {
      final available = await _billing.available();
      final products = available ? await _billing.products() : const <BillingProduct>[];
      final facts = await _billing.entitlementFacts();
      if (mounted) {
        setState(() {
          _storeAvailable = available && products.isNotEmpty;
          _products = products;
          _lifecycle = premiumLifecycleFor(facts, AppConfig.revenueCatEntitlement);
          _loading = false;
        });
      }
    } catch (_) {
      // Ağ geçidi zaten fırlatmamalı; yine de ekran hiçbir koşulda çökmez.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tamamlanmış bir satın almayı sahipliğe çevir.
  ///
  /// İKİ SUNUCU KÖPRÜSÜ VARDIR ve ikisinde de **yetkinin kaynağı sunucudur**:
  /// · [BillingServerBridge.clientReceipt] — Play makbuzu `POST /api/iap/validate` ile doğrulanır.
  /// · [BillingServerBridge.revenueCatWebhook] — sunucu yetkiyi RevenueCat webhook'undan alır;
  ///   istemcide ham makbuz yoktur, bu yüzden sahiplik sunucudan **tazelenir**.
  Future<void> _onPurchase(BillingPurchase purchase) async {
    // SIRA DEĞİŞTİ (Faz 2): önce erişim açılır, sonra sunucuya bağlanmaya çalışılır.
    //
    // Eski sıra tam tersiydi ve misafir kullanıcıda şu zinciri üretiyordu: Play ödemeyi alır →
    // `POST /api/iap/validate` **401** → istisna → hak HİÇ verilmez → özellikler kilitli kalır.
    // Kullanıcı para ödemiş ama uygulama bunu göremiyordu. Artık mağazanın onayladığı satın alma
    // cihaza yazılır ve erişim anında açılır; sunucuya bağlama başarısız olursa makbuz kuyrukta
    // bekler ve oturum açılınca/uygulama açılınca yeniden denenir.
    final bound = await ref
        .read(entitlementsProvider.notifier)
        .grantFromStore(
          storeProductId: purchase.storeProductId,
          purchaseToken: purchase.purchaseToken,
          nowMs: DateTime.now().millisecondsSinceEpoch,
        );
    // RevenueCat yolunda ham makbuz YOKTUR; sahiplik sunucudan tazelenir.
    if (!bound && purchase.purchaseToken == null) {
      await ref.read(entitlementsProvider.notifier).refresh();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    // Satın alma mı geri yükleme mi olduğunu `_celebrateNextGrant` ayırır: yalnız kullanıcının
    // BAŞLATTIĞI akış bir satın almadır. Geri yüklemede bu olay gönderilmez, yoksa her geri
    // yükleme yeni bir satın alma gibi sayılırdı.
    if (_celebrateNextGrant) {
      ref.track(
        AnalyticsEvent.purchaseCompleted(
          productId: purchase.storeProductId,
          guest: !ref.read(authControllerProvider).isAuthenticated,
        ),
      );
    }
    // Kutlama YALNIZ satın alma anında; sessiz geri yüklemede pencere açılmaz.
    if (_celebrateNextGrant) {
      _celebrateNextGrant = false;
      await showPremiumSuccess(context);
    }
  }

  /// Bir sonraki hak verilişinde kutlama penceresi açılsın mı? (Satın alma → evet, açılışta
  /// gelen bekleyen bir işlem → hayır.)
  bool _celebrateNextGrant = false;

  Future<void> _buy() async {
    final product = _storeProduct;
    if (product == null) {
      _snack('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
      return;
    }
    setState(() {
      _busy = true;
      _celebrateNextGrant = true;
    });
    ref.track(AnalyticsEvent.purchaseStarted(productId: product.storeProductId));
    final result = await _billing.purchase(product);
    if (!mounted) return;
    switch (result) {
      // Sonuç satın alma akışından (listen) gelebilir; başarı orada işlenir.
      case BillingSuccess(:final purchases):
        if (purchases.isEmpty) return;
        for (final p in purchases) {
          await _onPurchase(p);
        }
      // Vazgeçme HATA DEĞİLDİR — mesaj gösterilmez (Faz 2 kalıbı).
      case BillingCancelled():
        setState(() {
          _busy = false;
          _celebrateNextGrant = false;
        });
      case BillingFailure(:final message, :final alreadyOwned):
        setState(() {
          _busy = false;
          _celebrateNextGrant = false;
        });
        _snack(message);
        // "Zaten sahipsin" → kullanıcıyı bir çıkmazda bırakma, erişimi kendin getir.
        if (alreadyOwned) await _restore(silent: true);
    }
  }

  /// **Play politikası: "Satın Alımı Geri Yükle" her koşulda erişilebilir olmalıdır.** Bu yüzden
  /// düğme mağaza kapalıyken de görünür — sahiplik sunucudan da gelebilir.
  /// Faz 2 — geri yükleme ARTIK GERÇEKTEN ÇALIŞIYOR.
  ///
  /// İki kök neden vardı ve ikisi de düzeltildi:
  /// 1. `PlayBillingGateway.restore()` mağazayı beklemeden boş sonuç dönüyordu; ekran bu boşluğa
  ///    bakıp "bulunamadı" diyordu (bkz. o dosyadaki not).
  /// 2. Sonuç yalnız SUNUCUDAN okunuyordu; misafirde sunucu 401 döndüğü için geri yüklenen
  ///    satın alma hiçbir zaman görünmüyordu.
  ///
  /// [silent] true ise ("zaten sahipsin" sonrası otomatik çağrı) yalnız başarı bildirilir;
  /// kullanıcı istemediği bir işlem için hata mesajı görmez.
  Future<void> _restore({bool silent = false}) async {
    if (_restoring) return;
    setState(() => _restoring = true);
    final result = await _billing.restore();

    // Mağazanın geri yüklediği her satın alma cihaza yazılır → erişim oturum olmadan da açılır.
    if (result case BillingSuccess(:final purchases)) {
      for (final p in purchases) {
        await ref
            .read(entitlementsProvider.notifier)
            .grantFromStore(
              storeProductId: p.storeProductId,
              purchaseToken: p.purchaseToken,
              nowMs: DateTime.now().millisecondsSinceEpoch,
            );
      }
    }
    // Sunucu tarafı da tazelenir (başka cihazda alınmış olabilir) ve bekleyen makbuzlar bağlanır.
    await ref.read(entitlementsProvider.notifier).refresh();
    await ref.read(entitlementsProvider.notifier).bindPendingPurchases();

    if (!mounted) return;
    setState(() => _restoring = false);
    ref.track(
      AnalyticsEvent.restorePurchases(
        found: switch (result) {
          BillingSuccess(:final purchases) => purchases.length,
          _ => 0,
        },
      ),
    );
    switch (result) {
      case BillingFailure(:final message):
        if (!silent) _snack(message);
      case BillingCancelled():
        break;
      case BillingSuccess():
        final owned = ref.read(entitlementsProvider);
        if (isPremium(owned)) {
          _snack('Satın almaların geri yüklendi.');
        } else if (!silent) {
          _snack('Geri yüklenecek bir satın alma bulunamadı.');
        }
    }
  }

  /// Geri yükleme sürüyor mu (düğme iki kez basılmasın, durum görünsün).
  bool _restoring = false;

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(entitlementsProvider);
    final hasPremium = isPremium(owned);
    final priceLabel = _storeProduct?.priceLabel ?? '₺${_product.priceTRY}';
    final lifecycleMessage = premiumLifecycleMessage(_lifecycle);

    return Scaffold(
      // Referanstaki üst şerit: solda geri, sağda kapat. Başlık YOK — hero'nun kendi başlığı var
      // ve iki başlık üst üste binerdi.
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        // Play politikası: geri yükleme her koşulda erişilebilir olmalı → koşulsuz eylem.
        actions: [
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: _restoring
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Geri yükle'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  0,
                  AppSpacing.s4,
                  AppSpacing.s8,
                ),
                children: [
                  _PaywallHeadline(hasPremium: hasPremium),
                  const SizedBox(height: AppSpacing.s4),
                  const _PaywallHero(),
                  const SizedBox(height: AppSpacing.s5),
                  const PaywallFeatureStrip(),
                  const SizedBox(height: AppSpacing.s4),
                  PaywallChecklist(features: _product.features),
                  const SizedBox(height: AppSpacing.s5),

                  // Yaşam döngüsü uyarısı — yalnız sağlayıcı gerçekten bir durum bildirdiyse.
                  if (lifecycleMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                      child: AppCallout(
                        tone: _lifecycle.grantsAccess ? CalloutTone.info : CalloutTone.warning,
                        title: _lifecycle.needsUserAction ? 'Ödeme sorunu' : 'Abonelik durumu',
                        text: lifecycleMessage,
                      ),
                    ),
                  if (!_storeAvailable && !hasPremium)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.s4),
                      child: AppCallout(
                        tone: CalloutTone.warning,
                        title: 'Mağaza kullanılamıyor',
                        text:
                            'Uygulama-içi satın alma yalnız Google Play üzerinden yüklenmiş sürümde çalışır. '
                            'Sahip olduğun paketi "Geri yükle" ile getirebilirsin.',
                      ),
                    ),

                  // Faz 2 — SAHİPSE satın alma yüzeyi HİÇ ÇİZİLMEZ.
                  //
                  // Devre dışı bir düğme bırakmak yetmez: kullanıcı ödediği bir şeyin satış
                  // ekranını görmeye devam eder. Sahiplikte ekran bir DURUM ekranına dönüşür —
                  // fiyat, sayaç, satın alma düğmesi ve güven şeridi kalkar.
                  if (hasPremium)
                    _OwnedBanner()
                  else ...[
                    PaywallPriceBlock(
                      priceLabel: priceLabel,
                      offer: _offer,
                      onBuy: _storeAvailable ? _buy : null,
                      busy: _busy,
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _TrustRow(),
                  ],
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Ödeme Google Play üzerinden alınır. Ömür boyu erişim, abonelik yok. '
                    'Kesin ve güncel kural için MEB/MTSK esastır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.text3, fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Referanstaki iki satırlık başlık: küçük büyük-harfli üst satır + büyük turkuaz vurgu.
class _PaywallHeadline extends StatelessWidget {
  const _PaywallHeadline({required this.hasPremium});
  final bool hasPremium;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(
          hasPremium ? 'PAKETİN AKTİF' : 'TÜM POTANSİYELİNİ AÇ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: p.text2,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            hasPremium ? 'İYİ ÇALIŞMALAR!' : 'SINAVA HAZIR OL!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.primary,
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text.rich(
          TextSpan(
            style: TextStyle(color: p.text2, fontSize: 14, height: 1.45),
            children: [
              const TextSpan(text: 'Komple Ehliyet Paketi ile tüm konulara sınırsız eriş, '),
              TextSpan(
                text: 'sınavda bir adım önde',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' ol!'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Hero — taç madalyonu + araç + "KOMPLE EHLİYET PAKETİ" şeridi.
///
/// Bu, referansın TEK raster parçasıdır (`tool/extract_paywall_hero.py` notuna bakın): sanat
/// widget'la yeniden çizilemez, mockup ise raster olarak sevk edilmez.
class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Komple Ehliyet Paketi',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Image.asset(
          AppImages.paywallHero,
          fit: BoxFit.cover,
          // Gösterim genişliğine indirilir (bellek); 2× cihaz oranına kadar keskin.
          cacheWidth: 1080,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(IconData i, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 15, color: p.green),
            const SizedBox(width: 5),
            Text(t, style: TextStyle(color: p.text3, fontSize: 11.5)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item(Icons.verified_user_rounded, '7 gün iade'),
        item(Icons.lock_rounded, '%100 Güvenli'),
        item(Icons.all_inclusive_rounded, 'Ömür boyu'),
      ],
    );
  }
}

/// Sahiplik durumu — satın alma düğmesinin YERİNE geçer.
///
/// Faz 2 gereği düğme "Premium Aktif"e döner ve BASILAMAZ. Devre dışı bir düğme bırakmak yerine
/// aynı yerde aynı boyutta bir DURUM göstergesi çizilir: kullanıcı aradığı yerde cevabı bulur,
/// ama tıklanacak bir şey olmadığı da bakışta bellidir.
class _OwnedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Semantics(
          label: 'Premium Aktif',
          enabled: false,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: p.green.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: p.green.withValues(alpha: 0.55), width: 1.6),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: p.green, size: 21),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  'Premium Aktif',
                  style: TextStyle(
                    color: p.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Tüm içerik açık — ömür boyu. İyi çalışmalar!',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4),
        ),
      ],
    );
  }
}
