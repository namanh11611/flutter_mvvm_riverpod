// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String? ?? null,
      email: json['email'] as String? ?? null,
      name: json['name'] as String? ?? null,
      job: json['job'] as String? ?? null,
      avatar: json['avatar'] as String? ?? null,
      diamond: (json['diamond'] as num?)?.toInt() ?? null,
      expiryDatePremium: json['expiry_date_premium'] == null
          ? null
          : DateTime.parse(json['expiry_date_premium'] as String),
      isLifetimePremium: json['is_lifetime_premium'] as bool? ?? null,
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'job': instance.job,
      'avatar': instance.avatar,
      'diamond': instance.diamond,
      'expiry_date_premium': instance.expiryDatePremium?.toIso8601String(),
      'is_lifetime_premium': instance.isLifetimePremium,
    };
