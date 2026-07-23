import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../content/content_enums.dart';
import 'question.dart';

part 'srs.freezed.dart';
part 'srs.g.dart';

/// Öğrenme bilimi çekirdeği — web `@ea/srs-engine`'in birebir Dart limanı (SM-2 + adaptif seçim +
/// hazırlık skoru). Saf, yan-etkisiz; `now` (epoch ms) dışarıdan verilir → deterministik test.

const int dayMs = 86400000;
const double minEase = 1.3;

/// e-Sınav dağılımı (web `EXAM_BLUEPRINT.distribution` + total).
const Map<String, int> examDistribution = {'trafik': 23, 'ilkyardim': 12, 'motor': 9, 'adab': 6};
const int examTotalQuestions = 50;

/// Bir sorunun kullanıcıdaki tekrar kartı (persist: `ea:cards:v1` → questionId→SrsCard).
@freezed
abstract class SrsCard with _$SrsCard {
  const factory SrsCard({
    required String questionId,
    required double ease,
    required int intervalDays,
    required int repetitions,
    required int dueAt,
    required int reviews,
    required int lapses,
  }) = _SrsCard;
  factory SrsCard.fromJson(Map<String, Object?> json) => _$SrsCardFromJson(json);
}

/// Cevap kaydı (persist: `ea:answers:v1`, son 2000 ile sınırlı).
@freezed
abstract class AnswerLog with _$AnswerLog {
  const factory AnswerLog({
    required String questionId,
    required Subject subject,
    required String topic,
    required bool correct,
    required int at,
  }) = _AnswerLog;
  factory AnswerLog.fromJson(Map<String, Object?> json) => _$AnswerLogFromJson(json);
}

/// Yeni kart (henüz çalışılmamış soru).
SrsCard newCard(String questionId, int now) => SrsCard(
  questionId: questionId,
  ease: 2.5,
  intervalDays: 0,
  repetitions: 0,
  dueAt: now,
  reviews: 0,
  lapses: 0,
);

/// SM-2 tekrar adımı. grade < 3 → başarısız (aralık sıfırlanır, ceza; ~10 dk sonra tekrar).
SrsCard review(SrsCard card, int grade, int now) {
  final reviews = card.reviews + 1;
  var ease = card.ease;
  var intervalDays = card.intervalDays;
  var repetitions = card.repetitions;
  var lapses = card.lapses;

  if (grade < 3) {
    repetitions = 0;
    intervalDays = 0;
    lapses += 1;
    ease = math.max(minEase, ease - 0.2);
  } else {
    repetitions += 1;
    ease = math.max(minEase, ease + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02)));
    if (repetitions == 1) {
      intervalDays = 1;
    } else if (repetitions == 2) {
      intervalDays = 6;
    } else {
      intervalDays = (card.intervalDays * ease).round();
    }
    intervalDays = math.min(math.max(intervalDays, 1), 180);
  }

  final dueDelta = grade < 3 ? (0.007 * dayMs).round() : intervalDays * dayMs;
  return card.copyWith(
    ease: ease,
    intervalDays: intervalDays,
    repetitions: repetitions,
    reviews: reviews,
    lapses: lapses,
    dueAt: now + dueDelta,
  );
}

/// 4-kademeli UI cevabını SM-2 grade'ine çevir.
int toGrade(String outcome) => switch (outcome) {
  'again' => 1,
  'hard' => 3,
  'good' => 4,
  'easy' => 5,
  _ => 4,
};

bool isDue(SrsCard card, int now) => card.dueAt <= now;

/// Adaptif seçim: vadesi gelen + görülmemiş sorulardan, zayıf konulara ağırlıkla `limit` id seç.
List<String> selectNext(
  List<Question> pool,
  Map<String, SrsCard> cards,
  Map<String, double> topicMastery,
  int now,
  int limit,
) {
  final scored = pool.map((q) {
    final card = cards[q.id];
    final mastery = topicMastery[q.topic] ?? 0.0;
    var score = 0.0;
    if (card != null) {
      score += isDue(card, now) ? 100 + (now - card.dueAt) / dayMs : -50;
      score += card.lapses * 10;
    } else {
      score += 40;
    }
    score += (1 - mastery) * 60;
    return (id: q.id, score: score);
  }).toList();
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).map((s) => s.id).toList();
}

