import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

/// The card primitive — mirrors the web `.card` (surface, 16px radius, hairline border, soft
/// elevation, press feedback). All content surfaces use this.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
    this.onTap,
    this.accent,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Optional left accent bar (e.g., status color).
  final Color? accent;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadii.base);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: radius,
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF0F1826).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: accent == null
          ? Padding(padding: padding, child: child)
          // IntrinsicHeight so the full-height accent bar works even inside an unbounded-height
          // scroll view (a bare stretch Row would force infinite height there).
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppRadii.base),
                      ),
                    ),
                  ),
                  Expanded(child: Padding(padding: padding, child: child)),
                ],
              ),
            ),
    );

    return Padding(
      padding: margin,
      child: onTap == null
          ? ClipRRect(borderRadius: radius, child: content)
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: p.primary.withValues(alpha: 0.08),
                highlightColor: p.primary.withValues(alpha: 0.04),
                child: content,
              ),
            ),
    );
  }
}
