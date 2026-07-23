// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_bank.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExamBlueprint {

 int get totalQuestions; int get passCorrect; int get durationMinutes; Map<String, int> get distribution;
/// Create a copy of ExamBlueprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamBlueprintCopyWith<ExamBlueprint> get copyWith => _$ExamBlueprintCopyWithImpl<ExamBlueprint>(this as ExamBlueprint, _$identity);

  /// Serializes this ExamBlueprint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamBlueprint&&(identical(other.totalQuestions, totalQuestions) || other.totalQuestions == totalQuestions)&&(identical(other.passCorrect, passCorrect) || other.passCorrect == passCorrect)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&const DeepCollectionEquality().equals(other.distribution, distribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalQuestions,passCorrect,durationMinutes,const DeepCollectionEquality().hash(distribution));

@override
String toString() {
  return 'ExamBlueprint(totalQuestions: $totalQuestions, passCorrect: $passCorrect, durationMinutes: $durationMinutes, distribution: $distribution)';
}


}

/// @nodoc
abstract mixin class $ExamBlueprintCopyWith<$Res>  {
  factory $ExamBlueprintCopyWith(ExamBlueprint value, $Res Function(ExamBlueprint) _then) = _$ExamBlueprintCopyWithImpl;
@useResult
$Res call({
 int totalQuestions, int passCorrect, int durationMinutes, Map<String, int> distribution
});




}
/// @nodoc
class _$ExamBlueprintCopyWithImpl<$Res>
    implements $ExamBlueprintCopyWith<$Res> {
  _$ExamBlueprintCopyWithImpl(this._self, this._then);

  final ExamBlueprint _self;
  final $Res Function(ExamBlueprint) _then;

/// Create a copy of ExamBlueprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalQuestions = null,Object? passCorrect = null,Object? durationMinutes = null,Object? distribution = null,}) {
  return _then(_self.copyWith(
totalQuestions: null == totalQuestions ? _self.totalQuestions : totalQuestions // ignore: cast_nullable_to_non_nullable
as int,passCorrect: null == passCorrect ? _self.passCorrect : passCorrect // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamBlueprint].
extension ExamBlueprintPatterns on ExamBlueprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamBlueprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamBlueprint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamBlueprint value)  $default,){
final _that = this;
switch (_that) {
case _ExamBlueprint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamBlueprint value)?  $default,){
final _that = this;
switch (_that) {
case _ExamBlueprint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalQuestions,  int passCorrect,  int durationMinutes,  Map<String, int> distribution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamBlueprint() when $default != null:
return $default(_that.totalQuestions,_that.passCorrect,_that.durationMinutes,_that.distribution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalQuestions,  int passCorrect,  int durationMinutes,  Map<String, int> distribution)  $default,) {final _that = this;
switch (_that) {
case _ExamBlueprint():
return $default(_that.totalQuestions,_that.passCorrect,_that.durationMinutes,_that.distribution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalQuestions,  int passCorrect,  int durationMinutes,  Map<String, int> distribution)?  $default,) {final _that = this;
switch (_that) {
case _ExamBlueprint() when $default != null:
return $default(_that.totalQuestions,_that.passCorrect,_that.durationMinutes,_that.distribution);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamBlueprint implements ExamBlueprint {
  const _ExamBlueprint({required this.totalQuestions, required this.passCorrect, required this.durationMinutes, required final  Map<String, int> distribution}): _distribution = distribution;
  factory _ExamBlueprint.fromJson(Map<String, dynamic> json) => _$ExamBlueprintFromJson(json);

@override final  int totalQuestions;
@override final  int passCorrect;
@override final  int durationMinutes;
 final  Map<String, int> _distribution;
@override Map<String, int> get distribution {
  if (_distribution is EqualUnmodifiableMapView) return _distribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_distribution);
}


/// Create a copy of ExamBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamBlueprintCopyWith<_ExamBlueprint> get copyWith => __$ExamBlueprintCopyWithImpl<_ExamBlueprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamBlueprintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamBlueprint&&(identical(other.totalQuestions, totalQuestions) || other.totalQuestions == totalQuestions)&&(identical(other.passCorrect, passCorrect) || other.passCorrect == passCorrect)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&const DeepCollectionEquality().equals(other._distribution, _distribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalQuestions,passCorrect,durationMinutes,const DeepCollectionEquality().hash(_distribution));

@override
String toString() {
  return 'ExamBlueprint(totalQuestions: $totalQuestions, passCorrect: $passCorrect, durationMinutes: $durationMinutes, distribution: $distribution)';
}


}

/// @nodoc
abstract mixin class _$ExamBlueprintCopyWith<$Res> implements $ExamBlueprintCopyWith<$Res> {
  factory _$ExamBlueprintCopyWith(_ExamBlueprint value, $Res Function(_ExamBlueprint) _then) = __$ExamBlueprintCopyWithImpl;
@override @useResult
$Res call({
 int totalQuestions, int passCorrect, int durationMinutes, Map<String, int> distribution
});




}
/// @nodoc
class __$ExamBlueprintCopyWithImpl<$Res>
    implements _$ExamBlueprintCopyWith<$Res> {
  __$ExamBlueprintCopyWithImpl(this._self, this._then);

  final _ExamBlueprint _self;
  final $Res Function(_ExamBlueprint) _then;

/// Create a copy of ExamBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalQuestions = null,Object? passCorrect = null,Object? durationMinutes = null,Object? distribution = null,}) {
  return _then(_ExamBlueprint(
totalQuestions: null == totalQuestions ? _self.totalQuestions : totalQuestions // ignore: cast_nullable_to_non_nullable
as int,passCorrect: null == passCorrect ? _self.passCorrect : passCorrect // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,distribution: null == distribution ? _self._distribution : distribution // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$QuestionBank {

 String get version; String get generatedAt; int get count; ExamBlueprint get blueprint; List<Question> get questions;
/// Create a copy of QuestionBank
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionBankCopyWith<QuestionBank> get copyWith => _$QuestionBankCopyWithImpl<QuestionBank>(this as QuestionBank, _$identity);

  /// Serializes this QuestionBank to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionBank&&(identical(other.version, version) || other.version == version)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.count, count) || other.count == count)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint)&&const DeepCollectionEquality().equals(other.questions, questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,generatedAt,count,blueprint,const DeepCollectionEquality().hash(questions));

@override
String toString() {
  return 'QuestionBank(version: $version, generatedAt: $generatedAt, count: $count, blueprint: $blueprint, questions: $questions)';
}


}

/// @nodoc
abstract mixin class $QuestionBankCopyWith<$Res>  {
  factory $QuestionBankCopyWith(QuestionBank value, $Res Function(QuestionBank) _then) = _$QuestionBankCopyWithImpl;
@useResult
$Res call({
 String version, String generatedAt, int count, ExamBlueprint blueprint, List<Question> questions
});


$ExamBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class _$QuestionBankCopyWithImpl<$Res>
    implements $QuestionBankCopyWith<$Res> {
  _$QuestionBankCopyWithImpl(this._self, this._then);

  final QuestionBank _self;
  final $Res Function(QuestionBank) _then;

/// Create a copy of QuestionBank
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? generatedAt = null,Object? count = null,Object? blueprint = null,Object? questions = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as ExamBlueprint,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<Question>,
  ));
}
/// Create a copy of QuestionBank
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExamBlueprintCopyWith<$Res> get blueprint {
  
  return $ExamBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuestionBank].
extension QuestionBankPatterns on QuestionBank {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionBank value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionBank() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionBank value)  $default,){
final _that = this;
switch (_that) {
case _QuestionBank():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionBank value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionBank() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String generatedAt,  int count,  ExamBlueprint blueprint,  List<Question> questions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionBank() when $default != null:
return $default(_that.version,_that.generatedAt,_that.count,_that.blueprint,_that.questions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String generatedAt,  int count,  ExamBlueprint blueprint,  List<Question> questions)  $default,) {final _that = this;
switch (_that) {
case _QuestionBank():
return $default(_that.version,_that.generatedAt,_that.count,_that.blueprint,_that.questions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String generatedAt,  int count,  ExamBlueprint blueprint,  List<Question> questions)?  $default,) {final _that = this;
switch (_that) {
case _QuestionBank() when $default != null:
return $default(_that.version,_that.generatedAt,_that.count,_that.blueprint,_that.questions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionBank implements QuestionBank {
  const _QuestionBank({required this.version, required this.generatedAt, required this.count, required this.blueprint, required final  List<Question> questions}): _questions = questions;
  factory _QuestionBank.fromJson(Map<String, dynamic> json) => _$QuestionBankFromJson(json);

@override final  String version;
@override final  String generatedAt;
@override final  int count;
@override final  ExamBlueprint blueprint;
 final  List<Question> _questions;
@override List<Question> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}


/// Create a copy of QuestionBank
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionBankCopyWith<_QuestionBank> get copyWith => __$QuestionBankCopyWithImpl<_QuestionBank>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionBankToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionBank&&(identical(other.version, version) || other.version == version)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.count, count) || other.count == count)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint)&&const DeepCollectionEquality().equals(other._questions, _questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,generatedAt,count,blueprint,const DeepCollectionEquality().hash(_questions));

@override
String toString() {
  return 'QuestionBank(version: $version, generatedAt: $generatedAt, count: $count, blueprint: $blueprint, questions: $questions)';
}


}

/// @nodoc
abstract mixin class _$QuestionBankCopyWith<$Res> implements $QuestionBankCopyWith<$Res> {
  factory _$QuestionBankCopyWith(_QuestionBank value, $Res Function(_QuestionBank) _then) = __$QuestionBankCopyWithImpl;
@override @useResult
$Res call({
 String version, String generatedAt, int count, ExamBlueprint blueprint, List<Question> questions
});


@override $ExamBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class __$QuestionBankCopyWithImpl<$Res>
    implements _$QuestionBankCopyWith<$Res> {
  __$QuestionBankCopyWithImpl(this._self, this._then);

  final _QuestionBank _self;
  final $Res Function(_QuestionBank) _then;

/// Create a copy of QuestionBank
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? generatedAt = null,Object? count = null,Object? blueprint = null,Object? questions = null,}) {
  return _then(_QuestionBank(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as ExamBlueprint,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<Question>,
  ));
}

/// Create a copy of QuestionBank
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExamBlueprintCopyWith<$Res> get blueprint {
  
  return $ExamBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}

// dart format on
