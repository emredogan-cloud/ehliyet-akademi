// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SnapshotCounts _$SnapshotCountsFromJson(Map<String, dynamic> json) =>
    _SnapshotCounts(
      lessons: (json['lessons'] as num).toInt(),
      signs: (json['signs'] as num).toInt(),
      vehicleParts: (json['vehicleParts'] as num).toInt(),
      videos: (json['videos'] as num).toInt(),
    );

Map<String, dynamic> _$SnapshotCountsToJson(_SnapshotCounts instance) =>
    <String, dynamic>{
      'lessons': instance.lessons,
      'signs': instance.signs,
      'vehicleParts': instance.vehicleParts,
      'videos': instance.videos,
    };

_ContentSnapshot _$ContentSnapshotFromJson(Map<String, dynamic> json) =>
    _ContentSnapshot(
      version: json['version'] as String,
      generatedAt: json['generatedAt'] as String,
      counts: SnapshotCounts.fromJson(json['counts'] as Map<String, dynamic>),
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      signs: (json['signs'] as List<dynamic>)
          .map((e) => TrafficSign.fromJson(e as Map<String, dynamic>))
          .toList(),
      vehicleParts: (json['vehicleParts'] as List<dynamic>)
          .map((e) => VehiclePart.fromJson(e as Map<String, dynamic>))
          .toList(),
      videos: (json['videos'] as List<dynamic>)
          .map((e) => VideoContent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContentSnapshotToJson(_ContentSnapshot instance) =>
    <String, dynamic>{
      'version': instance.version,
      'generatedAt': instance.generatedAt,
      'counts': instance.counts,
      'lessons': instance.lessons,
      'signs': instance.signs,
      'vehicleParts': instance.vehicleParts,
      'videos': instance.videos,
    };
