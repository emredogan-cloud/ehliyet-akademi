import 'package:flutter/material.dart';

/// Design tokens — 1:1 with the web platform's `globals.css :root` (light) and
/// `:root[data-theme='dark']` (dark). This is the single source of the mobile look; never
/// hand-pick a color outside these tokens. See APP_ARCHITECTURE_PLAN.md §5.

/// Color palette for one theme (light or dark).
@immutable
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.primary,
    required this.primary700,
    required this.primaryBright,
    required this.primary050,
    required this.accent,
    required this.red,
    required this.yellow,
    required this.green,
    required this.blue,
    required this.brightness,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color text2;
  final Color text3;
  final Color primary;
  final Color primary700;
  final Color primaryBright;
  final Color primary050;
  final Color accent;
  final Color red;
  final Color yellow;
  final Color green;
  final Color blue;
  final Brightness brightness;

  /// Light theme (web `:root`).
  static const light = AppPalette(
    bg: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F9FD),
    surface3: Color(0xFFEEF2F9),
    border: Color(0xFFE3E8F1),
    borderStrong: Color(0xFFCCD6E6),
    text: Color(0xFF0F1826),
    text2: Color(0xFF46566B),
    text3: Color(0xFF74839A),
    primary: Color(0xFF0D9488),
    primary700: Color(0xFF0B7268),
    primaryBright: Color(0xFF14B8A6),
    primary050: Color(0xFFE6F7F4),
    accent: Color(0xFFF59E0B),
    red: Color(0xFFDC2626),
    yellow: Color(0xFFD97706),
    green: Color(0xFF16A34A),
    blue: Color(0xFF2563EB),
    brightness: Brightness.light,
  );

  /// Dark theme (web `:root[data-theme='dark']` — reference navy palette).
  static const dark = AppPalette(
    bg: Color(0xFF050B16),
    surface: Color(0xFF0B1523),
    surface2: Color(0xFF0F1C2E),
    surface3: Color(0xFF14243A),
    border: Color(0xFF1C2C44),
    borderStrong: Color(0xFF29405F),
    text: Color(0xFFE8EEF7),
    text2: Color(0xFF9FB0C6),
    text3: Color(0xFF6D7F97),
    primary: Color(0xFF2DD4BF),
    primary700: Color(0xFF5EEAD4),
    primaryBright: Color(0xFF2DD4BF),
    primary050: Color(0xFF0B2B2A),
    accent: Color(0xFFF5A623),
    red: Color(0xFFF87171),
    yellow: Color(0xFFFBBF24),
    green: Color(0xFF34D399),
    blue: Color(0xFF60A5FA),
    brightness: Brightness.dark,
  );
}

/// Spacing scale — web 8px grid (`--sp-1..12`).
class AppSpacing {
  const AppSpacing._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
}

/// Corner radii — web `--radius*`.
class AppRadii {
  const AppRadii._();
  static const double sm = 10;
  static const double base = 16;
  static const double lg = 22;
  static const double pill = 999;
}

/// Motion — web `--dur-*` + easing curves.
class AppMotion {
  const AppMotion._();
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 400);
  // web --ease-out: cubic-bezier(0.16, 1, 0.3, 1)
  static const Cubic easeOut = Cubic(0.16, 1, 0.3, 1);
  // web --ease: cubic-bezier(0.4, 0, 0.2, 1)
  static const Cubic ease = Cubic(0.4, 0, 0.2, 1);
}

/// Access the active palette from context (via theme extension).
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPaletteExtension>()!.palette;
}

/// Theme extension carrying the full palette (so widgets get all token colors, not just
/// ColorScheme's subset).
@immutable
class AppPaletteExtension extends ThemeExtension<AppPaletteExtension> {
  const AppPaletteExtension(this.palette);
  final AppPalette palette;

  @override
  AppPaletteExtension copyWith({AppPalette? palette}) =>
      AppPaletteExtension(palette ?? this.palette);

  @override
  AppPaletteExtension lerp(ThemeExtension<AppPaletteExtension>? other, double t) => this;
}
