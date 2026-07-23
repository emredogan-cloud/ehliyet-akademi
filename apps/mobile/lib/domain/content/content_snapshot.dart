import 'package:freezed_annotation/freezed_annotation.dart';

import 'lesson.dart';
import 'traffic_sign.dart';
import 'vehicle_part.dart';
import 'video_content.dart';

part 'content_snapshot.freezed.dart';
part 'content_snapshot.g.dart';

/// İçerik anlık görüntüsü sayaçları (`/api/mobile/content-snapshot` → counts).
@freezed
abstract class SnapshotCounts with _$SnapshotCounts {
  const factory SnapshotCounts({
    required int lessons,
    required int signs,
    required int vehicleParts,
    required int videos,
  }) = _SnapshotCounts;
  factory SnapshotCounts.fromJson(Map<String, Object?> json) => _$SnapshotCountsFromJson(json);
}

/// Tüm öğrenme içeriğinin çevrimdışı-öncelikli anlık görüntüsü.
@freezed
abstract class ContentSnapshot with _$ContentSnapshot {
  const factory ContentSnapshot({
    required String version,
    required String generatedAt,
    required SnapshotCounts counts,
    required List<Lesson> lessons,
    required List<TrafficSign> signs,
    required List<VehiclePart> vehicleParts,
    required List<VideoContent> videos,
  }) = _ContentSnapshot;
  factory ContentSnapshot.fromJson(Map<String, Object?> json) => _$ContentSnapshotFromJson(json);
}
