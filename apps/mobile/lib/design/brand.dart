import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Reusable brand widgets for the redesigned UI. All colors come from the design tokens
/// (`context.palette`) — never hand-picked — so light + dark stay in parity.

// ─────────────────────────────────────────────────────────────────────────────
// Steering-wheel emblem (the recurring brand glyph — badges, headers, shields).
// ─────────────────────────────────────────────────────────────────────────────

class SteeringWheelIcon extends StatelessWidget {
  const SteeringWheelIcon({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WheelPainter(color ?? context.palette.primary)),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = size.width * 0.09;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    canvas.drawCircle(c, r - stroke / 2, ring);
    // hub
    canvas.drawCircle(c, r * 0.20, Paint()..color = color);
    // three spokes (down, upper-left, upper-right)
    final spoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (final a in [math.pi / 2, math.pi * 7 / 6, math.pi * 11 / 6]) {
      final inner = c + Offset(math.cos(a), math.sin(a)) * (r * 0.20);
      final outer = c + Offset(math.cos(a), math.sin(a)) * (r - stroke);
      canvas.drawLine(inner, outer, spoke);
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.color != color;
}

/// The header/brand emblem — a glowing rounded-square holding the steering wheel.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.glow = true});
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.primary.withValues(alpha: 0.22), p.primary.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: p.primary.withValues(alpha: 0.45)),
        boxShadow: glow
            ? [BoxShadow(color: p.primary.withValues(alpha: 0.30), blurRadius: size * 0.4, spreadRadius: -2)]
            : null,
      ),
      alignment: Alignment.center,
      child: SteeringWheelIcon(size: size * 0.56, color: p.primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary CTA — glowing teal gradient pill (used app-wide).
// ─────────────────────────────────────────────────────────────────────────────

class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.leading,
    this.loading = false,
    this.height = 56,
    this.gold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final Widget? leading;
  final bool loading;
  final double height;

  /// Premium (gold) variant.
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    // Faz E13: altın ton tema token'ından (p.accent) gelir; sabit değer açık temada yanlıştı.
    final base = gold ? p.accent : p.primary;
    final gradientColors = gold
        ? [p.accent, p.yellow]
        : [p.primary, p.primaryBright];
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: [
                  BoxShadow(color: base.withValues(alpha: 0.42), blurRadius: 26, spreadRadius: -4, offset: const Offset(0, 8)),
                ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.s2)],
                          Text(
                            label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: AppSpacing.s2),
                            Icon(trailingIcon, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mascot / illustration image — bundled WebP with a graceful fallback + semantics.
// ─────────────────────────────────────────────────────────────────────────────

class MascotImage extends StatelessWidget {
  const MascotImage(this.asset, {super.key, this.height, this.width, this.semanticLabel, this.fit = BoxFit.contain});
  final String asset;
  final double? height;
  final double? width;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      width: width,
      fit: fit,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => SizedBox(height: height, width: width),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colored rounded-square icon tile (list rows, quick actions).
// ─────────────────────────────────────────────────────────────────────────────

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 52, this.glow = false});
  final IconData icon;
  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.10)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: size * 0.35, spreadRadius: -3)]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero glow card — a surface card with a subtle brand gradient + glow border.
// ─────────────────────────────────────────────────────────────────────────────

class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
    this.onTap,
    this.accentColor,
    this.selected = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = accentColor ?? p.primary;
    final radius = BorderRadius.circular(AppRadii.lg);
    final content = Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [accent.withValues(alpha: 0.16), p.surface]
              : [p.surface2, p.surface],
        ),
        borderRadius: radius,
        border: Border.all(
          color: selected ? accent : p.border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 22, spreadRadius: -6, offset: const Offset(0, 8))
          else
            BoxShadow(
              color: p.brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F1826).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return ClipRRect(borderRadius: radius, child: content);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: accent.withValues(alpha: 0.08),
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented progress bar (onboarding steps).
// ─────────────────────────────────────────────────────────────────────────────

class SegmentBar extends StatelessWidget {
  const SegmentBar({super.key, required this.total, required this.active});
  final int total;
  final int active; // 1-based count of filled segments

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.easeOut,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              height: 5,
              decoration: BoxDecoration(
                color: i < active ? p.primary : p.border,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: i < active
                    ? [BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: -2)]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Hub header — a mascot illustration next to a title + subtitle (Learn / Practice hubs).
class HubHeader extends StatelessWidget {
  const HubHeader({super.key, required this.title, required this.subtitle, required this.mascot, this.mascotHeight = 150});
  final String title;
  final String subtitle;
  final String mascot;
  final double mascotHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.s2),
              Text(subtitle, style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        MascotImage(mascot, height: mascotHeight, semanticLabel: ''),
      ],
    );
  }
}

/// Hub row — a large tappable card: colored icon badge + title + subtitle + optional count + chevron.
class HubRow extends StatelessWidget {
  const HubRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.count,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? count;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 54, glow: true),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.s2),
            Text(count!, style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 20)),
          ],
          ?trailing,
          if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}

/// Small pill badge (e.g. "EN POPÜLER", subject tags).
class BrandChip extends StatelessWidget {
  const BrandChip({super.key, required this.label, this.color, this.icon, this.filled = false});
  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: filled ? null : Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.white : c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : c,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
