import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('first run shows onboarding; Atla goes to Home', (tester) async {
    await pumpApp(tester, onboardingSeen: false);

    // redirected to onboarding
    expect(find.text('Devam'), findsOneWidget);
    expect(find.text('Ehliyet Akademi'), findsWidgets);
    expect(find.text('Bugün de çalışalım'), findsNothing);

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(find.text('Bugün de çalışalım'), findsOneWidget); // Home
  });

  testWidgets('completing all slides with Devam/Başla lands on Home', (tester) async {
    await pumpApp(tester, onboardingSeen: false);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Başla'), findsOneWidget); // last slide
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Bugün de çalışalım'), findsOneWidget);
  });

  testWidgets('returning user (seen) boots straight to Home', (tester) async {
    await pumpApp(tester); // onboardingSeen defaults to true
    expect(find.text('Bugün de çalışalım'), findsOneWidget);
    expect(find.text('Devam'), findsNothing);
  });
}