/// Ders bazlı istatistik.
class SubjectStat {
  const SubjectStat({
    required this.subject,
    required this.answered,
    required this.correct,
    required this.mastery,
  });
  final Subject subject;
  final int answered;
  final int correct;
  final double mastery;
}

enum TrafficLight { kirmizi, sari, yesil }

class PerSubjectReadiness {
  const PerSubjectReadiness({required this.subject, required this.mastery, required this.light});
  final Subject subject;
  final double mastery;
  final TrafficLight light;
}

class Readiness {
  const Readiness({
    required this.overall,
    required this.predictedPassProbability,
    required this.light,
    required this.perSubject,
    required this.message,
  });
  final int overall;
  final double predictedPassProbability;
  final TrafficLight light;
  final List<PerSubjectReadiness> perSubject;
  final String message;
}

TrafficLight lightFor(double mastery) {
  if (mastery >= 0.8) return TrafficLight.yesil;
  if (mastery >= 0.55) return TrafficLight.sari;
  return TrafficLight.kirmizi;
}

/// Hazırlık skoru — e-Sınav dağılımına göre ağırlıklı ders ustalığı + kalibre sigmoid geçme olasılığı.
Readiness computeReadiness(List<SubjectStat> stats) {
  final weights = <String, double>{
    'trafik': examDistribution['trafik']! / examTotalQuestions,
    'ilkyardim': examDistribution['ilkyardim']! / examTotalQuestions,
    'motor': examDistribution['motor']! / examTotalQuestions,
    'adab': examDistribution['adab']! / examTotalQuestions,
  };

  var weighted = 0.0;
  var weightSum = 0.0;
  final perSubject = <PerSubjectReadiness>[];
  for (final s in stats.where((s) => s.subject != Subject.pratik)) {
    final w = weights[s.subject.name] ?? 0.0;
    final confidence = math.min(1.0, s.answered / 8);
    final adjusted = s.mastery * confidence;
    weighted += adjusted * w;
    weightSum += w;
    perSubject.add(
      PerSubjectReadiness(subject: s.subject, mastery: s.mastery, light: lightFor(adjusted)),
    );
  }

  final overallFrac = weightSum > 0 ? weighted / weightSum : 0.0;
  final overall = (overallFrac * 100).round();

  const k = 12;
  final predictedPassProbability = 1 / (1 + math.exp(-k * (overallFrac - 0.7)));

  final light = lightFor(overallFrac);
  final message = light == TrafficLight.yesil
      ? 'Sınava hazırsın. Zayıf kalan birkaç konuyu tazele, güvenle gir.'
      : light == TrafficLight.sari
      ? 'İyi yoldasın ama henüz garanti değil. Kırmızı/sarı konulara odaklan.'
      : 'Şu an girsen risk yüksek. Temel konulardan başlayarak çalışmaya devam et.';

  return Readiness(
    overall: overall,
    predictedPassProbability: (predictedPassProbability * 100).round() / 100,
    light: light,
    perSubject: perSubject,
    message: message,
  );
}

/// Cevap kayıtlarından ders + konu istatistiği üret.
({List<SubjectStat> subjects, Map<String, double> topicMastery}) statsFromAnswers(
  List<AnswerLog> answers,
) {
  final bySubject = <Subject, ({int answered, int correct})>{};
  final byTopic = <String, ({int answered, int correct})>{};
  for (final a in answers) {
    final s = bySubject[a.subject] ?? (answered: 0, correct: 0);
    bySubject[a.subject] = (answered: s.answered + 1, correct: s.correct + (a.correct ? 1 : 0));
    final t = byTopic[a.topic] ?? (answered: 0, correct: 0);
    byTopic[a.topic] = (answered: t.answered + 1, correct: t.correct + (a.correct ? 1 : 0));
  }
  final subjects = bySubject.entries
      .map(
        (e) => SubjectStat(
          subject: e.key,
          answered: e.value.answered,
          correct: e.value.correct,
          mastery: e.value.answered > 0 ? e.value.correct / e.value.answered : 0.0,
        ),
      )
      .toList();
  final topicMastery = <String, double>{};
  for (final e in byTopic.entries) {
    topicMastery[e.key] = e.value.answered > 0 ? e.value.correct / e.value.answered : 0.0;
  }
  return (subjects: subjects, topicMastery: topicMastery);
}
