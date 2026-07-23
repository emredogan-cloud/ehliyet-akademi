// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Question {

 String get id; Subject get subject; String get topic; Difficulty get difficulty; String get stem; List<String> get options; int get answerIndex; String get explanation; Badge? get badge; List<String> get whyWrong;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.stem, stem) || other.stem == stem)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.answerIndex, answerIndex) || other.answerIndex == answerIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.badge, badge) || other.badge == badge)&&const DeepCollectionEquality().equals(other.whyWrong, whyWrong));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,difficulty,stem,const DeepCollectionEquality().hash(options),answerIndex,explanation,badge,const DeepCollectionEquality().hash(whyWrong));

@override
String toString() {
  return 'Question(id: $id, subject: $subject, topic: $topic, difficulty: $difficulty, stem: $stem, options: $options, answerIndex: $answerIndex, explanation: $explanation, badge: $badge, whyWrong: $whyWrong)';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 String id, Subject subject, String topic, Difficulty difficulty, String stem, List<String> options, int answerIndex, String explanation, Badge? badge, List<String> whyWrong
});




}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? difficulty = null,Object? stem = null,Object? options = null,Object? answerIndex = null,Object? explanation = null,Object? badge = freezed,Object? whyWrong = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty,stem: null == stem ? _self.stem : stem // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,answerIndex: null == answerIndex ? _self.answerIndex : answerIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as Badge?,whyWrong: null == whyWrong ? _self.whyWrong : whyWrong // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Question].
extension QuestionPatterns on Question {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Question value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Question value)  $default,){
final _that = this;
switch (_that) {
case _Question():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Question value)?  $default,){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Subject subject,  String topic,  Difficulty difficulty,  String stem,  List<String> options,  int answerIndex,  String explanation,  Badge? badge,  List<String> whyWrong)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.difficulty,_that.stem,_that.options,_that.answerIndex,_that.explanation,_that.badge,_that.whyWrong);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Subject subject,  String topic,  Difficulty difficulty,  String stem,  List<String> options,  int answerIndex,  String explanation,  Badge? badge,  List<String> whyWrong)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.id,_that.subject,_that.topic,_that.difficulty,_that.stem,_that.options,_that.answerIndex,_that.explanation,_that.badge,_that.whyWrong);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Subject subject,  String topic,  Difficulty difficulty,  String stem,  List<String> options,  int answerIndex,  String explanation,  Badge? badge,  List<String> whyWrong)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.difficulty,_that.stem,_that.options,_that.answerIndex,_that.explanation,_that.badge,_that.whyWrong);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question implements Question {
  const _Question({required this.id, required this.subject, required this.topic, this.difficulty = Difficulty.orta, required this.stem, required final  List<String> options, required this.answerIndex, required this.explanation, this.badge, final  List<String> whyWrong = const []}): _options = options,_whyWrong = whyWrong;
  factory _Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

@override final  String id;
@override final  Subject subject;
@override final  String topic;
@override@JsonKey() final  Difficulty difficulty;
@override final  String stem;
 final  List<String> _options;
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override final  int answerIndex;
@override final  String explanation;
@override final  Badge? badge;
 final  List<String> _whyWrong;
@override@JsonKey() List<String> get whyWrong {
  if (_whyWrong is EqualUnmodifiableListView) return _whyWrong;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whyWrong);
}


/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCopyWith<_Question> get copyWith => __$QuestionCopyWithImpl<_Question>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.stem, stem) || other.stem == stem)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.answerIndex, answerIndex) || other.answerIndex == answerIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.badge, badge) || other.badge == badge)&&const DeepCollectionEquality().equals(other._whyWrong, _whyWrong));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,difficulty,stem,const DeepCollectionEquality().hash(_options),answerIndex,explanation,badge,const DeepCollectionEquality().hash(_whyWrong));

@override
String toString() {
  return 'Question(id: $id, subject: $subject, topic: $topic, difficulty: $difficulty, stem: $stem, options: $options, answerIndex: $answerIndex, explanation: $explanation, badge: $badge, whyWrong: $whyWrong)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, Subject subject, String topic, Difficulty difficulty, String stem, List<String> options, int answerIndex, String explanation, Badge? badge, List<String> whyWrong
});




}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? difficulty = null,Object? stem = null,Object? options = null,Object? answerIndex = null,Object? explanation = null,Object? badge = freezed,Object? whyWrong = null,}) {
  return _then(_Question(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty,stem: null == stem ? _self.stem : stem // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,answerIndex: null == answerIndex ? _self.answerIndex : answerIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as Badge?,whyWrong: null == whyWrong ? _self._whyWrong : whyWrong // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
