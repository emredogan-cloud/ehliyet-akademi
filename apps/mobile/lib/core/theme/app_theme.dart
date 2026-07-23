import 'package:flutter/material.dart';
import 'tokens.dart';

/// Builds Flutter [ThemeData] from the design tokens — light + dark, 1:1 with the web.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.brightness == Brightness.dark ? const Color(0xFF04211F) : Colors.white,
      secondary: p.accent,
      onSecondary: p.brightness == Brightness.dark ? const Color(0xFF241804) : Colors.white,
      surface: p.surface,
      onSurface: p.text,
      error: p.red,
      onError: Colors.white,
      // extra roles mapped to tokens
      surfaceContainerHighest: p.surface3,
      outline: p.border,
      outlineVariant: p.borderStrong,
    );

    // Web font is a system stack (Segoe UI/system-ui/Roboto…) → platform default (Roboto on
    // Android) is a faithful match; type sizes mirror --fs-xs..3xl.
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      dividerColor: p.border,
      splashColor: p.primary.withValues(alpha: 0.10),
      highlightColor: p.primary.withValues(alpha: 0.06),
    );

    return base.copyWith(
      extensions: [AppPaletteExtension(p)],
      textTheme: _textTheme(base.textTheme, p),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: p.text,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? p.primary : p.text3,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.primary : p.text3,
            size: 24,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.base),
          side: BorderSide(color: p.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.brightness == Brightness.dark ? const Color(0xFF04211F) : Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surface3,
        contentTextStyle: TextStyle(color: p.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface2,
        prefixIconColor: p.text3,
        labelStyle: TextStyle(color: p.text3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: p.red),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Type scale mirrors web --fs-xs(.78) sm(.88) md(1) lg(1.15) xl(1.4) 2xl(1.9) 3xl(2.6) rem @16px.
  static TextTheme _textTheme(TextTheme base, AppPalette p) {
    TextStyle s(double px, FontWeight w, Color c, {double h = 1.35}) =>
        TextStyle(fontSize: px, fontWeight: w, color: c, height: h);
    return base.copyWith(
      displayLarge: s(42, FontWeight.w800, p.text, h: 1.1),
      displayMedium: s(30, FontWeight.w800, p.text, h: 1.15),
      headlineMedium: s(22, FontWeight.w800, p.text, h: 1.2),
      titleLarge: s(18, FontWeight.w700, p.text, h: 1.25),
      titleMedium: s(16, FontWeight.w700, p.text),
      bodyLarge: s(16, FontWeight.w400, p.text),
      bodyMedium: s(14, FontWeight.w400, p.text2),
      bodySmall: s(12.5, FontWeight.w400, p.text3),
      labelLarge: s(14, FontWeight.w700, p.text),
      labelSmall: s(11.5, FontWeight.w600, p.text3),
    );
  }
}
