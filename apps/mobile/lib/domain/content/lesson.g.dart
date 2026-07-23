// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Callout _$CalloutFromJson(Map<String, dynamic> json) => _Callout(
  tone: $enumDecode(_$CalloutToneEnumMap, json['tone']),
  title: json['title'] as String?,
  text: json['text'] as String,
);

Map<String, dynamic> _$CalloutToJson(_Callout instance) => <String, dynamic>{
  'tone': _$CalloutToneEnumMap[instance.tone]!,
  'title': instance.title,
  'text': instance.text,
};

const _$CalloutToneEnumMap = {
  CalloutTone.info: 'info',
  CalloutTone.success: 'success',
  CalloutTone.warning: 'warning',
  CalloutTone.danger: 'danger',
};

_CompareTable _$CompareTableFromJson(Map<String, dynamic> json) =>
    _CompareTable(
      caption: json['caption'] as String?,
      headers: (json['headers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList(),
    );

Map<String, dynamic> _$CompareTableToJson(_CompareTable instance) =>
    <String, dynamic>{
      'caption': instance.caption,
      'headers': instance.headers,
      'rows': instance.rows,
    };

_ReviewCard _$ReviewCardFromJson(Map<String, dynamic> json) =>
    _ReviewCard(front: json['front'] as String, back: json['back'] as String);

Map<String, dynamic> _$ReviewCardToJson(_ReviewCard instance) =>
    <String, dynamic>{'front': instance.front, 'back': instance.back};

_LessonMistake _$LessonMistakeFromJson(Map<String, dynamic> json) =>
    _LessonMistake(text: json['text'] as String, fix: json['fix'] as String);

Map<String, dynamic> _$LessonMistakeToJson(_LessonMistake instance) =>
    <String, dynamic>{'text': instance.text, 'fix': instance.fix};

_LessonSection _$LessonSectionFromJson(Map<String, dynamic> json) =>
    _LessonSection(
      heading: json['heading'] as String,
      badge: $enumDecodeNullable(_$BadgeEnumMap, json['badge']),
      body: json['body'] as String,
      callout: json['callout'] == null
          ? null
          : Callout.fromJson(json['callout'] as Map<String, dynamic>),
      compare: json['compare'] == null
          ? null
          : CompareTable.fromJson(json['compare'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LessonSectionToJson(_LessonSection instance) =>
    <String, dynamic>{
      'heading': instance.heading,
      'badge': _$BadgeEnumMap[instance.badge],
      'body': instance.body,
      'callout': instance.callout,
      'compare': instance.compare,
    };

const _$BadgeEnumMap = {
  Badge.official: 'official',
  Badge.examiner: 'examiner',
  Badge.instructor: 'instructor',
  Badge.best: 'best',
  Badge.safety: 'safety',
};

_Lesson _$LessonFromJson(Map<String, dynamic> json) => _Lesson(
  id: json['id'] as String,
  slug: json['slug'] as String,
  no: (json['no'] as num).toInt(),
  subject: $enumDecode(_$SubjectEnumMap, json['subject']),
  title: json['title'] as String,
  summary: json['summary'] as String,
  minutes: (json['minutes'] as num).toInt(),
  objectives: (json['objectives'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sections: (json['sections'] as List<dynamic>)
      .map((e) => LessonSection.fromJson(e as Map<String, dynamic>))
      .toList(),
  mistakes:
      (json['mistakes'] as List<dynamic>?)
          ?.map((e) => LessonMistake.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tips:
      (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  quizQuestionIds:
      (json['quizQuestionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  references:
      (json['references'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  memoryTips:
      (json['memoryTips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  examStrategy:
      (json['examStrategy'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  keyTakeaways:
      (json['keyTakeaways'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  reviewCards:
      (json['reviewCards'] as List<dynamic>?)
          ?.map((e) => ReviewCard.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  practiceQuestionIds:
      (json['practiceQuestionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  figureId: json['figureId'] as String?,
  premium: json['premium'] as bool? ?? false,
);

Map<String, dynamic> _$LessonToJson(_Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'no': instance.no,
  'subject': _$SubjectEnumMap[instance.subject]!,
  'title': instance.title,
  'summary': instance.summary,
  'minutes': instance.minutes,
  'objectives': instance.objectives,
  'sections': instance.sections,
  'mistakes': instance.mistakes,
  'tips': instance.tips,
  'quizQuestionIds': instance.quizQuestionIds,
  'references': instance.references,
  'memoryTips': instance.memoryTips,
  'examStrategy': instance.examStrategy,
  'keyTakeaways': instance.keyTakeaways,
  'reviewCards': instance.reviewCards,
  'practiceQuestionIds': instance.practiceQuestionIds,
  'figureId': instance.figureId,
  'premium': instance.premium,
};

const _$SubjectEnumMap = {
  Subject.trafik: 'trafik',
  Subject.ilkyardim: 'ilkyardim',
  Subject.motor: 'motor',
  Subject.adab: 'adab',
  Subject.pratik: 'pratik',
};
