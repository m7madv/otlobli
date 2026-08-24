// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'brief_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BriefActionItem {

 String get title; String? get owner; String? get dueDateIso; String? get originalDatePhrase; double get confidence;
/// Create a copy of BriefActionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefActionItemCopyWith<BriefActionItem> get copyWith => _$BriefActionItemCopyWithImpl<BriefActionItem>(this as BriefActionItem, _$identity);

  /// Serializes this BriefActionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefActionItem&&(identical(other.title, title) || other.title == title)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.dueDateIso, dueDateIso) || other.dueDateIso == dueDateIso)&&(identical(other.originalDatePhrase, originalDatePhrase) || other.originalDatePhrase == originalDatePhrase)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,owner,dueDateIso,originalDatePhrase,confidence);

@override
String toString() {
  return 'BriefActionItem(title: $title, owner: $owner, dueDateIso: $dueDateIso, originalDatePhrase: $originalDatePhrase, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $BriefActionItemCopyWith<$Res>  {
  factory $BriefActionItemCopyWith(BriefActionItem value, $Res Function(BriefActionItem) _then) = _$BriefActionItemCopyWithImpl;
@useResult
$Res call({
 String title, String? owner, String? dueDateIso, String? originalDatePhrase, double confidence
});




}
/// @nodoc
class _$BriefActionItemCopyWithImpl<$Res>
    implements $BriefActionItemCopyWith<$Res> {
  _$BriefActionItemCopyWithImpl(this._self, this._then);

  final BriefActionItem _self;
  final $Res Function(BriefActionItem) _then;

/// Create a copy of BriefActionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? owner = freezed,Object? dueDateIso = freezed,Object? originalDatePhrase = freezed,Object? confidence = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,dueDateIso: freezed == dueDateIso ? _self.dueDateIso : dueDateIso // ignore: cast_nullable_to_non_nullable
as String?,originalDatePhrase: freezed == originalDatePhrase ? _self.originalDatePhrase : originalDatePhrase // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefActionItem].
extension BriefActionItemPatterns on BriefActionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefActionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefActionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefActionItem value)  $default,){
final _that = this;
switch (_that) {
case _BriefActionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefActionItem value)?  $default,){
final _that = this;
switch (_that) {
case _BriefActionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? owner,  String? dueDateIso,  String? originalDatePhrase,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefActionItem() when $default != null:
return $default(_that.title,_that.owner,_that.dueDateIso,_that.originalDatePhrase,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? owner,  String? dueDateIso,  String? originalDatePhrase,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _BriefActionItem():
return $default(_that.title,_that.owner,_that.dueDateIso,_that.originalDatePhrase,_that.confidence);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? owner,  String? dueDateIso,  String? originalDatePhrase,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _BriefActionItem() when $default != null:
return $default(_that.title,_that.owner,_that.dueDateIso,_that.originalDatePhrase,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefActionItem implements BriefActionItem {
  const _BriefActionItem({required this.title, this.owner, this.dueDateIso, this.originalDatePhrase, this.confidence = 0});
  factory _BriefActionItem.fromJson(Map<String, dynamic> json) => _$BriefActionItemFromJson(json);

@override final  String title;
@override final  String? owner;
@override final  String? dueDateIso;
@override final  String? originalDatePhrase;
@override@JsonKey() final  double confidence;

/// Create a copy of BriefActionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefActionItemCopyWith<_BriefActionItem> get copyWith => __$BriefActionItemCopyWithImpl<_BriefActionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefActionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefActionItem&&(identical(other.title, title) || other.title == title)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.dueDateIso, dueDateIso) || other.dueDateIso == dueDateIso)&&(identical(other.originalDatePhrase, originalDatePhrase) || other.originalDatePhrase == originalDatePhrase)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,owner,dueDateIso,originalDatePhrase,confidence);

@override
String toString() {
  return 'BriefActionItem(title: $title, owner: $owner, dueDateIso: $dueDateIso, originalDatePhrase: $originalDatePhrase, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$BriefActionItemCopyWith<$Res> implements $BriefActionItemCopyWith<$Res> {
  factory _$BriefActionItemCopyWith(_BriefActionItem value, $Res Function(_BriefActionItem) _then) = __$BriefActionItemCopyWithImpl;
@override @useResult
$Res call({
 String title, String? owner, String? dueDateIso, String? originalDatePhrase, double confidence
});




}
/// @nodoc
class __$BriefActionItemCopyWithImpl<$Res>
    implements _$BriefActionItemCopyWith<$Res> {
  __$BriefActionItemCopyWithImpl(this._self, this._then);

  final _BriefActionItem _self;
  final $Res Function(_BriefActionItem) _then;

/// Create a copy of BriefActionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? owner = freezed,Object? dueDateIso = freezed,Object? originalDatePhrase = freezed,Object? confidence = null,}) {
  return _then(_BriefActionItem(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,dueDateIso: freezed == dueDateIso ? _self.dueDateIso : dueDateIso // ignore: cast_nullable_to_non_nullable
as String?,originalDatePhrase: freezed == originalDatePhrase ? _self.originalDatePhrase : originalDatePhrase // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$BriefImportantDate {

 String get label; String? get dateIso; String get originalPhrase; double get confidence; bool get requiresConfirmation;
/// Create a copy of BriefImportantDate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefImportantDateCopyWith<BriefImportantDate> get copyWith => _$BriefImportantDateCopyWithImpl<BriefImportantDate>(this as BriefImportantDate, _$identity);

  /// Serializes this BriefImportantDate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefImportantDate&&(identical(other.label, label) || other.label == label)&&(identical(other.dateIso, dateIso) || other.dateIso == dateIso)&&(identical(other.originalPhrase, originalPhrase) || other.originalPhrase == originalPhrase)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.requiresConfirmation, requiresConfirmation) || other.requiresConfirmation == requiresConfirmation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,dateIso,originalPhrase,confidence,requiresConfirmation);

@override
String toString() {
  return 'BriefImportantDate(label: $label, dateIso: $dateIso, originalPhrase: $originalPhrase, confidence: $confidence, requiresConfirmation: $requiresConfirmation)';
}


}

/// @nodoc
abstract mixin class $BriefImportantDateCopyWith<$Res>  {
  factory $BriefImportantDateCopyWith(BriefImportantDate value, $Res Function(BriefImportantDate) _then) = _$BriefImportantDateCopyWithImpl;
@useResult
$Res call({
 String label, String? dateIso, String originalPhrase, double confidence, bool requiresConfirmation
});




}
/// @nodoc
class _$BriefImportantDateCopyWithImpl<$Res>
    implements $BriefImportantDateCopyWith<$Res> {
  _$BriefImportantDateCopyWithImpl(this._self, this._then);

  final BriefImportantDate _self;
  final $Res Function(BriefImportantDate) _then;

/// Create a copy of BriefImportantDate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? dateIso = freezed,Object? originalPhrase = null,Object? confidence = null,Object? requiresConfirmation = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,dateIso: freezed == dateIso ? _self.dateIso : dateIso // ignore: cast_nullable_to_non_nullable
as String?,originalPhrase: null == originalPhrase ? _self.originalPhrase : originalPhrase // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,requiresConfirmation: null == requiresConfirmation ? _self.requiresConfirmation : requiresConfirmation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefImportantDate].
extension BriefImportantDatePatterns on BriefImportantDate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefImportantDate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefImportantDate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefImportantDate value)  $default,){
final _that = this;
switch (_that) {
case _BriefImportantDate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefImportantDate value)?  $default,){
final _that = this;
switch (_that) {
case _BriefImportantDate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String? dateIso,  String originalPhrase,  double confidence,  bool requiresConfirmation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefImportantDate() when $default != null:
return $default(_that.label,_that.dateIso,_that.originalPhrase,_that.confidence,_that.requiresConfirmation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String? dateIso,  String originalPhrase,  double confidence,  bool requiresConfirmation)  $default,) {final _that = this;
switch (_that) {
case _BriefImportantDate():
return $default(_that.label,_that.dateIso,_that.originalPhrase,_that.confidence,_that.requiresConfirmation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String? dateIso,  String originalPhrase,  double confidence,  bool requiresConfirmation)?  $default,) {final _that = this;
switch (_that) {
case _BriefImportantDate() when $default != null:
return $default(_that.label,_that.dateIso,_that.originalPhrase,_that.confidence,_that.requiresConfirmation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefImportantDate implements BriefImportantDate {
  const _BriefImportantDate({required this.label, this.dateIso, required this.originalPhrase, this.confidence = 0, this.requiresConfirmation = true});
  factory _BriefImportantDate.fromJson(Map<String, dynamic> json) => _$BriefImportantDateFromJson(json);

@override final  String label;
@override final  String? dateIso;
@override final  String originalPhrase;
@override@JsonKey() final  double confidence;
@override@JsonKey() final  bool requiresConfirmation;

/// Create a copy of BriefImportantDate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefImportantDateCopyWith<_BriefImportantDate> get copyWith => __$BriefImportantDateCopyWithImpl<_BriefImportantDate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefImportantDateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefImportantDate&&(identical(other.label, label) || other.label == label)&&(identical(other.dateIso, dateIso) || other.dateIso == dateIso)&&(identical(other.originalPhrase, originalPhrase) || other.originalPhrase == originalPhrase)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.requiresConfirmation, requiresConfirmation) || other.requiresConfirmation == requiresConfirmation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,dateIso,originalPhrase,confidence,requiresConfirmation);

@override
String toString() {
  return 'BriefImportantDate(label: $label, dateIso: $dateIso, originalPhrase: $originalPhrase, confidence: $confidence, requiresConfirmation: $requiresConfirmation)';
}


}

/// @nodoc
abstract mixin class _$BriefImportantDateCopyWith<$Res> implements $BriefImportantDateCopyWith<$Res> {
  factory _$BriefImportantDateCopyWith(_BriefImportantDate value, $Res Function(_BriefImportantDate) _then) = __$BriefImportantDateCopyWithImpl;
@override @useResult
$Res call({
 String label, String? dateIso, String originalPhrase, double confidence, bool requiresConfirmation
});




}
/// @nodoc
class __$BriefImportantDateCopyWithImpl<$Res>
    implements _$BriefImportantDateCopyWith<$Res> {
  __$BriefImportantDateCopyWithImpl(this._self, this._then);

  final _BriefImportantDate _self;
  final $Res Function(_BriefImportantDate) _then;

/// Create a copy of BriefImportantDate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? dateIso = freezed,Object? originalPhrase = null,Object? confidence = null,Object? requiresConfirmation = null,}) {
  return _then(_BriefImportantDate(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,dateIso: freezed == dateIso ? _self.dateIso : dateIso // ignore: cast_nullable_to_non_nullable
as String?,originalPhrase: null == originalPhrase ? _self.originalPhrase : originalPhrase // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,requiresConfirmation: null == requiresConfirmation ? _self.requiresConfirmation : requiresConfirmation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SuggestedReplies {

 String get short; String get friendly; String get professional;
/// Create a copy of SuggestedReplies
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuggestedRepliesCopyWith<SuggestedReplies> get copyWith => _$SuggestedRepliesCopyWithImpl<SuggestedReplies>(this as SuggestedReplies, _$identity);

  /// Serializes this SuggestedReplies to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SuggestedReplies&&(identical(other.short, short) || other.short == short)&&(identical(other.friendly, friendly) || other.friendly == friendly)&&(identical(other.professional, professional) || other.professional == professional));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,short,friendly,professional);

@override
String toString() {
  return 'SuggestedReplies(short: $short, friendly: $friendly, professional: $professional)';
}


}

/// @nodoc
abstract mixin class $SuggestedRepliesCopyWith<$Res>  {
  factory $SuggestedRepliesCopyWith(SuggestedReplies value, $Res Function(SuggestedReplies) _then) = _$SuggestedRepliesCopyWithImpl;
@useResult
$Res call({
 String short, String friendly, String professional
});




}
/// @nodoc
class _$SuggestedRepliesCopyWithImpl<$Res>
    implements $SuggestedRepliesCopyWith<$Res> {
  _$SuggestedRepliesCopyWithImpl(this._self, this._then);

  final SuggestedReplies _self;
  final $Res Function(SuggestedReplies) _then;

/// Create a copy of SuggestedReplies
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? short = null,Object? friendly = null,Object? professional = null,}) {
  return _then(_self.copyWith(
short: null == short ? _self.short : short // ignore: cast_nullable_to_non_nullable
as String,friendly: null == friendly ? _self.friendly : friendly // ignore: cast_nullable_to_non_nullable
as String,professional: null == professional ? _self.professional : professional // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SuggestedReplies].
extension SuggestedRepliesPatterns on SuggestedReplies {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SuggestedReplies value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SuggestedReplies() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SuggestedReplies value)  $default,){
final _that = this;
switch (_that) {
case _SuggestedReplies():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SuggestedReplies value)?  $default,){
final _that = this;
switch (_that) {
case _SuggestedReplies() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String short,  String friendly,  String professional)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SuggestedReplies() when $default != null:
return $default(_that.short,_that.friendly,_that.professional);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String short,  String friendly,  String professional)  $default,) {final _that = this;
switch (_that) {
case _SuggestedReplies():
return $default(_that.short,_that.friendly,_that.professional);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String short,  String friendly,  String professional)?  $default,) {final _that = this;
switch (_that) {
case _SuggestedReplies() when $default != null:
return $default(_that.short,_that.friendly,_that.professional);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SuggestedReplies implements SuggestedReplies {
  const _SuggestedReplies({required this.short, required this.friendly, required this.professional});
  factory _SuggestedReplies.fromJson(Map<String, dynamic> json) => _$SuggestedRepliesFromJson(json);

@override final  String short;
@override final  String friendly;
@override final  String professional;

/// Create a copy of SuggestedReplies
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuggestedRepliesCopyWith<_SuggestedReplies> get copyWith => __$SuggestedRepliesCopyWithImpl<_SuggestedReplies>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SuggestedRepliesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuggestedReplies&&(identical(other.short, short) || other.short == short)&&(identical(other.friendly, friendly) || other.friendly == friendly)&&(identical(other.professional, professional) || other.professional == professional));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,short,friendly,professional);

@override
String toString() {
  return 'SuggestedReplies(short: $short, friendly: $friendly, professional: $professional)';
}


}

/// @nodoc
abstract mixin class _$SuggestedRepliesCopyWith<$Res> implements $SuggestedRepliesCopyWith<$Res> {
  factory _$SuggestedRepliesCopyWith(_SuggestedReplies value, $Res Function(_SuggestedReplies) _then) = __$SuggestedRepliesCopyWithImpl;
@override @useResult
$Res call({
 String short, String friendly, String professional
});




}
/// @nodoc
class __$SuggestedRepliesCopyWithImpl<$Res>
    implements _$SuggestedRepliesCopyWith<$Res> {
  __$SuggestedRepliesCopyWithImpl(this._self, this._then);

  final _SuggestedReplies _self;
  final $Res Function(_SuggestedReplies) _then;

/// Create a copy of SuggestedReplies
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? short = null,Object? friendly = null,Object? professional = null,}) {
  return _then(_SuggestedReplies(
short: null == short ? _self.short : short // ignore: cast_nullable_to_non_nullable
as String,friendly: null == friendly ? _self.friendly : friendly // ignore: cast_nullable_to_non_nullable
as String,professional: null == professional ? _self.professional : professional // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BriefResult {

 String get id; String get detectedLanguage; String get title; String get transcript; String get summary; List<String> get keyPoints; List<BriefActionItem> get actionItems; List<BriefImportantDate> get importantDates; SuggestedReplies get suggestedReplies; int get audioDurationSeconds; DateTime get processedAt; bool get savedLocally;
/// Create a copy of BriefResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefResultCopyWith<BriefResult> get copyWith => _$BriefResultCopyWithImpl<BriefResult>(this as BriefResult, _$identity);

  /// Serializes this BriefResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefResult&&(identical(other.id, id) || other.id == id)&&(identical(other.detectedLanguage, detectedLanguage) || other.detectedLanguage == detectedLanguage)&&(identical(other.title, title) || other.title == title)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.keyPoints, keyPoints)&&const DeepCollectionEquality().equals(other.actionItems, actionItems)&&const DeepCollectionEquality().equals(other.importantDates, importantDates)&&(identical(other.suggestedReplies, suggestedReplies) || other.suggestedReplies == suggestedReplies)&&(identical(other.audioDurationSeconds, audioDurationSeconds) || other.audioDurationSeconds == audioDurationSeconds)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.savedLocally, savedLocally) || other.savedLocally == savedLocally));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,detectedLanguage,title,transcript,summary,const DeepCollectionEquality().hash(keyPoints),const DeepCollectionEquality().hash(actionItems),const DeepCollectionEquality().hash(importantDates),suggestedReplies,audioDurationSeconds,processedAt,savedLocally);

@override
String toString() {
  return 'BriefResult(id: $id, detectedLanguage: $detectedLanguage, title: $title, transcript: $transcript, summary: $summary, keyPoints: $keyPoints, actionItems: $actionItems, importantDates: $importantDates, suggestedReplies: $suggestedReplies, audioDurationSeconds: $audioDurationSeconds, processedAt: $processedAt, savedLocally: $savedLocally)';
}


}

/// @nodoc
abstract mixin class $BriefResultCopyWith<$Res>  {
  factory $BriefResultCopyWith(BriefResult value, $Res Function(BriefResult) _then) = _$BriefResultCopyWithImpl;
@useResult
$Res call({
 String id, String detectedLanguage, String title, String transcript, String summary, List<String> keyPoints, List<BriefActionItem> actionItems, List<BriefImportantDate> importantDates, SuggestedReplies suggestedReplies, int audioDurationSeconds, DateTime processedAt, bool savedLocally
});


$SuggestedRepliesCopyWith<$Res> get suggestedReplies;

}
/// @nodoc
class _$BriefResultCopyWithImpl<$Res>
    implements $BriefResultCopyWith<$Res> {
  _$BriefResultCopyWithImpl(this._self, this._then);

  final BriefResult _self;
  final $Res Function(BriefResult) _then;

/// Create a copy of BriefResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? detectedLanguage = null,Object? title = null,Object? transcript = null,Object? summary = null,Object? keyPoints = null,Object? actionItems = null,Object? importantDates = null,Object? suggestedReplies = null,Object? audioDurationSeconds = null,Object? processedAt = null,Object? savedLocally = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,detectedLanguage: null == detectedLanguage ? _self.detectedLanguage : detectedLanguage // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,keyPoints: null == keyPoints ? _self.keyPoints : keyPoints // ignore: cast_nullable_to_non_nullable
as List<String>,actionItems: null == actionItems ? _self.actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as List<BriefActionItem>,importantDates: null == importantDates ? _self.importantDates : importantDates // ignore: cast_nullable_to_non_nullable
as List<BriefImportantDate>,suggestedReplies: null == suggestedReplies ? _self.suggestedReplies : suggestedReplies // ignore: cast_nullable_to_non_nullable
as SuggestedReplies,audioDurationSeconds: null == audioDurationSeconds ? _self.audioDurationSeconds : audioDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,processedAt: null == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime,savedLocally: null == savedLocally ? _self.savedLocally : savedLocally // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BriefResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SuggestedRepliesCopyWith<$Res> get suggestedReplies {

  return $SuggestedRepliesCopyWith<$Res>(_self.suggestedReplies, (value) {
    return _then(_self.copyWith(suggestedReplies: value));
  });
}
}


/// Adds pattern-matching-related methods to [BriefResult].
extension BriefResultPatterns on BriefResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefResult value)  $default,){
final _that = this;
switch (_that) {
case _BriefResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefResult value)?  $default,){
final _that = this;
switch (_that) {
case _BriefResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String detectedLanguage,  String title,  String transcript,  String summary,  List<String> keyPoints,  List<BriefActionItem> actionItems,  List<BriefImportantDate> importantDates,  SuggestedReplies suggestedReplies,  int audioDurationSeconds,  DateTime processedAt,  bool savedLocally)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefResult() when $default != null:
return $default(_that.id,_that.detectedLanguage,_that.title,_that.transcript,_that.summary,_that.keyPoints,_that.actionItems,_that.importantDates,_that.suggestedReplies,_that.audioDurationSeconds,_that.processedAt,_that.savedLocally);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String detectedLanguage,  String title,  String transcript,  String summary,  List<String> keyPoints,  List<BriefActionItem> actionItems,  List<BriefImportantDate> importantDates,  SuggestedReplies suggestedReplies,  int audioDurationSeconds,  DateTime processedAt,  bool savedLocally)  $default,) {final _that = this;
switch (_that) {
case _BriefResult():
return $default(_that.id,_that.detectedLanguage,_that.title,_that.transcript,_that.summary,_that.keyPoints,_that.actionItems,_that.importantDates,_that.suggestedReplies,_that.audioDurationSeconds,_that.processedAt,_that.savedLocally);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String detectedLanguage,  String title,  String transcript,  String summary,  List<String> keyPoints,  List<BriefActionItem> actionItems,  List<BriefImportantDate> importantDates,  SuggestedReplies suggestedReplies,  int audioDurationSeconds,  DateTime processedAt,  bool savedLocally)?  $default,) {final _that = this;
switch (_that) {
case _BriefResult() when $default != null:
return $default(_that.id,_that.detectedLanguage,_that.title,_that.transcript,_that.summary,_that.keyPoints,_that.actionItems,_that.importantDates,_that.suggestedReplies,_that.audioDurationSeconds,_that.processedAt,_that.savedLocally);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _BriefResult implements BriefResult {
  const _BriefResult({required this.id, required this.detectedLanguage, required this.title, required this.transcript, required this.summary, required final  List<String> keyPoints, required final  List<BriefActionItem> actionItems, required final  List<BriefImportantDate> importantDates, required this.suggestedReplies, required this.audioDurationSeconds, required this.processedAt, this.savedLocally = false}): _keyPoints = keyPoints,_actionItems = actionItems,_importantDates = importantDates;
  factory _BriefResult.fromJson(Map<String, dynamic> json) => _$BriefResultFromJson(json);

@override final  String id;
@override final  String detectedLanguage;
@override final  String title;
@override final  String transcript;
@override final  String summary;
 final  List<String> _keyPoints;
@override List<String> get keyPoints {
  if (_keyPoints is EqualUnmodifiableListView) return _keyPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyPoints);
}

 final  List<BriefActionItem> _actionItems;
@override List<BriefActionItem> get actionItems {
  if (_actionItems is EqualUnmodifiableListView) return _actionItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actionItems);
}

 final  List<BriefImportantDate> _importantDates;
@override List<BriefImportantDate> get importantDates {
  if (_importantDates is EqualUnmodifiableListView) return _importantDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_importantDates);
}

@override final  SuggestedReplies suggestedReplies;
@override final  int audioDurationSeconds;
@override final  DateTime processedAt;
@override@JsonKey() final  bool savedLocally;

/// Create a copy of BriefResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefResultCopyWith<_BriefResult> get copyWith => __$BriefResultCopyWithImpl<_BriefResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefResult&&(identical(other.id, id) || other.id == id)&&(identical(other.detectedLanguage, detectedLanguage) || other.detectedLanguage == detectedLanguage)&&(identical(other.title, title) || other.title == title)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._keyPoints, _keyPoints)&&const DeepCollectionEquality().equals(other._actionItems, _actionItems)&&const DeepCollectionEquality().equals(other._importantDates, _importantDates)&&(identical(other.suggestedReplies, suggestedReplies) || other.suggestedReplies == suggestedReplies)&&(identical(other.audioDurationSeconds, audioDurationSeconds) || other.audioDurationSeconds == audioDurationSeconds)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.savedLocally, savedLocally) || other.savedLocally == savedLocally));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,detectedLanguage,title,transcript,summary,const DeepCollectionEquality().hash(_keyPoints),const DeepCollectionEquality().hash(_actionItems),const DeepCollectionEquality().hash(_importantDates),suggestedReplies,audioDurationSeconds,processedAt,savedLocally);

@override
String toString() {
  return 'BriefResult(id: $id, detectedLanguage: $detectedLanguage, title: $title, transcript: $transcript, summary: $summary, keyPoints: $keyPoints, actionItems: $actionItems, importantDates: $importantDates, suggestedReplies: $suggestedReplies, audioDurationSeconds: $audioDurationSeconds, processedAt: $processedAt, savedLocally: $savedLocally)';
}


}

/// @nodoc
abstract mixin class _$BriefResultCopyWith<$Res> implements $BriefResultCopyWith<$Res> {
  factory _$BriefResultCopyWith(_BriefResult value, $Res Function(_BriefResult) _then) = __$BriefResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String detectedLanguage, String title, String transcript, String summary, List<String> keyPoints, List<BriefActionItem> actionItems, List<BriefImportantDate> importantDates, SuggestedReplies suggestedReplies, int audioDurationSeconds, DateTime processedAt, bool savedLocally
});


@override $SuggestedRepliesCopyWith<$Res> get suggestedReplies;

}
/// @nodoc
class __$BriefResultCopyWithImpl<$Res>
    implements _$BriefResultCopyWith<$Res> {
  __$BriefResultCopyWithImpl(this._self, this._then);

  final _BriefResult _self;
  final $Res Function(_BriefResult) _then;

/// Create a copy of BriefResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? detectedLanguage = null,Object? title = null,Object? transcript = null,Object? summary = null,Object? keyPoints = null,Object? actionItems = null,Object? importantDates = null,Object? suggestedReplies = null,Object? audioDurationSeconds = null,Object? processedAt = null,Object? savedLocally = null,}) {
  return _then(_BriefResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,detectedLanguage: null == detectedLanguage ? _self.detectedLanguage : detectedLanguage // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,keyPoints: null == keyPoints ? _self._keyPoints : keyPoints // ignore: cast_nullable_to_non_nullable
as List<String>,actionItems: null == actionItems ? _self._actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as List<BriefActionItem>,importantDates: null == importantDates ? _self._importantDates : importantDates // ignore: cast_nullable_to_non_nullable
as List<BriefImportantDate>,suggestedReplies: null == suggestedReplies ? _self.suggestedReplies : suggestedReplies // ignore: cast_nullable_to_non_nullable
as SuggestedReplies,audioDurationSeconds: null == audioDurationSeconds ? _self.audioDurationSeconds : audioDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,processedAt: null == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime,savedLocally: null == savedLocally ? _self.savedLocally : savedLocally // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BriefResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SuggestedRepliesCopyWith<$Res> get suggestedReplies {

  return $SuggestedRepliesCopyWith<$Res>(_self.suggestedReplies, (value) {
    return _then(_self.copyWith(suggestedReplies: value));
  });
}
}

// dart format on
