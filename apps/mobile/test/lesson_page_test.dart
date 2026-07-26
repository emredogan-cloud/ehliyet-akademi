import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/lesson.dart';
import 'package:ehliyet_akademi/domain/content/lesson_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 11 — ders sayfası yeniden tasarımı.
///
/// Yol haritası "hero · ilerleme · süre · zorluk · hiyerarşi · hareket" istiyordu. Bu dosya,
/// bunların ölçülebilir olanlarını sabitler; özellikle **zorluğun uydurulmadığını**.
Lesson _lesson({int minutes = 8, int sections = 2, int mistakes = 1}) => Lesson(
  id: 'x',
  slug: 'x',
  no: 1,
  subject: Subject.trafik,
  title: 'Deneme dersi',
  summary: 'Özet.',
  minutes: minutes,
  objectives: const [],
  sections: [
    for (var i = 0; i < sections; i++) LessonSection(heading: 'B$i', body: 'gövde'),
  ],
  mistakes: [
    for (var i = 0; i < mistakes; i++) const LessonMistake(text: 'yanlış', fix: 'doğru'),
  ],
);

void main() {
  group('zorluk — TÜRETİLİR, veriye yazılmaz', () {
    test('kısa + az bölümlü ders kolaydır', () {
      expect(lessonDifficulty(_lesson(minutes: 5, sections: 2, mistakes: 1)), LessonDifficulty.kolay);
    });

    test('orta yüklü ders ortadır', () {
      expect(lessonDifficulty(_lesson(minutes: 10, sections: 4, mistakes: 2)), LessonDifficulty.orta);
    });

    test('uzun + çok bölümlü + çok tuzaklı ders zordur', () {
      expect(lessonDifficulty(_lesson(minutes: 20, sections: 5, mistakes: 3)), LessonDifficulty.zor);
    });

    test('DETERMİNİSTİKTİR — aynı ders hep aynı kademeyi verir', () {
      final l = _lesson(minutes: 12, sections: 3, mistakes: 2);
      final first = lessonDifficulty(l);
      for (var i = 0; i < 20; i++) {
        expect(lessonDifficulty(l), first);
      }
    });

    test('kademe MONOTONDUR — yük arttıkça zorluk azalmaz', () {
      var prev = 0;
      for (final m in [2, 6, 10, 14, 20, 30]) {
        final idx = LessonDifficulty.values.indexOf(lessonDifficulty(_lesson(minutes: m)));
        expect(idx, greaterThanOrEqualTo(prev), reason: '$m dk');
        prev = idx;
      }
    });
  });

  group('okuma ilerlemesi (saf)', () {
    test('içerik ekrana SIĞIYORSA ilerleme tamdır', () {
      // 0 dönseydi kısa derste çubuk hep boş kalırdı — yanlış bir "hiç okumadın" sinyali.
      expect(lessonReadingProgress(offset: 0, maxExtent: 0), 1);
    });

    test('orantılıdır ve 0..1 aralığına sıkışır', () {
      expect(lessonReadingProgress(offset: 50, maxExtent: 200), 0.25);
      expect(lessonReadingProgress(offset: -30, maxExtent: 200), 0);
      expect(lessonReadingProgress(offset: 999, maxExtent: 200), 1);
    });
  });

  group('konu görseli', () {
    test('her konunun bir görseli vardır ve konular AYRIŞIR', () {
      final assets = Subject.values.map(lessonHeroAsset).toList();
      expect(assets.every((a) => a.isNotEmpty), isTrue);
      expect(assets.toSet().length, Subject.values.length, reason: 'konular görselle ayrışmalı');
    });
  });

  group('ders sayfası yüzeyi', () {
    Future<void> openLesson(WidgetTester tester) async {
      await useTallSurface(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dersler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trafiğe Giriş'));
      await tester.pumpAndSettle();
    }

    testWidgets('hero: konu · başlık · süre · ZORLUK gösterilir', (tester) async {
      await openLesson(tester);

      // Süre ve zorluk künyesi hero'da olmalı.
      expect(find.textContaining(' dk'), findsWidgets);
      final labels = LessonDifficulty.values.map((d) => d.label);
      expect(
        labels.any((l) => find.text(l).evaluate().isNotEmpty),
        isTrue,
        reason: 'zorluk kademesi gösterilmeli',
      );
    });

    testWidgets('okuma ilerlemesi çubuğu vardır', (tester) async {
      await openLesson(tester);
      expect(find.byType(FractionallySizedBox), findsWidgets);
    });

    testWidgets('HAREKET azaltıldığında animasyon kurulmaz', (tester) async {
      // E13 erişilebilirlik kuralı: "animasyonları azalt" açıkken hareket üretilmez.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      await openLesson(tester);
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
