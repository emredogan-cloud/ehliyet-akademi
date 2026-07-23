// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Callout {

 CalloutTone get tone; String? get title; String get text;
/// Create a copy of Callout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalloutCopyWith<Callout> get copyWith => _$CalloutCopyWithImpl<Callout>(this as Callout, _$identity);

  /// Serializes this Callout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Callout&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tone,title,text);

@override
String toString() {
  return 'Callout(tone: $tone, title: $title, text: $text)';
}


}

/// @nodoc
abstract mixin class $CalloutCopyWith<$Res>  {
  factory $CalloutCopyWith(Callout value, $Res Function(Callout) _then) = _$CalloutCopyWithImpl;
@useResult
$Res call({
 CalloutTone tone, String? title, String text
});




}
/// @nodoc
class _$CalloutCopyWithImpl<$Res>
    implements $CalloutCopyWith<$Res> {
  _$CalloutCopyWithImpl(this._self, this._then);

  final Callout _self;
  final $Res Function(Callout) _then;

/// Create a copy of Callout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tone = null,Object? title = freezed,Object? text = null,}) {
  return _then(_self.copyWith(
tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as CalloutTone,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Callout].
extension CalloutPatterns on Callout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Callout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Callout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Callout value)  $default,){
final _that = this;
switch (_that) {
case _Callout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Callout value)?  $default,){
final _that = this;
switch (_that) {
case _Callout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CalloutTone tone,  String? title,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Callout() when $default != null:
return $default(_that.tone,_that.title,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CalloutTone tone,  String? title,  String text)  $default,) {final _that = this;
switch (_that) {
case _Callout():
return $default(_that.tone,_that.title,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CalloutTone tone,  String? title,  String text)?  $default,) {final _that = this;
switch (_that) {
case _Callout() when $default != null:
return $default(_that.tone,_that.title,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Callout implements Callout {
  const _Callout({required this.tone, this.title, required this.text});
  factory _Callout.fromJson(Map<String, dynamic> json) => _$CalloutFromJson(json);

@override final  CalloutTone tone;
@override final  String? title;
@override final  String text;

/// Create a copy of Callout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalloutCopyWith<_Callout> get copyWith => __$CalloutCopyWithImpl<_Callout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalloutToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Callout&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tone,title,text);

@override
String toString() {
  return 'Callout(tone: $tone, title: $title, text: $text)';
}


}

/// @nodoc
abstract mixin class _$CalloutCopyWith<$Res> implements $CalloutCopyWith<$Res> {
  factory _$CalloutCopyWith(_Callout value, $Res Function(_Callout) _then) = __$CalloutCopyWithImpl;
@override @useResult
$Res call({
 CalloutTone tone, String? title, String text
});




}
/// @nodoc
class __$CalloutCopyWithImpl<$Res>
    implements _$CalloutCopyWith<$Res> {
  __$CalloutCopyWithImpl(this._self, this._then);

  final _Callout _self;
  final $Res Function(_Callout) _then;

/// Create a copy of Callout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tone = null,Object? title = freezed,Object? text = null,}) {
  return _then(_Callout(
tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as CalloutTone,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CompareTable {

 String? get caption; List<String> get headers; List<List<String>> get rows;
/// Create a copy of CompareTable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompareTableCopyWith<CompareTable> get copyWith => _$CompareTableCopyWithImpl<CompareTable>(this as CompareTable, _$identity);

  /// Serializes this CompareTable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareTable&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.headers, headers)&&const DeepCollectionEquality().equals(other.rows, rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,caption,const DeepCollectionEquality().hash(headers),const DeepCollectionEquality().hash(rows));

@override
String toString() {
  return 'CompareTable(caption: $caption, headers: $headers, rows: $rows)';
}


}

/// @nodoc
abstract mixin class $CompareTableCopyWith<$Res>  {
  factory $CompareTableCopyWith(CompareTable value, $Res Function(CompareTable) _then) = _$CompareTableCopyWithImpl;
@useResult
$Res call({
 String? caption, List<String> headers, List<List<String>> rows
});




}
/// @nodoc
class _$CompareTableCopyWithImpl<$Res>
    implements $CompareTableCopyWith<$Res> {
  _$CompareTableCopyWithImpl(this._self, this._then);

  final CompareTable _self;
  final $Res Function(CompareTable) _then;

/// Create a copy of CompareTable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? caption = freezed,Object? headers = null,Object? rows = null,}) {
  return _then(_self.copyWith(
caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as List<String>,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [CompareTable].
extension CompareTablePatterns on CompareTable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompareTable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompareTable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompareTable value)  $default,){
final _that = this;
switch (_that) {
case _CompareTable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompareTable value)?  $default,){
final _that = this;
switch (_that) {
case _CompareTable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? caption,  List<String> headers,  List<List<String>> rows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompareTable() when $default != null:
return $default(_that.caption,_that.headers,_that.rows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? caption,  List<String> headers,  List<List<String>> rows)  $default,) {final _that = this;
switch (_that) {
case _CompareTable():
return $default(_that.caption,_that.headers,_that.rows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? caption,  List<String> headers,  List<List<String>> rows)?  $default,) {final _that = this;
switch (_that) {
case _CompareTable() when $default != null:
return $default(_that.caption,_that.headers,_that.rows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompareTable implements CompareTable {
  const _CompareTable({this.caption, required final  List<String> headers, required final  List<List<String>> rows}): _headers = headers,_rows = rows;
  factory _CompareTable.fromJson(Map<String, dynamic> json) => _$CompareTableFromJson(json);

@override final  String? caption;
 final  List<String> _headers;
@override List<String> get headers {
  if (_headers is EqualUnmodifiableListView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_headers);
}

 final  List<List<String>> _rows;
@override List<List<String>> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of CompareTable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompareTableCopyWith<_CompareTable> get copyWith => __$CompareTableCopyWithImpl<_CompareTable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompareTableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompareTable&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._headers, _headers)&&const DeepCollectionEquality().equals(other._rows, _rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,caption,const DeepCollectionEquality().hash(_headers),const DeepCollectionEquality().hash(_rows));

@override
String toString() {
  return 'CompareTable(caption: $caption, headers: $headers, rows: $rows)';
}


}

/// @nodoc
abstract mixin class _$CompareTableCopyWith<$Res> implements $CompareTableCopyWith<$Res> {
  factory _$CompareTableCopyWith(_CompareTable value, $Res Function(_CompareTable) _then) = __$CompareTableCopyWithImpl;
@override @useResult
$Res call({
 String? caption, List<String> headers, List<List<String>> rows
});




}
/// @nodoc
class __$CompareTableCopyWithImpl<$Res>
    implements _$CompareTableCopyWith<$Res> {
  __$CompareTableCopyWithImpl(this._self, this._then);

  final _CompareTable _self;
  final $Res Function(_CompareTable) _then;

/// Create a copy of CompareTable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? caption = freezed,Object? headers = null,Object? rows = null,}) {
  return _then(_CompareTable(
caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as List<String>,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}


}


/// @nodoc
mixin _$ReviewCard {

 String get front; String get back;
/// Create a copy of ReviewCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewCardCopyWith<ReviewCard> get copyWith => _$ReviewCardCopyWithImpl<ReviewCard>(this as ReviewCard, _$identity);

  /// Serializes this ReviewCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewCard&&(identical(other.front, front) || other.front == front)&&(identical(other.back, back) || other.back == back));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,front,back);

@override
String toString() {
  return 'ReviewCard(front: $front, back: $back)';
}


}

/// @nodoc
abstract mixin class $ReviewCardCopyWith<$Res>  {
  factory $ReviewCardCopyWith(ReviewCard value, $Res Function(ReviewCard) _then) = _$ReviewCardCopyWithImpl;
@useResult
$Res call({
 String front, String back
});




}
/// @nodoc
class _$ReviewCardCopyWithImpl<$Res>
    implements $ReviewCardCopyWith<$Res> {
  _$ReviewCardCopyWithImpl(this._self, this._then);

  final ReviewCard _self;
  final $Res Function(ReviewCard) _then;

/// Create a copy of ReviewCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? front = null,Object? back = null,}) {
  return _then(_self.copyWith(
front: null == front ? _self.front : front // ignore: cast_nullable_to_non_nullable
as String,back: null == back ? _self.back : back // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewCard].
extension ReviewCardPatterns on ReviewCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewCard value)  $default,){
final _that = this;
switch (_that) {
case _ReviewCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewCard value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String front,  String back)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewCard() when $default != null:
return $default(_that.front,_that.back);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String front,  String back)  $default,) {final _that = this;
switch (_that) {
case _ReviewCard():
return $default(_that.front,_that.back);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String front,  String back)?  $default,) {final _that = this;
switch (_that) {
case _ReviewCard() when $default != null:
return $default(_that.front,_that.back);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewCard implements ReviewCard {
  const _ReviewCard({required this.front, required this.back});
  factory _ReviewCard.fromJson(Map<String, dynamic> json) => _$ReviewCardFromJson(json);

@override final  String front;
@override final  String back;

/// Create a copy of ReviewCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewCardCopyWith<_ReviewCard> get copyWith => __$ReviewCardCopyWithImpl<_ReviewCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewCard&&(identical(other.front, front) || other.front == front)&&(identical(other.back, back) || other.back == back));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,front,back);

@override
String toString() {
  return 'ReviewCard(front: $front, back: $back)';
}


}

/// @nodoc
abstract mixin class _$ReviewCardCopyWith<$Res> implements $ReviewCardCopyWith<$Res> {
  factory _$ReviewCardCopyWith(_ReviewCard value, $Res Function(_ReviewCard) _then) = __$ReviewCardCopyWithImpl;
@override @useResult
$Res call({
 String front, String back
});




}
/// @nodoc
class __$ReviewCardCopyWithImpl<$Res>
    implements _$ReviewCardCopyWith<$Res> {
  __$ReviewCardCopyWithImpl(this._self, this._then);

  final _ReviewCard _self;
  final $Res Function(_ReviewCard) _then;

/// Create a copy of ReviewCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? front = null,Object? back = null,}) {
  return _then(_ReviewCard(
front: null == front ? _self.front : front // ignore: cast_nullable_to_non_nullable
as String,back: null == back ? _self.back : back // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LessonMistake {

 String get text; String get fix;
/// Create a copy of LessonMistake
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonMistakeCopyWith<LessonMistake> get copyWith => _$LessonMistakeCopyWithImpl<LessonMistake>(this as LessonMistake, _$identity);

  /// Serializes this LessonMistake to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonMistake&&(identical(other.text, text) || other.text == text)&&(identical(other.fix, fix) || other.fix == fix));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,fix);

@override
String toString() {
  return 'LessonMistake(text: $text, fix: $fix)';
}


}

/// @nodoc
abstract mixin class $LessonMistakeCopyWith<$Res>  {
  factory $LessonMistakeCopyWith(LessonMistake value, $Res Function(LessonMistake) _then) = _$LessonMistakeCopyWithImpl;
@useResult
$Res call({
 String text, String fix
});




}
/// @nodoc
class _$LessonMistakeCopyWithImpl<$Res>
    implements $LessonMistakeCopyWith<$Res> {
  _$LessonMistakeCopyWithImpl(this._self, this._then);

  final LessonMistake _self;
  final $Res Function(LessonMistake) _then;

/// Create a copy of LessonMistake
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? fix = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fix: null == fix ? _self.fix : fix // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonMistake].
extension LessonMistakePatterns on LessonMistake {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonMistake value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonMistake() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonMistake value)  $default,){
final _that = this;
switch (_that) {
case _LessonMistake():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonMistake value)?  $default,){
final _that = this;
switch (_that) {
case _LessonMistake() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String fix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonMistake() when $default != null:
return $default(_that.text,_that.fix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String fix)  $default,) {final _that = this;
switch (_that) {
case _LessonMistake():
return $default(_that.text,_that.fix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String fix)?  $default,) {final _that = this;
switch (_that) {
case _LessonMistake() when $default != null:
return $default(_that.text,_that.fix);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonMistake implements LessonMistake {
  const _LessonMistake({required this.text, required this.fix});
  factory _LessonMistake.fromJson(Map<String, dynamic> json) => _$LessonMistakeFromJson(json);

@override final  String text;
@override final  String fix;

/// Create a copy of LessonMistake
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonMistakeCopyWith<_LessonMistake> get copyWith => __$LessonMistakeCopyWithImpl<_LessonMistake>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonMistakeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonMistake&&(identical(other.text, text) || other.text == text)&&(identical(other.fix, fix) || other.fix == fix));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,fix);

@override
String toString() {
  return 'LessonMistake(text: $text, fix: $fix)';
}


}

/// @nodoc
abstract mixin class _$LessonMistakeCopyWith<$Res> implements $LessonMistakeCopyWith<$Res> {
  factory _$LessonMistakeCopyWith(_LessonMistake value, $Res Function(_LessonMistake) _then) = __$LessonMistakeCopyWithImpl;
@override @useResult
$Res call({
 String text, String fix
});




}
/// @nodoc
class __$LessonMistakeCopyWithImpl<$Res>
    implements _$LessonMistakeCopyWith<$Res> {
  __$LessonMistakeCopyWithImpl(this._self, this._then);

  final _LessonMistake _self;
  final $Res Function(_LessonMistake) _then;

/// Create a copy of LessonMistake
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? fix = null,}) {
  return _then(_LessonMistake(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fix: null == fix ? _self.fix : fix // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LessonSection {

 String get heading; Badge? get badge; String get body; Callout? get callout; CompareTable? get compare;
/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonSectionCopyWith<LessonSection> get copyWith => _$LessonSectionCopyWithImpl<LessonSection>(this as LessonSection, _$identity);

  /// Serializes this LessonSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonSection&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.body, body) || other.body == body)&&(identical(other.callout, callout) || other.callout == callout)&&(identical(other.compare, compare) || other.compare == compare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,heading,badge,body,callout,compare);

@override
String toString() {
  return 'LessonSection(heading: $heading, badge: $badge, body: $body, callout: $callout, compare: $compare)';
}


}

/// @nodoc
abstract mixin class $LessonSectionCopyWith<$Res>  {
  factory $LessonSectionCopyWith(LessonSection value, $Res Function(LessonSection) _then) = _$LessonSectionCopyWithImpl;
@useResult
$Res call({
 String heading, Badge? badge, String body, Callout? callout, CompareTable? compare
});


$CalloutCopyWith<$Res>? get callout;$CompareTableCopyWith<$Res>? get compare;

}
/// @nodoc
class _$LessonSectionCopyWithImpl<$Res>
    implements $LessonSectionCopyWith<$Res> {
  _$LessonSectionCopyWithImpl(this._self, this._then);

  final LessonSection _self;
  final $Res Function(LessonSection) _then;

/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? heading = null,Object? badge = freezed,Object? body = null,Object? callout = freezed,Object? compare = freezed,}) {
  return _then(_self.copyWith(
heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as Badge?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,callout: freezed == callout ? _self.callout : callout // ignore: cast_nullable_to_non_nullable
as Callout?,compare: freezed == compare ? _self.compare : compare // ignore: cast_nullable_to_non_nullable
as CompareTable?,
  ));
}
/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalloutCopyWith<$Res>? get callout {
    if (_self.callout == null) {
    return null;
  }

  return $CalloutCopyWith<$Res>(_self.callout!, (value) {
    return _then(_self.copyWith(callout: value));
  });
}/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompareTableCopyWith<$Res>? get compare {
    if (_self.compare == null) {
    return null;
  }

  return $CompareTableCopyWith<$Res>(_self.compare!, (value) {
    return _then(_self.copyWith(compare: value));
  });
}
}


/// Adds pattern-matching-related methods to [LessonSection].
extension LessonSectionPatterns on LessonSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonSection value)  $default,){
final _that = this;
switch (_that) {
case _LessonSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonSection value)?  $default,){
final _that = this;
switch (_that) {
case _LessonSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String heading,  Badge? badge,  String body,  Callout? callout,  CompareTable? compare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonSection() when $default != null:
return $default(_that.heading,_that.badge,_that.body,_that.callout,_that.compare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String heading,  Badge? badge,  String body,  Callout? callout,  CompareTable? compare)  $default,) {final _that = this;
switch (_that) {
case _LessonSection():
return $default(_that.heading,_that.badge,_that.body,_that.callout,_that.compare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String heading,  Badge? badge,  String body,  Callout? callout,  CompareTable? compare)?  $default,) {final _that = this;
switch (_that) {
case _LessonSection() when $default != null:
return $default(_that.heading,_that.badge,_that.body,_that.callout,_that.compare);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonSection implements LessonSection {
  const _LessonSection({required this.heading, this.badge, required this.body, this.callout, this.compare});
  factory _LessonSection.fromJson(Map<String, dynamic> json) => _$LessonSectionFromJson(json);

@override final  String heading;
@override final  Badge? badge;
@override final  String body;
@override final  Callout? callout;
@override final  CompareTable? compare;

/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonSectionCopyWith<_LessonSection> get copyWith => __$LessonSectionCopyWithImpl<_LessonSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonSection&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.body, body) || other.body == body)&&(identical(other.callout, callout) || other.callout == callout)&&(identical(other.compare, compare) || other.compare == compare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,heading,badge,body,callout,compare);

@override
String toString() {
  return 'LessonSection(heading: $heading, badge: $badge, body: $body, callout: $callout, compare: $compare)';
}


}

/// @nodoc
abstract mixin class _$LessonSectionCopyWith<$Res> implements $LessonSectionCopyWith<$Res> {
  factory _$LessonSectionCopyWith(_LessonSection value, $Res Function(_LessonSection) _then) = __$LessonSectionCopyWithImpl;
@override @useResult
$Res call({
 String heading, Badge? badge, String body, Callout? callout, CompareTable? compare
});


@override $CalloutCopyWith<$Res>? get callout;@override $CompareTableCopyWith<$Res>? get compare;

}
/// @nodoc
class __$LessonSectionCopyWithImpl<$Res>
    implements _$LessonSectionCopyWith<$Res> {
  __$LessonSectionCopyWithImpl(this._self, this._then);

  final _LessonSection _self;
  final $Res Function(_LessonSection) _then;

/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? heading = null,Object? badge = freezed,Object? body = null,Object? callout = freezed,Object? compare = freezed,}) {
  return _then(_LessonSection(
heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as Badge?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,callout: freezed == callout ? _self.callout : callout // ignore: cast_nullable_to_non_nullable
as Callout?,compare: freezed == compare ? _self.compare : compare // ignore: cast_nullable_to_non_nullable
as CompareTable?,
  ));
}

/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalloutCopyWith<$Res>? get callout {
    if (_self.callout == null) {
    return null;
  }

  return $CalloutCopyWith<$Res>(_self.callout!, (value) {
    return _then(_self.copyWith(callout: value));
  });
}/// Create a copy of LessonSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompareTableCopyWith<$Res>? get compare {
    if (_self.compare == null) {
    return null;
  }

  return $CompareTableCopyWith<$Res>(_self.compare!, (value) {
    return _then(_self.copyWith(compare: value));
  });
}
}


/// @nodoc
mixin _$Lesson {

 String get id; String get slug; int get no; Subject get subject; String get title; String get summary; int get minutes; List<String> get objectives; List<LessonSection> get sections; List<LessonMistake> get mistakes; List<String> get tips; List<String> get quizQuestionIds; List<String> get references; List<String> get memoryTips; List<String> get examStrategy; List<String> get keyTakeaways; List<ReviewCard> get reviewCards; List<String> get practiceQuestionIds; String? get figureId; bool get premium;
/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonCopyWith<Lesson> get copyWith => _$LessonCopyWithImpl<Lesson>(this as Lesson, _$identity);

  /// Serializes this Lesson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lesson&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.no, no) || other.no == no)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&const DeepCollectionEquality().equals(other.objectives, objectives)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.mistakes, mistakes)&&const DeepCollectionEquality().equals(other.tips, tips)&&const DeepCollectionEquality().equals(other.quizQuestionIds, quizQuestionIds)&&const DeepCollectionEquality().equals(other.references, references)&&const DeepCollectionEquality().equals(other.memoryTips, memoryTips)&&const DeepCollectionEquality().equals(other.examStrategy, examStrategy)&&const DeepCollectionEquality().equals(other.keyTakeaways, keyTakeaways)&&const DeepCollectionEquality().equals(other.reviewCards, reviewCards)&&const DeepCollectionEquality().equals(other.practiceQuestionIds, practiceQuestionIds)&&(identical(other.figureId, figureId) || other.figureId == figureId)&&(identical(other.premium, premium) || other.premium == premium));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,no,subject,title,summary,minutes,const DeepCollectionEquality().hash(objectives),const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(mistakes),const DeepCollectionEquality().hash(tips),const DeepCollectionEquality().hash(quizQuestionIds),const DeepCollectionEquality().hash(references),const DeepCollectionEquality().hash(memoryTips),const DeepCollectionEquality().hash(examStrategy),const DeepCollectionEquality().hash(keyTakeaways),const DeepCollectionEquality().hash(reviewCards),const DeepCollectionEquality().hash(practiceQuestionIds),figureId,premium]);

@override
String toString() {
  return 'Lesson(id: $id, slug: $slug, no: $no, subject: $subject, title: $title, summary: $summary, minutes: $minutes, objectives: $objectives, sections: $sections, mistakes: $mistakes, tips: $tips, quizQuestionIds: $quizQuestionIds, references: $references, memoryTips: $memoryTips, examStrategy: $examStrategy, keyTakeaways: $keyTakeaways, reviewCards: $reviewCards, practiceQuestionIds: $practiceQuestionIds, figureId: $figureId, premium: $premium)';
}


}

/// @nodoc
abstract mixin class $LessonCopyWith<$Res>  {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) _then) = _$LessonCopyWithImpl;
@useResult
$Res call({
 String id, String slug, int no, Subject subject, String title, String summary, int minutes, List<String> objectives, List<LessonSection> sections, List<LessonMistake> mistakes, List<String> tips, List<String> quizQuestionIds, List<String> references, List<String> memoryTips, List<String> examStrategy, List<String> keyTakeaways, List<ReviewCard> reviewCards, List<String> practiceQuestionIds, String? figureId, bool premium
});




}
/// @nodoc
class _$LessonCopyWithImpl<$Res>
    implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._self, this._then);

  final Lesson _self;
  final $Res Function(Lesson) _then;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? no = null,Object? subject = null,Object? title = null,Object? summary = null,Object? minutes = null,Object? objectives = null,Object? sections = null,Object? mistakes = null,Object? tips = null,Object? quizQuestionIds = null,Object? references = null,Object? memoryTips = null,Object? examStrategy = null,Object? keyTakeaways = null,Object? reviewCards = null,Object? practiceQuestionIds = null,Object? figureId = freezed,Object? premium = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,no: null == no ? _self.no : no // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,objectives: null == objectives ? _self.objectives : objectives // ignore: cast_nullable_to_non_nullable
as List<String>,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<LessonSection>,mistakes: null == mistakes ? _self.mistakes : mistakes // ignore: cast_nullable_to_non_nullable
as List<LessonMistake>,tips: null == tips ? _self.tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>,quizQuestionIds: null == quizQuestionIds ? _self.quizQuestionIds : quizQuestionIds // ignore: cast_nullable_to_non_nullable
as List<String>,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as List<String>,memoryTips: null == memoryTips ? _self.memoryTips : memoryTips // ignore: cast_nullable_to_non_nullable
as List<String>,examStrategy: null == examStrategy ? _self.examStrategy : examStrategy // ignore: cast_nullable_to_non_nullable
as List<String>,keyTakeaways: null == keyTakeaways ? _self.keyTakeaways : keyTakeaways // ignore: cast_nullable_to_non_nullable
as List<String>,reviewCards: null == reviewCards ? _self.reviewCards : reviewCards // ignore: cast_nullable_to_non_nullable
as List<ReviewCard>,practiceQuestionIds: null == practiceQuestionIds ? _self.practiceQuestionIds : practiceQuestionIds // ignore: cast_nullable_to_non_nullable
as List<String>,figureId: freezed == figureId ? _self.figureId : figureId // ignore: cast_nullable_to_non_nullable
as String?,premium: null == premium ? _self.premium : premium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Lesson].
extension LessonPatterns on Lesson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lesson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lesson value)  $default,){
final _that = this;
switch (_that) {
case _Lesson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lesson value)?  $default,){
final _that = this;
switch (_that) {
case _Lesson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  int no,  Subject subject,  String title,  String summary,  int minutes,  List<String> objectives,  List<LessonSection> sections,  List<LessonMistake> mistakes,  List<String> tips,  List<String> quizQuestionIds,  List<String> references,  List<String> memoryTips,  List<String> examStrategy,  List<String> keyTakeaways,  List<ReviewCard> reviewCards,  List<String> practiceQuestionIds,  String? figureId,  bool premium)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that.id,_that.slug,_that.no,_that.subject,_that.title,_that.summary,_that.minutes,_that.objectives,_that.sections,_that.mistakes,_that.tips,_that.quizQuestionIds,_that.references,_that.memoryTips,_that.examStrategy,_that.keyTakeaways,_that.reviewCards,_that.practiceQuestionIds,_that.figureId,_that.premium);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  int no,  Subject subject,  String title,  String summary,  int minutes,  List<String> objectives,  List<LessonSection> sections,  List<LessonMistake> mistakes,  List<String> tips,  List<String> quizQuestionIds,  List<String> references,  List<String> memoryTips,  List<String> examStrategy,  List<String> keyTakeaways,  List<ReviewCard> reviewCards,  List<String> practiceQuestionIds,  String? figureId,  bool premium)  $default,) {final _that = this;
switch (_that) {
case _Lesson():
return $default(_that.id,_that.slug,_that.no,_that.subject,_that.title,_that.summary,_that.minutes,_that.objectives,_that.sections,_that.mistakes,_that.tips,_that.quizQuestionIds,_that.references,_that.memoryTips,_that.examStrategy,_that.keyTakeaways,_that.reviewCards,_that.practiceQuestionIds,_that.figureId,_that.premium);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  int no,  Subject subject,  String title,  String summary,  int minutes,  List<String> objectives,  List<LessonSection> sections,  List<LessonMistake> mistakes,  List<String> tips,  List<String> quizQuestionIds,  List<String> references,  List<String> memoryTips,  List<String> examStrategy,  List<String> keyTakeaways,  List<ReviewCard> reviewCards,  List<String> practiceQuestionIds,  String? figureId,  bool premium)?  $default,) {final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that.id,_that.slug,_that.no,_that.subject,_that.title,_that.summary,_that.minutes,_that.objectives,_that.sections,_that.mistakes,_that.tips,_that.quizQuestionIds,_that.references,_that.memoryTips,_that.examStrategy,_that.keyTakeaways,_that.reviewCards,_that.practiceQuestionIds,_that.figureId,_that.premium);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lesson implements Lesson {
  const _Lesson({required this.id, required this.slug, required this.no, required this.subject, required this.title, required this.summary, required this.minutes, required final  List<String> objectives, required final  List<LessonSection> sections, final  List<LessonMistake> mistakes = const [], final  List<String> tips = const [], final  List<String> quizQuestionIds = const [], final  List<String> references = const [], final  List<String> memoryTips = const [], final  List<String> examStrategy = const [], final  List<String> keyTakeaways = const [], final  List<ReviewCard> reviewCards = const [], final  List<String> practiceQuestionIds = const [], this.figureId, this.premium = false}): _objectives = objectives,_sections = sections,_mistakes = mistakes,_tips = tips,_quizQuestionIds = quizQuestionIds,_references = references,_memoryTips = memoryTips,_examStrategy = examStrategy,_keyTakeaways = keyTakeaways,_reviewCards = reviewCards,_practiceQuestionIds = practiceQuestionIds;
  factory _Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

@override final  String id;
@override final  String slug;
@override final  int no;
@override final  Subject subject;
@override final  String title;
@override final  String summary;
@override final  int minutes;
 final  List<String> _objectives;
@override List<String> get objectives {
  if (_objectives is EqualUnmodifiableListView) return _objectives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_objectives);
}

 final  List<LessonSection> _sections;
@override List<LessonSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

 final  List<LessonMistake> _mistakes;
@override@JsonKey() List<LessonMistake> get mistakes {
  if (_mistakes is EqualUnmodifiableListView) return _mistakes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mistakes);
}

 final  List<String> _tips;
@override@JsonKey() List<String> get tips {
  if (_tips is EqualUnmodifiableListView) return _tips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tips);
}

 final  List<String> _quizQuestionIds;
@override@JsonKey() List<String> get quizQuestionIds {
  if (_quizQuestionIds is EqualUnmodifiableListView) return _quizQuestionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quizQuestionIds);
}

 final  List<String> _references;
@override@JsonKey() List<String> get references {
  if (_references is EqualUnmodifiableListView) return _references;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_references);
}

 final  List<String> _memoryTips;
@override@JsonKey() List<String> get memoryTips {
  if (_memoryTips is EqualUnmodifiableListView) return _memoryTips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memoryTips);
}

 final  List<String> _examStrategy;
@override@JsonKey() List<String> get examStrategy {
  if (_examStrategy is EqualUnmodifiableListView) return _examStrategy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_examStrategy);
}

 final  List<String> _keyTakeaways;
@override@JsonKey() List<String> get keyTakeaways {
  if (_keyTakeaways is EqualUnmodifiableListView) return _keyTakeaways;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyTakeaways);
}

 final  List<ReviewCard> _reviewCards;
@override@JsonKey() List<ReviewCard> get reviewCards {
  if (_reviewCards is EqualUnmodifiableListView) return _reviewCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviewCards);
}

 final  List<String> _practiceQuestionIds;
