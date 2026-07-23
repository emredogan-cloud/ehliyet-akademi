// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'srs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SrsCard {

 String get questionId; double get ease; int get intervalDays; int get repetitions; int get dueAt; int get reviews; int get lapses;
/// Create a copy of SrsCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SrsCardCopyWith<SrsCard> get copyWith => _$SrsCardCopyWithImpl<SrsCard>(this as SrsCard, _$identity);

  /// Serializes this SrsCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SrsCard&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.ease, ease) || other.ease == ease)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.lapses, lapses) || other.lapses == lapses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,ease,intervalDays,repetitions,dueAt,reviews,lapses);

@override
String toString() {
  return 'SrsCard(questionId: $questionId, ease: $ease, intervalDays: $intervalDays, repetitions: $repetitions, dueAt: $dueAt, reviews: $reviews, lapses: $lapses)';
}


}

/// @nodoc
abstract mixin class $SrsCardCopyWith<$Res>  {
  factory $SrsCardCopyWith(SrsCard value, $Res Function(SrsCard) _then) = _$SrsCardCopyWithImpl;
@useResult
$Res call({
 String questionId, double ease, int intervalDays, int repetitions, int dueAt, int reviews, int lapses
});




}
/// @nodoc
class _$SrsCardCopyWithImpl<$Res>
    implements $SrsCardCopyWith<$Res> {
  _$SrsCardCopyWithImpl(this._self, this._then);

  final SrsCard _self;
  final $Res Function(SrsCard) _then;

/// Create a copy of SrsCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? ease = null,Object? intervalDays = null,Object? repetitions = null,Object? dueAt = null,Object? reviews = null,Object? lapses = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,ease: null == ease ? _self.ease : ease // ignore: cast_nullable_to_non_nullable
as double,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,dueAt: null == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as int,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,lapses: null == lapses ? _self.lapses : lapses // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SrsCard].
extension SrsCardPatterns on SrsCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SrsCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SrsCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SrsCard value)  $default,){
final _that = this;
switch (_that) {
case _SrsCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SrsCard value)?  $default,){
final _that = this;
switch (_that) {
case _SrsCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  double ease,  int intervalDays,  int repetitions,  int dueAt,  int reviews,  int lapses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SrsCard() when $default != null:
return $default(_that.questionId,_that.ease,_that.intervalDays,_that.repetitions,_that.dueAt,_that.reviews,_that.lapses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  double ease,  int intervalDays,  int repetitions,  int dueAt,  int reviews,  int lapses)  $default,) {final _that = this;
switch (_that) {
case _SrsCard():
return $default(_that.questionId,_that.ease,_that.intervalDays,_that.repetitions,_that.dueAt,_that.reviews,_that.lapses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  double ease,  int intervalDays,  int repetitions,  int dueAt,  int reviews,  int lapses)?  $default,) {final _that = this;
switch (_that) {
case _SrsCard() when $default != null:
return $default(_that.questionId,_that.ease,_that.intervalDays,_that.repetitions,_that.dueAt,_that.reviews,_that.lapses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SrsCard implements SrsCard {
  const _SrsCard({required this.questionId, required this.ease, required this.intervalDays, required this.repetitions, required this.dueAt, required this.reviews, required this.lapses});
  factory _SrsCard.fromJson(Map<String, dynamic> json) => _$SrsCardFromJson(json);

@override final  String questionId;
@override final  double ease;
@override final  int intervalDays;
@override final  int repetitions;
@override final  int dueAt;
@override final  int reviews;
@override final  int lapses;

/// Create a copy of SrsCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SrsCardCopyWith<_SrsCard> get copyWith => __$SrsCardCopyWithImpl<_SrsCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SrsCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SrsCard&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.ease, ease) || other.ease == ease)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.lapses, lapses) || other.lapses == lapses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,ease,intervalDays,repetitions,dueAt,reviews,lapses);

@override
String toString() {
  return 'SrsCard(questionId: $questionId, ease: $ease, intervalDays: $intervalDays, repetitions: $repetitions, dueAt: $dueAt, reviews: $reviews, lapses: $lapses)';
}


}

/// @nodoc
abstract mixin class _$SrsCardCopyWith<$Res> implements $SrsCardCopyWith<$Res> {
  factory _$SrsCardCopyWith(_SrsCard value, $Res Function(_SrsCard) _then) = __$SrsCardCopyWithImpl;
@override @useResult
$Res call({
 String questionId, double ease, int intervalDays, int repetitions, int dueAt, int reviews, int lapses
});




}
/// @nodoc
class __$SrsCardCopyWithImpl<$Res>
    implements _$SrsCardCopyWith<$Res> {
  __$SrsCardCopyWithImpl(this._self, this._then);

  final _SrsCard _self;
  final $Res Function(_SrsCard) _then;

/// Create a copy of SrsCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? ease = null,Object? intervalDays = null,Object? repetitions = null,Object? dueAt = null,Object? reviews = null,Object? lapses = null,}) {
  return _then(_SrsCard(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,ease: null == ease ? _self.ease : ease // ignore: cast_nullable_to_non_nullable
as double,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,dueAt: null == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as int,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,lapses: null == lapses ? _self.lapses : lapses // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AnswerLog {

 String get questionId; Subject get subject; String get topic; bool get correct; int get at;
/// Create a copy of AnswerLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerLogCopyWith<AnswerLog> get copyWith => _$AnswerLogCopyWithImpl<AnswerLog>(this as AnswerLog, _$identity);

  /// Serializes this AnswerLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerLog&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.correct, correct) || other.correct == correct)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,subject,topic,correct,at);

@override
String toString() {
  return 'AnswerLog(questionId: $questionId, subject: $subject, topic: $topic, correct: $correct, at: $at)';
}


}

/// @nodoc
abstract mixin class $AnswerLogCopyWith<$Res>  {
  factory $AnswerLogCopyWith(AnswerLog value, $Res Function(AnswerLog) _then) = _$AnswerLogCopyWithImpl;
@useResult
$Res call({
 String questionId, Subject subject, String topic, bool correct, int at
});




}
/// @nodoc
class _$AnswerLogCopyWithImpl<$Res>
    implements $AnswerLogCopyWith<$Res> {
  _$AnswerLogCopyWithImpl(this._self, this._then);

  final AnswerLog _self;
  final $Res Function(AnswerLog) _then;

/// Create a copy of AnswerLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? subject = null,Object? topic = null,Object? correct = null,Object? at = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as bool,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AnswerLog].
extension AnswerLogPatterns on AnswerLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnswerLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnswerLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnswerLog value)  $default,){
final _that = this;
switch (_that) {
case _AnswerLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnswerLog value)?  $default,){
final _that = this;
switch (_that) {
case _AnswerLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  Subject subject,  String topic,  bool correct,  int at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnswerLog() when $default != null:
return $default(_that.questionId,_that.subject,_that.topic,_that.correct,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  Subject subject,  String topic,  bool correct,  int at)  $default,) {final _that = this;
switch (_that) {
case _AnswerLog():
return $default(_that.questionId,_that.subject,_that.topic,_that.correct,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  Subject subject,  String topic,  bool correct,  int at)?  $default,) {final _that = this;
switch (_that) {
case _AnswerLog() when $default != null:
return $default(_that.questionId,_that.subject,_that.topic,_that.correct,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnswerLog implements AnswerLog {
  const _AnswerLog({required this.questionId, required this.subject, required this.topic, required this.correct, required this.at});
  factory _AnswerLog.fromJson(Map<String, dynamic> json) => _$AnswerLogFromJson(json);

@override final  String questionId;
@override final  Subject subject;
@override final  String topic;
@override final  bool correct;
@override final  int at;

/// Create a copy of AnswerLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerLogCopyWith<_AnswerLog> get copyWith => __$AnswerLogCopyWithImpl<_AnswerLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswerLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnswerLog&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.correct, correct) || other.correct == correct)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,subject,topic,correct,at);

@override
String toString() {
  return 'AnswerLog(questionId: $questionId, subject: $subject, topic: $topic, correct: $correct, at: $at)';
}


}

/// @nodoc
abstract mixin class _$AnswerLogCopyWith<$Res> implements $AnswerLogCopyWith<$Res> {
  factory _$AnswerLogCopyWith(_AnswerLog value, $Res Function(_AnswerLog) _then) = __$AnswerLogCopyWithImpl;
@override @useResult
$Res call({
 String questionId, Subject subject, String topic, bool correct, int at
});




}
/// @nodoc
class __$AnswerLogCopyWithImpl<$Res>
    implements _$AnswerLogCopyWith<$Res> {
  __$AnswerLogCopyWithImpl(this._self, this._then);

  final _AnswerLog _self;
  final $Res Function(_AnswerLog) _then;

/// Create a copy of AnswerLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? subject = null,Object? topic = null,Object? correct = null,Object? at = null,}) {
  return _then(_AnswerLog(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as bool,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
