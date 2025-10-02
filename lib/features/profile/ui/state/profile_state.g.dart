// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileState _$ProfileStateFromJson(Map<String, dynamic> json) =>
    _ProfileState(
      profile: json['profile'] == null
          ? null
          : Profile.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileStateToJson(_ProfileState instance) =>
    <String, dynamic>{
      'profile': instance.profile,
    };
