import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/core/theme/tokens.dart';

void main() {
  group('AppTheme — tokens → ThemeData (web parity)', () {
    test('light theme uses the web light palette', () {
      final t = AppTheme.light();
      expect(t.brightness, Brightness.light);
      expect(t.colorScheme.primary, const Color(0xFF0D9488)); // web --primary
      expect(t.scaffoldBackgroundColor, const Color(0xFFF4F6FB)); // web --bg
      expect(t.extension<AppPaletteExtension>(), isNotNull);
      expect(t.extension<AppPaletteExtension>()!.palette.accent, const Color(0xFFF59E0B));
    });

    test('dark theme uses the web dark (navy) palette', () {
      final t = AppTheme.dark();
      expect(t.brightness, Brightness.dark);
      expect(t.colorScheme.primary, const Color(0xFF2DD4BF)); // web dark --primary
      expect(t.scaffoldBackgroundColor, const Color(0xFF050B16)); // web dark --bg
    });

    test('spacing scale is an 8px grid', () {
      expect(AppSpacing.s2, 8);
      expect(AppSpacing.s4, 16);
      expect(AppSpacing.s6, 24);
    });

    test('radius + motion tokens match web', () {
      expect(AppRadii.base, 16);
      expect(AppMotion.base, const Duration(milliseconds: 240));
      expect(AppMotion.easeOut, const Cubic(0.16, 1, 0.3, 1));
    });
  });
}
