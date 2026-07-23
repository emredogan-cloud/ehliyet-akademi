import 'dart:convert';

import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:ehliyet_akademi/features/progress/widgets/readiness_radar.dart';
import 'package:ehliyet_akademi/features/progress/widgets/study_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Map<String, Object> _seed() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final answers = [
    for (var i = 0; i < 12; i++)
      AnswerLog(
        questionId: 't$i',
        subject: Subject.trafik,
        topic: 'hiz',
        correct: i < 9,
        at: now,
      ).toJson(),
    for (var i = 0; i < 6; i++)
      AnswerLog(
        questionId: 'm$i',
        subject: Subject.motor,
        topic: 'motor',
        correct: i < 2,
        at: now,
      ).toJson(),
  ];
  return {
    'ea:answers:v1': jsonEncode(answers),
    'ea:counters:v1': jsonEncode({'examsFinished': 1}),
  };
}

void main() {
  testWidgets('Home → İstatistiklerim opens the progress screen with level/radar/badges', (
    tester,
  ) async {
    await pumpApp(tester, prefs: _seed());

    // On Home, the readiness card + a progress entry are present.
    await tester.scrollUntilVisible(
      find.text('İstatistiklerim'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('İstatistiklerim'));
    await tester.pumpAndSettle();

    expect(find.text('İlerleme'), findsWidgets); // app bar title
    expect(find.textContaining('Seviye'), findsOneWidget); // level card
    expect(find.text('Ders bazında ustalık'), findsOneWidget);
    expect(find.byType(ReadinessRadar), findsOneWidget);

    // heatmap + badges are below the fold → scroll the main list (heatmap has its own inner scroll)
    final mainList = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.byType(StudyHeatmap), 300, scrollable: mainList);
    await tester.pumpAndSettle();
    expect(find.byType(StudyHeatmap), findsOneWidget);

    await tester.scrollUntilVisible(find.text('İlk Adım'), 300, scrollable: mainList);
    await tester.pumpAndSettle();
    expect(find.text('İlk Adım'), findsOneWidget); // unlocked achievement (18 answers)
  });

  testWidgets('progress screen shows empty state with no data', (tester) async {
    await pumpApp(tester); // no answers
    await tester.scrollUntilVisible(
      find.text('İstatistiklerim'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('İstatistiklerim'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz veri yok'), findsOneWidget);
  });
}
