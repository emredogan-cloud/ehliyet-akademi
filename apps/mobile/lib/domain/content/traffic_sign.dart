import 'package:freezed_annotation/freezed_annotation.dart';

import 'content_enums.dart';

part 'traffic_sign.freezed.dart';
part 'traffic_sign.g.dart';

/// Trafik işareti (web `TrafficSign`) — şekil + glyph parametrik çizim için taşınır.
@freezed
abstract class TrafficSign with _$TrafficSign {
  const factory TrafficSign({
    required String id,
    required SignCategory category,
    required String name,
    required SignShape shape,
    String? glyph,
    String? glyphText,
    required String meaning,
    required String memoryTip,
    required ExamImportance examImportance,
    String? commonMistake,
    String? relatedLessonSlug,
    @Default([]) List<String> keywords,
  }) = _TrafficSign;
  factory TrafficSign.fromJson(Map<String, Object?> json) => _$TrafficSignFromJson(json);
}
