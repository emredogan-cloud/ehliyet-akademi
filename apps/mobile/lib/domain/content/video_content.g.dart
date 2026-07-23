// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoChapter _$VideoChapterFromJson(Map<String, dynamic> json) =>
    _VideoChapter(
      t: (json['t'] as num).toInt(),
      title: json['title'] as String,
    );

Map<String, dynamic> _$VideoChapterToJson(_VideoChapter instance) =>
    <String, dynamic>{'t': instance.t, 'title': instance.title};

_TranscriptCue _$TranscriptCueFromJson(Map<String, dynamic> json) =>
    _TranscriptCue(t: (json['t'] as num).toInt(), text: json['text'] as String);

Map<String, dynamic> _$TranscriptCueToJson(_TranscriptCue instance) =>
    <String, dynamic>{'t': instance.t, 'text': instance.text};

_VideoContent _$VideoContentFromJson(Map<String, dynamic> json) =>
    _VideoContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      src: json['src'] as String?,
      srcWebm: json['srcWebm'] as String?,
      poster: json['poster'] as String?,
      captions: json['captions'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((e) => VideoChapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      transcript:
          (json['transcript'] as List<dynamic>?)
              ?.map((e) => TranscriptCue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      relatedLessonSlug: json['relatedLessonSlug'] as String?,
    );

Map<String, dynamic> _$VideoContentToJson(_VideoContent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'src': instance.src,
      'srcWebm': instance.srcWebm,
      'poster': instance.poster,
      'captions': instance.captions,
      'duration': instance.duration,
      'chapters': instance.chapters,
      'transcript': instance.transcript,
      'relatedLessonSlug': instance.relatedLessonSlug,
    };
