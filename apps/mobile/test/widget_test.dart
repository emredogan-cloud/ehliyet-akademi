import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ehliyet_akademi/app/app.dart';

void main() {
  testWidgets('boots on Home with readiness + coach nudge', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EhliyetAkademiApp()));
    await tester.pumpAndSettle();

    // Above-the-fold content in the default test viewport.
    expect(find.text('Bugün de çalışalım'), findsOneWidget); // home header
    expect(find.text('Sınava hazırlık'), findsOneWidget); // readiness card
    expect(find.text('AI Koç'), findsWidgets); // coach nudge card + tab
    expect(find.text('Ana Sayfa'), findsOneWidget); // bottom tab label

    // Below-the-fold content exists once scrolled into view.
    await tester.dragUntilVisible(
      find.text('Hızlı işlemler'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    expect(find.text('Hızlı işlemler'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs (no dead routes)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EhliyetAkademiApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Öğren'));
    await tester.pumpAndSettle();
    expect(find.text('Öğrenme'), findsOneWidget);

    await tester.tap(find.text('Pratik'));
    await tester.pumpAndSettle();
    expect(find.text('Pratik & Sınav'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Koyu tema'), findsOneWidget);
  });

  testWidgets('theme toggle flips off system mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EhliyetAkademiApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    final appBefore = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(appBefore.themeMode, ThemeMode.system);

    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final appAfter = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(appAfter.themeMode, isNot(ThemeMode.system)); // toggled to explicit light/dark
  });
}
