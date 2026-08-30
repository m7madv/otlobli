// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppState {

 AuthUser? get user; bool get authBusy; ThemeMode get themeMode; int get navigationIndex; SubscriptionStatus get subscription; bool get audioImporting; AudioInput? get selectedAudio; ProcessingOptions get processingOptions; ProcessingStep get processingStep; bool get processing; BriefResult? get activeResult; int get resultNavigationRequest; List<BriefResult> get history; String? get errorMessage;
/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppStateCopyWith<AppState> get copyWith => _$AppStateCopyWithImpl<AppState>(this as AppState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppState&&(identical(other.user, user) || other.user == user)&&(identical(other.authBusy, authBusy) || other.authBusy == authBusy)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.navigationIndex, navigationIndex) || other.navigationIndex == navigationIndex)&&(identical(other.subscription, subscription) || other.subscription == subscription)&&(identical(other.audioImporting, audioImporting) || other.audioImporting == audioImporting)&&(identical(other.selectedAudio, selectedAudio) || other.selectedAudio == selectedAudio)&&(identical(other.processingOptions, processingOptions) || other.processingOptions == processingOptions)&&(identical(other.processingStep, processingStep) || other.processingStep == processingStep)&&(identical(other.processing, processing) || other.processing == processing)&&(identical(other.activeResult, activeResult) || other.activeResult == activeResult)&&(identical(other.resultNavigationRequest, resultNavigationRequest) || other.resultNavigationRequest == resultNavigationRequest)&&const DeepCollectionEquality().equals(other.history, history)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,user,authBusy,themeMode,navigationIndex,subscription,audioImporting,selectedAudio,processingOptions,processingStep,processing,activeResult,resultNavigationRequest,const DeepCollectionEquality().hash(history),errorMessage);

