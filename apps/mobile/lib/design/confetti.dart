import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Faz 10 — konfeti.
///
/// NEDEN HAZIR PAKET DEĞİL: konfeti tek bir `CustomPainter` ve biraz fizikten ibarettir; bir
/// paket eklemek uygulamaya bir bağımlılık daha, bir bakım yükü daha getirirdi. Buradaki uygulama
/// ~120 satır ve projenin kendi hareket kurallarına (hareket azaltma) uyuyor.
///
/// BÜTÇE: parçacıklar TEK BİR tuvale çizilir (parçacık başına widget YOK) ve tek bir
/// [RepaintBoundary] içindedir. Konum/hız bir kez, TOHUMLU üretilir; her karede yalnız konum
/// ilerletilir.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.count = 90,
    this.duration = const Duration(milliseconds: 2600),
    required this.colors,
  });

  final int count;
  final Duration duration;

  /// Parçacık renkleri — çağıran temadan verir (E13: sabit renk yok).
  final List<Color> colors;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    // Sabit tohum: her kutlama aynı görünür. "Rastgele ama kararlı" — hata ayıklanabilir olması
    // ve testte deterministik kalması için.
    final rnd = math.Random(20261010);
    _pieces = List.generate(widget.count, (i) {
      // Yayılım yukarı doğru bir koni: aşağı fırlayan konfeti doğal görünmüyor.
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.9;
      final speed = 0.55 + rnd.nextDouble() * 0.75;
      return _Piece(
        dx: 0.5 + (rnd.nextDouble() - 0.5) * 0.16,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 5 + rnd.nextDouble() * 6,
        color: widget.colors[i % widget.colors.length],
        spin: (rnd.nextDouble() - 0.5) * 10,
        phase: rnd.nextDouble(),
        // Kare parçalar arasına birkaç şerit: tek biçim konfeti yapay görünüyor.
        ribbon: i % 4 == 0,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // E13 erişilebilirlik kuralı: hareket azaltıldığında konfeti HİÇ oynatılmaz.
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (!_controller.isAnimating && _controller.value == 0) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(t: _controller.value, pieces: _pieces),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

@immutable
class _Piece {
  const _Piece({
    required this.dx,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.spin,
    required this.phase,
    required this.ribbon,
  });
  final double dx;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double spin;
  final double phase;
  final bool ribbon;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.t, required this.pieces});
  final double t;
  final List<_Piece> pieces;

  /// Yerçekimi — patlama yukarı çıkar, sonra düşer.
  static const _gravity = 1.75;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      // Her parçacık kendi fazından başlar → hepsi aynı anda fırlamaz.
      final life = (t - p.phase * 0.16).clamp(0.0, 1.0);
      if (life <= 0) continue;

      final x = size.width * p.dx + p.vx * life * size.width * 0.9;
      final y = size.height * 0.55 + (p.vy * life + _gravity * life * life * 0.5) * size.height;
      if (y > size.height + 40) continue;

      // Son çeyrekte sönümlenir: konfeti ekranda "asılı" kalmamalı.
      final fade = life > 0.75 ? (1 - (life - 0.75) / 0.25).clamp(0.0, 1.0) : 1.0;
      paint.color = p.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * life);
      final w = p.size;
      final h = p.ribbon ? p.size * 2.4 : p.size;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Radius.circular(p.ribbon ? 1.5 : 1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
