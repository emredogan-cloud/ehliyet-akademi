import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:ehliyet_akademi/domain/progress/gamification.dart';
import 'package:flutter_test/flutter_test.dart';

AnswerLog _a(bool correct, {int at = 1700000000000, String topic = 'hiz'}) =>
    AnswerLog(questionId: 'q', subject: Subject.trafik, topic: topic, correct: correct, at: at);

void main() {
  group('XP + levels', () {
    test('xp: correct=10, wrong=3', () {
      expect(xpFromAnswers([_a(true), _a(true), _a(false)]), 23);
      expect(xpFromAnswers(const []), 0);
    });

    test('level thresholds 0/100/300/600', () {
      expect(levelForXp(0).level, 1);
      expect(levelForXp(99).level, 1);
      expect(levelForXp(100).level, 2);
      expect(levelForXp(299).level, 2);
      expect(levelForXp(300).level, 3);
      final l = levelForXp(150);
      expect(l.level, 2);
      expect(l.levelStartXp, 100);
      expect(l.nextLevelXp, 300);
      expect(l.xpToNext, 150);
      expect(l.progress, closeTo(0.25, 1e-9));
    });
  });

  group('achievements', () {
    test('unlock by thresholds', () {
      final many = [for (var i = 0; i < 100; i++) _a(i < 60)];
      final ach = computeAchievements(
        answers: many,
        streak: const StreakState(current: 3, best: 8, lastDay: '2026-07-23'),
        examsFinished: 1,
      );
      Achievement byId(String id) => ach.firstWhere((a) => a.id == id);
      expect(byId('first-steps').unlocked, isTrue);
      expect(byId('century').unlocked, isTrue); // 100 answered
      expect(byId('sharp').unlocked, isTrue); // 60 correct >= 50
      expect(byId('streak-7').unlocked, isTrue); // best 8
      expect(byId('first-exam').unlocked, isTrue);
      expect(byId('exam-veteran').unlocked, isFalse); // needs 10
    });

    test('nothing unlocked at zero', () {
      final ach = computeAchievements(
        answers: const [],
        streak: StreakState.empty,
        examsFinished: 0,
      );
      expect(ach.every((a) => !a.unlocked), isTrue);
    });
  });

  test('answersPerDay groups by local day', () {
    final d1 = DateTime(2026, 7, 20, 10).millisecondsSinceEpoch;
    final d2 = DateTime(2026, 7, 21, 9).millisecondsSinceEpoch;
    final map = answersPerDay([_a(true, at: d1), _a(false, at: d1), _a(true, at: d2)]);
    expect(map['2026-07-20'], 2);
    expect(map['2026-07-21'], 1);
  });
}
