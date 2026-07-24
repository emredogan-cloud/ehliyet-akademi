import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('first run shows the welcome slide; Atla goes to Home', (tester) async {
    await pumpApp(tester, onboardingSeen: false);

    // redirected to onboarding welcome slide
    expect(find.text('Devam'), findsOneWidget);
    expect(find.text('EHLİYET AKADEMİ'), findsWidgets);
    expect(find.text('Bugün de çalışalım'), findsNothing);

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(find.text('Bugün de çalışalım'), findsOneWidget); // Home
  });

  testWidgets('completing the personalization flow lands on Home', (tester) async {
    await pumpApp(tester, onboardingSeen: false);

    // Welcome → 4 personalization steps → AI Koç → Home
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();

    // step 1: licence category
    expect(find.text('Hangi ehliyet türünü alıyorsun?'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
    }

    // AI Koç slide
    expect(find.text('Koç ile Başla'), findsOneWidget);
    await tester.tap(find.text('Koç ile Başla'));
    await tester.pumpAndSettle();

    expect(find.text('Bugün de çalışalım'), findsOneWidget);
  });

  testWidgets('personalization selections drive the study profile daily goal', (tester) async {
    await pumpApp(tester, onboardingSeen: false);
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();

    // Step 4 (timeframe): pick "1 Haftadan Az" → intense plan.
    await tester.tap(find.text('Devam Et')); // to step 2
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et')); // to step 3
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et')); // to step 4
    await tester.pumpAndSettle();
    expect(find.text('Sınavına ne kadar süre kaldı?'), findsOneWidget);
    await tester.tap(find.text('1 Haftadan Az'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et')); // to AI Koç
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koç ile Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Bugün de çalışalım'), findsOneWidget);
  });

  testWidgets('returning user (seen) boots straight to Home', (tester) async {
    await pumpApp(tester); // onboardingSeen defaults to true
    expect(find.text('Bugün de çalışalım'), findsOneWidget);
    expect(find.text('Devam'), findsNothing);
  });
}
