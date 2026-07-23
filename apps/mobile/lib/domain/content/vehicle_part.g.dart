// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehiclePart _$VehiclePartFromJson(Map<String, dynamic> json) => _VehiclePart(
  id: json['id'] as String,
  name: json['name'] as String,
  system: $enumDecode(_$VehicleSystemEnumMap, json['system']),
  desc: json['desc'] as String,
  tip: json['tip'] as String,
  relatedLessonSlug: json['relatedLessonSlug'] as String?,
  photo: json['photo'] as String?,
  inspection:
      (json['inspection'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  mistake: json['mistake'] as String?,
);

Map<String, dynamic> _$VehiclePartToJson(_VehiclePart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'system': _$VehicleSystemEnumMap[instance.system]!,
      'desc': instance.desc,
      'tip': instance.tip,
      'relatedLessonSlug': instance.relatedLessonSlug,
      'photo': instance.photo,
      'inspection': instance.inspection,
      'mistake': instance.mistake,
    };

const _$VehicleSystemEnumMap = {
  VehicleSystem.motorBolmesi: 'motor-bolmesi',
  VehicleSystem.kabin: 'kabin',
  VehicleSystem.dis: 'dis',
  VehicleSystem.muayene: 'muayene',
};
