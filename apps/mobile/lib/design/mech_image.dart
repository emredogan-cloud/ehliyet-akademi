import 'package:flutter/material.dart';

import '../core/mech_assets.dart';
import '../core/theme/tokens.dart';

/// Mekanik parça görseli — şeffaf zeminli WebP'yi yumuşak bir plakanın üstünde gösterir
/// (Evolution Faz E2). Varlık yoksa yerine ikon konur; hiçbir zaman boş kutu kalmaz.
class MechImage extends StatelessWidget {
  const MechImage({
    super.key,
    required this.id,
    this.size = 64,
    this.fallbackIcon = Icons.build_rounded,
    this.plate = true,
  });

  final String id;
  final double size;
  final IconData fallbackIcon;

  /// Görselin arkasına hafif bir plaka çizilsin mi (liste satırlarında okunurluğu artırır).
  final bool plate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final asset = mechAsset(id);
    final child = asset == null
        ? Icon(fallbackIcon, color: p.accent, size: size * 0.42)
        : Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Icon(fallbackIcon, color: p.accent, size: size * 0.42),
            ),
          );
    if (!plate) return SizedBox(width: size, height: size, child: child);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface3.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: child,
    );
  }
}
