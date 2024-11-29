// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welcome_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WelcomeStateImpl _$$WelcomeStateImplFromJson(Map<String, dynamic> json) =>
    _$WelcomeStateImpl(
      isRegisterSuccessfully: json['isRegisterSuccessfully'] as bool? ?? false,
      isLoginWithGoogleSuccessfully:
          json['isLoginWithGoogleSuccessfully'] as bool? ?? false,
      isLoginWithAppleSuccessfully:
          json['isLoginWithAppleSuccessfully'] as bool? ?? false,
    );

Map<String, dynamic> _$$WelcomeStateImplToJson(_$WelcomeStateImpl instance) =>
    <String, dynamic>{
      'isRegisterSuccessfully': instance.isRegisterSuccessfully,
      'isLoginWithGoogleSuccessfully': instance.isLoginWithGoogleSuccessfully,
      'isLoginWithAppleSuccessfully': instance.isLoginWithAppleSuccessfully,
    };
