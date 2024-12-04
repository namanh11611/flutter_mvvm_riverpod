// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileStateImpl _$$ProfileStateImplFromJson(Map<String, dynamic> json) =>
    _$ProfileStateImpl(
      profile: json['profile'] == null
          ? null
          : Profile.fromJson(json['profile'] as Map<String, dynamic>),
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$ProfileStateImplToJson(_$ProfileStateImpl instance) =>
    <String, dynamic>{
      'profile': instance.profile,
      'isLoading': instance.isLoading,
      'error': instance.error,
    };
