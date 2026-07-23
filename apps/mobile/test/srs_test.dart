import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String id, Subject subject, String topic) => Question(
  id: id,
  subject: subject,
  topic: topic,
  stem: 'stem for $id — yeterince uzun bir soru metni',
  options: const ['a', 'b', 'c', 'd'],
  answerIndex: 0,
  explanation: 'açıklama metni yeterince uzun',
);

void main() {
  const now = 1000000000000;

  group('SM-2 review', () {
    test('newCard defaults', () {
      final c = newCard('q1', now);
      expect(c.ease, 2.5);
      expect(c.intervalDays, 0);
      expect(c.repetitions, 0);
      expect(c.dueAt, now);
    });

    test('grade good (4) keeps ease, interval 1 day, first rep', () {
      final c = review(newCard('q1', now), 4, now);
      expect(c.ease, closeTo(2.5, 1e-9));
      expect(c.repetitions, 1);
      expect(c.intervalDays, 1);
      expect(c.dueAt, now + dayMs);
      expect(c.reviews, 1);
    });

    test('grade easy (5) raises ease to 2.6', () {
      final c = review(newCard('q1', now), 5, now);
      expect(c.ease, closeTo(2.6, 1e-9));
    });

    test('grade hard (3) lowers ease to 2.36', () {
      final c = review(newCard('q1', now), 3, now);
      expect(c.ease, closeTo(2.36, 1e-9));
    });

    test('fail (grade 1) resets interval/reps, +lapse, ease -0.2, due ~10 min', () {
      final good = review(newCard('q1', now), 4, now); // rep 1
      final fail = review(good, 1, now + dayMs);
      expect(fail.repetitions, 0);
      expect(fail.intervalDays, 0);
      expect(fail.lapses, 1);
      expect(fail.ease, closeTo(2.3, 1e-9));
      expect(fail.dueAt, (now + dayMs) + (0.007 * dayMs).round()); // ~10 min
    });

    test('two good reviews → interval 6 on second rep', () {
      final r1 = review(newCard('q1', now), 4, now); // interval 1
      final r2 = review(r1, 4, now + dayMs); // rep 2 → interval 6
      expect(r2.repetitions, 2);
      expect(r2.intervalDays, 6);
    });

    test('ease floor is 1.3', () {
      var c = newCard('q1', now);
      for (var i = 0; i < 20; i++) {
        c = review(c, 1, now); // repeated fails
      }
      expect(c.ease, minEase);
    });

    test('toGrade maps outcomes; isDue compares dueAt', () {
      expect(toGrade('again'), 1);
      expect(toGrade('hard'), 3);
      expect(toGrade('good'), 4);
      expect(toGrade('easy'), 5);
      final c = newCard('q1', now);
      expect(isDue(c, now), isTrue);
      expect(isDue(c, now - 1), isFalse);
    });
  });

  group('selectNext', () {
    test('overdue cards outrank unseen; weak topics weighted', () {
      final pool = [
        _q('seen-due', Subject.trafik, 'hiz'),
        _q('unseen', Subject.trafik, 'hiz'),
      ];
      final overdue = newCard('seen-due', now).copyWith(dueAt: now - 5 * dayMs, lapses: 2);
      final ids = selectNext(pool, {'seen-due': overdue}, {'hiz': 0.2}, now, 2);
      expect(ids.first, 'seen-due'); // overdue+lapses beats unseen
    });
  });

  group('readiness', () {
    test('statsFromAnswers + computeReadiness weight by exam distribution', () {
      final answers = [
        for (var i = 0; i < 10; i++)
          AnswerLog(questionId: 't$i', subject: Subject.trafik, topic: 'hiz', correct: true, at: now),
        for (var i = 0; i < 10; i++)
          AnswerLog(
            questionId: 'i$i',
            subject: Subject.ilkyardim,
            topic: 'kanama',
            correct: i < 5,
            at: now,
          ),
      ];
      final stats = statsFromAnswers(answers);
      final trafik = stats.subjects.firstWhere((s) => s.subject == Subject.trafik);
      expect(trafik.mastery, 1.0);
      final r = computeReadiness(stats.subjects);
      expect(r.overall, inInclusiveRange(0, 100));
      expect(r.predictedPassProbability, inInclusiveRange(0.0, 1.0));
      expect(r.perSubject, isNotEmpty);
      // pratik excluded from readiness
      expect(r.perSubject.any((p) => p.subject == Subject.pratik), isFalse);
    });

    test('lightFor thresholds', () {
      expect(lightFor(0.9), TrafficLight.yesil);
      expect(lightFor(0.6), TrafficLight.sari);
      expect(lightFor(0.3), TrafficLight.kirmizi);
    });
  });

  test('SrsCard json round-trip (persist shape)', () {
    final c = review(newCard('q1', now), 4, now);
    final restored = SrsCard.fromJson(c.toJson());
    expect(restored, c);
  });
}
