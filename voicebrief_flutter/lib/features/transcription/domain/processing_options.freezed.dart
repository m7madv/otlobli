// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'processing_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProcessingOptions {

 bool get transcript; bool get summary; bool get actionItems; bool get suggestedReplies; bool get translation;
/// Create a copy of ProcessingOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessingOptionsCopyWith<ProcessingOptions> get copyWith => _$ProcessingOptionsCopyWithImpl<ProcessingOptions>(this as ProcessingOptions, _$identity);

  /// Serializes this ProcessingOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessingOptions&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.actionItems, actionItems) || other.actionItems == actionItems)&&(identical(other.suggestedReplies, suggestedReplies) || other.suggestedReplies == suggestedReplies)&&(identical(other.translation, translation) || other.translation == translation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,transcript,summary,actionItems,suggestedReplies,translation);

@override
String toString() {
  return 'ProcessingOptions(transcript: $transcript, summary: $summary, actionItems: $actionItems, suggestedReplies: $suggestedReplies, translation: $translation)';
}


}

/// @nodoc
abstract mixin class $ProcessingOptionsCopyWith<$Res>  {
  factory $ProcessingOptionsCopyWith(ProcessingOptions value, $Res Function(ProcessingOptions) _then) = _$ProcessingOptionsCopyWithImpl;
@useResult
$Res call({
 bool transcript, bool summary, bool actionItems, bool suggestedReplies, bool translation
});




}
/// @nodoc
class _$ProcessingOptionsCopyWithImpl<$Res>
    implements $ProcessingOptionsCopyWith<$Res> {
  _$ProcessingOptionsCopyWithImpl(this._self, this._then);

  final ProcessingOptions _self;
  final $Res Function(ProcessingOptions) _then;

/// Create a copy of ProcessingOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transcript = null,Object? summary = null,Object? actionItems = null,Object? suggestedReplies = null,Object? translation = null,}) {
  return _then(_self.copyWith(
transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as bool,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as bool,actionItems: null == actionItems ? _self.actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as bool,suggestedReplies: null == suggestedReplies ? _self.suggestedReplies : suggestedReplies // ignore: cast_nullable_to_non_nullable
as bool,translation: null == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessingOptions].
extension ProcessingOptionsPatterns on ProcessingOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessingOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessingOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessingOptions value)  $default,){
final _that = this;
switch (_that) {
case _ProcessingOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessingOptions value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessingOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool transcript,  bool summary,  bool actionItems,  bool suggestedReplies,  bool translation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessingOptions() when $default != null:
return $default(_that.transcript,_that.summary,_that.actionItems,_that.suggestedReplies,_that.translation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool transcript,  bool summary,  bool actionItems,  bool suggestedReplies,  bool translation)  $default,) {final _that = this;
switch (_that) {
case _ProcessingOptions():
return $default(_that.transcript,_that.summary,_that.actionItems,_that.suggestedReplies,_that.translation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool transcript,  bool summary,  bool actionItems,  bool suggestedReplies,  bool translation)?  $default,) {final _that = this;
switch (_that) {
case _ProcessingOptions() when $default != null:
return $default(_that.transcript,_that.summary,_that.actionItems,_that.suggestedReplies,_that.translation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProcessingOptions implements ProcessingOptions {
  const _ProcessingOptions({this.transcript = true, this.summary = true, this.actionItems = true, this.suggestedReplies = true, this.translation = false});
  factory _ProcessingOptions.fromJson(Map<String, dynamic> json) => _$ProcessingOptionsFromJson(json);

@override@JsonKey() final  bool transcript;
@override@JsonKey() final  bool summary;
@override@JsonKey() final  bool actionItems;
@override@JsonKey() final  bool suggestedReplies;
@override@JsonKey() final  bool translation;

/// Create a copy of ProcessingOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessingOptionsCopyWith<_ProcessingOptions> get copyWith => __$ProcessingOptionsCopyWithImpl<_ProcessingOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProcessingOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessingOptions&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.actionItems, actionItems) || other.actionItems == actionItems)&&(identical(other.suggestedReplies, suggestedReplies) || other.suggestedReplies == suggestedReplies)&&(identical(other.translation, translation) || other.translation == translation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,transcript,summary,actionItems,suggestedReplies,translation);

@override
String toString() {
  return 'ProcessingOptions(transcript: $transcript, summary: $summary, actionItems: $actionItems, suggestedReplies: $suggestedReplies, translation: $translation)';
}


}

/// @nodoc
abstract mixin class _$ProcessingOptionsCopyWith<$Res> implements $ProcessingOptionsCopyWith<$Res> {
  factory _$ProcessingOptionsCopyWith(_ProcessingOptions value, $Res Function(_ProcessingOptions) _then) = __$ProcessingOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool transcript, bool summary, bool actionItems, bool suggestedReplies, bool translation
});




}
/// @nodoc
class __$ProcessingOptionsCopyWithImpl<$Res>
    implements _$ProcessingOptionsCopyWith<$Res> {
  __$ProcessingOptionsCopyWithImpl(this._self, this._then);

  final _ProcessingOptions _self;
  final $Res Function(_ProcessingOptions) _then;

/// Create a copy of ProcessingOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transcript = null,Object? summary = null,Object? actionItems = null,Object? suggestedReplies = null,Object? translation = null,}) {
  return _then(_ProcessingOptions(
transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as bool,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as bool,actionItems: null == actionItems ? _self.actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as bool,suggestedReplies: null == suggestedReplies ? _self.suggestedReplies : suggestedReplies // ignore: cast_nullable_to_non_nullable
as bool,translation: null == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
