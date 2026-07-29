import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Faz 6 — uygulamanın TEK ortak canlı zemini.
///
/// Uygulamanın kökünde (`MaterialApp.builder`) bir kez kurulur; her ekran onun üstünde çizilir.
/// Sayfa değişince zemin YENİDEN KURULMAZ, o yüzden hareket sayfalar arasında kesintisiz akar —
/// "tek bir yüzeyde geziniyorum" hissini veren şey budur.
///
/// KOMPOZİSYON (üstten alta):
/// 1. Tema zemini (`p.bg`) — okunabilirliğin temeli; asla kaybolmaz.
/// 2. Üç yumuşak yeşil ışık havuzu (aurora), çok yavaş sürüklenir.
/// 3. Yıldız benzeri küçük ışıklar, bağımsız fazlarla yanıp söner.
///
/// BÜTÇE (bilinçli seçimler — "düşük GPU" bir dilek değil, tasarım kısıtı):
/// · `MaskFilter.blur` KULLANILMAZ. Yumuşaklık radyal degrade SHADER'ıyla elde edilir; blur her
///   karede ayrı bir geçiş (off-screen pass) demektir ve alt segment cihazlarda kareyi düşürür.
/// · `BackdropFilter` YOKTUR — aynı sebep, daha pahalısı.
/// · Parçacık sayısı sabit ve küçüktür ([_starCount]); konumlar TOHUMLU üretilir, her karede
///   yeniden hesaplanmaz.
/// · Boyama tek bir [RepaintBoundary] içindedir: zemin canlanırken üstteki içerik katmanı
///   yeniden boyanmaz.
/// · "Animasyonları azalt" açıkken tikleyici HİÇ KURULMAZ — hem erişilebilirlik kuralı (E13) hem
///   pil. O durumda sabit ama aynı görünen tek bir kare çizilir.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  /// Tam tur süresi. Uzun olması ŞART: hareket fark edilmemeli, yalnız hissedilmeli.
  static const _period = Duration(seconds: 120);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _period);

  /// Yıldızlar bir kez üretilir (tohumlu → her açılışta aynı gökyüzü).
  static final List<_Star> _stars = _buildStars();

  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldRun = !MediaQuery.disableAnimationsOf(context);
    if (shouldRun == _running) return;
    _running = shouldRun;
    if (shouldRun) {
      _controller.repeat();
    } else {
      _controller.stop();
      // Sabit kare: hareketsiz ama "boş" değil — aurora ve yıldızlar yerinde durur.
      _controller.value = 0.18;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _BackgroundPainter(t: _controller.value, palette: p, stars: _stars),
                // `isComplex` + `willChange`: Skia'ya "bu katmanı önbelleğe alma, her karede
                // değişiyor" der; yanlış önbellekleme titremeye yol açıyordu.
                isComplex: true,
                willChange: _running,
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }

  static List<_Star> _buildStars() {
    // Sabit tohum: gökyüzü her açılışta aynı. Rastgele ama KARARLI.
    final rnd = math.Random(20260729);
    return List.generate(_starCount, (i) {
      return _Star(
        // Konumlar 0..1 aralığında normalize; gerçek piksele boyama sırasında çevrilir.
        dx: rnd.nextDouble(),
        dy: rnd.nextDouble(),
        radius: 0.6 + rnd.nextDouble() * 1.1,
        phase: rnd.nextDouble(),
        // Her yıldız farklı hızda yanıp söner; hepsi aynı anda parlarsa "flaş" gibi görünür.
        speed: 0.6 + rnd.nextDouble() * 1.8,
      );
    });
  }
}

/// Yıldız sayısı — 22, cihazda ölçülen denge: daha azı seyrek, daha çoğu gürültülü görünüyor
/// ve boyama maliyeti doğrusal artıyor.
const int _starCount = 22;

@immutable
class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.speed,
  });
  final double dx;
  final double dy;
  final double radius;
  final double phase;
  final double speed;
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({required this.t, required this.palette, required this.stars});

  /// 0..1 arası tur konumu.
  final double t;
  final AppPalette palette;
  final List<_Star> stars;

  bool get _dark => palette.brightness == Brightness.dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) Zemin — tema rengi + çok hafif dikey derinlik.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.bg,
            Color.lerp(palette.bg, palette.primary, _dark ? 0.055 : 0.035)!,
            palette.bg,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // 2) Aurora — üç yumuşak yeşil ışık havuzu.
    //
    // Sürüklenme Lissajous benzeri iki farklı frekansla kurulur; böylece hareket TEKRAR ETMİYOR
    // gibi görünür (aslında `_period` sonunda başa döner, ama göz bunu yakalayamaz).
    final tau = 2 * math.pi;
    final blobs = <_Blob>[
      _Blob(
        center: Offset(
          size.width * (0.22 + 0.10 * math.sin(tau * t)),
          size.height * (0.16 + 0.06 * math.cos(tau * t * 0.7)),
        ),
        radius: size.shortestSide * 0.85,
        color: palette.primary,
        strength: _dark ? 0.17 : 0.11,
      ),
      _Blob(
        center: Offset(
          size.width * (0.86 + 0.09 * math.cos(tau * t * 0.8)),
          size.height * (0.42 + 0.08 * math.sin(tau * t * 1.3)),
        ),
        radius: size.shortestSide * 0.75,
        color: palette.green,
        strength: _dark ? 0.13 : 0.09,
      ),
      _Blob(
        center: Offset(
          size.width * (0.40 + 0.12 * math.cos(tau * t * 0.5)),
          size.height * (0.92 + 0.05 * math.sin(tau * t * 0.9)),
        ),
        radius: size.shortestSide * 0.95,
        color: palette.primaryBright,
        strength: _dark ? 0.14 : 0.08,
      ),
    ];

    for (final b in blobs) {
      final blobRect = Rect.fromCircle(center: b.center, radius: b.radius);
      canvas.drawCircle(
        b.center,
        b.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: b.strength),
              b.color.withValues(alpha: b.strength * 0.45),
              b.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(blobRect),
      );
    }

    // 3) Yıldızlar — küçük, yavaş yanıp sönen ışıklar.
    //
    // Açık temada beyaz nokta GÖRÜNMEZ; bu yüzden yıldız rengi de temadan gelir: koyu temada
    // aydınlık bir turkuaz, açık temada birincil yeşilin koyusu.
    final starColor = _dark ? palette.primary700 : palette.primary;
    final starPaint = Paint();
    for (final s in stars) {
      // 0..1 üçgen dalga → yumuşak yanıp sönme (sinüsün mutlak değeri sertti).
      final wave = 0.5 + 0.5 * math.sin(tau * (t * s.speed + s.phase));
      final alpha = (_dark ? 0.10 : 0.06) + wave * (_dark ? 0.34 : 0.16);
      starPaint.color = starColor.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.t != t || old.palette != palette || !identical(old.stars, stars);
}

@immutable
class _Blob {
  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
    required this.strength,
  });
  final Offset center;
  final double radius;
  final Color color;
  final double strength;
}
