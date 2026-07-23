import 'package:freezed_annotation/freezed_annotation.dart';

import 'content_enums.dart';

part 'lesson.freezed.dart';
part 'lesson.g.dart';

/// Vurgu kutusu — ders içi görsel öne çıkarma (web `Callout`).
@freezed
abstract class Callout with _$Callout {
  const factory Callout({
    required CalloutTone tone,
    String? title,
    required String text,
  }) = _Callout;
  factory Callout.fromJson(Map<String, Object?> json) => _$CalloutFromJson(json);
}

/// Karşılaştırma tablosu (web `CompareTable`).
@freezed
abstract class CompareTable with _$CompareTable {
  const factory CompareTable({
    String? caption,
    required List<String> headers,
    required List<List<String>> rows,
  }) = _CompareTable;
  factory CompareTable.fromJson(Map<String, Object?> json) => _$CompareTableFromJson(json);
}

/// Aktif hatırlama kartı (web `ReviewCard`).
@freezed
abstract class ReviewCard with _$ReviewCard {
  const factory ReviewCard({required String front, required String back}) = _ReviewCard;
  factory ReviewCard.fromJson(Map<String, Object?> json) => _$ReviewCardFromJson(json);
}

/// Sık yapılan hata + düzeltmesi (web `Lesson.mistakes[]`).
@freezed
abstract class LessonMistake with _$LessonMistake {
  const factory LessonMistake({required String text, required String fix}) = _LessonMistake;
  factory LessonMistake.fromJson(Map<String, Object?> json) => _$LessonMistakeFromJson(json);
}

/// Ders bölümü (rozetli anlatım + opsiyonel görsel bloklar) (web `LessonSection`).
@freezed
abstract class LessonSection with _$LessonSection {
  const factory LessonSection({
    required String heading,
    Badge? badge,
    required String body,
    Callout? callout,
    CompareTable? compare,
  }) = _LessonSection;
  factory LessonSection.fromJson(Map<String, Object?> json) => _$LessonSectionFromJson(json);
}

/// Öğrenme dersi (web `Lesson`) — birebir alan eşlemesi.
@freezed
abstract class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String slug,
    required int no,
    required Subject subject,
    required String title,
    required String summary,
    required int minutes,
    required List<String> objectives,
    required List<LessonSection> sections,
    @Default([]) List<LessonMistake> mistakes,
    @Default([]) List<String> tips,
    @Default([]) List<String> quizQuestionIds,
    @Default([]) List<String> references,
    @Default([]) List<String> memoryTips,
    @Default([]) List<String> examStrategy,
    @Default([]) List<String> keyTakeaways,
    @Default([]) List<ReviewCard> reviewCards,
    @Default([]) List<String> practiceQuestionIds,
    String? figureId,
    @Default(false) bool premium,
  }) = _Lesson;
  factory Lesson.fromJson(Map<String, Object?> json) => _$LessonFromJson(json);
}
