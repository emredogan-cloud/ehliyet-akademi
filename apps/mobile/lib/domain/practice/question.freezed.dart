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
mixin _$ImageHotspot {

 String get id; double get x; double get y; double get w; double get h; String get label;
/// Create a copy of ImageHotspot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageHotspotCopyWith<ImageHotspot> get copyWith => _$ImageHotspotCopyWithImpl<ImageHotspot>(this as ImageHotspot, _$identity);

  /// Serializes this ImageHotspot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageHotspot&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,x,y,w,h,label);

@override
String toString() {
  return 'ImageHotspot(id: $id, x: $x, y: $y, w: $w, h: $h, label: $label)';
}


}

/// @nodoc
abstract mixin class $ImageHotspotCopyWith<$Res>  {
  factory $ImageHotspotCopyWith(ImageHotspot value, $Res Function(ImageHotspot) _then) = _$ImageHotspotCopyWithImpl;
@useResult
$Res call({
 String id, double x, double y, double w, double h, String label
});




}
/// @nodoc
class _$ImageHotspotCopyWithImpl<$Res>
    implements $ImageHotspotCopyWith<$Res> {
  _$ImageHotspotCopyWithImpl(this._self, this._then);

  final ImageHotspot _self;
  final $Res Function(ImageHotspot) _then;

/// Create a copy of ImageHotspot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? x = null,Object? y = null,Object? w = null,Object? h = null,Object? label = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,w: null == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as double,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageHotspot].
extension ImageHotspotPatterns on ImageHotspot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageHotspot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageHotspot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageHotspot value)  $default,){
final _that = this;
switch (_that) {
case _ImageHotspot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageHotspot value)?  $default,){
final _that = this;
switch (_that) {
case _ImageHotspot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double x,  double y,  double w,  double h,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageHotspot() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.w,_that.h,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double x,  double y,  double w,  double h,  String label)  $default,) {final _that = this;
switch (_that) {
case _ImageHotspot():
return $default(_that.id,_that.x,_that.y,_that.w,_that.h,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double x,  double y,  double w,  double h,  String label)?  $default,) {final _that = this;
switch (_that) {
case _ImageHotspot() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.w,_that.h,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageHotspot implements ImageHotspot {
  const _ImageHotspot({required this.id, required this.x, required this.y, required this.w, required this.h, required this.label});
  factory _ImageHotspot.fromJson(Map<String, dynamic> json) => _$ImageHotspotFromJson(json);

@override final  String id;
@override final  double x;
@override final  double y;
@override final  double w;
@override final  double h;
@override final  String label;

/// Create a copy of ImageHotspot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageHotspotCopyWith<_ImageHotspot> get copyWith => __$ImageHotspotCopyWithImpl<_ImageHotspot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageHotspotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageHotspot&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,x,y,w,h,label);

@override
String toString() {
  return 'ImageHotspot(id: $id, x: $x, y: $y, w: $w, h: $h, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ImageHotspotCopyWith<$Res> implements $ImageHotspotCopyWith<$Res> {
  factory _$ImageHotspotCopyWith(_ImageHotspot value, $Res Function(_ImageHotspot) _then) = __$ImageHotspotCopyWithImpl;
@override @useResult
$Res call({
 String id, double x, double y, double w, double h, String label
});




}
/// @nodoc
class __$ImageHotspotCopyWithImpl<$Res>
    implements _$ImageHotspotCopyWith<$Res> {
  __$ImageHotspotCopyWithImpl(this._self, this._then);

  final _ImageHotspot _self;
  final $Res Function(_ImageHotspot) _then;

/// Create a copy of ImageHotspot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? x = null,Object? y = null,Object? w = null,Object? h = null,Object? label = null,}) {
  return _then(_ImageHotspot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,w: null == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as double,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$QuestionImage {

/// Varlık kimliği — paketteki yola `AssetCatalog` sözleşmesiyle çözülür.
 String get assetId;/// ZORUNLU. Görsel çizilemezse soru bu metinle yine cevaplanabilir olmalı; ekran okuyucu
/// kullanan biri için de tek kaynak budur.
 String get alt; String? get caption; List<ImageHotspot> get hotspots;
/// Create a copy of QuestionImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionImageCopyWith<QuestionImage> get copyWith => _$QuestionImageCopyWithImpl<QuestionImage>(this as QuestionImage, _$identity);

  /// Serializes this QuestionImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionImage&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.alt, alt) || other.alt == alt)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.hotspots, hotspots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,alt,caption,const DeepCollectionEquality().hash(hotspots));

@override
String toString() {
  return 'QuestionImage(assetId: $assetId, alt: $alt, caption: $caption, hotspots: $hotspots)';
}


}

/// @nodoc
abstract mixin class $QuestionImageCopyWith<$Res>  {
  factory $QuestionImageCopyWith(QuestionImage value, $Res Function(QuestionImage) _then) = _$QuestionImageCopyWithImpl;
@useResult
$Res call({
 String assetId, String alt, String? caption, List<ImageHotspot> hotspots
});




}
/// @nodoc
class _$QuestionImageCopyWithImpl<$Res>
    implements $QuestionImageCopyWith<$Res> {
  _$QuestionImageCopyWithImpl(this._self, this._then);

  final QuestionImage _self;
  final $Res Function(QuestionImage) _then;

/// Create a copy of QuestionImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetId = null,Object? alt = null,Object? caption = freezed,Object? hotspots = null,}) {
  return _then(_self.copyWith(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,alt: null == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,hotspots: null == hotspots ? _self.hotspots : hotspots // ignore: cast_nullable_to_non_nullable
as List<ImageHotspot>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionImage].
extension QuestionImagePatterns on QuestionImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionImage value)  $default,){
final _that = this;
switch (_that) {
case _QuestionImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionImage value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assetId,  String alt,  String? caption,  List<ImageHotspot> hotspots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionImage() when $default != null:
return $default(_that.assetId,_that.alt,_that.caption,_that.hotspots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assetId,  String alt,  String? caption,  List<ImageHotspot> hotspots)  $default,) {final _that = this;
switch (_that) {
case _QuestionImage():
return $default(_that.assetId,_that.alt,_that.caption,_that.hotspots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assetId,  String alt,  String? caption,  List<ImageHotspot> hotspots)?  $default,) {final _that = this;
switch (_that) {
case _QuestionImage() when $default != null:
return $default(_that.assetId,_that.alt,_that.caption,_that.hotspots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionImage implements QuestionImage {
  const _QuestionImage({required this.assetId, required this.alt, this.caption, final  List<ImageHotspot> hotspots = const []}): _hotspots = hotspots;
  factory _QuestionImage.fromJson(Map<String, dynamic> json) => _$QuestionImageFromJson(json);

/// Varlık kimliği — paketteki yola `AssetCatalog` sözleşmesiyle çözülür.
@override final  String assetId;
/// ZORUNLU. Görsel çizilemezse soru bu metinle yine cevaplanabilir olmalı; ekran okuyucu
/// kullanan biri için de tek kaynak budur.
@override final  String alt;
@override final  String? caption;
 final  List<ImageHotspot> _hotspots;
@override@JsonKey() List<ImageHotspot> get hotspots {
  if (_hotspots is EqualUnmodifiableListView) return _hotspots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hotspots);
}


/// Create a copy of QuestionImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionImageCopyWith<_QuestionImage> get copyWith => __$QuestionImageCopyWithImpl<_QuestionImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionImage&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.alt, alt) || other.alt == alt)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._hotspots, _hotspots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,alt,caption,const DeepCollectionEquality().hash(_hotspots));

@override
String toString() {
  return 'QuestionImage(assetId: $assetId, alt: $alt, caption: $caption, hotspots: $hotspots)';
}


}

/// @nodoc
abstract mixin class _$QuestionImageCopyWith<$Res> implements $QuestionImageCopyWith<$Res> {
  factory _$QuestionImageCopyWith(_QuestionImage value, $Res Function(_QuestionImage) _then) = __$QuestionImageCopyWithImpl;
@override @useResult
$Res call({
 String assetId, String alt, String? caption, List<ImageHotspot> hotspots
});




}
/// @nodoc
class __$QuestionImageCopyWithImpl<$Res>
    implements _$QuestionImageCopyWith<$Res> {
  __$QuestionImageCopyWithImpl(this._self, this._then);

  final _QuestionImage _self;
  final $Res Function(_QuestionImage) _then;

/// Create a copy of QuestionImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetId = null,Object? alt = null,Object? caption = freezed,Object? hotspots = null,}) {
  return _then(_QuestionImage(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,alt: null == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,hotspots: null == hotspots ? _self._hotspots : hotspots // ignore: cast_nullable_to_non_nullable
as List<ImageHotspot>,
  ));
}


}


/// @nodoc
mixin _$QuestionMedia {

 List<QuestionImage> get images; MediaLayout get layout;
/// Create a copy of QuestionMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionMediaCopyWith<QuestionMedia> get copyWith => _$QuestionMediaCopyWithImpl<QuestionMedia>(this as QuestionMedia, _$identity);

  /// Serializes this QuestionMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionMedia&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.layout, layout) || other.layout == layout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(images),layout);

@override
String toString() {
  return 'QuestionMedia(images: $images, layout: $layout)';
}


}

/// @nodoc
abstract mixin class $QuestionMediaCopyWith<$Res>  {
  factory $QuestionMediaCopyWith(QuestionMedia value, $Res Function(QuestionMedia) _then) = _$QuestionMediaCopyWithImpl;
@useResult
$Res call({
 List<QuestionImage> images, MediaLayout layout
});




}
/// @nodoc
class _$QuestionMediaCopyWithImpl<$Res>
    implements $QuestionMediaCopyWith<$Res> {
  _$QuestionMediaCopyWithImpl(this._self, this._then);

  final QuestionMedia _self;
  final $Res Function(QuestionMedia) _then;

/// Create a copy of QuestionMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? images = null,Object? layout = null,}) {
  return _then(_self.copyWith(
images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<QuestionImage>,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as MediaLayout,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionMedia].
extension QuestionMediaPatterns on QuestionMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionMedia value)  $default,){
final _that = this;
switch (_that) {
case _QuestionMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionMedia value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<QuestionImage> images,  MediaLayout layout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionMedia() when $default != null:
return $default(_that.images,_that.layout);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<QuestionImage> images,  MediaLayout layout)  $default,) {final _that = this;
switch (_that) {
case _QuestionMedia():
return $default(_that.images,_that.layout);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<QuestionImage> images,  MediaLayout layout)?  $default,) {final _that = this;
switch (_that) {
case _QuestionMedia() when $default != null:
return $default(_that.images,_that.layout);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionMedia implements QuestionMedia {
  const _QuestionMedia({required final  List<QuestionImage> images, this.layout = MediaLayout.single}): _images = images;
  factory _QuestionMedia.fromJson(Map<String, dynamic> json) => _$QuestionMediaFromJson(json);

 final  List<QuestionImage> _images;
@override List<QuestionImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override@JsonKey() final  MediaLayout layout;

/// Create a copy of QuestionMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionMediaCopyWith<_QuestionMedia> get copyWith => __$QuestionMediaCopyWithImpl<_QuestionMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionMediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionMedia&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.layout, layout) || other.layout == layout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_images),layout);

@override
String toString() {
  return 'QuestionMedia(images: $images, layout: $layout)';
}


}

/// @nodoc
abstract mixin class _$QuestionMediaCopyWith<$Res> implements $QuestionMediaCopyWith<$Res> {
  factory _$QuestionMediaCopyWith(_QuestionMedia value, $Res Function(_QuestionMedia) _then) = __$QuestionMediaCopyWithImpl;
@override @useResult
$Res call({
 List<QuestionImage> images, MediaLayout layout
});




}
/// @nodoc
class __$QuestionMediaCopyWithImpl<$Res>
    implements _$QuestionMediaCopyWith<$Res> {
  __$QuestionMediaCopyWithImpl(this._self, this._then);

  final _QuestionMedia _self;
  final $Res Function(_QuestionMedia) _then;

/// Create a copy of QuestionMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? images = null,Object? layout = null,}) {
  return _then(_QuestionMedia(
images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<QuestionImage>,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as MediaLayout,
  ));
}


}


/// @nodoc
mixin _$Question {

 String get id; Subject get subject; String get topic; Difficulty get difficulty; String get stem; List<String> get options; int get answerIndex; String get explanation; Badge? get badge; List<String> get whyWrong;/// QIP v3 · Faz 1 — tür + görsel. İkisi de VARSAYILANLI/OPSİYONEL: sunucudan gelen eski
/// yükte bu alanlar yoktur ve soru aynen çalışmaya devam eder.
 QuestionKind get kind; QuestionMedia? get media;/// Öğrenme kazanımı — görsel sorularda zorunlu değil ama üreteç her zaman dolduruyor.
 String? get objective;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.stem, stem) || other.stem == stem)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.answerIndex, answerIndex) || other.answerIndex == answerIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.badge, badge) || other.badge == badge)&&const DeepCollectionEquality().equals(other.whyWrong, whyWrong)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.media, media) || other.media == media)&&(identical(other.objective, objective) || other.objective == objective));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,difficulty,stem,const DeepCollectionEquality().hash(options),answerIndex,explanation,badge,const DeepCollectionEquality().hash(whyWrong),kind,media,objective);

@override
String toString() {
  return 'Question(id: $id, subject: $subject, topic: $topic, difficulty: $difficulty, stem: $stem, options: $options, answerIndex: $answerIndex, explanation: $explanation, badge: $badge, whyWrong: $whyWrong, kind: $kind, media: $media, objective: $objective)';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 String id, Subject subject, String topic, Difficulty difficulty, String stem, List<String> options, int answerIndex, String explanation, Badge? badge, List<String> whyWrong, QuestionKind kind, QuestionMedia? media, String? objective
});


$QuestionMediaCopyWith<$Res>? get media;

}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? difficulty = null,Object? stem = null,Object? options = null,Object? answerIndex = null,Object? explanation = null,Object? badge = freezed,Object? whyWrong = null,Object? kind = null,Object? media = freezed,Object? objective = freezed,}) {
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
as List<String>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QuestionKind,media: freezed == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as QuestionMedia?,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionMediaCopyWith<$Res>? get media {
    if (_self.media == null) {
    return null;
  }

  return $QuestionMediaCopyWith<$Res>(_self.media!, (value) {
    return _then(_self.copyWith(media: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Subject subject,  String topic,  Difficulty difficulty,  String stem,  List<String> options,  int answerIndex,  String explanation,  Badge? badge,  List<String> whyWrong,  QuestionKind kind,  QuestionMedia? media,  String? objective)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.difficulty,_that.stem,_that.options,_that.answerIndex,_that.explanation,_that.badge,_that.whyWrong,_that.kind,_that.media,_that.objective);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Subject subject,  String topic,  Difficulty difficulty,  String stem,  List<String> options,  int answerIndex,  String explanation,  Badge? badge,  List<String> whyWrong,  QuestionKind kind,  QuestionMedia? media,  String? objective)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.id,_that.subject,_that.topic,_that.difficulty,_that.stem,_that.options,_that.answerIndex,_that.explanation,_that.badge,_that.whyWrong,_that.kind,_that.media,_that.objective);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Subject subject,  String topic,  Difficulty difficulty,  String stem,  List<String> options,  int answerIndex,  String explanation,  Badge? badge,  List<String> whyWrong,  QuestionKind kind,  QuestionMedia? media,  String? objective)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.difficulty,_that.stem,_that.options,_that.answerIndex,_that.explanation,_that.badge,_that.whyWrong,_that.kind,_that.media,_that.objective);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question implements Question {
  const _Question({required this.id, required this.subject, required this.topic, this.difficulty = Difficulty.orta, required this.stem, required final  List<String> options, required this.answerIndex, required this.explanation, this.badge, final  List<String> whyWrong = const [], this.kind = QuestionKind.text, this.media, this.objective}): _options = options,_whyWrong = whyWrong;
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

/// QIP v3 · Faz 1 — tür + görsel. İkisi de VARSAYILANLI/OPSİYONEL: sunucudan gelen eski
/// yükte bu alanlar yoktur ve soru aynen çalışmaya devam eder.
@override@JsonKey() final  QuestionKind kind;
@override final  QuestionMedia? media;
/// Öğrenme kazanımı — görsel sorularda zorunlu değil ama üreteç her zaman dolduruyor.
@override final  String? objective;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.stem, stem) || other.stem == stem)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.answerIndex, answerIndex) || other.answerIndex == answerIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.badge, badge) || other.badge == badge)&&const DeepCollectionEquality().equals(other._whyWrong, _whyWrong)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.media, media) || other.media == media)&&(identical(other.objective, objective) || other.objective == objective));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,difficulty,stem,const DeepCollectionEquality().hash(_options),answerIndex,explanation,badge,const DeepCollectionEquality().hash(_whyWrong),kind,media,objective);

@override
String toString() {
  return 'Question(id: $id, subject: $subject, topic: $topic, difficulty: $difficulty, stem: $stem, options: $options, answerIndex: $answerIndex, explanation: $explanation, badge: $badge, whyWrong: $whyWrong, kind: $kind, media: $media, objective: $objective)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, Subject subject, String topic, Difficulty difficulty, String stem, List<String> options, int answerIndex, String explanation, Badge? badge, List<String> whyWrong, QuestionKind kind, QuestionMedia? media, String? objective
});


@override $QuestionMediaCopyWith<$Res>? get media;

}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? difficulty = null,Object? stem = null,Object? options = null,Object? answerIndex = null,Object? explanation = null,Object? badge = freezed,Object? whyWrong = null,Object? kind = null,Object? media = freezed,Object? objective = freezed,}) {
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
as List<String>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QuestionKind,media: freezed == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as QuestionMedia?,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionMediaCopyWith<$Res>? get media {
    if (_self.media == null) {
    return null;
  }

  return $QuestionMediaCopyWith<$Res>(_self.media!, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}

// dart format on
