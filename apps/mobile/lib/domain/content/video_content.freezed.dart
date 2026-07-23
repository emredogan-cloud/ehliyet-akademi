// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoChapter {

 int get t; String get title;
/// Create a copy of VideoChapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoChapterCopyWith<VideoChapter> get copyWith => _$VideoChapterCopyWithImpl<VideoChapter>(this as VideoChapter, _$identity);

  /// Serializes this VideoChapter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoChapter&&(identical(other.t, t) || other.t == t)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,title);

@override
String toString() {
  return 'VideoChapter(t: $t, title: $title)';
}


}

/// @nodoc
abstract mixin class $VideoChapterCopyWith<$Res>  {
  factory $VideoChapterCopyWith(VideoChapter value, $Res Function(VideoChapter) _then) = _$VideoChapterCopyWithImpl;
@useResult
$Res call({
 int t, String title
});




}
/// @nodoc
class _$VideoChapterCopyWithImpl<$Res>
    implements $VideoChapterCopyWith<$Res> {
  _$VideoChapterCopyWithImpl(this._self, this._then);

  final VideoChapter _self;
  final $Res Function(VideoChapter) _then;

/// Create a copy of VideoChapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = null,Object? title = null,}) {
  return _then(_self.copyWith(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoChapter].
extension VideoChapterPatterns on VideoChapter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoChapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoChapter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoChapter value)  $default,){
final _that = this;
switch (_that) {
case _VideoChapter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoChapter value)?  $default,){
final _that = this;
switch (_that) {
case _VideoChapter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int t,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoChapter() when $default != null:
return $default(_that.t,_that.title);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int t,  String title)  $default,) {final _that = this;
switch (_that) {
case _VideoChapter():
return $default(_that.t,_that.title);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int t,  String title)?  $default,) {final _that = this;
switch (_that) {
case _VideoChapter() when $default != null:
return $default(_that.t,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoChapter implements VideoChapter {
  const _VideoChapter({required this.t, required this.title});
  factory _VideoChapter.fromJson(Map<String, dynamic> json) => _$VideoChapterFromJson(json);

@override final  int t;
@override final  String title;

/// Create a copy of VideoChapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoChapterCopyWith<_VideoChapter> get copyWith => __$VideoChapterCopyWithImpl<_VideoChapter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoChapterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoChapter&&(identical(other.t, t) || other.t == t)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,title);

@override
String toString() {
  return 'VideoChapter(t: $t, title: $title)';
}


}

/// @nodoc
abstract mixin class _$VideoChapterCopyWith<$Res> implements $VideoChapterCopyWith<$Res> {
  factory _$VideoChapterCopyWith(_VideoChapter value, $Res Function(_VideoChapter) _then) = __$VideoChapterCopyWithImpl;
@override @useResult
$Res call({
 int t, String title
});




}
/// @nodoc
class __$VideoChapterCopyWithImpl<$Res>
    implements _$VideoChapterCopyWith<$Res> {
  __$VideoChapterCopyWithImpl(this._self, this._then);

  final _VideoChapter _self;
  final $Res Function(_VideoChapter) _then;

/// Create a copy of VideoChapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = null,Object? title = null,}) {
  return _then(_VideoChapter(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TranscriptCue {

 int get t; String get text;
/// Create a copy of TranscriptCue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscriptCueCopyWith<TranscriptCue> get copyWith => _$TranscriptCueCopyWithImpl<TranscriptCue>(this as TranscriptCue, _$identity);

  /// Serializes this TranscriptCue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranscriptCue&&(identical(other.t, t) || other.t == t)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,text);

@override
String toString() {
  return 'TranscriptCue(t: $t, text: $text)';
}


}

/// @nodoc
abstract mixin class $TranscriptCueCopyWith<$Res>  {
  factory $TranscriptCueCopyWith(TranscriptCue value, $Res Function(TranscriptCue) _then) = _$TranscriptCueCopyWithImpl;
@useResult
$Res call({
 int t, String text
});




}
/// @nodoc
class _$TranscriptCueCopyWithImpl<$Res>
    implements $TranscriptCueCopyWith<$Res> {
  _$TranscriptCueCopyWithImpl(this._self, this._then);

  final TranscriptCue _self;
  final $Res Function(TranscriptCue) _then;

/// Create a copy of TranscriptCue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = null,Object? text = null,}) {
  return _then(_self.copyWith(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TranscriptCue].
extension TranscriptCuePatterns on TranscriptCue {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranscriptCue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranscriptCue() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranscriptCue value)  $default,){
final _that = this;
switch (_that) {
case _TranscriptCue():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranscriptCue value)?  $default,){
final _that = this;
switch (_that) {
case _TranscriptCue() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int t,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranscriptCue() when $default != null:
return $default(_that.t,_that.text);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int t,  String text)  $default,) {final _that = this;
switch (_that) {
case _TranscriptCue():
return $default(_that.t,_that.text);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int t,  String text)?  $default,) {final _that = this;
switch (_that) {
case _TranscriptCue() when $default != null:
return $default(_that.t,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranscriptCue implements TranscriptCue {
  const _TranscriptCue({required this.t, required this.text});
  factory _TranscriptCue.fromJson(Map<String, dynamic> json) => _$TranscriptCueFromJson(json);

@override final  int t;
@override final  String text;

/// Create a copy of TranscriptCue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscriptCueCopyWith<_TranscriptCue> get copyWith => __$TranscriptCueCopyWithImpl<_TranscriptCue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranscriptCueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranscriptCue&&(identical(other.t, t) || other.t == t)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,text);

@override
String toString() {
  return 'TranscriptCue(t: $t, text: $text)';
}


}

/// @nodoc
abstract mixin class _$TranscriptCueCopyWith<$Res> implements $TranscriptCueCopyWith<$Res> {
  factory _$TranscriptCueCopyWith(_TranscriptCue value, $Res Function(_TranscriptCue) _then) = __$TranscriptCueCopyWithImpl;
@override @useResult
$Res call({
 int t, String text
});




}
/// @nodoc
class __$TranscriptCueCopyWithImpl<$Res>
    implements _$TranscriptCueCopyWith<$Res> {
  __$TranscriptCueCopyWithImpl(this._self, this._then);

  final _TranscriptCue _self;
  final $Res Function(_TranscriptCue) _then;

/// Create a copy of TranscriptCue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = null,Object? text = null,}) {
  return _then(_TranscriptCue(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VideoContent {

 String get id; String get title; String get description; String get status; String? get src; String? get srcWebm; String? get poster; String? get captions; int? get duration; List<VideoChapter> get chapters; List<TranscriptCue> get transcript; String? get relatedLessonSlug;
/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoContentCopyWith<VideoContent> get copyWith => _$VideoContentCopyWithImpl<VideoContent>(this as VideoContent, _$identity);

  /// Serializes this VideoContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoContent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.src, src) || other.src == src)&&(identical(other.srcWebm, srcWebm) || other.srcWebm == srcWebm)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.captions, captions) || other.captions == captions)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&const DeepCollectionEquality().equals(other.transcript, transcript)&&(identical(other.relatedLessonSlug, relatedLessonSlug) || other.relatedLessonSlug == relatedLessonSlug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,status,src,srcWebm,poster,captions,duration,const DeepCollectionEquality().hash(chapters),const DeepCollectionEquality().hash(transcript),relatedLessonSlug);

@override
String toString() {
  return 'VideoContent(id: $id, title: $title, description: $description, status: $status, src: $src, srcWebm: $srcWebm, poster: $poster, captions: $captions, duration: $duration, chapters: $chapters, transcript: $transcript, relatedLessonSlug: $relatedLessonSlug)';
}


}

/// @nodoc
abstract mixin class $VideoContentCopyWith<$Res>  {
  factory $VideoContentCopyWith(VideoContent value, $Res Function(VideoContent) _then) = _$VideoContentCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String status, String? src, String? srcWebm, String? poster, String? captions, int? duration, List<VideoChapter> chapters, List<TranscriptCue> transcript, String? relatedLessonSlug
});




}
/// @nodoc
class _$VideoContentCopyWithImpl<$Res>
    implements $VideoContentCopyWith<$Res> {
  _$VideoContentCopyWithImpl(this._self, this._then);

  final VideoContent _self;
  final $Res Function(VideoContent) _then;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? status = null,Object? src = freezed,Object? srcWebm = freezed,Object? poster = freezed,Object? captions = freezed,Object? duration = freezed,Object? chapters = null,Object? transcript = null,Object? relatedLessonSlug = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,src: freezed == src ? _self.src : src // ignore: cast_nullable_to_non_nullable
as String?,srcWebm: freezed == srcWebm ? _self.srcWebm : srcWebm // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as String?,captions: freezed == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<VideoChapter>,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<TranscriptCue>,relatedLessonSlug: freezed == relatedLessonSlug ? _self.relatedLessonSlug : relatedLessonSlug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoContent].
extension VideoContentPatterns on VideoContent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoContent value)  $default,){
final _that = this;
switch (_that) {
case _VideoContent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoContent value)?  $default,){
final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String status,  String? src,  String? srcWebm,  String? poster,  String? captions,  int? duration,  List<VideoChapter> chapters,  List<TranscriptCue> transcript,  String? relatedLessonSlug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.src,_that.srcWebm,_that.poster,_that.captions,_that.duration,_that.chapters,_that.transcript,_that.relatedLessonSlug);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String status,  String? src,  String? srcWebm,  String? poster,  String? captions,  int? duration,  List<VideoChapter> chapters,  List<TranscriptCue> transcript,  String? relatedLessonSlug)  $default,) {final _that = this;
switch (_that) {
case _VideoContent():
return $default(_that.id,_that.title,_that.description,_that.status,_that.src,_that.srcWebm,_that.poster,_that.captions,_that.duration,_that.chapters,_that.transcript,_that.relatedLessonSlug);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String status,  String? src,  String? srcWebm,  String? poster,  String? captions,  int? duration,  List<VideoChapter> chapters,  List<TranscriptCue> transcript,  String? relatedLessonSlug)?  $default,) {final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.src,_that.srcWebm,_that.poster,_that.captions,_that.duration,_that.chapters,_that.transcript,_that.relatedLessonSlug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoContent extends VideoContent {
  const _VideoContent({required this.id, required this.title, required this.description, required this.status, this.src, this.srcWebm, this.poster, this.captions, this.duration, final  List<VideoChapter> chapters = const [], final  List<TranscriptCue> transcript = const [], this.relatedLessonSlug}): _chapters = chapters,_transcript = transcript,super._();
  factory _VideoContent.fromJson(Map<String, dynamic> json) => _$VideoContentFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String status;
@override final  String? src;
@override final  String? srcWebm;
@override final  String? poster;
@override final  String? captions;
@override final  int? duration;
 final  List<VideoChapter> _chapters;
@override@JsonKey() List<VideoChapter> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}

 final  List<TranscriptCue> _transcript;
@override@JsonKey() List<TranscriptCue> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

@override final  String? relatedLessonSlug;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoContentCopyWith<_VideoContent> get copyWith => __$VideoContentCopyWithImpl<_VideoContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoContent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.src, src) || other.src == src)&&(identical(other.srcWebm, srcWebm) || other.srcWebm == srcWebm)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.captions, captions) || other.captions == captions)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&const DeepCollectionEquality().equals(other._transcript, _transcript)&&(identical(other.relatedLessonSlug, relatedLessonSlug) || other.relatedLessonSlug == relatedLessonSlug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,status,src,srcWebm,poster,captions,duration,const DeepCollectionEquality().hash(_chapters),const DeepCollectionEquality().hash(_transcript),relatedLessonSlug);

@override
String toString() {
  return 'VideoContent(id: $id, title: $title, description: $description, status: $status, src: $src, srcWebm: $srcWebm, poster: $poster, captions: $captions, duration: $duration, chapters: $chapters, transcript: $transcript, relatedLessonSlug: $relatedLessonSlug)';
}


}

/// @nodoc
abstract mixin class _$VideoContentCopyWith<$Res> implements $VideoContentCopyWith<$Res> {
  factory _$VideoContentCopyWith(_VideoContent value, $Res Function(_VideoContent) _then) = __$VideoContentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String status, String? src, String? srcWebm, String? poster, String? captions, int? duration, List<VideoChapter> chapters, List<TranscriptCue> transcript, String? relatedLessonSlug
});




}
/// @nodoc
class __$VideoContentCopyWithImpl<$Res>
    implements _$VideoContentCopyWith<$Res> {
  __$VideoContentCopyWithImpl(this._self, this._then);

  final _VideoContent _self;
  final $Res Function(_VideoContent) _then;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? status = null,Object? src = freezed,Object? srcWebm = freezed,Object? poster = freezed,Object? captions = freezed,Object? duration = freezed,Object? chapters = null,Object? transcript = null,Object? relatedLessonSlug = freezed,}) {
  return _then(_VideoContent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,src: freezed == src ? _self.src : src // ignore: cast_nullable_to_non_nullable
as String?,srcWebm: freezed == srcWebm ? _self.srcWebm : srcWebm // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as String?,captions: freezed == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<VideoChapter>,transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<TranscriptCue>,relatedLessonSlug: freezed == relatedLessonSlug ? _self.relatedLessonSlug : relatedLessonSlug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
