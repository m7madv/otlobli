// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AudioInput {

 String get path; String get displayName; String get mimeType; int get sizeBytes; int get durationSeconds; AudioSourceKind get source;
/// Create a copy of AudioInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioInputCopyWith<AudioInput> get copyWith => _$AudioInputCopyWithImpl<AudioInput>(this as AudioInput, _$identity);

  /// Serializes this AudioInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioInput&&(identical(other.path, path) || other.path == path)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,displayName,mimeType,sizeBytes,durationSeconds,source);

@override
String toString() {
  return 'AudioInput(path: $path, displayName: $displayName, mimeType: $mimeType, sizeBytes: $sizeBytes, durationSeconds: $durationSeconds, source: $source)';
}


}

/// @nodoc
abstract mixin class $AudioInputCopyWith<$Res>  {
  factory $AudioInputCopyWith(AudioInput value, $Res Function(AudioInput) _then) = _$AudioInputCopyWithImpl;
@useResult
$Res call({
 String path, String displayName, String mimeType, int sizeBytes, int durationSeconds, AudioSourceKind source
});




}
/// @nodoc
class _$AudioInputCopyWithImpl<$Res>
    implements $AudioInputCopyWith<$Res> {
  _$AudioInputCopyWithImpl(this._self, this._then);

  final AudioInput _self;
  final $Res Function(AudioInput) _then;

/// Create a copy of AudioInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? displayName = null,Object? mimeType = null,Object? sizeBytes = null,Object? durationSeconds = null,Object? source = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AudioSourceKind,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioInput].
extension AudioInputPatterns on AudioInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioInput value)  $default,){
final _that = this;
switch (_that) {
case _AudioInput():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioInput value)?  $default,){
final _that = this;
switch (_that) {
case _AudioInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String displayName,  String mimeType,  int sizeBytes,  int durationSeconds,  AudioSourceKind source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioInput() when $default != null:
return $default(_that.path,_that.displayName,_that.mimeType,_that.sizeBytes,_that.durationSeconds,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String displayName,  String mimeType,  int sizeBytes,  int durationSeconds,  AudioSourceKind source)  $default,) {final _that = this;
switch (_that) {
case _AudioInput():
return $default(_that.path,_that.displayName,_that.mimeType,_that.sizeBytes,_that.durationSeconds,_that.source);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String displayName,  String mimeType,  int sizeBytes,  int durationSeconds,  AudioSourceKind source)?  $default,) {final _that = this;
switch (_that) {
case _AudioInput() when $default != null:
return $default(_that.path,_that.displayName,_that.mimeType,_that.sizeBytes,_that.durationSeconds,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioInput implements AudioInput {
  const _AudioInput({required this.path, required this.displayName, required this.mimeType, required this.sizeBytes, required this.durationSeconds, required this.source});
  factory _AudioInput.fromJson(Map<String, dynamic> json) => _$AudioInputFromJson(json);

@override final  String path;
@override final  String displayName;
@override final  String mimeType;
@override final  int sizeBytes;
@override final  int durationSeconds;
@override final  AudioSourceKind source;

/// Create a copy of AudioInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioInputCopyWith<_AudioInput> get copyWith => __$AudioInputCopyWithImpl<_AudioInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioInputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioInput&&(identical(other.path, path) || other.path == path)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,displayName,mimeType,sizeBytes,durationSeconds,source);

@override
String toString() {
  return 'AudioInput(path: $path, displayName: $displayName, mimeType: $mimeType, sizeBytes: $sizeBytes, durationSeconds: $durationSeconds, source: $source)';
}


}

/// @nodoc
abstract mixin class _$AudioInputCopyWith<$Res> implements $AudioInputCopyWith<$Res> {
  factory _$AudioInputCopyWith(_AudioInput value, $Res Function(_AudioInput) _then) = __$AudioInputCopyWithImpl;
@override @useResult
$Res call({
 String path, String displayName, String mimeType, int sizeBytes, int durationSeconds, AudioSourceKind source
});




}
/// @nodoc
class __$AudioInputCopyWithImpl<$Res>
    implements _$AudioInputCopyWith<$Res> {
  __$AudioInputCopyWithImpl(this._self, this._then);

  final _AudioInput _self;
  final $Res Function(_AudioInput) _then;

/// Create a copy of AudioInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? displayName = null,Object? mimeType = null,Object? sizeBytes = null,Object? durationSeconds = null,Object? source = null,}) {
  return _then(_AudioInput(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AudioSourceKind,
  ));
}


}

// dart format on
