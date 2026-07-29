import 'package:ehliyet_akademi/app/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 4 — alt gezinme: Topluluk birinci sınıf sekme.
void main() {
  group('alt gezinme çubuğu', () {
    testWidgets('altı sekme vardır ve Topluluk bunlardan biridir', (tester) async {
      await pumpApp(tester);

      final bar = find.byType(AppBottomNav);
      expect(bar, findsOneWidget);
      for (final label in const ['Ana Sayfa', 'Öğren', 'Pratik', 'AI Koç', 'Topluluk', 'Profil']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
          reason: '"$label" sekmesi çubukta olmalı',
        );
      }
    });

    testWidgets('Topluluk sekmesi topluluk ekranını açar (Profil üzerinden DEĞİL)', (tester) async {
      await pumpApp(tester, community: FakeCommunityApi());
      await tapTab(tester, 'Topluluk');

      // Topluluk ekranının kendi başlığı görünür.
      expect(find.widgetWithText(AppBar, 'Topluluk'), findsOneWidget);
    });

    /// Ayrı dalın ASIL kazancı: her sekme kendi yığınını korur. Topluluk'ta bir alt sayfaya
    /// inip başka sekmeye geçip dönünce, kullanıcı bıraktığı yerde olmalıdır.
    testWidgets('sekme yığınları birbirinden bağımsız korunur', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, community: FakeCommunityApi());

      await tapTab(tester, 'Topluluk');
      await tester.tap(find.text('Topluluğa katıl'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Topluluğa katıl'), findsOneWidget);

      // Başka sekmeye git ve geri dön — alt sayfa KORUNUR.
      await tapTab(tester, 'Ana Sayfa');
      expect(find.widgetWithText(AppBar, 'Topluluğa katıl'), findsNothing);
      await tapTab(tester, 'Topluluk');
      expect(find.widgetWithText(AppBar, 'Topluluğa katıl'), findsOneWidget);
    });

    /// Etkin sekmeye yeniden dokunmak o dalın köküne döner — yerel uygulama davranışı.
    testWidgets('etkin sekmeye yeniden dokunmak kökle döner', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, community: FakeCommunityApi());

      await tapTab(tester, 'Topluluk');
      await tester.tap(find.text('Topluluğa katıl'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Topluluğa katıl'), findsOneWidget);

      await tapTab(tester, 'Topluluk');
      expect(find.widgetWithText(AppBar, 'Topluluğa katıl'), findsNothing);
    });

    /// E13 erişilebilirlik kuralı — çubuk da bu kurala tabidir.
    testWidgets('hareket azaltıldığında çubukta animasyon kurulmaz', (tester) async {
      await pumpApp(tester); // pumpApp varsayılanı reduceMotion: true
      expect(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
    });

    testWidgets('sekmeler ekran okuyucuya seçili durumunu bildirir', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);

      expect(
        tester.getSemantics(
          find.descendant(of: find.byType(AppBottomNav), matching: find.text('Ana Sayfa')),
        ),
        matchesSemantics(
          label: 'Ana Sayfa',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(
          find.descendant(of: find.byType(AppBottomNav), matching: find.text('Topluluk')),
        ),
        matchesSemantics(
          label: 'Topluluk',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
