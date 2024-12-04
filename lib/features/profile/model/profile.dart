import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    @Default(null) String? id,
    @Default(null) String? email,
    @Default(null) String? name,
    @Default(null) String? job,
    @Default(null) String? avatar,
    @Default(null) int? diamond,
    @JsonKey(name: 'expiry_date_premium')
    @Default(null)
    DateTime? expiryDatePremium,
    @JsonKey(name: 'is_lifetime_premium')
    @Default(null)
    bool? isLifetimePremium,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) => _$ProfileFromJson(json);
}
