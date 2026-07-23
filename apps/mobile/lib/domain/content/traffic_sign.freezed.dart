// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'traffic_sign.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrafficSign {

 String get id; SignCategory get category; String get name; SignShape get shape; String? get glyph; String? get glyphText; String get meaning; String get memoryTip; ExamImportance get examImportance; String? get commonMistake; String? get relatedLessonSlug; List<String> get keywords;
/// Create a copy of TrafficSign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrafficSignCopyWith<TrafficSign> get copyWith => _$TrafficSignCopyWithImpl<TrafficSign>(this as TrafficSign, _$identity);

  /// Serializes this TrafficSign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrafficSign&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.glyph, glyph) || other.glyph == glyph)&&(identical(other.glyphText, glyphText) || other.glyphText == glyphText)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.memoryTip, memoryTip) || other.memoryTip == memoryTip)&&(identical(other.examImportance, examImportance) || other.examImportance == examImportance)&&(identical(other.commonMistake, commonMistake) || other.commonMistake == commonMistake)&&(identical(other.relatedLessonSlug, relatedLessonSlug) || other.relatedLessonSlug == relatedLessonSlug)&&const DeepCollectionEquality().equals(other.keywords, keywords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,name,shape,glyph,glyphText,meaning,memoryTip,examImportance,commonMistake,relatedLessonSlug,const DeepCollectionEquality().hash(keywords));

@override
String toString() {
  return 'TrafficSign(id: $id, category: $category, name: $name, shape: $shape, glyph: $glyph, glyphText: $glyphText, meaning: $meaning, memoryTip: $memoryTip, examImportance: $examImportance, commonMistake: $commonMistake, relatedLessonSlug: $relatedLessonSlug, keywords: $keywords)';
}


}

