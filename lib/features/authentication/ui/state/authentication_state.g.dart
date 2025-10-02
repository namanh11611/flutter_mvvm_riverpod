// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthenticationState _$AuthenticationStateFromJson(Map<String, dynamic> json) =>
    _AuthenticationState(
      authResponse:
          _authResponseFromJson(json['authResponse'] as Map<String, dynamic>?),
      isRegisterSuccessfully: json['isRegisterSuccessfully'] as bool? ?? false,
      isSignInSuccessfully: json['isSignInSuccessfully'] as bool? ?? false,
    );

Map<String, dynamic> _$AuthenticationStateToJson(
        _AuthenticationState instance) =>
    <String, dynamic>{
      'authResponse': _authResponseToJson(instance.authResponse),
      'isRegisterSuccessfully': instance.isRegisterSuccessfully,
      'isSignInSuccessfully': instance.isSignInSuccessfully,
    };
