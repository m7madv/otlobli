// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionOption {

 String get productId; String get title; String get localizedPrice; bool get annual; String? get localizedMonthlyEquivalent; String? get packageIdentifier;
/// Create a copy of SubscriptionOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionOptionCopyWith<SubscriptionOption> get copyWith => _$SubscriptionOptionCopyWithImpl<SubscriptionOption>(this as SubscriptionOption, _$identity);

  /// Serializes this SubscriptionOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionOption&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.title, title) || other.title == title)&&(identical(other.localizedPrice, localizedPrice) || other.localizedPrice == localizedPrice)&&(identical(other.annual, annual) || other.annual == annual)&&(identical(other.localizedMonthlyEquivalent, localizedMonthlyEquivalent) || other.localizedMonthlyEquivalent == localizedMonthlyEquivalent)&&(identical(other.packageIdentifier, packageIdentifier) || other.packageIdentifier == packageIdentifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,title,localizedPrice,annual,localizedMonthlyEquivalent,packageIdentifier);

@override
String toString() {
  return 'SubscriptionOption(productId: $productId, title: $title, localizedPrice: $localizedPrice, annual: $annual, localizedMonthlyEquivalent: $localizedMonthlyEquivalent, packageIdentifier: $packageIdentifier)';
}


}

