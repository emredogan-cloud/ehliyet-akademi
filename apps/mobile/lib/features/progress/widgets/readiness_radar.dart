import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Radar (örümcek) grafiği — ders bazlı ustalık (0..1). Her eksen bir ders.
class ReadinessRadar extends StatelessWidget {
  const ReadinessRadar({super.key, required this.axes, this.size = 220});

  /// (etiket, 0..1) ekseni; sırayla üstten saat yönünde çizilir.
  final List<({String label, double value})> axes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final summary = axes.map((a) => '${a.label} %${(a.value * 100).round()}').join(', ');
    return Semantics(
      label: 'Ders bazında ustalık radarı: $summary',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RadarPainter(
            axes: axes,
            grid: p.border,
            gridStrong: p.borderStrong,
            fill: p.primary.withValues(alpha: 0.22),
            stroke: p.primary,
            label: p.text2,
            dot: p.primary,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axes,
    required this.grid,
    required this.gridStrong,
    required this.fill,
    required this.stroke,
    required this.label,
    required this.dot,
  });
  final List<({String label, double value})> axes;
  final Color grid;
  final Color gridStrong;
  final Color fill;
  final Color stroke;
  final Color label;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 26;

    Offset pointFor(int i, double frac) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      return center + Offset(math.cos(angle), math.sin(angle)) * radius * frac;
    }

    // Grid halkaları.
    for (final ring in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final pt = pointFor(i, ring);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 1.0 ? 1.4 : 1
          ..color = ring == 1.0 ? gridStrong : grid,
      );
    }

    // Eksen çizgileri.
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, pointFor(i, 1), Paint()..color = grid..strokeWidth = 1);
    }

    // Veri poligonu.
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final pt = pointFor(i, axes[i].value.clamp(0.0, 1.0));
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }
    dataPath.close();
    canvas.drawPath(dataPath, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < n; i++) {
      final pt = pointFor(i, axes[i].value.clamp(0.0, 1.0));
      canvas.drawCircle(pt, 3, Paint()..color = dot);
    }

    // Etiketler — eksen ucunun dışında, yöne göre hizalı (veri noktasıyla çakışmaz).
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final anchor = center + dir * (radius + 16);
      final tp = TextPainter(
        text: TextSpan(
          text: axes[i].label,
          style: TextStyle(color: label, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 84);
      // Yatay: sağ eksende sola-yasla, sol eksende sağa-yasla, tepe/dip ortala.
      final dx = dir.dx > 0.3
          ? 0.0
          : dir.dx < -0.3
          ? -tp.width
          : -tp.width / 2;
      // Dikey: dipte metni aşağı, tepede yukarı it.
      final dy = dir.dy > 0.3 ? 0.0 : -tp.height;
      tp.paint(canvas, anchor + Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.axes != axes;
}
