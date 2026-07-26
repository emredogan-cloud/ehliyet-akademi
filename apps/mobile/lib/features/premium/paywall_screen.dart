import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets.dart';
import '../../core/config.dart';
import '../../core/theme/tokens.dart';
import '../../data/premium/billing_gateway.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/premium/entitlement_status.dart';
import '../../domain/premium/products.dart';
import 'premium_popups.dart';


/// Premium paywall — TEK ürün: "Komple Ehliyet Paketi" (399 ₺, tek seferlik / ömür boyu). Satın al +
/// geri yükle. Gerçek satın alma Play Store'a bağlıdır (bu ortamda test edilemez — mağaza
/// kullanılamıyorsa dürüstçe bilgilendirilir; sahiplik/geri yükleme sunucudan çalışır).
///
/// Beta Faz 3: ekran artık somut bir ödeme eklentisine değil, [BillingGateway] soyutlamasına bağlı.
/// Etkin ağ geçidi derleme zamanı anahtarına göre seçilir (RevenueCat varsa o, yoksa mevcut
/// `in_app_purchase` yolu). **Ekran hangisinin etkin olduğunu bilmez** — yalnız sözleşmeyi kullanır.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

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
    _billing.listen(_onPurchase);
    _loadStore();
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
    try {
      final token = purchase.purchaseToken;
      if (token != null && token.isNotEmpty) {
        final serverId =
            productByStoreId(purchase.storeProductId)?.id ??
            purchase.storeProductId.replaceAll('_', '-');
        final owned = await ref
            .read(entitlementsApiProvider)
            .validatePurchase(
              productId: serverId,
              purchaseToken: token,
              packageName: AppConfig.androidPackage,
            );
        await ref.read(entitlementsProvider.notifier).applyOwned(owned);
      } else {
        await ref.read(entitlementsProvider.notifier).refresh();
      }
      if (mounted) {
        setState(() => _busy = false);
        await showPremiumSuccess(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Doğrulama başarısız. Daha sonra "Geri yükle" ile tekrar dene.');
      }
    }
  }

  Future<void> _buy() async {
    final product = _storeProduct;
    if (product == null) {
      _snack('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
      return;
    }
    setState(() => _busy = true);
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
        setState(() => _busy = false);
      case BillingFailure(:final message):
        setState(() => _busy = false);
        _snack(message);
    }
  }

  /// **Play politikası: "Satın Alımı Geri Yükle" her koşulda erişilebilir olmalıdır.** Bu yüzden
  /// düğme mağaza kapalıyken de görünür — sahiplik sunucudan da gelebilir.
  Future<void> _restore() async {
    final result = await _billing.restore();
    await ref.read(entitlementsProvider.notifier).refresh();
    if (!mounted) return;
    switch (result) {
      case BillingFailure(:final message):
        _snack(message);
      case BillingCancelled():
        break;
      case BillingSuccess():
        final owned = ref.read(entitlementsProvider);
        _snack(
          isPremium(owned)
              ? 'Satın almaların geri yüklendi.'
              : 'Geri yüklenecek bir satın alma bulunamadı.',
        );
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final owned = ref.watch(entitlementsProvider);
    final hasPremium = isPremium(owned);
    final priceLabel = _storeProduct?.priceLabel ?? '₺${_product.priceTRY}';
    final lifecycleMessage = premiumLifecycleMessage(_lifecycle);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium'a Geç"),
        // Play politikası: geri yükleme her koşulda erişilebilir olmalı → koşulsuz eylem.
        actions: [
          TextButton(
            onPressed: _restore,
            child: const Text('Geri yükle'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s3, AppSpacing.s5, AppSpacing.s6),
                children: [
                  Center(child: MascotImage(AppImages.illLockGold, height: 168, semanticLabel: 'Premium')),
                  const SizedBox(height: AppSpacing.s2),
                  Center(
                    child: BrandChip(
                      label: hasPremium ? 'PREMIUM AKTİF' : "KOMPLE PAKET",
                      icon: Icons.workspace_premium_rounded,
                      color: context.palette.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    _product.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    _product.blurb,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text2, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  _FeatureCard(product: _product),
                  const SizedBox(height: AppSpacing.s4),
                  // Yaşam döngüsü uyarısı — yalnız sağlayıcı gerçekten bir durum bildirdiyse.
                  if (lifecycleMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                      child: AppCallout(
                        tone: _lifecycle.grantsAccess ? CalloutTone.info : CalloutTone.warning,
                        title: _lifecycle.needsUserAction ? 'Ödeme sorunu' : 'Abonelik durumu',
                        text: lifecycleMessage,
                      ),
                    ),
                  if (!_storeAvailable && !hasPremium)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.s3),
                      child: AppCallout(
                        tone: CalloutTone.warning,
                        title: 'Mağaza kullanılamıyor',
                        text: 'Uygulama-içi satın alma yalnız Google Play üzerinden yüklenmiş sürümde çalışır. '
                            'Sahip olduğun paketi "Geri yükle" ile getirebilirsin.',
                      ),
                    ),
                  if (hasPremium)
                    _OwnedBanner()
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(priceLabel, style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 34)),
                        const SizedBox(width: 6),
                        Text('· tek seferlik', style: TextStyle(color: p.text3, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    GradientPillButton(
                      label: 'Paketi Satın Al',
                      gold: true,
                      loading: _busy,
                      leading: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      onPressed: _storeAvailable ? _buy : null,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    _TrustRow(),
                  ],
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    'Ödeme Google Play üzerinden alınır. Ömür boyu erişim, abonelik yok. '
                    'Kesin ve güncel kural için MEB/MTSK esastır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in product.features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 16, color: p.primary),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
        ],
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

class _OwnedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: p.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: p.green, size: 22),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              'Premium paketine sahipsin — tüm içerik açık. İyi çalışmalar!',
              style: TextStyle(color: p.text, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
