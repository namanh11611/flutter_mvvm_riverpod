// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'welcome_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WelcomeState _$WelcomeStateFromJson(Map<String, dynamic> json) {
  return _WelcomeState.fromJson(json);
}

/// @nodoc
mixin _$WelcomeState {
  @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
  AuthResponse? get authResponse => throw _privateConstructorUsedError;
  bool get isRegisterSuccessfully => throw _privateConstructorUsedError;
  bool get isLoginSuccessfully => throw _privateConstructorUsedError;

  /// Serializes this WelcomeState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WelcomeStateCopyWith<WelcomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomeStateCopyWith<$Res> {
  factory $WelcomeStateCopyWith(
          WelcomeState value, $Res Function(WelcomeState) then) =
      _$WelcomeStateCopyWithImpl<$Res, WelcomeState>;
  @useResult
  $Res call(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      AuthResponse? authResponse,
      bool isRegisterSuccessfully,
      bool isLoginSuccessfully});
}

/// @nodoc
class _$WelcomeStateCopyWithImpl<$Res, $Val extends WelcomeState>
    implements $WelcomeStateCopyWith<$Res> {
  _$WelcomeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authResponse = freezed,
    Object? isRegisterSuccessfully = null,
    Object? isLoginSuccessfully = null,
  }) {
    return _then(_value.copyWith(
      authResponse: freezed == authResponse
          ? _value.authResponse
          : authResponse // ignore: cast_nullable_to_non_nullable
              as AuthResponse?,
      isRegisterSuccessfully: null == isRegisterSuccessfully
          ? _value.isRegisterSuccessfully
          : isRegisterSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoginSuccessfully: null == isLoginSuccessfully
          ? _value.isLoginSuccessfully
          : isLoginSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WelcomeStateImplCopyWith<$Res>
    implements $WelcomeStateCopyWith<$Res> {
  factory _$$WelcomeStateImplCopyWith(
          _$WelcomeStateImpl value, $Res Function(_$WelcomeStateImpl) then) =
      __$$WelcomeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      AuthResponse? authResponse,
      bool isRegisterSuccessfully,
      bool isLoginSuccessfully});
}

/// @nodoc
class __$$WelcomeStateImplCopyWithImpl<$Res>
    extends _$WelcomeStateCopyWithImpl<$Res, _$WelcomeStateImpl>
    implements _$$WelcomeStateImplCopyWith<$Res> {
  __$$WelcomeStateImplCopyWithImpl(
      _$WelcomeStateImpl _value, $Res Function(_$WelcomeStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authResponse = freezed,
    Object? isRegisterSuccessfully = null,
    Object? isLoginSuccessfully = null,
  }) {
    return _then(_$WelcomeStateImpl(
      authResponse: freezed == authResponse
          ? _value.authResponse
          : authResponse // ignore: cast_nullable_to_non_nullable
              as AuthResponse?,
      isRegisterSuccessfully: null == isRegisterSuccessfully
          ? _value.isRegisterSuccessfully
          : isRegisterSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoginSuccessfully: null == isLoginSuccessfully
          ? _value.isLoginSuccessfully
          : isLoginSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WelcomeStateImpl implements _WelcomeState {
  const _$WelcomeStateImpl(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      this.authResponse,
      this.isRegisterSuccessfully = false,
      this.isLoginSuccessfully = false});

  factory _$WelcomeStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WelcomeStateImplFromJson(json);

  @override
  @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
  final AuthResponse? authResponse;
  @override
  @JsonKey()
  final bool isRegisterSuccessfully;
  @override
  @JsonKey()
  final bool isLoginSuccessfully;

  @override
  String toString() {
    return 'WelcomeState(authResponse: $authResponse, isRegisterSuccessfully: $isRegisterSuccessfully, isLoginSuccessfully: $isLoginSuccessfully)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WelcomeStateImpl &&
            (identical(other.authResponse, authResponse) ||
                other.authResponse == authResponse) &&
            (identical(other.isRegisterSuccessfully, isRegisterSuccessfully) ||
                other.isRegisterSuccessfully == isRegisterSuccessfully) &&
            (identical(other.isLoginSuccessfully, isLoginSuccessfully) ||
                other.isLoginSuccessfully == isLoginSuccessfully));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, authResponse, isRegisterSuccessfully, isLoginSuccessfully);

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WelcomeStateImplCopyWith<_$WelcomeStateImpl> get copyWith =>
      __$$WelcomeStateImplCopyWithImpl<_$WelcomeStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WelcomeStateImplToJson(
      this,
    );
  }
}

abstract class _WelcomeState implements WelcomeState {
  const factory _WelcomeState(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      final AuthResponse? authResponse,
      final bool isRegisterSuccessfully,
      final bool isLoginSuccessfully}) = _$WelcomeStateImpl;

  factory _WelcomeState.fromJson(Map<String, dynamic> json) =
      _$WelcomeStateImpl.fromJson;

  @override
  @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
  AuthResponse? get authResponse;
  @override
  bool get isRegisterSuccessfully;
  @override
  bool get isLoginSuccessfully;

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WelcomeStateImplCopyWith<_$WelcomeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
