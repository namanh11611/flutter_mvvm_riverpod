// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String? ?? null,
  email: json['email'] as String? ?? null,
  name: json['name'] as String? ?? null,
  job: json['job'] as String? ?? null,
  avatar: json['avatar'] as String? ?? null,
  diamond: (json['diamond'] as num?)?.toInt() ?? null,
  expiryDatePremium: json['expiryDatePremium'] == null
      ? null
      : DateTime.parse(json['expiryDatePremium'] as String),
  isLifetimePremium: json['isLifetimePremium'] as bool? ?? null,
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'job': instance.job,
  'avatar': instance.avatar,
  'diamond': instance.diamond,
  'expiryDatePremium': instance.expiryDatePremium?.toIso8601String(),
  'isLifetimePremium': instance.isLifetimePremium,
};