/// @nodoc
abstract mixin class $SubscriptionOptionCopyWith<$Res>  {
  factory $SubscriptionOptionCopyWith(SubscriptionOption value, $Res Function(SubscriptionOption) _then) = _$SubscriptionOptionCopyWithImpl;
@useResult
$Res call({
 String productId, String title, String localizedPrice, bool annual, String? localizedMonthlyEquivalent, String? packageIdentifier
});




}
/// @nodoc
class _$SubscriptionOptionCopyWithImpl<$Res>
    implements $SubscriptionOptionCopyWith<$Res> {
  _$SubscriptionOptionCopyWithImpl(this._self, this._then);

  final SubscriptionOption _self;
  final $Res Function(SubscriptionOption) _then;

/// Create a copy of SubscriptionOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? title = null,Object? localizedPrice = null,Object? annual = null,Object? localizedMonthlyEquivalent = freezed,Object? packageIdentifier = freezed,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,localizedPrice: null == localizedPrice ? _self.localizedPrice : localizedPrice // ignore: cast_nullable_to_non_nullable
as String,annual: null == annual ? _self.annual : annual // ignore: cast_nullable_to_non_nullable
as bool,localizedMonthlyEquivalent: freezed == localizedMonthlyEquivalent ? _self.localizedMonthlyEquivalent : localizedMonthlyEquivalent // ignore: cast_nullable_to_non_nullable
as String?,packageIdentifier: freezed == packageIdentifier ? _self.packageIdentifier : packageIdentifier // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionOption].
extension SubscriptionOptionPatterns on SubscriptionOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionOption value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionOption value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String title,  String localizedPrice,  bool annual,  String? localizedMonthlyEquivalent,  String? packageIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionOption() when $default != null:
return $default(_that.productId,_that.title,_that.localizedPrice,_that.annual,_that.localizedMonthlyEquivalent,_that.packageIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String title,  String localizedPrice,  bool annual,  String? localizedMonthlyEquivalent,  String? packageIdentifier)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionOption():
return $default(_that.productId,_that.title,_that.localizedPrice,_that.annual,_that.localizedMonthlyEquivalent,_that.packageIdentifier);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String title,  String localizedPrice,  bool annual,  String? localizedMonthlyEquivalent,  String? packageIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionOption() when $default != null:
return $default(_that.productId,_that.title,_that.localizedPrice,_that.annual,_that.localizedMonthlyEquivalent,_that.packageIdentifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionOption implements SubscriptionOption {
  const _SubscriptionOption({required this.productId, required this.title, required this.localizedPrice, required this.annual, this.localizedMonthlyEquivalent, this.packageIdentifier});
  factory _SubscriptionOption.fromJson(Map<String, dynamic> json) => _$SubscriptionOptionFromJson(json);

@override final  String productId;
@override final  String title;
@override final  String localizedPrice;
@override final  bool annual;
@override final  String? localizedMonthlyEquivalent;
@override final  String? packageIdentifier;

/// Create a copy of SubscriptionOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionOptionCopyWith<_SubscriptionOption> get copyWith => __$SubscriptionOptionCopyWithImpl<_SubscriptionOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionOption&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.title, title) || other.title == title)&&(identical(other.localizedPrice, localizedPrice) || other.localizedPrice == localizedPrice)&&(identical(other.annual, annual) || other.annual == annual)&&(identical(other.localizedMonthlyEquivalent, localizedMonthlyEquivalent) || other.localizedMonthlyEquivalent == localizedMonthlyEquivalent)&&(identical(other.packageIdentifier, packageIdentifier) || other.packageIdentifier == packageIdentifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,title,localizedPrice,annual,localizedMonthlyEquivalent,packageIdentifier);

@override
String toString() {
  return 'SubscriptionOption(productId: $productId, title: $title, localizedPrice: $localizedPrice, annual: $annual, localizedMonthlyEquivalent: $localizedMonthlyEquivalent, packageIdentifier: $packageIdentifier)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionOptionCopyWith<$Res> implements $SubscriptionOptionCopyWith<$Res> {
  factory _$SubscriptionOptionCopyWith(_SubscriptionOption value, $Res Function(_SubscriptionOption) _then) = __$SubscriptionOptionCopyWithImpl;
@override @useResult
$Res call({
 String productId, String title, String localizedPrice, bool annual, String? localizedMonthlyEquivalent, String? packageIdentifier
});




}
/// @nodoc
class __$SubscriptionOptionCopyWithImpl<$Res>
    implements _$SubscriptionOptionCopyWith<$Res> {
  __$SubscriptionOptionCopyWithImpl(this._self, this._then);

  final _SubscriptionOption _self;
  final $Res Function(_SubscriptionOption) _then;

/// Create a copy of SubscriptionOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? title = null,Object? localizedPrice = null,Object? annual = null,Object? localizedMonthlyEquivalent = freezed,Object? packageIdentifier = freezed,}) {
  return _then(_SubscriptionOption(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,localizedPrice: null == localizedPrice ? _self.localizedPrice : localizedPrice // ignore: cast_nullable_to_non_nullable
as String,annual: null == annual ? _self.annual : annual // ignore: cast_nullable_to_non_nullable
as bool,localizedMonthlyEquivalent: freezed == localizedMonthlyEquivalent ? _self.localizedMonthlyEquivalent : localizedMonthlyEquivalent // ignore: cast_nullable_to_non_nullable
as String?,packageIdentifier: freezed == packageIdentifier ? _self.packageIdentifier : packageIdentifier // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubscriptionStatus {

 SubscriptionTier get tier; int get remainingMinutes; int get totalMinutes; List<SubscriptionOption> get options; bool get offeringsLoaded;
/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionStatusCopyWith<SubscriptionStatus> get copyWith => _$SubscriptionStatusCopyWithImpl<SubscriptionStatus>(this as SubscriptionStatus, _$identity);

  /// Serializes this SubscriptionStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionStatus&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.remainingMinutes, remainingMinutes) || other.remainingMinutes == remainingMinutes)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.offeringsLoaded, offeringsLoaded) || other.offeringsLoaded == offeringsLoaded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,remainingMinutes,totalMinutes,const DeepCollectionEquality().hash(options),offeringsLoaded);

@override
String toString() {
  return 'SubscriptionStatus(tier: $tier, remainingMinutes: $remainingMinutes, totalMinutes: $totalMinutes, options: $options, offeringsLoaded: $offeringsLoaded)';
}


}

/// @nodoc
abstract mixin class $SubscriptionStatusCopyWith<$Res>  {
  factory $SubscriptionStatusCopyWith(SubscriptionStatus value, $Res Function(SubscriptionStatus) _then) = _$SubscriptionStatusCopyWithImpl;
@useResult
$Res call({
 SubscriptionTier tier, int remainingMinutes, int totalMinutes, List<SubscriptionOption> options, bool offeringsLoaded
});




}
/// @nodoc
class _$SubscriptionStatusCopyWithImpl<$Res>
    implements $SubscriptionStatusCopyWith<$Res> {
  _$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final SubscriptionStatus _self;
  final $Res Function(SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? remainingMinutes = null,Object? totalMinutes = null,Object? options = null,Object? offeringsLoaded = null,}) {
  return _then(_self.copyWith(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as SubscriptionTier,remainingMinutes: null == remainingMinutes ? _self.remainingMinutes : remainingMinutes // ignore: cast_nullable_to_non_nullable
as int,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<SubscriptionOption>,offeringsLoaded: null == offeringsLoaded ? _self.offeringsLoaded : offeringsLoaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionStatus].
extension SubscriptionStatusPatterns on SubscriptionStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionStatus value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubscriptionTier tier,  int remainingMinutes,  int totalMinutes,  List<SubscriptionOption> options,  bool offeringsLoaded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.tier,_that.remainingMinutes,_that.totalMinutes,_that.options,_that.offeringsLoaded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubscriptionTier tier,  int remainingMinutes,  int totalMinutes,  List<SubscriptionOption> options,  bool offeringsLoaded)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus():
return $default(_that.tier,_that.remainingMinutes,_that.totalMinutes,_that.options,_that.offeringsLoaded);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubscriptionTier tier,  int remainingMinutes,  int totalMinutes,  List<SubscriptionOption> options,  bool offeringsLoaded)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.tier,_that.remainingMinutes,_that.totalMinutes,_that.options,_that.offeringsLoaded);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SubscriptionStatus implements SubscriptionStatus {
  const _SubscriptionStatus({required this.tier, required this.remainingMinutes, required this.totalMinutes, final  List<SubscriptionOption> options = const [], this.offeringsLoaded = false}): _options = options;
  factory _SubscriptionStatus.fromJson(Map<String, dynamic> json) => _$SubscriptionStatusFromJson(json);

@override final  SubscriptionTier tier;
@override final  int remainingMinutes;
@override final  int totalMinutes;
 final  List<SubscriptionOption> _options;
@override@JsonKey() List<SubscriptionOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  bool offeringsLoaded;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionStatusCopyWith<_SubscriptionStatus> get copyWith => __$SubscriptionStatusCopyWithImpl<_SubscriptionStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionStatus&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.remainingMinutes, remainingMinutes) || other.remainingMinutes == remainingMinutes)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.offeringsLoaded, offeringsLoaded) || other.offeringsLoaded == offeringsLoaded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,remainingMinutes,totalMinutes,const DeepCollectionEquality().hash(_options),offeringsLoaded);

@override
String toString() {
  return 'SubscriptionStatus(tier: $tier, remainingMinutes: $remainingMinutes, totalMinutes: $totalMinutes, options: $options, offeringsLoaded: $offeringsLoaded)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionStatusCopyWith<$Res> implements $SubscriptionStatusCopyWith<$Res> {
  factory _$SubscriptionStatusCopyWith(_SubscriptionStatus value, $Res Function(_SubscriptionStatus) _then) = __$SubscriptionStatusCopyWithImpl;
@override @useResult
$Res call({
 SubscriptionTier tier, int remainingMinutes, int totalMinutes, List<SubscriptionOption> options, bool offeringsLoaded
});




}
/// @nodoc
class __$SubscriptionStatusCopyWithImpl<$Res>
    implements _$SubscriptionStatusCopyWith<$Res> {
  __$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final _SubscriptionStatus _self;
  final $Res Function(_SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,Object? remainingMinutes = null,Object? totalMinutes = null,Object? options = null,Object? offeringsLoaded = null,}) {
  return _then(_SubscriptionStatus(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as SubscriptionTier,remainingMinutes: null == remainingMinutes ? _self.remainingMinutes : remainingMinutes // ignore: cast_nullable_to_non_nullable
as int,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<SubscriptionOption>,offeringsLoaded: null == offeringsLoaded ? _self.offeringsLoaded : offeringsLoaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