@override@JsonKey() List<String> get practiceQuestionIds {
  if (_practiceQuestionIds is EqualUnmodifiableListView) return _practiceQuestionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_practiceQuestionIds);
}

@override final  String? figureId;
@override@JsonKey() final  bool premium;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonCopyWith<_Lesson> get copyWith => __$LessonCopyWithImpl<_Lesson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lesson&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.no, no) || other.no == no)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&const DeepCollectionEquality().equals(other._objectives, _objectives)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._mistakes, _mistakes)&&const DeepCollectionEquality().equals(other._tips, _tips)&&const DeepCollectionEquality().equals(other._quizQuestionIds, _quizQuestionIds)&&const DeepCollectionEquality().equals(other._references, _references)&&const DeepCollectionEquality().equals(other._memoryTips, _memoryTips)&&const DeepCollectionEquality().equals(other._examStrategy, _examStrategy)&&const DeepCollectionEquality().equals(other._keyTakeaways, _keyTakeaways)&&const DeepCollectionEquality().equals(other._reviewCards, _reviewCards)&&const DeepCollectionEquality().equals(other._practiceQuestionIds, _practiceQuestionIds)&&(identical(other.figureId, figureId) || other.figureId == figureId)&&(identical(other.premium, premium) || other.premium == premium));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,no,subject,title,summary,minutes,const DeepCollectionEquality().hash(_objectives),const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_mistakes),const DeepCollectionEquality().hash(_tips),const DeepCollectionEquality().hash(_quizQuestionIds),const DeepCollectionEquality().hash(_references),const DeepCollectionEquality().hash(_memoryTips),const DeepCollectionEquality().hash(_examStrategy),const DeepCollectionEquality().hash(_keyTakeaways),const DeepCollectionEquality().hash(_reviewCards),const DeepCollectionEquality().hash(_practiceQuestionIds),figureId,premium]);

