import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/exam.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:ehliyet_akademi/features/practice/widgets/question_view.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 11 — her soru A/B/C/D. Kural üç yerde birden duruyor; bu dosya istemci tarafını kilitler.
void main() {
  Question q({required List<String> options, int answerIndex = 0, String id = 'x-1'}) => Question(
    id: id,
    subject: Subject.trafik,
    topic: 'genel',
    stem: 'Yeterince uzun bir soru metni burada duruyor.',
    options: options,
    answerIndex: answerIndex,
    explanation: 'Yeterince uzun bir açıklama burada duruyor.',
  );

  group('biçim kuralı', () {
    test('tam dört seçenek geçerli', () {
      expect(isWellFormedQuestion(q(options: const ['a', 'b', 'c', 'd'])), isTrue);
    });

    test('üç ya da beş seçenek geçersiz', () {
      expect(isWellFormedQuestion(q(options: const ['a', 'b', 'c'])), isFalse);
      expect(isWellFormedQuestion(q(options: const ['a', 'b', 'c', 'd', 'e'])), isFalse);
    });

    test('aralık dışı cevap geçersiz', () {
      expect(
        isWellFormedQuestion(q(options: const ['a', 'b', 'c', 'd'], answerIndex: 4)),
        isFalse,
      );
      expect(
        isWellFormedQuestion(q(options: const ['a', 'b', 'c', 'd'], answerIndex: -1)),
        isFalse,
      );
    });

    test('harfler A’dan D’ye', () {
      expect([for (var i = 0; i < kOptionCount; i++) optionLetter(i)], ['A', 'B', 'C', 'D']);
    });
  });

  group('bozuk soru kullanıcıya GÖSTERİLMEZ', () {
    /// Sunucudan gelen banka istemcinin kontrolü dışındadır; eski bir dağıtım üç şıklı soru
    /// gönderebilir. Sınav kurucusu onu almamalı.
    test('sınav kurucusu bozuk soruyu almaz', () {
      final pool = [
        for (var i = 0; i < 30; i++)
          q(id: 'ok-$i', options: const ['a', 'b', 'c', 'd'], answerIndex: i % 4),
        for (var i = 0; i < 10; i++) q(id: 'bad-$i', options: const ['a', 'b', 'c']),
      ];
      final exam = buildExam(pool);
      expect(exam.questions, isNotEmpty);
      for (final question in exam.questions) {
        expect(question.options.length, kOptionCount, reason: '${question.id} bozuk');
        expect(question.id, isNot(startsWith('bad-')));
      }
    });
  });

  group('ekranda', () {
    testWidgets('Akıllı Çalışma her soruda dört şık çizer', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester);

      await tapTab(tester, 'Pratik');
      await tester.tap(find.text('Akıllı Çalışma').last);
      await tester.pumpAndSettle();

      // Şık rozetleri: tam A, B, C, D.
      for (final letter in const ['A', 'B', 'C', 'D']) {
        expect(
          find.descendant(of: find.byType(OptionTile), matching: find.text(letter)),
          findsOneWidget,
          reason: '"$letter" şıkkı yok',
        );
      }
      expect(find.byType(OptionTile), findsNWidgets(kOptionCount));
    });
  });
}
