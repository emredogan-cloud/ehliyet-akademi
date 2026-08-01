import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/premium/billing_gateway.dart';
import '../../domain/premium/products.dart';

/// Ürün Evrimi v1.1 · Faz 10 — üç paketin yan yana seçildiği blok.
///
/// TASARIM KARARI — KAYDIRMA YOK. Paketler tek bakışta karşılaştırılabilmeli; kullanıcı üçüncü
/// paketi görmek için kaydırmak zorunda kalırsa karşılaştırma yapmaz, ilk gördüğünü seçer.
/// Bu yüzden kartlar dikey değil YATAY dizilir ve içerik kasten kısa tutulur.
///
/// ÖNERİLEN kart (ömür boyu) daha geniş paylı ve vurgulu çizilir — sahte aciliyet değil, açık
/// bir yönlendirme: en çok değer veren paket görsel olarak da en büyüğüdür.
///
/// FİYAT KAYNAĞI: her zaman mağaza. `Product.fallbackPriceLabel` yalnız mağaza yanıt vermediğinde
/// devreye girer ve o durumda satın alma düğmesi zaten kapalıdır.
class PaywallPlans extends StatelessWidget {
  const PaywallPlans({
    super.key,
    required this.selectedId,
    required this.onSelect,
    required this.storeProducts,
  });

  /// Seçili paketin katalog kimliği.
  final String selectedId;
  final ValueChanged<String> onSelect;

  /// Mağazadan gelen ürünler — `storeProductId` ile eşlenir. Boşsa yedek etiket gösterilir.
  final List<BillingProduct> storeProducts;

  String _priceLabel(Product p) {
    for (final s in storeProducts) {
      if (s.storeProductId == p.storeProductId) return s.priceLabel;
    }
    return p.fallbackPriceLabel;
  }

  @override
  Widget build(BuildContext context) {
    // `IntrinsicHeight` ŞART: kartlar `CrossAxisAlignment.stretch` ile aynı yüksekliğe
    // getiriliyor, ama bu blok kaydırılabilir bir sütunun içinde duruyor — orada dikey kısıt
    // SONSUZDUR ve "sonsuza kadar uza" demek çökmeye yol açar. `IntrinsicHeight` önce en uzun
    // kartın yüksekliğini ölçer, sonra hepsine onu verir. Maliyeti kabul edilir: üç çocuk,
    // ekranda bir kez.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in products) ...[
            Expanded(
              // Önerilen kart daha geniş pay alır — "en büyük kart" isteği yerleşimin kendisinde.
              flex: p.highlight ? 5 : 4,
              child: _PlanCard(
                product: p,
                priceLabel: _priceLabel(p),
                selected: p.id == selectedId,
                onTap: () => onSelect(p.id),
              ),
            ),
            if (p != products.last) const SizedBox(width: AppSpacing.s2),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
  });

  final Product product;
  final String priceLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = product.highlight ? p.primary : p.text2;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${product.title}, $priceLabel'
          '${product.highlight ? ', önerilen' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: selected ? p.primary.withValues(alpha: 0.08) : p.surface2,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? p.primary : p.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.highlight)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s1),
                  child: Text(
                    'ÖNERİLEN',
                    style: TextStyle(
                      color: p.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              Text(
                product.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              // Fiyat, kartın en görünür ögesi. Uzun etiketler (ör. "₺479,99") dar kartta
              // taşmasın diye küçültülerek sığdırılır — kırpılmaz.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  priceLabel,
                  style: TextStyle(
                    color: p.text,
                    fontSize: product.highlight ? 20 : 17,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                product.period.isSubscription ? 'abonelik' : 'tek seferlik',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text3, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
