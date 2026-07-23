import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Finder _coachTab() =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text('AI Koç'));

void main() {
  testWidgets('AI Koç intro shows nudges + suggestions, and chat sends a question', (tester) async {
    final coach = FakeCoachApi(answer: 'Kırmızı ışıkta tam durulur.', grounded: true);
    await pumpApp(tester, coach: coach);

    await tester.tap(_coachTab());
    await tester.pumpAndSettle();

    // intro state
    expect(find.text('Bir şey sor'), findsOneWidget);
    expect(find.text('İlk yardımda ABC nedir?'), findsOneWidget); // a suggestion chip
    expect(find.text('Hoş geldin!'), findsOneWidget); // welcome nudge (0 answers)

    // tap a suggestion → sends to the (fake) coach
    await tester.tap(find.text('Kırmızı ışıkta sağa dönülür mü?'));
    await tester.pumpAndSettle();

    expect(coach.calls, 1);
    expect(find.text('Kırmızı ışıkta sağa dönülür mü?'), findsWidgets); // user bubble
    expect(find.text('Kırmızı ışıkta tam durulur.'), findsOneWidget); // AI answer
    expect(find.text('İçeriğe dayalı'), findsOneWidget); // grounded badge
  });

  testWidgets('typing and sending a custom question works', (tester) async {
    final coach = FakeCoachApi(answer: 'Takograf hız ve süre kaydeder.', grounded: false);
    await pumpApp(tester, coach: coach);

    await tester.tap(_coachTab());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Takograf nedir?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(coach.lastQuestion, 'Takograf nedir?');
    expect(find.text('Takograf hız ve süre kaydeder.'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget); // non-grounded badge
  });
}
