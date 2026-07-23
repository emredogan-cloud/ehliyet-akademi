import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

/// Animated circular readiness gauge (0..1) with the platform's traffic-light coloring
/// (kırmızı/sarı/yeşil) — mirrors the web readiness concept.
class ReadinessRing extends StatefulWidget {
  const ReadinessRing({super.key, required this.value, this.size = 118, this.label = 'Hazırlık'});
  final double value; // 0..1
  final double size;
  final String label;

  @override
  State<ReadinessRing> createState() => _ReadinessRingState();
}

class _ReadinessRingState extends State<ReadinessRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.slow);
    _a = Tween<double>(begin: 0, end: widget.value.clamp(0, 1))
        .animate(CurvedAnimation(parent: _c, curve: AppMotion.easeOut));
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant ReadinessRing old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _a = Tween<double>(begin: _a.value, end: widget.value.clamp(0, 1))
          .animate(CurvedAnimation(parent: _c, curve: AppMotion.easeOut));
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color _colorFor(double v, AppPalette p) {
    if (v >= 0.75) return p.green;
    if (v >= 0.5) return p.accent;
    return p.red;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final v = _a.value;
        final color = _colorFor(v, p);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(v, color, p.surface3),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '%${(v * 100).round()}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.text),
                  ),
                  Text(widget.label, style: TextStyle(fontSize: 11.5, color: p.text3)),
                ],
              ),
            ),
          ),
        );
      },
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
    const stroke = 11.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
