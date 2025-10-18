import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    @Default(null) String? id,
    @Default(null) String? email,
    @Default(null) String? name,
    @Default(null) String? job,
    @Default(null) String? avatar,
    @Default(null) int? diamond,
    @Default(null) DateTime? expiryDatePremium,
    @Default(null) bool? isLifetimePremium,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
