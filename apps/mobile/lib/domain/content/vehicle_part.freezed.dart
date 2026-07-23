// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_part.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VehiclePart {

 String get id; String get name; VehicleSystem get system; String get desc; String get tip; String? get relatedLessonSlug; String? get photo; List<String> get inspection; String? get mistake;
/// Create a copy of VehiclePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehiclePartCopyWith<VehiclePart> get copyWith => _$VehiclePartCopyWithImpl<VehiclePart>(this as VehiclePart, _$identity);

  /// Serializes this VehiclePart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehiclePart&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.system, system) || other.system == system)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.relatedLessonSlug, relatedLessonSlug) || other.relatedLessonSlug == relatedLessonSlug)&&(identical(other.photo, photo) || other.photo == photo)&&const DeepCollectionEquality().equals(other.inspection, inspection)&&(identical(other.mistake, mistake) || other.mistake == mistake));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,system,desc,tip,relatedLessonSlug,photo,const DeepCollectionEquality().hash(inspection),mistake);

@override
String toString() {
  return 'VehiclePart(id: $id, name: $name, system: $system, desc: $desc, tip: $tip, relatedLessonSlug: $relatedLessonSlug, photo: $photo, inspection: $inspection, mistake: $mistake)';
}


}

/// @nodoc
abstract mixin class $VehiclePartCopyWith<$Res>  {
  factory $VehiclePartCopyWith(VehiclePart value, $Res Function(VehiclePart) _then) = _$VehiclePartCopyWithImpl;
@useResult
$Res call({
 String id, String name, VehicleSystem system, String desc, String tip, String? relatedLessonSlug, String? photo, List<String> inspection, String? mistake
});




}
/// @nodoc
class _$VehiclePartCopyWithImpl<$Res>
    implements $VehiclePartCopyWith<$Res> {
  _$VehiclePartCopyWithImpl(this._self, this._then);

  final VehiclePart _self;
  final $Res Function(VehiclePart) _then;

/// Create a copy of VehiclePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? system = null,Object? desc = null,Object? tip = null,Object? relatedLessonSlug = freezed,Object? photo = freezed,Object? inspection = null,Object? mistake = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as VehicleSystem,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as String,relatedLessonSlug: freezed == relatedLessonSlug ? _self.relatedLessonSlug : relatedLessonSlug // ignore: cast_nullable_to_non_nullable
as String?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,inspection: null == inspection ? _self.inspection : inspection // ignore: cast_nullable_to_non_nullable
as List<String>,mistake: freezed == mistake ? _self.mistake : mistake // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VehiclePart].
extension VehiclePartPatterns on VehiclePart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehiclePart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehiclePart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehiclePart value)  $default,){
final _that = this;
switch (_that) {
case _VehiclePart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehiclePart value)?  $default,){
final _that = this;
switch (_that) {
case _VehiclePart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  VehicleSystem system,  String desc,  String tip,  String? relatedLessonSlug,  String? photo,  List<String> inspection,  String? mistake)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehiclePart() when $default != null:
return $default(_that.id,_that.name,_that.system,_that.desc,_that.tip,_that.relatedLessonSlug,_that.photo,_that.inspection,_that.mistake);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  VehicleSystem system,  String desc,  String tip,  String? relatedLessonSlug,  String? photo,  List<String> inspection,  String? mistake)  $default,) {final _that = this;
switch (_that) {
case _VehiclePart():
return $default(_that.id,_that.name,_that.system,_that.desc,_that.tip,_that.relatedLessonSlug,_that.photo,_that.inspection,_that.mistake);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  VehicleSystem system,  String desc,  String tip,  String? relatedLessonSlug,  String? photo,  List<String> inspection,  String? mistake)?  $default,) {final _that = this;
switch (_that) {
case _VehiclePart() when $default != null:
return $default(_that.id,_that.name,_that.system,_that.desc,_that.tip,_that.relatedLessonSlug,_that.photo,_that.inspection,_that.mistake);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehiclePart implements VehiclePart {
  const _VehiclePart({required this.id, required this.name, required this.system, required this.desc, required this.tip, this.relatedLessonSlug, this.photo, final  List<String> inspection = const [], this.mistake}): _inspection = inspection;
  factory _VehiclePart.fromJson(Map<String, dynamic> json) => _$VehiclePartFromJson(json);

@override final  String id;
@override final  String name;
@override final  VehicleSystem system;
@override final  String desc;
@override final  String tip;
@override final  String? relatedLessonSlug;
@override final  String? photo;
 final  List<String> _inspection;
@override@JsonKey() List<String> get inspection {
  if (_inspection is EqualUnmodifiableListView) return _inspection;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inspection);
}

@override final  String? mistake;

/// Create a copy of VehiclePart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehiclePartCopyWith<_VehiclePart> get copyWith => __$VehiclePartCopyWithImpl<_VehiclePart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehiclePartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehiclePart&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.system, system) || other.system == system)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.relatedLessonSlug, relatedLessonSlug) || other.relatedLessonSlug == relatedLessonSlug)&&(identical(other.photo, photo) || other.photo == photo)&&const DeepCollectionEquality().equals(other._inspection, _inspection)&&(identical(other.mistake, mistake) || other.mistake == mistake));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,system,desc,tip,relatedLessonSlug,photo,const DeepCollectionEquality().hash(_inspection),mistake);

@override
String toString() {
  return 'VehiclePart(id: $id, name: $name, system: $system, desc: $desc, tip: $tip, relatedLessonSlug: $relatedLessonSlug, photo: $photo, inspection: $inspection, mistake: $mistake)';
}


}

/// @nodoc
abstract mixin class _$VehiclePartCopyWith<$Res> implements $VehiclePartCopyWith<$Res> {
  factory _$VehiclePartCopyWith(_VehiclePart value, $Res Function(_VehiclePart) _then) = __$VehiclePartCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, VehicleSystem system, String desc, String tip, String? relatedLessonSlug, String? photo, List<String> inspection, String? mistake
});




}
/// @nodoc
class __$VehiclePartCopyWithImpl<$Res>
    implements _$VehiclePartCopyWith<$Res> {
  __$VehiclePartCopyWithImpl(this._self, this._then);

  final _VehiclePart _self;
  final $Res Function(_VehiclePart) _then;

/// Create a copy of VehiclePart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? system = null,Object? desc = null,Object? tip = null,Object? relatedLessonSlug = freezed,Object? photo = freezed,Object? inspection = null,Object? mistake = freezed,}) {
  return _then(_VehiclePart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as VehicleSystem,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as String,relatedLessonSlug: freezed == relatedLessonSlug ? _self.relatedLessonSlug : relatedLessonSlug // ignore: cast_nullable_to_non_nullable
as String?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,inspection: null == inspection ? _self._inspection : inspection // ignore: cast_nullable_to_non_nullable
as List<String>,mistake: freezed == mistake ? _self.mistake : mistake // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