/// @nodoc
abstract mixin class $TrafficSignCopyWith<$Res>  {
  factory $TrafficSignCopyWith(TrafficSign value, $Res Function(TrafficSign) _then) = _$TrafficSignCopyWithImpl;
@useResult
$Res call({
 String id, SignCategory category, String name, SignShape shape, String? glyph, String? glyphText, String meaning, String memoryTip, ExamImportance examImportance, String? commonMistake, String? relatedLessonSlug, List<String> keywords
});




}
/// @nodoc
class _$TrafficSignCopyWithImpl<$Res>
    implements $TrafficSignCopyWith<$Res> {
  _$TrafficSignCopyWithImpl(this._self, this._then);

  final TrafficSign _self;
  final $Res Function(TrafficSign) _then;

/// Create a copy of TrafficSign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? name = null,Object? shape = null,Object? glyph = freezed,Object? glyphText = freezed,Object? meaning = null,Object? memoryTip = null,Object? examImportance = null,Object? commonMistake = freezed,Object? relatedLessonSlug = freezed,Object? keywords = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SignCategory,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as SignShape,glyph: freezed == glyph ? _self.glyph : glyph // ignore: cast_nullable_to_non_nullable
as String?,glyphText: freezed == glyphText ? _self.glyphText : glyphText // ignore: cast_nullable_to_non_nullable
as String?,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,memoryTip: null == memoryTip ? _self.memoryTip : memoryTip // ignore: cast_nullable_to_non_nullable
as String,examImportance: null == examImportance ? _self.examImportance : examImportance // ignore: cast_nullable_to_non_nullable
as ExamImportance,commonMistake: freezed == commonMistake ? _self.commonMistake : commonMistake // ignore: cast_nullable_to_non_nullable
as String?,relatedLessonSlug: freezed == relatedLessonSlug ? _self.relatedLessonSlug : relatedLessonSlug // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrafficSign].
extension TrafficSignPatterns on TrafficSign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrafficSign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrafficSign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrafficSign value)  $default,){
final _that = this;
switch (_that) {
case _TrafficSign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrafficSign value)?  $default,){
final _that = this;
switch (_that) {
case _TrafficSign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SignCategory category,  String name,  SignShape shape,  String? glyph,  String? glyphText,  String meaning,  String memoryTip,  ExamImportance examImportance,  String? commonMistake,  String? relatedLessonSlug,  List<String> keywords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrafficSign() when $default != null:
return $default(_that.id,_that.category,_that.name,_that.shape,_that.glyph,_that.glyphText,_that.meaning,_that.memoryTip,_that.examImportance,_that.commonMistake,_that.relatedLessonSlug,_that.keywords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SignCategory category,  String name,  SignShape shape,  String? glyph,  String? glyphText,  String meaning,  String memoryTip,  ExamImportance examImportance,  String? commonMistake,  String? relatedLessonSlug,  List<String> keywords)  $default,) {final _that = this;
switch (_that) {
case _TrafficSign():
return $default(_that.id,_that.category,_that.name,_that.shape,_that.glyph,_that.glyphText,_that.meaning,_that.memoryTip,_that.examImportance,_that.commonMistake,_that.relatedLessonSlug,_that.keywords);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SignCategory category,  String name,  SignShape shape,  String? glyph,  String? glyphText,  String meaning,  String memoryTip,  ExamImportance examImportance,  String? commonMistake,  String? relatedLessonSlug,  List<String> keywords)?  $default,) {final _that = this;
switch (_that) {
case _TrafficSign() when $default != null:
return $default(_that.id,_that.category,_that.name,_that.shape,_that.glyph,_that.glyphText,_that.meaning,_that.memoryTip,_that.examImportance,_that.commonMistake,_that.relatedLessonSlug,_that.keywords);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrafficSign implements TrafficSign {
  const _TrafficSign({required this.id, required this.category, required this.name, required this.shape, this.glyph, this.glyphText, required this.meaning, required this.memoryTip, required this.examImportance, this.commonMistake, this.relatedLessonSlug, final  List<String> keywords = const []}): _keywords = keywords;
  factory _TrafficSign.fromJson(Map<String, dynamic> json) => _$TrafficSignFromJson(json);

@override final  String id;
@override final  SignCategory category;
@override final  String name;
@override final  SignShape shape;
@override final  String? glyph;
@override final  String? glyphText;
@override final  String meaning;
@override final  String memoryTip;
@override final  ExamImportance examImportance;
@override final  String? commonMistake;
@override final  String? relatedLessonSlug;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}


/// Create a copy of TrafficSign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrafficSignCopyWith<_TrafficSign> get copyWith => __$TrafficSignCopyWithImpl<_TrafficSign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrafficSignToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrafficSign&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.glyph, glyph) || other.glyph == glyph)&&(identical(other.glyphText, glyphText) || other.glyphText == glyphText)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.memoryTip, memoryTip) || other.memoryTip == memoryTip)&&(identical(other.examImportance, examImportance) || other.examImportance == examImportance)&&(identical(other.commonMistake, commonMistake) || other.commonMistake == commonMistake)&&(identical(other.relatedLessonSlug, relatedLessonSlug) || other.relatedLessonSlug == relatedLessonSlug)&&const DeepCollectionEquality().equals(other._keywords, _keywords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,name,shape,glyph,glyphText,meaning,memoryTip,examImportance,commonMistake,relatedLessonSlug,const DeepCollectionEquality().hash(_keywords));

@override
String toString() {
  return 'TrafficSign(id: $id, category: $category, name: $name, shape: $shape, glyph: $glyph, glyphText: $glyphText, meaning: $meaning, memoryTip: $memoryTip, examImportance: $examImportance, commonMistake: $commonMistake, relatedLessonSlug: $relatedLessonSlug, keywords: $keywords)';
}


}

/// @nodoc
abstract mixin class _$TrafficSignCopyWith<$Res> implements $TrafficSignCopyWith<$Res> {
  factory _$TrafficSignCopyWith(_TrafficSign value, $Res Function(_TrafficSign) _then) = __$TrafficSignCopyWithImpl;
@override @useResult
$Res call({
 String id, SignCategory category, String name, SignShape shape, String? glyph, String? glyphText, String meaning, String memoryTip, ExamImportance examImportance, String? commonMistake, String? relatedLessonSlug, List<String> keywords
});




}
/// @nodoc
class __$TrafficSignCopyWithImpl<$Res>
    implements _$TrafficSignCopyWith<$Res> {
  __$TrafficSignCopyWithImpl(this._self, this._then);

  final _TrafficSign _self;
  final $Res Function(_TrafficSign) _then;

/// Create a copy of TrafficSign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? name = null,Object? shape = null,Object? glyph = freezed,Object? glyphText = freezed,Object? meaning = null,Object? memoryTip = null,Object? examImportance = null,Object? commonMistake = freezed,Object? relatedLessonSlug = freezed,Object? keywords = null,}) {
  return _then(_TrafficSign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SignCategory,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as SignShape,glyph: freezed == glyph ? _self.glyph : glyph // ignore: cast_nullable_to_non_nullable
as String?,glyphText: freezed == glyphText ? _self.glyphText : glyphText // ignore: cast_nullable_to_non_nullable
as String?,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,memoryTip: null == memoryTip ? _self.memoryTip : memoryTip // ignore: cast_nullable_to_non_nullable
as String,examImportance: null == examImportance ? _self.examImportance : examImportance // ignore: cast_nullable_to_non_nullable
as ExamImportance,commonMistake: freezed == commonMistake ? _self.commonMistake : commonMistake // ignore: cast_nullable_to_non_nullable
as String?,relatedLessonSlug: freezed == relatedLessonSlug ? _self.relatedLessonSlug : relatedLessonSlug // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
