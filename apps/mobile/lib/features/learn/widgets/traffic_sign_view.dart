import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/content/content_enums.dart';
import '../../../domain/content/traffic_sign.dart';

/// Trafik işareti görünümü — web `TrafficSign.tsx`'in birebir Dart limanı: şekil KABUĞU (shell) +
/// SEMBOL (glyph), 100×100 grid. Piktogramlar aynı özgün çizgi diliyle (SVG path verisi birebir
/// kopyalanır) çizilir → telif-güvenli. Metin (glyphText / DUR / YOL VER) flutter_svg yerine Flutter
/// widget'ı olarak bindirilir (güvenilir metin oluşturma için).
class TrafficSignView extends StatelessWidget {
  const TrafficSignView({super.key, required this.sign, this.size = 84});

  final TrafficSign sign;
  final double size;

  static const _red = '#d92d20';
  static const _blue = '#1558d6';
  static const _green = '#067647';
  static const _yellow = '#f5b301';
  static const _dark = '#111827';
  static const _white = '#ffffff';

  static String _fgFor(SignShape shape) =>
      (shape == SignShape.disc || shape == SignShape.rectBlue || shape == SignShape.rectGreen)
      ? _white
      : _dark;

  @override
  Widget build(BuildContext context) {
    final fg = _fgFor(sign.shape);
    final svg = _svgFor(sign.shape, sign.glyph, fg);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(svg, width: size, height: size),
          ..._textOverlays(fg),
        ],
      ),
    );
  }

  List<Widget> _textOverlays(String fg) {
    final widgets = <Widget>[];
    // DUR (octagon) — gömülü beyaz metin.
    if (sign.shape == SignShape.octagon) {
      widgets.add(
        Align(
          alignment: const Alignment(0, 0.02),
          child: _signText('DUR', px: 24, weight: FontWeight.w800, color: Colors.white),
        ),
      );
    }
    // YOL VER (inv-triangle) — üst kısımda kırmızı metin.
    if (sign.shape == SignShape.invTriangle) {
      widgets.add(
        Align(
          alignment: const Alignment(0, -0.16),
          child: _signText(
            'YOL VER',
            px: 13,
            weight: FontWeight.w700,
            color: const Color(0xFFD92D20),
          ),
        ),
      );
    }
    // glyphText (hız/ağırlık sayıları, "OTOYOL" vb.) — merkezde, zemine göre koyu/beyaz.
    final gt = sign.glyphText;
    if (gt != null && gt.isNotEmpty) {
      final px = gt.length > 4
          ? 15.0
          : gt.length > 2
          ? 24.0
          : 34.0;
      widgets.add(
        _signText(gt, px: px, weight: FontWeight.w800, color: _colorFromHex(fg)),
      );
    }
    return widgets;
  }

  Widget _signText(String text, {required double px, required FontWeight weight, required Color color}) {
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: TextStyle(
        // 100 birimlik viewBox'taki px, widget boyutuna ölçeklenir.
        fontSize: px / 100 * size,
        fontWeight: weight,
        color: color,
        height: 1,
        letterSpacing: 0,
      ),
    );
  }

  static Color _colorFromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  // ——— Şekil kabuğu (web `Shell`) ———
  static String _svgFor(SignShape shape, String? glyph, String fg) {
    final inner = glyph != null ? _glyphInner(glyph, fg) : '';
    final body = switch (shape) {
      SignShape.triangle =>
        '<path d="M50 12 L88 78 H12 Z" fill="$_white" stroke="$_red" stroke-width="9" stroke-linejoin="round"/>'
            '<g transform="translate(0 8) scale(0.78) translate(14 6)">$inner</g>',
      SignShape.invTriangle =>
        '<path d="M12 20 H88 L50 86 Z" fill="$_white" stroke="$_red" stroke-width="9" stroke-linejoin="round"/>$inner',
      SignShape.ring =>
        '<circle cx="50" cy="50" r="40" fill="$_white" stroke="$_red" stroke-width="10"/>$inner',
      SignShape.disc => '<circle cx="50" cy="50" r="42" fill="$_blue"/>$inner',
      SignShape.rectBlue => '<rect x="12" y="16" width="76" height="68" rx="8" fill="$_blue"/>$inner',
      SignShape.rectGreen =>
        '<rect x="12" y="16" width="76" height="68" rx="8" fill="$_green"/>$inner',
      SignShape.octagon =>
        '<path d="M32 12 H68 L88 32 V68 L68 88 H32 L12 68 V32 Z" fill="$_red" stroke="#fff" stroke-width="3"/>',
      SignShape.diamond =>
        '<path d="M50 10 L90 50 L50 90 L10 50 Z" fill="$_yellow" stroke="#fff" stroke-width="4"/>$inner',
    };
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">$body</svg>';
  }

  // ——— Sembol kayıtları (web `GLYPHS`) — SVG path verisi birebir korunur ———
  static String _glyphInner(String key, String fg) {
    switch (key) {
      case 'exclam':
        return '<g fill="$fg"><rect x="45" y="30" width="10" height="30" rx="3"/><circle cx="50" cy="70" r="6"/></g>';
      case 'curveLeft':
        return '<path d="M58 72 V52 q0 -14 -14 -14 q-14 0 -14 14" fill="none" stroke="$fg" stroke-width="8" stroke-linecap="round"/>';
      case 'curveRight':
        return '<path d="M42 72 V52 q0 -14 14 -14 q14 0 14 14" fill="none" stroke="$fg" stroke-width="8" stroke-linecap="round"/>';
      case 'sCurve':
        return '<path d="M40 74 q-8 -12 4 -20 q12 -8 4 -20" fill="none" stroke="$fg" stroke-width="8" stroke-linecap="round"/>';
      case 'bump':
        return '<path d="M28 66 q22 -34 44 0" fill="none" stroke="$fg" stroke-width="8" stroke-linecap="round"/>';
      case 'slippery':
        return '<g fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round"><rect x="34" y="34" width="20" height="12" rx="3"/><path d="M30 62 q10 8 22 2 M40 70 q10 6 22 0"/></g>';
      case 'pedestrian':
        return '<g fill="$fg"><circle cx="50" cy="30" r="7"/><path d="M50 38 l-8 18 M50 38 l8 18 M50 42 l-10 8 M50 42 l10 8" stroke="$fg" stroke-width="5" stroke-linecap="round" fill="none"/></g>';
      case 'children':
        return '<g fill="none" stroke="$fg" stroke-width="5" stroke-linecap="round"><circle cx="40" cy="34" r="5" fill="$fg"/><circle cx="60" cy="38" r="5" fill="$fg"/><path d="M40 40 v14 M35 48 h10 M40 54 l-5 12 M40 54 l5 12"/><path d="M60 44 v12 M56 50 h8 M60 56 l-4 10 M60 56 l4 10"/></g>';
      case 'animal':
        return '<path d="M30 66 q4 -18 14 -18 q4 -10 10 -6 q2 -8 6 -2 l2 6 q10 2 10 20" fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'roundabout':
        return '<g fill="none" stroke="$fg" stroke-width="7"><circle cx="50" cy="52" r="16" stroke-dasharray="10 8"/><path d="M66 44 l4 -8 -9 -1" fill="$fg" stroke="none"/></g>';
      case 'narrow':
        return '<path d="M34 30 L44 52 L44 72 M66 30 L56 52 L56 72" fill="none" stroke="$fg" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'twoway':
        return '<g fill="$fg" stroke="$fg" stroke-width="6" stroke-linecap="round"><path d="M42 30 v40 M58 70 v-40"/><path d="M42 30 l-6 8 h12 z M58 70 l-6 -8 h12 z" stroke="none"/></g>';
      case 'light':
        return '<g><rect x="42" y="26" width="16" height="44" rx="6" fill="none" stroke="$fg" stroke-width="4"/><circle cx="50" cy="36" r="4" fill="$_red"/><circle cx="50" cy="48" r="4" fill="$_yellow"/><circle cx="50" cy="60" r="4" fill="$_green"/></g>';
      case 'cross':
        return '<path d="M34 34 L66 66 M66 34 L34 66" fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round"/>';
      case 'car':
        return '<g fill="$fg"><path d="M28 58 l6 -14 h32 l6 14 z"/><circle cx="38" cy="60" r="5"/><circle cx="62" cy="60" r="5"/></g>';
      case 'twoCars':
        return '<g><g fill="$fg"><rect x="30" y="46" width="18" height="9" rx="2"/></g><g fill="$_red"><rect x="52" y="46" width="18" height="9" rx="2"/></g><path d="M50 30 v40" fill="none" stroke="$fg" stroke-width="4"/></g>';
      case 'noStop':
        return '<g fill="none" stroke="$fg" stroke-width="7"><circle cx="50" cy="50" r="4" fill="$fg"/></g>';
      case 'arrowRight':
        return '<path d="M32 50 h30 M52 38 l14 12 -14 12" fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'arrowStraight':
        return '<path d="M50 70 V34 M38 46 l12 -12 12 12" fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'arrowLeft':
        return '<path d="M68 50 h-30 M48 38 l-14 12 14 12" fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'bike':
        return '<g fill="none" stroke="$fg" stroke-width="5"><circle cx="36" cy="60" r="11"/><circle cx="64" cy="60" r="11"/><path d="M36 60 l12 -18 h10 M48 42 l16 18 M44 60 h20"/></g>';
      case 'hospital':
        return '<path d="M44 30 h12 v12 h12 v12 h-12 v12 h-12 v-12 h-12 v-12 h12 z" fill="$fg"/>';
      case 'parkingP':
        return '<path d="M40 30 v40 M40 30 h14 a11 11 0 0 1 0 22 h-14" fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'digger':
        return '<g fill="$fg"><rect x="30" y="54" width="24" height="12" rx="2"/><path d="M54 58 l16 -16 4 4 -14 16 z"/></g>';
      case 'hillDown':
        return '<g fill="$fg" stroke="$fg"><path d="M28 40 L72 68 L28 68 Z" opacity="0.85"/></g>';
      case 'levelCross':
        return '<path d="M32 34 L68 66 M52 34 h16 v16" fill="none" stroke="$fg" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'hillUp':
        return '<g><path d="M22 72 L78 40 L78 72 Z" fill="$fg"/><text x="30" y="42" font-size="16" font-weight="700" fill="$fg">%10</text></g>';
      case 'narrowRight':
        return '<g stroke="$fg" stroke-width="7" fill="none" stroke-linecap="round"><path d="M34 26 V74"/><path d="M66 26 Q60 50 66 74"/></g>';
      case 'narrowLeft':
        return '<g stroke="$fg" stroke-width="7" fill="none" stroke-linecap="round"><path d="M66 26 V74"/><path d="M34 26 Q40 50 34 74"/></g>';
      case 'gravel':
        return '<g fill="$fg"><path d="M22 66 h34 l8 -14 h-18 l-6 8 h-12 z"/><circle cx="30" cy="72" r="5"/><circle cx="48" cy="72" r="5"/><circle cx="66" cy="44" r="3"/><circle cx="74" cy="36" r="3"/><circle cx="70" cy="54" r="3"/></g>';
      case 'wind':
        return '<g><path d="M36 30 V76" fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round"/><path d="M36 30 L74 36 L36 48 Z" fill="$fg"/></g>';
      case 'tunnel':
        return '<path d="M26 74 V52 Q26 28 50 28 Q74 28 74 52 V74 H62 V54 Q62 40 50 40 Q38 40 38 54 V74 Z" fill="$fg"/>';
      case 'rocks':
        return '<g fill="$fg"><path d="M24 30 L44 34 L38 48 L22 46 Z"/><path d="M46 44 L60 48 L54 60 L42 56 Z"/><path d="M30 74 h44 l-8 -12 h-30 z"/></g>';
      case 'quay':
        return '<g><path d="M24 56 L52 48" fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round"/><g transform="rotate(20 44 40)"><rect x="30" y="34" width="26" height="10" rx="3" fill="$fg"/><circle cx="36" cy="47" r="4" fill="$fg"/><circle cx="50" cy="47" r="4" fill="$fg"/></g><path d="M24 70 q6 -6 12 0 q6 6 12 0 q6 -6 12 0 q6 6 12 0" fill="none" stroke="$fg" stroke-width="5" stroke-linecap="round"/></g>';
      case 'airplane':
        return '<path d="M20 62 L80 62 L64 50 L52 50 L40 34 L32 34 L38 50 L26 50 L20 44 L14 44 L18 56 Z" fill="$fg" transform="rotate(-8 50 50)"/>';
      case 'tram':
        return '<g fill="$fg"><rect x="30" y="30" width="40" height="34" rx="6"/><rect x="36" y="36" width="12" height="10" fill="#ffffff" opacity="0.85"/><rect x="52" y="36" width="12" height="10" fill="#ffffff" opacity="0.85"/><circle cx="38" cy="70" r="5"/><circle cx="62" cy="70" r="5"/><path d="M44 30 L50 20 L56 30" fill="none" stroke="$fg" stroke-width="4"/></g>';
      case 'truck':
        return '<g fill="$fg"><rect x="18" y="38" width="38" height="22" rx="3"/><path d="M56 44 h16 l8 10 v6 h-24 z"/><circle cx="30" cy="66" r="6"/><circle cx="66" cy="66" r="6"/></g>';
      case 'motorcycle':
        return '<g fill="$fg"><circle cx="26" cy="64" r="9" fill="none" stroke="$fg" stroke-width="5"/><circle cx="74" cy="64" r="9" fill="none" stroke="$fg" stroke-width="5"/><path d="M26 64 L44 48 H58 L66 40 H74 L66 52 L74 64" fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><rect x="40" y="42" width="14" height="7" rx="3"/></g>';
      case 'tractor':
        return '<g fill="$fg"><circle cx="32" cy="62" r="12" fill="none" stroke="$fg" stroke-width="6"/><circle cx="68" cy="66" r="7" fill="none" stroke="$fg" stroke-width="5"/><path d="M40 50 h16 v-14 h10 l6 20" fill="none" stroke="$fg" stroke-width="6" stroke-linejoin="round"/></g>';
      case 'handcart':
        return '<g fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round"><path d="M30 34 L58 34 L66 56 L38 56 Z" fill="$fg"/><path d="M66 42 L80 38"/><circle cx="50" cy="66" r="7"/></g>';
      case 'horseCart':
        return '<g fill="$fg"><path d="M22 44 q8 -10 16 0 l-2 10 h-12 z"/><path d="M24 40 q-2 -8 6 -8" fill="none" stroke="$fg" stroke-width="4"/><rect x="46" y="40" width="26" height="12" rx="2"/><circle cx="58" cy="62" r="8" fill="none" stroke="$fg" stroke-width="5"/><path d="M38 46 h10" fill="none" stroke="$fg" stroke-width="4"/></g>';
      case 'deer':
        return '<g fill="$fg"><path d="M30 70 L36 52 L32 40 L44 48 L60 44 L72 52 L66 60 L68 70 L60 70 L58 60 L44 62 L42 70 Z"/><path d="M64 44 L60 30 M64 44 L70 28 M60 36 L54 30 M68 34 L74 30" stroke="$fg" stroke-width="4" fill="none" stroke-linecap="round"/></g>';
      case 'chains':
        return _chains(fg);
      case 'uTurn':
        return '<g fill="none" stroke="$fg" stroke-width="8" stroke-linecap="round"><path d="M36 72 V44 Q36 28 50 28 Q64 28 64 44 V60"/><path d="M54 54 L64 70 L74 54" fill="$fg" stroke="none"/></g>';
      case 'turnLeft':
        return '<g fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round"><path d="M62 74 V50 Q62 38 50 38 H40"/><path d="M44 26 L28 38 L44 50" fill="$fg" stroke="none"/></g>';
      case 'turnRight':
        return '<g fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round"><path d="M38 74 V50 Q38 38 50 38 H60"/><path d="M56 26 L72 38 L56 50" fill="$fg" stroke="none"/></g>';
      case 'phone':
        return '<path d="M32 26 q18 -8 36 0 l-6 12 q-12 -5 -24 0 Z M30 40 q-8 18 4 34 l10 -8 q-7 -10 -2 -20 Z M70 40 l-12 6 q5 10 -2 20 l10 8 q12 -16 4 -34 Z" fill="$fg"/>';
      case 'wrenchTool':
        return '<g fill="$fg"><path d="M30 24 l8 0 0 12 8 0 0 -12 8 0 0 20 -24 0 Z"/><rect x="38" y="44" width="8" height="32" rx="3"/></g>';
      case 'fuel':
        return '<g fill="$fg"><rect x="30" y="28" width="26" height="46" rx="4"/><rect x="35" y="34" width="16" height="12" fill="#ffffff" opacity="0.85"/><path d="M58 40 h6 l8 10 v18 a5 5 0 0 1 -10 0 v-12 h-4" fill="none" stroke="$fg" stroke-width="5"/></g>';
      case 'bed':
        return '<g fill="$fg"><path d="M20 64 V40 h6 v14 h48 a8 8 0 0 1 8 8 v10 h-6 v-6 H26 v6 h-6 z"/><circle cx="34" cy="46" r="6"/></g>';
      case 'cutlery':
        return '<g fill="$fg"><path d="M36 24 v20 a6 6 0 0 1 -12 0 V24 h4 v18 h4 V24 Z"/><rect x="28" y="46" width="6" height="30" rx="3"/><path d="M62 24 q10 0 10 14 q0 12 -8 14 v24 h-6 V24 Z"/></g>';
      case 'fountain':
        return '<g fill="$fg"><rect x="34" y="46" width="22" height="30" rx="3"/><path d="M56 50 h10 q4 0 4 5 v6 h-6 v-4 h-8"/><path d="M68 64 q-3 8 0 10 q6 -2 0 -10"/><rect x="30" y="40" width="30" height="8" rx="2"/></g>';
      case 'tent':
        return '<g fill="none" stroke="$fg" stroke-width="6" stroke-linecap="round"><path d="M22 72 L50 30 L78 72 Z" stroke-linejoin="round"/><path d="M50 72 L50 48"/></g>';
      case 'bus':
        return '<g fill="$fg"><rect x="22" y="32" width="56" height="32" rx="6"/><rect x="28" y="38" width="12" height="10" fill="#ffffff" opacity="0.85"/><rect x="44" y="38" width="12" height="10" fill="#ffffff" opacity="0.85"/><rect x="60" y="38" width="12" height="10" fill="#ffffff" opacity="0.85"/><circle cx="34" cy="68" r="6"/><circle cx="66" cy="68" r="6"/></g>';
      case 'keepRight':
        return '<g fill="none" stroke="$fg" stroke-width="9" stroke-linecap="round"><path d="M42 26 V44 Q42 56 54 60 L62 64"/><path d="M62 48 L72 68 L50 66" fill="$fg" stroke="none"/></g>';
      case 'priorityArrows':
        return '<g><path d="M38 74 V34 M38 34 L30 46 M38 34 L46 46" fill="none" stroke="$fg" stroke-width="8" stroke-linecap="round"/><path d="M62 30 V66 M62 66 L56 58 M62 66 L68 58" fill="none" stroke="$_red" stroke-width="6" stroke-linecap="round"/></g>';
      case 'deadEnd':
        return '<g><path d="M50 76 V40" fill="none" stroke="$fg" stroke-width="10"/><rect x="30" y="26" width="40" height="10" fill="$_red"/></g>';
      case 'endBar':
        return _endBar(fg);
      case 'snow':
        return _snow(fg);
      default:
        return '';
    }
  }

  // ——— Hesaplanan piktogramlar (web `.map` üretimleri) ———
  static String _chains(String fg) {
    final buf = StringBuffer(
      '<g fill="none" stroke="$fg" stroke-width="5"><circle cx="50" cy="50" r="24"/><circle cx="50" cy="50" r="10"/>',
    );
    for (final a in [0, 60, 120, 180, 240, 300]) {
      final cx = (50 + 24 * math.cos(a * math.pi / 180)).toStringAsFixed(3);
      final cy = (50 + 24 * math.sin(a * math.pi / 180)).toStringAsFixed(3);
      buf.write('<circle cx="$cx" cy="$cy" r="5" fill="$fg" stroke="none"/>');
    }
    buf.write('</g>');
    return buf.toString();
  }

  static String _endBar(String fg) {
    final buf = StringBuffer('<g stroke="$fg" stroke-width="5" opacity="0.9" fill="none">');
    for (final o in [-14, 0, 14]) {
      buf.write('<path d="M${30 + o} 74 L${58 + o} 26"/>');
    }
    buf.write('</g>');
    return buf.toString();
  }

  static String _snow(String fg) {
    final buf = StringBuffer(
      '<g stroke="$fg" stroke-width="4" stroke-linecap="round" fill="none">',
    );
    for (final a in [0, 60, 120]) {
      buf.write('<path d="M50 26 V74" transform="rotate($a 50 50)"/>');
    }
    for (final a in [0, 60, 120, 180, 240, 300]) {
      buf.write('<path d="M50 30 L44 38 M50 30 L56 38" transform="rotate($a 50 50)"/>');
    }
    buf.write('</g>');
    return buf.toString();
  }
}
