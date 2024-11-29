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
  bool get isRegisterSuccessfully => throw _privateConstructorUsedError;
  bool get isLoginWithGoogleSuccessfully => throw _privateConstructorUsedError;
  bool get isLoginWithAppleSuccessfully => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      {bool isRegisterSuccessfully,
      bool isLoginWithGoogleSuccessfully,
      bool isLoginWithAppleSuccessfully});
}

/// @nodoc
class _$WelcomeStateCopyWithImpl<$Res, $Val extends WelcomeState>
    implements $WelcomeStateCopyWith<$Res> {
  _$WelcomeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRegisterSuccessfully = null,
    Object? isLoginWithGoogleSuccessfully = null,
    Object? isLoginWithAppleSuccessfully = null,
  }) {
    return _then(_value.copyWith(
      isRegisterSuccessfully: null == isRegisterSuccessfully
          ? _value.isRegisterSuccessfully
          : isRegisterSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoginWithGoogleSuccessfully: null == isLoginWithGoogleSuccessfully
          ? _value.isLoginWithGoogleSuccessfully
          : isLoginWithGoogleSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoginWithAppleSuccessfully: null == isLoginWithAppleSuccessfully
          ? _value.isLoginWithAppleSuccessfully
          : isLoginWithAppleSuccessfully // ignore: cast_nullable_to_non_nullable
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
      {bool isRegisterSuccessfully,
      bool isLoginWithGoogleSuccessfully,
      bool isLoginWithAppleSuccessfully});
}

/// @nodoc
class __$$WelcomeStateImplCopyWithImpl<$Res>
    extends _$WelcomeStateCopyWithImpl<$Res, _$WelcomeStateImpl>
    implements _$$WelcomeStateImplCopyWith<$Res> {
  __$$WelcomeStateImplCopyWithImpl(
      _$WelcomeStateImpl _value, $Res Function(_$WelcomeStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRegisterSuccessfully = null,
    Object? isLoginWithGoogleSuccessfully = null,
    Object? isLoginWithAppleSuccessfully = null,
  }) {
    return _then(_$WelcomeStateImpl(
      isRegisterSuccessfully: null == isRegisterSuccessfully
          ? _value.isRegisterSuccessfully
          : isRegisterSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoginWithGoogleSuccessfully: null == isLoginWithGoogleSuccessfully
          ? _value.isLoginWithGoogleSuccessfully
          : isLoginWithGoogleSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoginWithAppleSuccessfully: null == isLoginWithAppleSuccessfully
          ? _value.isLoginWithAppleSuccessfully
          : isLoginWithAppleSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WelcomeStateImpl implements _WelcomeState {
  const _$WelcomeStateImpl(
      {this.isRegisterSuccessfully = false,
      this.isLoginWithGoogleSuccessfully = false,
      this.isLoginWithAppleSuccessfully = false});

  factory _$WelcomeStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WelcomeStateImplFromJson(json);

  @override
  @JsonKey()
  final bool isRegisterSuccessfully;
  @override
  @JsonKey()
  final bool isLoginWithGoogleSuccessfully;
  @override
  @JsonKey()
  final bool isLoginWithAppleSuccessfully;

  @override
  String toString() {
    return 'WelcomeState(isRegisterSuccessfully: $isRegisterSuccessfully, isLoginWithGoogleSuccessfully: $isLoginWithGoogleSuccessfully, isLoginWithAppleSuccessfully: $isLoginWithAppleSuccessfully)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WelcomeStateImpl &&
            (identical(other.isRegisterSuccessfully, isRegisterSuccessfully) ||
                other.isRegisterSuccessfully == isRegisterSuccessfully) &&
            (identical(other.isLoginWithGoogleSuccessfully,
                    isLoginWithGoogleSuccessfully) ||
                other.isLoginWithGoogleSuccessfully ==
                    isLoginWithGoogleSuccessfully) &&
            (identical(other.isLoginWithAppleSuccessfully,
                    isLoginWithAppleSuccessfully) ||
                other.isLoginWithAppleSuccessfully ==
                    isLoginWithAppleSuccessfully));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, isRegisterSuccessfully,
      isLoginWithGoogleSuccessfully, isLoginWithAppleSuccessfully);

  @JsonKey(ignore: true)
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
      {final bool isRegisterSuccessfully,
      final bool isLoginWithGoogleSuccessfully,
      final bool isLoginWithAppleSuccessfully}) = _$WelcomeStateImpl;

  factory _WelcomeState.fromJson(Map<String, dynamic> json) =
      _$WelcomeStateImpl.fromJson;

  @override
  bool get isRegisterSuccessfully;
  @override
  bool get isLoginWithGoogleSuccessfully;
  @override
  bool get isLoginWithAppleSuccessfully;
  @override
  @JsonKey(ignore: true)
  _$$WelcomeStateImplCopyWith<_$WelcomeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