@override
String toString() {
  return 'Lesson(id: $id, slug: $slug, no: $no, subject: $subject, title: $title, summary: $summary, minutes: $minutes, objectives: $objectives, sections: $sections, mistakes: $mistakes, tips: $tips, quizQuestionIds: $quizQuestionIds, references: $references, memoryTips: $memoryTips, examStrategy: $examStrategy, keyTakeaways: $keyTakeaways, reviewCards: $reviewCards, practiceQuestionIds: $practiceQuestionIds, figureId: $figureId, premium: $premium)';
}


}

/// @nodoc
abstract mixin class _$LessonCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$LessonCopyWith(_Lesson value, $Res Function(_Lesson) _then) = __$LessonCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, int no, Subject subject, String title, String summary, int minutes, List<String> objectives, List<LessonSection> sections, List<LessonMistake> mistakes, List<String> tips, List<String> quizQuestionIds, List<String> references, List<String> memoryTips, List<String> examStrategy, List<String> keyTakeaways, List<ReviewCard> reviewCards, List<String> practiceQuestionIds, String? figureId, bool premium
});




}
/// @nodoc
class __$LessonCopyWithImpl<$Res>
    implements _$LessonCopyWith<$Res> {
  __$LessonCopyWithImpl(this._self, this._then);

  final _Lesson _self;
  final $Res Function(_Lesson) _then;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? no = null,Object? subject = null,Object? title = null,Object? summary = null,Object? minutes = null,Object? objectives = null,Object? sections = null,Object? mistakes = null,Object? tips = null,Object? quizQuestionIds = null,Object? references = null,Object? memoryTips = null,Object? examStrategy = null,Object? keyTakeaways = null,Object? reviewCards = null,Object? practiceQuestionIds = null,Object? figureId = freezed,Object? premium = null,}) {
  return _then(_Lesson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,no: null == no ? _self.no : no // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,objectives: null == objectives ? _self._objectives : objectives // ignore: cast_nullable_to_non_nullable
as List<String>,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<LessonSection>,mistakes: null == mistakes ? _self._mistakes : mistakes // ignore: cast_nullable_to_non_nullable
as List<LessonMistake>,tips: null == tips ? _self._tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>,quizQuestionIds: null == quizQuestionIds ? _self._quizQuestionIds : quizQuestionIds // ignore: cast_nullable_to_non_nullable
as List<String>,references: null == references ? _self._references : references // ignore: cast_nullable_to_non_nullable
as List<String>,memoryTips: null == memoryTips ? _self._memoryTips : memoryTips // ignore: cast_nullable_to_non_nullable
as List<String>,examStrategy: null == examStrategy ? _self._examStrategy : examStrategy // ignore: cast_nullable_to_non_nullable
as List<String>,keyTakeaways: null == keyTakeaways ? _self._keyTakeaways : keyTakeaways // ignore: cast_nullable_to_non_nullable
as List<String>,reviewCards: null == reviewCards ? _self._reviewCards : reviewCards // ignore: cast_nullable_to_non_nullable
as List<ReviewCard>,practiceQuestionIds: null == practiceQuestionIds ? _self._practiceQuestionIds : practiceQuestionIds // ignore: cast_nullable_to_non_nullable
as List<String>,figureId: freezed == figureId ? _self.figureId : figureId // ignore: cast_nullable_to_non_nullable
as String?,premium: null == premium ? _self.premium : premium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
