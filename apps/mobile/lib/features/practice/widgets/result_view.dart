import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../../core/theme/tokens.dart';
import '../../../design/brand.dart';

/// Sonuç ekranı istatistiği (Doğru / Yanlış / Süre …).
class ResultStat {
  const ResultStat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;
}

/// Sonuç ekranı eylemi (birincil/ikincil düğme).
class ResultAction {
  const ResultAction({required this.label, required this.onTap, this.icon, this.primary = false});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool primary;
}

/// Paylaşılan oturum sonucu ekranı — hedef illüstrasyonu, başarı halkası, istatistikler ve eylemler.
/// Hem akıllı-çalışma (SRS) hem deneme sınavı sonucu için kullanılır (smart-work-results tasarımı).
class SessionResultView extends StatelessWidget {
  const SessionResultView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.accent,
    required this.stats,
    required this.actions,
    this.extra,
  });

  final String title;
  final String subtitle;
  final int percent;
  final Color accent;
  final List<ResultStat> stats;
  final List<ResultAction> actions;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s10),
      children: [
        Center(child: MascotImage(AppImages.illTarget, height: 150, semanticLabel: '')),
        const SizedBox(height: AppSpacing.s2),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s2),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4)),
        const SizedBox(height: AppSpacing.s5),
        Center(child: _ResultRing(percent: percent, color: accent)),
        const SizedBox(height: AppSpacing.s5),
        GlowCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: Row(
            children: [
              for (final s in stats)
                Expanded(
                  child: Column(
                    children: [
                      Icon(s.icon, color: s.color, size: 22),
                      const SizedBox(height: 6),
                      Text(s.value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: p.text)),
                      Text(s.label, style: TextStyle(color: p.text3, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (extra != null) ...[const SizedBox(height: AppSpacing.s4), extra!],
        const SizedBox(height: AppSpacing.s5),
        for (var i = 0; i < actions.length; i++) ...[
          if (actions[i].primary)
            GradientPillButton(
              label: actions[i].label,
              leading: actions[i].icon != null ? Icon(actions[i].icon, color: Colors.white, size: 20) : null,
              onPressed: actions[i].onTap,
            )
          else
            _SecondaryButton(action: actions[i]),
          if (i != actions.length - 1) const SizedBox(height: AppSpacing.s3),
        ],
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.action});
  final ResultAction action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: action.onTap,
        icon: action.icon != null ? Icon(action.icon, size: 18) : const SizedBox.shrink(),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        ),
      ),
    );
  }
}

class _ResultRing extends StatelessWidget {
  const _ResultRing({required this.percent, required this.color});
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (percent / 100).clamp(0, 1)),
      duration: AppMotion.slow,
      curve: AppMotion.easeOut,
      builder: (context, v, _) => SizedBox(
        width: 168,
        height: 168,
        child: CustomPaint(
          painter: _RingPainter(v, color, p.surface3),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('%${(v * 100).round()}',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color)),
                Text('Başarı oranı', style: TextStyle(fontSize: 12.5, color: p.text3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track);
  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}
