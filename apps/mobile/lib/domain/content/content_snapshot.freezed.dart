// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SnapshotCounts {

 int get lessons; int get signs; int get vehicleParts; int get videos;
/// Create a copy of SnapshotCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnapshotCountsCopyWith<SnapshotCounts> get copyWith => _$SnapshotCountsCopyWithImpl<SnapshotCounts>(this as SnapshotCounts, _$identity);

  /// Serializes this SnapshotCounts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SnapshotCounts&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.signs, signs) || other.signs == signs)&&(identical(other.vehicleParts, vehicleParts) || other.vehicleParts == vehicleParts)&&(identical(other.videos, videos) || other.videos == videos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessons,signs,vehicleParts,videos);

@override
String toString() {
  return 'SnapshotCounts(lessons: $lessons, signs: $signs, vehicleParts: $vehicleParts, videos: $videos)';
}


}

/// @nodoc
abstract mixin class $SnapshotCountsCopyWith<$Res>  {
  factory $SnapshotCountsCopyWith(SnapshotCounts value, $Res Function(SnapshotCounts) _then) = _$SnapshotCountsCopyWithImpl;
@useResult
$Res call({
 int lessons, int signs, int vehicleParts, int videos
});




}
/// @nodoc
class _$SnapshotCountsCopyWithImpl<$Res>
    implements $SnapshotCountsCopyWith<$Res> {
  _$SnapshotCountsCopyWithImpl(this._self, this._then);

  final SnapshotCounts _self;
  final $Res Function(SnapshotCounts) _then;

/// Create a copy of SnapshotCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lessons = null,Object? signs = null,Object? vehicleParts = null,Object? videos = null,}) {
  return _then(_self.copyWith(
lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as int,signs: null == signs ? _self.signs : signs // ignore: cast_nullable_to_non_nullable
as int,vehicleParts: null == vehicleParts ? _self.vehicleParts : vehicleParts // ignore: cast_nullable_to_non_nullable
as int,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SnapshotCounts].
extension SnapshotCountsPatterns on SnapshotCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SnapshotCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SnapshotCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SnapshotCounts value)  $default,){
final _that = this;
switch (_that) {
case _SnapshotCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SnapshotCounts value)?  $default,){
final _that = this;
switch (_that) {
case _SnapshotCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int lessons,  int signs,  int vehicleParts,  int videos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SnapshotCounts() when $default != null:
return $default(_that.lessons,_that.signs,_that.vehicleParts,_that.videos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int lessons,  int signs,  int vehicleParts,  int videos)  $default,) {final _that = this;
switch (_that) {
case _SnapshotCounts():
return $default(_that.lessons,_that.signs,_that.vehicleParts,_that.videos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int lessons,  int signs,  int vehicleParts,  int videos)?  $default,) {final _that = this;
switch (_that) {
case _SnapshotCounts() when $default != null:
return $default(_that.lessons,_that.signs,_that.vehicleParts,_that.videos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SnapshotCounts implements SnapshotCounts {
  const _SnapshotCounts({required this.lessons, required this.signs, required this.vehicleParts, required this.videos});
  factory _SnapshotCounts.fromJson(Map<String, dynamic> json) => _$SnapshotCountsFromJson(json);

@override final  int lessons;
@override final  int signs;
@override final  int vehicleParts;
@override final  int videos;

/// Create a copy of SnapshotCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnapshotCountsCopyWith<_SnapshotCounts> get copyWith => __$SnapshotCountsCopyWithImpl<_SnapshotCounts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SnapshotCountsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SnapshotCounts&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.signs, signs) || other.signs == signs)&&(identical(other.vehicleParts, vehicleParts) || other.vehicleParts == vehicleParts)&&(identical(other.videos, videos) || other.videos == videos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessons,signs,vehicleParts,videos);

@override
String toString() {
  return 'SnapshotCounts(lessons: $lessons, signs: $signs, vehicleParts: $vehicleParts, videos: $videos)';
}


}

/// @nodoc
abstract mixin class _$SnapshotCountsCopyWith<$Res> implements $SnapshotCountsCopyWith<$Res> {
  factory _$SnapshotCountsCopyWith(_SnapshotCounts value, $Res Function(_SnapshotCounts) _then) = __$SnapshotCountsCopyWithImpl;
@override @useResult
$Res call({
 int lessons, int signs, int vehicleParts, int videos
});




}
/// @nodoc
class __$SnapshotCountsCopyWithImpl<$Res>
    implements _$SnapshotCountsCopyWith<$Res> {
  __$SnapshotCountsCopyWithImpl(this._self, this._then);

  final _SnapshotCounts _self;
  final $Res Function(_SnapshotCounts) _then;

/// Create a copy of SnapshotCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lessons = null,Object? signs = null,Object? vehicleParts = null,Object? videos = null,}) {
  return _then(_SnapshotCounts(
lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as int,signs: null == signs ? _self.signs : signs // ignore: cast_nullable_to_non_nullable
as int,vehicleParts: null == vehicleParts ? _self.vehicleParts : vehicleParts // ignore: cast_nullable_to_non_nullable
as int,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ContentSnapshot {

 String get version; String get generatedAt; SnapshotCounts get counts; List<Lesson> get lessons; List<TrafficSign> get signs; List<VehiclePart> get vehicleParts; List<VideoContent> get videos;
/// Create a copy of ContentSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentSnapshotCopyWith<ContentSnapshot> get copyWith => _$ContentSnapshotCopyWithImpl<ContentSnapshot>(this as ContentSnapshot, _$identity);

  /// Serializes this ContentSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentSnapshot&&(identical(other.version, version) || other.version == version)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.counts, counts) || other.counts == counts)&&const DeepCollectionEquality().equals(other.lessons, lessons)&&const DeepCollectionEquality().equals(other.signs, signs)&&const DeepCollectionEquality().equals(other.vehicleParts, vehicleParts)&&const DeepCollectionEquality().equals(other.videos, videos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,generatedAt,counts,const DeepCollectionEquality().hash(lessons),const DeepCollectionEquality().hash(signs),const DeepCollectionEquality().hash(vehicleParts),const DeepCollectionEquality().hash(videos));

@override
String toString() {
  return 'ContentSnapshot(version: $version, generatedAt: $generatedAt, counts: $counts, lessons: $lessons, signs: $signs, vehicleParts: $vehicleParts, videos: $videos)';
}


}

/// @nodoc
abstract mixin class $ContentSnapshotCopyWith<$Res>  {
  factory $ContentSnapshotCopyWith(ContentSnapshot value, $Res Function(ContentSnapshot) _then) = _$ContentSnapshotCopyWithImpl;
@useResult
$Res call({
 String version, String generatedAt, SnapshotCounts counts, List<Lesson> lessons, List<TrafficSign> signs, List<VehiclePart> vehicleParts, List<VideoContent> videos
});


$SnapshotCountsCopyWith<$Res> get counts;

}
/// @nodoc
class _$ContentSnapshotCopyWithImpl<$Res>
    implements $ContentSnapshotCopyWith<$Res> {
  _$ContentSnapshotCopyWithImpl(this._self, this._then);

  final ContentSnapshot _self;
  final $Res Function(ContentSnapshot) _then;

/// Create a copy of ContentSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? generatedAt = null,Object? counts = null,Object? lessons = null,Object? signs = null,Object? vehicleParts = null,Object? videos = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as SnapshotCounts,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<Lesson>,signs: null == signs ? _self.signs : signs // ignore: cast_nullable_to_non_nullable
as List<TrafficSign>,vehicleParts: null == vehicleParts ? _self.vehicleParts : vehicleParts // ignore: cast_nullable_to_non_nullable
as List<VehiclePart>,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as List<VideoContent>,
  ));
}
/// Create a copy of ContentSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SnapshotCountsCopyWith<$Res> get counts {
  
  return $SnapshotCountsCopyWith<$Res>(_self.counts, (value) {
    return _then(_self.copyWith(counts: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContentSnapshot].
extension ContentSnapshotPatterns on ContentSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _ContentSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _ContentSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String generatedAt,  SnapshotCounts counts,  List<Lesson> lessons,  List<TrafficSign> signs,  List<VehiclePart> vehicleParts,  List<VideoContent> videos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentSnapshot() when $default != null:
return $default(_that.version,_that.generatedAt,_that.counts,_that.lessons,_that.signs,_that.vehicleParts,_that.videos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String generatedAt,  SnapshotCounts counts,  List<Lesson> lessons,  List<TrafficSign> signs,  List<VehiclePart> vehicleParts,  List<VideoContent> videos)  $default,) {final _that = this;
switch (_that) {
case _ContentSnapshot():
return $default(_that.version,_that.generatedAt,_that.counts,_that.lessons,_that.signs,_that.vehicleParts,_that.videos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String generatedAt,  SnapshotCounts counts,  List<Lesson> lessons,  List<TrafficSign> signs,  List<VehiclePart> vehicleParts,  List<VideoContent> videos)?  $default,) {final _that = this;
switch (_that) {
case _ContentSnapshot() when $default != null:
return $default(_that.version,_that.generatedAt,_that.counts,_that.lessons,_that.signs,_that.vehicleParts,_that.videos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContentSnapshot implements ContentSnapshot {
  const _ContentSnapshot({required this.version, required this.generatedAt, required this.counts, required final  List<Lesson> lessons, required final  List<TrafficSign> signs, required final  List<VehiclePart> vehicleParts, required final  List<VideoContent> videos}): _lessons = lessons,_signs = signs,_vehicleParts = vehicleParts,_videos = videos;
  factory _ContentSnapshot.fromJson(Map<String, dynamic> json) => _$ContentSnapshotFromJson(json);

@override final  String version;
@override final  String generatedAt;
@override final  SnapshotCounts counts;
 final  List<Lesson> _lessons;
@override List<Lesson> get lessons {
  if (_lessons is EqualUnmodifiableListView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lessons);
}

 final  List<TrafficSign> _signs;
@override List<TrafficSign> get signs {
  if (_signs is EqualUnmodifiableListView) return _signs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signs);
}

 final  List<VehiclePart> _vehicleParts;
@override List<VehiclePart> get vehicleParts {
  if (_vehicleParts is EqualUnmodifiableListView) return _vehicleParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vehicleParts);
}

 final  List<VideoContent> _videos;
@override List<VideoContent> get videos {
  if (_videos is EqualUnmodifiableListView) return _videos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videos);
}


/// Create a copy of ContentSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentSnapshotCopyWith<_ContentSnapshot> get copyWith => __$ContentSnapshotCopyWithImpl<_ContentSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentSnapshot&&(identical(other.version, version) || other.version == version)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.counts, counts) || other.counts == counts)&&const DeepCollectionEquality().equals(other._lessons, _lessons)&&const DeepCollectionEquality().equals(other._signs, _signs)&&const DeepCollectionEquality().equals(other._vehicleParts, _vehicleParts)&&const DeepCollectionEquality().equals(other._videos, _videos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,generatedAt,counts,const DeepCollectionEquality().hash(_lessons),const DeepCollectionEquality().hash(_signs),const DeepCollectionEquality().hash(_vehicleParts),const DeepCollectionEquality().hash(_videos));

@override
String toString() {
  return 'ContentSnapshot(version: $version, generatedAt: $generatedAt, counts: $counts, lessons: $lessons, signs: $signs, vehicleParts: $vehicleParts, videos: $videos)';
}


}

/// @nodoc
abstract mixin class _$ContentSnapshotCopyWith<$Res> implements $ContentSnapshotCopyWith<$Res> {
  factory _$ContentSnapshotCopyWith(_ContentSnapshot value, $Res Function(_ContentSnapshot) _then) = __$ContentSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String version, String generatedAt, SnapshotCounts counts, List<Lesson> lessons, List<TrafficSign> signs, List<VehiclePart> vehicleParts, List<VideoContent> videos
});


@override $SnapshotCountsCopyWith<$Res> get counts;

}
/// @nodoc
class __$ContentSnapshotCopyWithImpl<$Res>
    implements _$ContentSnapshotCopyWith<$Res> {
  __$ContentSnapshotCopyWithImpl(this._self, this._then);

  final _ContentSnapshot _self;
  final $Res Function(_ContentSnapshot) _then;

/// Create a copy of ContentSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? generatedAt = null,Object? counts = null,Object? lessons = null,Object? signs = null,Object? vehicleParts = null,Object? videos = null,}) {
  return _then(_ContentSnapshot(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as SnapshotCounts,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<Lesson>,signs: null == signs ? _self._signs : signs // ignore: cast_nullable_to_non_nullable
as List<TrafficSign>,vehicleParts: null == vehicleParts ? _self._vehicleParts : vehicleParts // ignore: cast_nullable_to_non_nullable
as List<VehiclePart>,videos: null == videos ? _self._videos : videos // ignore: cast_nullable_to_non_nullable
as List<VideoContent>,
  ));
}

/// Create a copy of ContentSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SnapshotCountsCopyWith<$Res> get counts {
  
  return $SnapshotCountsCopyWith<$Res>(_self.counts, (value) {
    return _then(_self.copyWith(counts: value));
  });
}
}

// dart format on
