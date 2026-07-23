import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_content.freezed.dart';
part 'video_content.g.dart';

/// Video bölümü (zaman damgalı içindekiler) (web `VideoChapter`).
@freezed
abstract class VideoChapter with _$VideoChapter {
  const factory VideoChapter({required int t, required String title}) = _VideoChapter;
  factory VideoChapter.fromJson(Map<String, Object?> json) => _$VideoChapterFromJson(json);
}

/// Transkript satırı (web `TranscriptCue`).
@freezed
abstract class TranscriptCue with _$TranscriptCue {
  const factory TranscriptCue({required int t, required String text}) = _TranscriptCue;
  factory TranscriptCue.fromJson(Map<String, Object?> json) => _$TranscriptCueFromJson(json);
}

/// Video içeriği (web `VideoContent`). `available` olmayanlar `planned` (medya yok).
@freezed
abstract class VideoContent with _$VideoContent {
  const factory VideoContent({
    required String id,
    required String title,
    required String description,
    required String status,
    String? src,
    String? srcWebm,
    String? poster,
    String? captions,
    int? duration,
    @Default([]) List<VideoChapter> chapters,
    @Default([]) List<TranscriptCue> transcript,
    String? relatedLessonSlug,
  }) = _VideoContent;
  factory VideoContent.fromJson(Map<String, Object?> json) => _$VideoContentFromJson(json);

  const VideoContent._();

  /// Oynatılabilir mi (gerçek medya var mı)?
  bool get isAvailable => status == 'available' && (src != null && src!.isNotEmpty);
}
