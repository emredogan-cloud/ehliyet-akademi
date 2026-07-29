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

/// Faz 11 — her soru TAM DÖRT seçenek taşır: A, B, C, D.
///
/// Gerçek e-Sınav dört şıklıdır. Uygulama bir dönem şık harfini `options.length`'ten türetiyordu
/// ve bankaya sızmış üç şıklı sorularda kullanıcı A-B-C görüyordu. Kural artık üç yerde birden
/// duruyor: şemada (`z.array(...).length(4)`), veri kümesinde ve burada.
const int kOptionCount = 4;

/// Bu soru A/B/C/D biçimine uyuyor mu?
///
/// Sunucudan gelen banka istemcinin kontrolü DIŞINDADIR: eski bir dağıtım ya da elle düzenlenmiş
/// bir kayıt yine üç şıklı gelebilir. Uygulamanın buna karşı bir tutumu olmalı — sessizce yanlış
/// harflendirmektense o soruyu hiç göstermemek dürüsttür.
bool isWellFormedQuestion(Question q) =>
    q.options.length == kOptionCount && q.answerIndex >= 0 && q.answerIndex < kOptionCount;
