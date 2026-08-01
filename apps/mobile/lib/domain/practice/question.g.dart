// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImageHotspot _$ImageHotspotFromJson(Map<String, dynamic> json) =>
    _ImageHotspot(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      label: json['label'] as String,
    );

Map<String, dynamic> _$ImageHotspotToJson(_ImageHotspot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
      'w': instance.w,
      'h': instance.h,
      'label': instance.label,
    };

_QuestionImage _$QuestionImageFromJson(Map<String, dynamic> json) =>
    _QuestionImage(
      assetId: json['assetId'] as String,
      alt: json['alt'] as String,
      caption: json['caption'] as String?,
      hotspots:
          (json['hotspots'] as List<dynamic>?)
              ?.map((e) => ImageHotspot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$QuestionImageToJson(_QuestionImage instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'alt': instance.alt,
      'caption': instance.caption,
      'hotspots': instance.hotspots,
    };

_QuestionMedia _$QuestionMediaFromJson(Map<String, dynamic> json) =>
    _QuestionMedia(
      images: (json['images'] as List<dynamic>)
          .map((e) => QuestionImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      layout:
          $enumDecodeNullable(_$MediaLayoutEnumMap, json['layout']) ??
          MediaLayout.single,
    );

Map<String, dynamic> _$QuestionMediaToJson(_QuestionMedia instance) =>
    <String, dynamic>{
      'images': instance.images,
      'layout': _$MediaLayoutEnumMap[instance.layout]!,
    };

const _$MediaLayoutEnumMap = {
  MediaLayout.single: 'single',
  MediaLayout.grid: 'grid',
  MediaLayout.compare: 'compare',
};

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
  kind:
      $enumDecodeNullable(_$QuestionKindEnumMap, json['kind']) ??
      QuestionKind.text,
  media: json['media'] == null
      ? null
      : QuestionMedia.fromJson(json['media'] as Map<String, dynamic>),
  objective: json['objective'] as String?,
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
  'kind': _$QuestionKindEnumMap[instance.kind]!,
  'media': instance.media,
  'objective': instance.objective,
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

const _$QuestionKindEnumMap = {
  QuestionKind.text: 'text',
  QuestionKind.image: 'image',
  QuestionKind.scenario: 'scenario',
  QuestionKind.diagram: 'diagram',
  QuestionKind.intersection: 'intersection',
  QuestionKind.sign: 'sign',
  QuestionKind.mechanic: 'mechanic',
  QuestionKind.dashboard: 'dashboard',
};
