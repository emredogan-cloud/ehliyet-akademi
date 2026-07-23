import 'package:freezed_annotation/freezed_annotation.dart';

import 'question.dart';

part 'question_bank.freezed.dart';
part 'question_bank.g.dart';

/// Gerçek e-Sınav yapısı (web `EXAM_BLUEPRINT`): 50 soru · 45 dk · baraj 35 · dağılım 23/12/9/6.
@freezed
abstract class ExamBlueprint with _$ExamBlueprint {
  const factory ExamBlueprint({
    required int totalQuestions,
    required int passCorrect,
    required int durationMinutes,
    required Map<String, int> distribution,
  }) = _ExamBlueprint;
  factory ExamBlueprint.fromJson(Map<String, Object?> json) => _$ExamBlueprintFromJson(json);
}

/// Soru bankası anlık görüntüsü (`/api/mobile/question-bank`).
@freezed
abstract class QuestionBank with _$QuestionBank {
  const factory QuestionBank({
    required String version,
    required String generatedAt,
    required int count,
    required ExamBlueprint blueprint,
    required List<Question> questions,
  }) = _QuestionBank;
  factory QuestionBank.fromJson(Map<String, Object?> json) => _$QuestionBankFromJson(json);
}