@override
String toString() {
  return 'AppState(user: $user, authBusy: $authBusy, themeMode: $themeMode, navigationIndex: $navigationIndex, subscription: $subscription, audioImporting: $audioImporting, selectedAudio: $selectedAudio, processingOptions: $processingOptions, processingStep: $processingStep, processing: $processing, activeResult: $activeResult, resultNavigationRequest: $resultNavigationRequest, history: $history, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $AppStateCopyWith<$Res>  {
  factory $AppStateCopyWith(AppState value, $Res Function(AppState) _then) = _$AppStateCopyWithImpl;
@useResult
$Res call({
 AuthUser? user, bool authBusy, ThemeMode themeMode, int navigationIndex, SubscriptionStatus subscription, bool audioImporting, AudioInput? selectedAudio, ProcessingOptions processingOptions, ProcessingStep processingStep, bool processing, BriefResult? activeResult, int resultNavigationRequest, List<BriefResult> history, String? errorMessage
});


$AuthUserCopyWith<$Res>? get user;$SubscriptionStatusCopyWith<$Res> get subscription;$AudioInputCopyWith<$Res>? get selectedAudio;$ProcessingOptionsCopyWith<$Res> get processingOptions;$BriefResultCopyWith<$Res>? get activeResult;

}
/// @nodoc
class _$AppStateCopyWithImpl<$Res>
    implements $AppStateCopyWith<$Res> {
  _$AppStateCopyWithImpl(this._self, this._then);

  final AppState _self;
  final $Res Function(AppState) _then;

/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = freezed,Object? authBusy = null,Object? themeMode = null,Object? navigationIndex = null,Object? subscription = null,Object? audioImporting = null,Object? selectedAudio = freezed,Object? processingOptions = null,Object? processingStep = null,Object? processing = null,Object? activeResult = freezed,Object? resultNavigationRequest = null,Object? history = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser?,authBusy: null == authBusy ? _self.authBusy : authBusy // ignore: cast_nullable_to_non_nullable
as bool,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,navigationIndex: null == navigationIndex ? _self.navigationIndex : navigationIndex // ignore: cast_nullable_to_non_nullable
as int,subscription: null == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,audioImporting: null == audioImporting ? _self.audioImporting : audioImporting // ignore: cast_nullable_to_non_nullable
as bool,selectedAudio: freezed == selectedAudio ? _self.selectedAudio : selectedAudio // ignore: cast_nullable_to_non_nullable
as AudioInput?,processingOptions: null == processingOptions ? _self.processingOptions : processingOptions // ignore: cast_nullable_to_non_nullable
as ProcessingOptions,processingStep: null == processingStep ? _self.processingStep : processingStep // ignore: cast_nullable_to_non_nullable
as ProcessingStep,processing: null == processing ? _self.processing : processing // ignore: cast_nullable_to_non_nullable
as bool,activeResult: freezed == activeResult ? _self.activeResult : activeResult // ignore: cast_nullable_to_non_nullable
as BriefResult?,resultNavigationRequest: null == resultNavigationRequest ? _self.resultNavigationRequest : resultNavigationRequest // ignore: cast_nullable_to_non_nullable
as int,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<BriefResult>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionStatusCopyWith<$Res> get subscription {

  return $SubscriptionStatusCopyWith<$Res>(_self.subscription, (value) {
    return _then(_self.copyWith(subscription: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioInputCopyWith<$Res>? get selectedAudio {
    if (_self.selectedAudio == null) {
    return null;
  }

  return $AudioInputCopyWith<$Res>(_self.selectedAudio!, (value) {
    return _then(_self.copyWith(selectedAudio: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProcessingOptionsCopyWith<$Res> get processingOptions {

  return $ProcessingOptionsCopyWith<$Res>(_self.processingOptions, (value) {
    return _then(_self.copyWith(processingOptions: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefResultCopyWith<$Res>? get activeResult {
    if (_self.activeResult == null) {
    return null;
  }

  return $BriefResultCopyWith<$Res>(_self.activeResult!, (value) {
    return _then(_self.copyWith(activeResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppState].
extension AppStatePatterns on AppState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppState value)  $default,){
final _that = this;
switch (_that) {
case _AppState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppState value)?  $default,){
final _that = this;
switch (_that) {
case _AppState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthUser? user,  bool authBusy,  ThemeMode themeMode,  int navigationIndex,  SubscriptionStatus subscription,  bool audioImporting,  AudioInput? selectedAudio,  ProcessingOptions processingOptions,  ProcessingStep processingStep,  bool processing,  BriefResult? activeResult,  int resultNavigationRequest,  List<BriefResult> history,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppState() when $default != null:
return $default(_that.user,_that.authBusy,_that.themeMode,_that.navigationIndex,_that.subscription,_that.audioImporting,_that.selectedAudio,_that.processingOptions,_that.processingStep,_that.processing,_that.activeResult,_that.resultNavigationRequest,_that.history,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthUser? user,  bool authBusy,  ThemeMode themeMode,  int navigationIndex,  SubscriptionStatus subscription,  bool audioImporting,  AudioInput? selectedAudio,  ProcessingOptions processingOptions,  ProcessingStep processingStep,  bool processing,  BriefResult? activeResult,  int resultNavigationRequest,  List<BriefResult> history,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AppState():
return $default(_that.user,_that.authBusy,_that.themeMode,_that.navigationIndex,_that.subscription,_that.audioImporting,_that.selectedAudio,_that.processingOptions,_that.processingStep,_that.processing,_that.activeResult,_that.resultNavigationRequest,_that.history,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthUser? user,  bool authBusy,  ThemeMode themeMode,  int navigationIndex,  SubscriptionStatus subscription,  bool audioImporting,  AudioInput? selectedAudio,  ProcessingOptions processingOptions,  ProcessingStep processingStep,  bool processing,  BriefResult? activeResult,  int resultNavigationRequest,  List<BriefResult> history,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AppState() when $default != null:
return $default(_that.user,_that.authBusy,_that.themeMode,_that.navigationIndex,_that.subscription,_that.audioImporting,_that.selectedAudio,_that.processingOptions,_that.processingStep,_that.processing,_that.activeResult,_that.resultNavigationRequest,_that.history,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AppState implements AppState {
  const _AppState({this.user, this.authBusy = false, this.themeMode = ThemeMode.system, this.navigationIndex = 0, this.subscription = const SubscriptionStatus(tier: SubscriptionTier.free, remainingMinutes: 10, totalMinutes: 10), this.audioImporting = false, this.selectedAudio, this.processingOptions = const ProcessingOptions(), this.processingStep = ProcessingStep.preparing, this.processing = false, this.activeResult, this.resultNavigationRequest = 0, final  List<BriefResult> history = const [], this.errorMessage}): _history = history;


@override final  AuthUser? user;
@override@JsonKey() final  bool authBusy;
@override@JsonKey() final  ThemeMode themeMode;
@override@JsonKey() final  int navigationIndex;
@override@JsonKey() final  SubscriptionStatus subscription;
@override@JsonKey() final  bool audioImporting;
@override final  AudioInput? selectedAudio;
@override@JsonKey() final  ProcessingOptions processingOptions;
@override@JsonKey() final  ProcessingStep processingStep;
@override@JsonKey() final  bool processing;
@override final  BriefResult? activeResult;
@override@JsonKey() final  int resultNavigationRequest;
 final  List<BriefResult> _history;
@override@JsonKey() List<BriefResult> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

@override final  String? errorMessage;

/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppStateCopyWith<_AppState> get copyWith => __$AppStateCopyWithImpl<_AppState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppState&&(identical(other.user, user) || other.user == user)&&(identical(other.authBusy, authBusy) || other.authBusy == authBusy)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.navigationIndex, navigationIndex) || other.navigationIndex == navigationIndex)&&(identical(other.subscription, subscription) || other.subscription == subscription)&&(identical(other.audioImporting, audioImporting) || other.audioImporting == audioImporting)&&(identical(other.selectedAudio, selectedAudio) || other.selectedAudio == selectedAudio)&&(identical(other.processingOptions, processingOptions) || other.processingOptions == processingOptions)&&(identical(other.processingStep, processingStep) || other.processingStep == processingStep)&&(identical(other.processing, processing) || other.processing == processing)&&(identical(other.activeResult, activeResult) || other.activeResult == activeResult)&&(identical(other.resultNavigationRequest, resultNavigationRequest) || other.resultNavigationRequest == resultNavigationRequest)&&const DeepCollectionEquality().equals(other._history, _history)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,user,authBusy,themeMode,navigationIndex,subscription,audioImporting,selectedAudio,processingOptions,processingStep,processing,activeResult,resultNavigationRequest,const DeepCollectionEquality().hash(_history),errorMessage);

@override
String toString() {
  return 'AppState(user: $user, authBusy: $authBusy, themeMode: $themeMode, navigationIndex: $navigationIndex, subscription: $subscription, audioImporting: $audioImporting, selectedAudio: $selectedAudio, processingOptions: $processingOptions, processingStep: $processingStep, processing: $processing, activeResult: $activeResult, resultNavigationRequest: $resultNavigationRequest, history: $history, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AppStateCopyWith<$Res> implements $AppStateCopyWith<$Res> {
  factory _$AppStateCopyWith(_AppState value, $Res Function(_AppState) _then) = __$AppStateCopyWithImpl;
@override @useResult
$Res call({
 AuthUser? user, bool authBusy, ThemeMode themeMode, int navigationIndex, SubscriptionStatus subscription, bool audioImporting, AudioInput? selectedAudio, ProcessingOptions processingOptions, ProcessingStep processingStep, bool processing, BriefResult? activeResult, int resultNavigationRequest, List<BriefResult> history, String? errorMessage
});


@override $AuthUserCopyWith<$Res>? get user;@override $SubscriptionStatusCopyWith<$Res> get subscription;@override $AudioInputCopyWith<$Res>? get selectedAudio;@override $ProcessingOptionsCopyWith<$Res> get processingOptions;@override $BriefResultCopyWith<$Res>? get activeResult;

}
/// @nodoc
class __$AppStateCopyWithImpl<$Res>
    implements _$AppStateCopyWith<$Res> {
  __$AppStateCopyWithImpl(this._self, this._then);

  final _AppState _self;
  final $Res Function(_AppState) _then;

/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = freezed,Object? authBusy = null,Object? themeMode = null,Object? navigationIndex = null,Object? subscription = null,Object? audioImporting = null,Object? selectedAudio = freezed,Object? processingOptions = null,Object? processingStep = null,Object? processing = null,Object? activeResult = freezed,Object? resultNavigationRequest = null,Object? history = null,Object? errorMessage = freezed,}) {
  return _then(_AppState(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser?,authBusy: null == authBusy ? _self.authBusy : authBusy // ignore: cast_nullable_to_non_nullable
as bool,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,navigationIndex: null == navigationIndex ? _self.navigationIndex : navigationIndex // ignore: cast_nullable_to_non_nullable
as int,subscription: null == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,audioImporting: null == audioImporting ? _self.audioImporting : audioImporting // ignore: cast_nullable_to_non_nullable
as bool,selectedAudio: freezed == selectedAudio ? _self.selectedAudio : selectedAudio // ignore: cast_nullable_to_non_nullable
as AudioInput?,processingOptions: null == processingOptions ? _self.processingOptions : processingOptions // ignore: cast_nullable_to_non_nullable
as ProcessingOptions,processingStep: null == processingStep ? _self.processingStep : processingStep // ignore: cast_nullable_to_non_nullable
as ProcessingStep,processing: null == processing ? _self.processing : processing // ignore: cast_nullable_to_non_nullable
as bool,activeResult: freezed == activeResult ? _self.activeResult : activeResult // ignore: cast_nullable_to_non_nullable
as BriefResult?,resultNavigationRequest: null == resultNavigationRequest ? _self.resultNavigationRequest : resultNavigationRequest // ignore: cast_nullable_to_non_nullable
as int,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<BriefResult>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionStatusCopyWith<$Res> get subscription {

  return $SubscriptionStatusCopyWith<$Res>(_self.subscription, (value) {
    return _then(_self.copyWith(subscription: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioInputCopyWith<$Res>? get selectedAudio {
    if (_self.selectedAudio == null) {
    return null;
  }

  return $AudioInputCopyWith<$Res>(_self.selectedAudio!, (value) {
    return _then(_self.copyWith(selectedAudio: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProcessingOptionsCopyWith<$Res> get processingOptions {

  return $ProcessingOptionsCopyWith<$Res>(_self.processingOptions, (value) {
    return _then(_self.copyWith(processingOptions: value));
  });
}/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefResultCopyWith<$Res>? get activeResult {
    if (_self.activeResult == null) {
    return null;
  }

  return $BriefResultCopyWith<$Res>(_self.activeResult!, (value) {
    return _then(_self.copyWith(activeResult: value));
  });
}
}

// dart format on
