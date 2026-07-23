// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  id: json['id'] as String,
  subject: $enumDecode(_$SubjectEnumMap, json['subject']),
  topic: json['topic'] as String,
  difficulty:
      $enumDecodeNullable(_$DifficultyEnumMap, json['difficulty']) ??
      Difficulty.orta,
  stem: json['stem'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  answerIndex: (json['answerIndex'] as num).toInt(),
  explanation: json['explanation'] as String,
  badge: $enumDecodeNullable(_$BadgeEnumMap, json['badge']),
  whyWrong:
      (json['whyWrong'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'id': instance.id,
  'subject': _$SubjectEnumMap[instance.subject]!,
  'topic': instance.topic,
  'difficulty': _$DifficultyEnumMap[instance.difficulty]!,
  'stem': instance.stem,
  'options': instance.options,
  'answerIndex': instance.answerIndex,
  'explanation': instance.explanation,
  'badge': _$BadgeEnumMap[instance.badge],
  'whyWrong': instance.whyWrong,
};

const _$SubjectEnumMap = {
  Subject.trafik: 'trafik',
  Subject.ilkyardim: 'ilkyardim',
  Subject.motor: 'motor',
  Subject.adab: 'adab',
  Subject.pratik: 'pratik',
};

const _$DifficultyEnumMap = {
  Difficulty.kolay: 'kolay',
  Difficulty.orta: 'orta',
  Difficulty.zor: 'zor',
};

const _$BadgeEnumMap = {
  Badge.official: 'official',
  Badge.examiner: 'examiner',
  Badge.instructor: 'instructor',
  Badge.best: 'best',
  Badge.safety: 'safety',
};
