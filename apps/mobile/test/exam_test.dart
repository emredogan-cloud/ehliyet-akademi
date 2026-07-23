import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/collections.dart';
import 'package:ehliyet_akademi/domain/practice/exam.dart';
import 'package:ehliyet_akademi/domain/practice/historical.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String id, Subject subject, {Difficulty d = Difficulty.orta, int answer = 0, String topic = 'genel'}) =>
    Question(
      id: id,
      subject: subject,
      topic: topic,
      difficulty: d,
      stem: 'stem $id yeterince uzun bir soru',
      options: const ['a', 'b', 'c', 'd'],
      answerIndex: answer,
      explanation: 'açıklama yeterince uzun metin',
    );

/// A bank that fully covers the blueprint (23/12/9/6) with headroom + some signs/difficulty spread.
List<Question> _fullBank() => [
  for (var i = 0; i < 40; i++)
    _q('t$i', Subject.trafik, topic: i.isEven ? 'isaretler' : 'hiz', d: i % 3 == 0 ? Difficulty.zor : Difficulty.kolay),
  for (var i = 0; i < 20; i++) _q('i$i', Subject.ilkyardim, topic: 'kanama'),
  for (var i = 0; i < 15; i++) _q('m$i', Subject.motor, topic: 'motor-temel', d: Difficulty.zor),
  for (var i = 0; i < 10; i++) _q('a$i', Subject.adab, topic: 'empati'),
  for (var i = 0; i < 5; i++) _q('p$i', Subject.pratik, topic: 'direksiyon'), // excluded from exams
];

void main() {
  group('seededRng / hash32', () {
    test('seededRng is deterministic per seed and in [0,1)', () {
      final a = seededRng(42);
      final b = seededRng(42);
      final seqA = [for (var i = 0; i < 5; i++) a()];
      final seqB = [for (var i = 0; i < 5; i++) b()];
      expect(seqA, seqB);
      for (final v in seqA) {
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThan(1.0));
      }
      // different seed → different sequence
      expect(seededRng(43)(), isNot(seededRng(42)()));
    });

    test('hash32 stable + date-sensitive', () {
      expect(hash32('2026-07-23'), hash32('2026-07-23'));
      expect(hash32('2026-07-23'), isNot(hash32('2026-07-24')));
      expect(hash32('x'), matches(RegExp(r'^[0-9a-f]{8}$')));
      expect(seedFromDate('2026-07-23'), seedFromDate('2026-07-23'));
    });
  });

  group('buildExam', () {
    test('full blueprint → 50 questions, exact distribution, pass 35, no pratik', () {
      final exam = buildExam(_fullBank(), rng: seededRng(7));
      expect(exam.questions, hasLength(50));
      expect(exam.fullBlueprint, isTrue);
      expect(exam.passCorrect, 35);
      expect(exam.durationSeconds, 45 * 60);
      final bySubject = <Subject, int>{};
      for (final q in exam.questions) {
        bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
      }
      expect(bySubject[Subject.trafik], 23);
      expect(bySubject[Subject.ilkyardim], 12);
      expect(bySubject[Subject.motor], 9);
      expect(bySubject[Subject.adab], 6);
      expect(bySubject[Subject.pratik] ?? 0, 0);
    });

    test('deterministic with a seed', () {
      final a = buildExam(_fullBank(), rng: seededRng(99)).questions.map((q) => q.id).toList();
      final b = buildExam(_fullBank(), rng: seededRng(99)).questions.map((q) => q.id).toList();
      expect(a, b);
    });

    test('insufficient bank → fullBlueprint false, prorated pass', () {
      final small = [
        for (var i = 0; i < 5; i++) _q('t$i', Subject.trafik),
        for (var i = 0; i < 3; i++) _q('i$i', Subject.ilkyardim),
      ];
      final exam = buildExam(small, rng: seededRng(1));
      expect(exam.fullBlueprint, isFalse);
      expect(exam.questions.length, 8);
      expect(exam.passCorrect, lessThan(35));
    });
  });

  group('scoreExam', () {
    test('counts correct, pass threshold, per-subject; null = wrong', () {
      final qs = [
        _q('t0', Subject.trafik, answer: 1),
        _q('t1', Subject.trafik, answer: 2),
        _q('i0', Subject.ilkyardim, answer: 0),
      ];
      final res = scoreExam(qs, [1, 0, null], 2); // first right, second wrong, third empty
      expect(res.correct, 1);
      expect(res.total, 3);
      expect(res.wrong, 2);
      expect(res.passed, isFalse);
      final trafik = res.perSubject.firstWhere((s) => s.subject == Subject.trafik);
      expect(trafik.total, 2);
      expect(trafik.correct, 1);
    });
  });

  group('collections + historical', () {
    test('collections are deterministic per day seed and themed', () {
      final bank = _fullBank();
      final seed = seedFromDate('2026-07-23');
      final week = seedFromDate('week');
      final a = examCollections(bank, daySeed: seed, weekSeed: week);
      final b = examCollections(bank, daySeed: seed, weekSeed: week);
      expect(a.map((c) => c.questionIds).toList(), b.map((c) => c.questionIds).toList());
      final motor = a.firstWhere((c) => c.id == 'sadece-motor');
      final motorIds = motor.questionIds.toSet();
      expect(bank.where((q) => motorIds.contains(q.id)).every((q) => q.subject == Subject.motor), isTrue);
      expect(a.firstWhere((c) => c.id == 'gunun-sinavi').count, 50);
    });

    test('historical: 18 sessions newest-first; per-date exam deterministic', () {
      expect(historicalSessionDates, hasLength(18));
      final sessions = historicalSessions();
      expect(sessions.first.date.compareTo(sessions.last.date), greaterThan(0)); // newest first
      final bank = _fullBank();
      final e1 = historicalExam(bank, '2016-05-14').questions.map((q) => q.id).toList();
      final e2 = historicalExam(bank, '2016-05-14').questions.map((q) => q.id).toList();
      expect(e1, e2);
      expect(e1, hasLength(50));
    });
  });
}
