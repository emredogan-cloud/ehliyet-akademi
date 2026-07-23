// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traffic_sign.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrafficSign _$TrafficSignFromJson(Map<String, dynamic> json) => _TrafficSign(
  id: json['id'] as String,
  category: $enumDecode(_$SignCategoryEnumMap, json['category']),
  name: json['name'] as String,
  shape: $enumDecode(_$SignShapeEnumMap, json['shape']),
  glyph: json['glyph'] as String?,
  glyphText: json['glyphText'] as String?,
  meaning: json['meaning'] as String,
  memoryTip: json['memoryTip'] as String,
  examImportance: $enumDecode(_$ExamImportanceEnumMap, json['examImportance']),
  commonMistake: json['commonMistake'] as String?,
  relatedLessonSlug: json['relatedLessonSlug'] as String?,
  keywords:
      (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$TrafficSignToJson(_TrafficSign instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': _$SignCategoryEnumMap[instance.category]!,
      'name': instance.name,
      'shape': _$SignShapeEnumMap[instance.shape]!,
      'glyph': instance.glyph,
      'glyphText': instance.glyphText,
      'meaning': instance.meaning,
      'memoryTip': instance.memoryTip,
      'examImportance': _$ExamImportanceEnumMap[instance.examImportance]!,
      'commonMistake': instance.commonMistake,
      'relatedLessonSlug': instance.relatedLessonSlug,
      'keywords': instance.keywords,
    };

const _$SignCategoryEnumMap = {
  SignCategory.tehlike: 'tehlike',
  SignCategory.yasak: 'yasak',
  SignCategory.mecburiyet: 'mecburiyet',
  SignCategory.bilgi: 'bilgi',
  SignCategory.park: 'park',
  SignCategory.otoyol: 'otoyol',
  SignCategory.gecici: 'gecici',
  SignCategory.oncelik: 'oncelik',
};

const _$SignShapeEnumMap = {
  SignShape.triangle: 'triangle',
  SignShape.invTriangle: 'inv-triangle',
  SignShape.ring: 'ring',
  SignShape.disc: 'disc',
  SignShape.rectBlue: 'rect-blue',
  SignShape.rectGreen: 'rect-green',
  SignShape.octagon: 'octagon',
  SignShape.diamond: 'diamond',
};

const _$ExamImportanceEnumMap = {
  ExamImportance.cokYuksek: 'çok yüksek',
  ExamImportance.yuksek: 'yüksek',
  ExamImportance.orta: 'orta',
};
