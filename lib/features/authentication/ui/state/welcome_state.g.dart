// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welcome_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WelcomeStateImpl _$$WelcomeStateImplFromJson(Map<String, dynamic> json) =>
    _$WelcomeStateImpl(
      authResponse:
          _authResponseFromJson(json['authResponse'] as Map<String, dynamic>?),
      isRegisterSuccessfully: json['isRegisterSuccessfully'] as bool? ?? false,
      isLoginSuccessfully: json['isLoginSuccessfully'] as bool? ?? false,
    );

Map<String, dynamic> _$$WelcomeStateImplToJson(_$WelcomeStateImpl instance) =>
    <String, dynamic>{
      'authResponse': _authResponseToJson(instance.authResponse),
      'isRegisterSuccessfully': instance.isRegisterSuccessfully,
      'isLoginSuccessfully': instance.isLoginSuccessfully,
    };
