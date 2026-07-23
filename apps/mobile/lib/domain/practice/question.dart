import 'package:freezed_annotation/freezed_annotation.dart';

import '../content/content_enums.dart';

part 'question.freezed.dart';
part 'question.g.dart';

/// Soru zorluğu (web `Difficulty`).
@JsonEnum()
enum Difficulty {
  @JsonValue('kolay')
  kolay,
  @JsonValue('orta')
  orta,
  @JsonValue('zor')
  zor;

  String get label => switch (this) {
    Difficulty.kolay => 'Kolay',
    Difficulty.orta => 'Orta',
    Difficulty.zor => 'Zor',
  };
}

/// e-Sınav sorusu (web `Question` yalın projeksiyonu — `/api/mobile/question-bank`).
@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required Subject subject,
    required String topic,
    @Default(Difficulty.orta) Difficulty difficulty,
    required String stem,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    Badge? badge,
    @Default([]) List<String> whyWrong,
  }) = _Question;
  factory Question.fromJson(Map<String, Object?> json) => _$QuestionFromJson(json);
}
