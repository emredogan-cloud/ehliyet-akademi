import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config.dart';
import '../../core/theme/tokens.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../data/premium/iap_service.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/premium/products.dart';

/// Premium paywall — ürün kataloğu (tek seferlik, ömür boyu), satın al + geri yükle.
/// Gerçek satın alma Play Store'a bağlıdır (bu ortamda test edilemez — mağaza kullanılamıyorsa
/// bilgilendirilir; sahiplik/geri yükleme sunucudan çalışır).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.highlightProductId});
  final String? highlightProductId;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late final IapService _iap;
  bool _loading = true;
  bool _storeAvailable = false;
  Map<String, ProductDetails> _details = const {};
  String? _busyProductId;

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
      final owned = await ref
          .read(entitlementsApiProvider)
          .validatePurchase(
            productId: serverId,
            purchaseToken: pd.verificationData.serverVerificationData,
            packageName: AppConfig.androidPackage,
          );
      await ref.read(entitlementsProvider.notifier).applyOwned(owned);
      if (mounted) {
        setState(() => _busyProductId = null);
        _snack('Satın alma başarılı — kilit açıldı 🎉');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busyProductId = null);
        _snack('Doğrulama başarısız. Daha sonra "Geri yükle" ile tekrar dene.');
      }
    }
  }

  Future<void> _buy(Product product) async {
    final pd = _details[product.storeProductId];
    if (pd == null) {
      _snack('Mağaza şu an kullanılamıyor. Lütfen daha sonra tekrar dene.');
      return;
    }
    setState(() => _busyProductId = product.id);
    try {
      await _iap.buy(pd);
    } catch (_) {
      if (mounted) {
        setState(() => _busyProductId = null);
        _snack('Satın alma başlatılamadı.');
      }
    }
  }

  Future<void> _restore() async {
    await _iap.restore();
    await ref.read(entitlementsProvider.notifier).refresh();
    _snack('Satın almalar geri yüklendi.');
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final owned = ref.watch(entitlementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        actions: [
          TextButton(onPressed: _restore, child: const Text('Geri yükle')),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s3,
                  AppSpacing.s4,
                  AppSpacing.s10,
                ),
                children: [
                  const AppPageHeader(
                    title: 'Premium',
                    emoji: '⭐',
                    subtitle: 'Tek seferlik öde, ömür boyu erişim. Abonelik yok.',
                  ),
                  if (!_storeAvailable)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.s3),
                      child: AppCallout(
                        tone: CalloutTone.warning,
                        title: 'Mağaza kullanılamıyor',
                        text:
                            'Uygulama-içi satın alma yalnız Google Play üzerinden yüklenmiş sürümde çalışır. '
                            'Sahip olduğun paketleri "Geri yükle" ile getirebilirsin.',
                      ),
                    ),
                  for (final product in _sorted()) ...[
                    _ProductCard(
                      product: product,
                      priceLabel: _details[product.storeProductId]?.price ?? '${product.priceTRY} ₺',
                      owned: owned.contains(product.id),
                      busy: _busyProductId == product.id,
                      enabled: _storeAvailable && _busyProductId == null,
                      highlighted: product.id == widget.highlightProductId,
                      onBuy: () => _buy(product),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'Ödeme Google Play üzerinden alınır. Kesin ve güncel kural için MEB/MTSK esastır.',
                    style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }

  List<Product> _sorted() {
    final list = [...products];
    list.sort((a, b) {
      if (a.highlight != b.highlight) return a.highlight ? -1 : 1;
      return b.priceTRY.compareTo(a.priceTRY);
    });
    return list;
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.priceLabel,
    required this.owned,
    required this.busy,
    required this.enabled,
    required this.highlighted,
    required this.onBuy,
  });
  final Product product;
  final String priceLabel;
  final bool owned;
  final bool busy;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      accent: highlighted ? p.accent : (owned ? p.green : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(product.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              if (product.highlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text('EN AVANTAJLI',
                      style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(product.blurb, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35)),
          const SizedBox(height: AppSpacing.s3),
          for (final f in product.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 15, color: p.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f, style: TextStyle(color: p.text2, fontSize: 13, height: 1.35)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Text(priceLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: p.text)),
              Text('  · tek seferlik', style: TextStyle(color: p.text3, fontSize: 12)),
              const Spacer(),
              if (owned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 8),
                  decoration: BoxDecoration(
                    color: p.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 16, color: p.green),
                      const SizedBox(width: 4),
                      Text('Sahipsin',
                          style: TextStyle(color: p.green, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                )
              else
                FilledButton(
                  onPressed: enabled ? onBuy : null,
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Satın al'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
