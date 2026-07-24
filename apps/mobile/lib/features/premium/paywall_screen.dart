import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/assets.dart';
import '../../core/config.dart';
import '../../core/theme/tokens.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../data/premium/iap_service.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/premium/products.dart';
import 'premium_popups.dart';

const _kGold = Color(0xFFF5A623);

/// Premium paywall — TEK ürün: "Komple Ehliyet Paketi" (399 ₺, tek seferlik / ömür boyu). Satın al +
/// geri yükle. Gerçek satın alma Play Store'a bağlıdır (bu ortamda test edilemez — mağaza
/// kullanılamıyorsa dürüstçe bilgilendirilir; sahiplik/geri yükleme sunucudan çalışır).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late final IapService _iap;
  bool _loading = true;
  bool _storeAvailable = false;
  Map<String, ProductDetails> _details = const {};
  bool _busy = false;

  Product get _product => premiumProduct;

  @override
  void initState() {
    super.initState();
    _iap = ref.read(iapServiceProvider);
    _iap.listen(_onPurchased);
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final available = await _iap.available();
      final details = available ? await _iap.queryProducts() : <String, ProductDetails>{};
      if (mounted) {
        setState(() {
          _storeAvailable = available && details.isNotEmpty;
          _details = details;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onPurchased(PurchaseDetails pd) async {
    try {
      final serverId = productByStoreId(pd.productID)?.id ?? pd.productID.replaceAll('_', '-');
      final owned = await ref.read(entitlementsApiProvider).validatePurchase(
            productId: serverId,
            purchaseToken: pd.verificationData.serverVerificationData,
            packageName: AppConfig.androidPackage,
          );
      await ref.read(entitlementsProvider.notifier).applyOwned(owned);
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
    final pd = _details[_product.storeProductId];
    if (pd == null) {
      _snack('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _iap.buy(pd);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Satın alma başlatılamadı.');
      }
    }
  }

  Future<void> _restore() async {
    await _iap.restore();
    await ref.read(entitlementsProvider.notifier).refresh();
    _snack('Satın almalar geri yüklendi.');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final owned = ref.watch(entitlementsProvider);
    final hasPremium = isPremium(owned);
    final priceLabel = _details[_product.storeProductId]?.price ?? '₺${_product.priceTRY}';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium'a Geç"),
        actions: [TextButton(onPressed: _restore, child: const Text('Geri yükle'))],
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
                      color: _kGold,
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
