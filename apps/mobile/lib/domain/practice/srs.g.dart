// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SrsCard _$SrsCardFromJson(Map<String, dynamic> json) => _SrsCard(
  questionId: json['questionId'] as String,
  ease: (json['ease'] as num).toDouble(),
  intervalDays: (json['intervalDays'] as num).toInt(),
  repetitions: (json['repetitions'] as num).toInt(),
  dueAt: (json['dueAt'] as num).toInt(),
  reviews: (json['reviews'] as num).toInt(),
  lapses: (json['lapses'] as num).toInt(),
);

Map<String, dynamic> _$SrsCardToJson(_SrsCard instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'ease': instance.ease,
  'intervalDays': instance.intervalDays,
  'repetitions': instance.repetitions,
  'dueAt': instance.dueAt,
  'reviews': instance.reviews,
  'lapses': instance.lapses,
};

_AnswerLog _$AnswerLogFromJson(Map<String, dynamic> json) => _AnswerLog(
  questionId: json['questionId'] as String,
  subject: $enumDecode(_$SubjectEnumMap, json['subject']),
  topic: json['topic'] as String,
  correct: json['correct'] as bool,
  at: (json['at'] as num).toInt(),
);

Map<String, dynamic> _$AnswerLogToJson(_AnswerLog instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'subject': _$SubjectEnumMap[instance.subject]!,
      'topic': instance.topic,
      'correct': instance.correct,
      'at': instance.at,
    };

const _$SubjectEnumMap = {
  Subject.trafik: 'trafik',
  Subject.ilkyardim: 'ilkyardim',
  Subject.motor: 'motor',
  Subject.adab: 'adab',
  Subject.pratik: 'pratik',
};
