import 'package:freezed_annotation/freezed_annotation.dart';

import 'content_enums.dart';

part 'vehicle_part.freezed.dart';
part 'vehicle_part.g.dart';

/// Araç bileşeni (web `VehiclePart`).
@freezed
abstract class VehiclePart with _$VehiclePart {
  const factory VehiclePart({
    required String id,
    required String name,
    required VehicleSystem system,
    required String desc,
    required String tip,
    String? relatedLessonSlug,
    String? photo,
    @Default([]) List<String> inspection,
    String? mistake,
  }) = _VehiclePart;
  factory VehiclePart.fromJson(Map<String, Object?> json) => _$VehiclePartFromJson(json);
}
