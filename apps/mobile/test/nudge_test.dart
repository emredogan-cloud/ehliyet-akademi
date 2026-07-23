import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/coach/nudge.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:flutter_test/flutter_test.dart';

const _now = 1_700_000_000_000; // fixed epoch ms

String _dayKey(int nowMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

Readiness _readiness(TrafficLight light, int overall, List<PerSubjectReadiness> per) => Readiness(
  overall: overall,
  predictedPassProbability: 0.5,
  light: light,
  perSubject: per,
  message: 'm',
);

void main() {
  final today = _dayKey(_now);
  final yesterday = _dayKey(_now - dayMs);

  test('no answers → single welcome nudge', () {
    final n = computeNudges(
      readiness: null,
      streak: StreakState.empty,
      dueCount: 0,
      answered: 0,
      nowMs: _now,
    );
    expect(n, hasLength(1));
    expect(n.single.id, 'welcome');
  });

  test('streak-protection fires first when studied yesterday not today', () {
    final n = computeNudges(
      readiness: null,
      streak: StreakState(current: 3, best: 5, lastDay: yesterday),
      dueCount: 0,
      answered: 20,
      nowMs: _now,
    );
    expect(n.first.id, 'streak-protection');
    expect(n.first.title, contains('3'));
  });

  test('due-cards nudge when cards are due', () {
    final n = computeNudges(
      readiness: null,
      streak: StreakState(current: 1, best: 1, lastDay: today),
      dueCount: 8,
      answered: 20,
      nowMs: _now,
    );
    expect(n.any((x) => x.id == 'due-cards' && x.body.contains('8')), isTrue);
  });

  test('red readiness → low-readiness + weak-subject nudges', () {
    final n = computeNudges(
      readiness: _readiness(TrafficLight.kirmizi, 40, [
        const PerSubjectReadiness(subject: Subject.trafik, mastery: 0.3, light: TrafficLight.kirmizi),
        const PerSubjectReadiness(subject: Subject.motor, mastery: 0.6, light: TrafficLight.sari),
      ]),
      streak: StreakState(current: 1, best: 1, lastDay: today),
      dueCount: 0,
      answered: 30,
      nowMs: _now,
    );
    expect(n.any((x) => x.id == 'exam-readiness-low'), isTrue);
    // weakest subject (trafik, 0.3) surfaced
    expect(n.any((x) => x.id.startsWith('weak-topic-') && x.title.contains('Trafik')), isTrue);
  });

  test('green readiness → exam-ready nudge points to a mock exam', () {
    final n = computeNudges(
      readiness: _readiness(TrafficLight.yesil, 88, [
        const PerSubjectReadiness(subject: Subject.trafik, mastery: 0.9, light: TrafficLight.yesil),
      ]),
      streak: StreakState(current: 1, best: 1, lastDay: today),
      dueCount: 0,
      answered: 60,
      nowMs: _now,
    );
    final ready = n.firstWhere((x) => x.id == 'exam-ready');
    expect(ready.action, '/practice/exam');
    expect(ready.tone, NudgeTone.good);
  });
}
