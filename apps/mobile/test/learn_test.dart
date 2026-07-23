import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> _openLearn(WidgetTester tester) async {
  await tester.tap(find.text('Öğren'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Öğren hub shows real counts and navigates to Dersler', (tester) async {
    await pumpApp(tester);
    await _openLearn(tester);

    expect(find.text('Öğrenme'), findsOneWidget);
    expect(find.text('Dersler'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // lesson & video counts from the snapshot

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();

    expect(find.text('Trafiğe Giriş'), findsOneWidget);
    expect(find.text('İlk Yardım Temeli'), findsOneWidget);
  });

  testWidgets('lesson detail renders objectives, sections and a review card', (tester) async {
    await pumpApp(tester);
    await _openLearn(tester);
    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trafiğe Giriş'));
    await tester.pumpAndSettle();

    expect(find.text('Bu derste'), findsOneWidget);
    expect(find.text('Giriş'), findsWidgets); // section heading

    // review card is below the fold → scroll to it, then reveal the answer
    await tester.scrollUntilVisible(find.text('Cevabı göster'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Cevabı göster'), findsOneWidget);
    await tester.tap(find.text('Cevabı göster'));
    await tester.pumpAndSettle();
    expect(find.text('Dur'), findsWidgets);
  });

  testWidgets('signs gallery renders signs and opens a detail', (tester) async {
    await pumpApp(tester);
    await _openLearn(tester);
    await tester.tap(find.text('Trafik İşaretleri'));
    await tester.pumpAndSettle();

    expect(find.text('Kaygan Yol'), findsOneWidget);
    expect(find.text('Azami Hız 30'), findsOneWidget);

    await tester.tap(find.text('Kaygan Yol'));
    await tester.pumpAndSettle();

    expect(find.text('Anlamı'), findsOneWidget);
    expect(find.text('Yol kaygan olabilir.'), findsOneWidget);
    expect(find.textContaining('Hafıza tekniği'), findsOneWidget);
  });

  testWidgets('signs search filters the gallery', (tester) async {
    await pumpApp(tester);
    await _openLearn(tester);
    await tester.tap(find.text('Trafik İşaretleri'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kaygan');
    await tester.pumpAndSettle();

    expect(find.text('Kaygan Yol'), findsOneWidget);
    expect(find.text('Azami Hız 30'), findsNothing);
  });

  testWidgets('vehicle list renders parts and detail shows inspection steps', (tester) async {
    await pumpApp(tester);
    await _openLearn(tester);
    await tester.tap(find.text('Araç Tekniği'));
    await tester.pumpAndSettle();

    expect(find.text('Motor Bölmesi'), findsOneWidget);
    expect(find.text('Lastikler'), findsOneWidget);

    await tester.tap(find.text('Motor Bölmesi'));
    await tester.pumpAndSettle();

    expect(find.text('Kontrol adımları'), findsOneWidget);
    expect(find.text('Yağ seviyesi'), findsOneWidget);
  });

  testWidgets('videos list separates available and planned', (tester) async {
    await pumpApp(tester);
    await _openLearn(tester);
    await tester.tap(find.text('Videolar'));
    await tester.pumpAndSettle();

    expect(find.text('İzlenebilir'), findsOneWidget);
    expect(find.text('Paralel Park'), findsOneWidget);

    // the "Yakında" (planned) section is below the fold → scroll the planned card into view
    await tester.scrollUntilVisible(find.text('Yakında Video'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Yakında Video'), findsOneWidget);
  });
}
