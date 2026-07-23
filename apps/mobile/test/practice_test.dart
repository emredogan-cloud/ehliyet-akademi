import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:ehliyet_akademi/domain/practice/question_bank.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A tiny bank (5 theory questions) so the exam runner can be finished in a short test.
QuestionBank _smallBank() {
  Question q(String id, Subject s) => Question(
    id: id,
    subject: s,
    topic: 'genel',
    stem: 'Kısa soru $id yeterince uzun metin',
    options: const ['Birinci', 'İkinci', 'Üçüncü', 'Dördüncü'],
    answerIndex: 0,
    explanation: 'Açıklama yeterince uzun metin burada.',
  );
  final questions = [
    for (var i = 0; i < 3; i++) q('t$i', Subject.trafik),
    for (var i = 0; i < 2; i++) q('i$i', Subject.ilkyardim),
  ];
  return QuestionBank(
    version: 'small',
    generatedAt: '2026-07-23T00:00:00.000Z',
    count: questions.length,
    blueprint: const ExamBlueprint(
      totalQuestions: 50,
      passCorrect: 35,
      durationMinutes: 45,
      distribution: {'trafik': 23, 'ilkyardim': 12, 'motor': 9, 'adab': 6},
    ),
    questions: questions,
  );
}

Future<void> _openPractice(WidgetTester tester) async {
  await tester.tap(find.text('Pratik'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Pratik hub → Akıllı Çalışma: answering a question reveals feedback', (tester) async {
    await pumpApp(tester);
    await _openPractice(tester);
    expect(find.text('Pratik & Sınav'), findsOneWidget);

    await tester.tap(find.text('Akıllı Çalışma'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/ 10'), findsOneWidget); // question counter (SRS session of 10)

    await tester.tap(find.text('Birinci').first); // answerIndex 0 → correct
    await tester.pumpAndSettle();

    expect(find.text('Doğru!'), findsOneWidget); // instant feedback
    expect(find.text('Sonraki soru'), findsOneWidget);
  });

  testWidgets('Deneme Sınavı: builds an exam, runs, and scores on finish', (tester) async {
    await pumpApp(tester, bank: _smallBank());
    await _openPractice(tester);

    await tester.tap(find.text('Deneme Sınavı'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5'), findsOneWidget); // 5-question shortened exam
    expect(find.textContaining('yanıtlandı'), findsOneWidget);

    // advance to the last question, then finish
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Sonraki'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Bitir')); // opens confirm dialog
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Bitir').last); // confirm
    await tester.pumpAndSettle();

    expect(find.text('KALDIN'), findsOneWidget); // nothing answered → fail
    expect(find.text('Başarı'), findsOneWidget);
  });

  testWidgets('Koleksiyonlar lists themed sets and opens one', (tester) async {
    await pumpApp(tester);
    await _openPractice(tester);

    await tester.tap(find.text('Koleksiyonlar'));
    await tester.pumpAndSettle();

    expect(find.text('Günün Sınavı'), findsOneWidget);
    expect(find.text('Zor Sorular'), findsOneWidget);

    await tester.tap(find.text('Günün Sınavı'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 50'), findsOneWidget); // collection opened as a runnable exam
  });

  testWidgets('Geçmiş Sınavlar lists MEB sessions', (tester) async {
    await pumpApp(tester);
    await _openPractice(tester);

    await tester.tap(find.text('Geçmiş Sınavlar'));
    await tester.pumpAndSettle();

    expect(find.text('MEB formatında hazırlanmış özgün deneme sınavı'), findsOneWidget);
    expect(find.text('2018'), findsOneWidget); // year header
    expect(find.text('Ağustos 2018'), findsOneWidget); // newest session
  });
}
