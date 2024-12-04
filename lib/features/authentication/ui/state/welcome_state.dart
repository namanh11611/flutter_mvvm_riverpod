import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'welcome_state.freezed.dart';

part 'welcome_state.g.dart';

@freezed
class WelcomeState with _$WelcomeState {
  const factory WelcomeState({
    @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson) AuthResponse? authResponse,
    @Default(false) bool isRegisterSuccessfully,
    @Default(false) bool isLoginSuccessfully,
  }) = _WelcomeState;

  factory WelcomeState.fromJson(Map<String, Object?> json) =>
      _$WelcomeStateFromJson(json);
}

AuthResponse? _authResponseFromJson(Map<String, dynamic>? json) {
  return json == null ? null : AuthResponse.fromJson(json);
}

Map<String, dynamic>? _authResponseToJson(AuthResponse? instance) {
  if (instance == null) return null;
  return {
    'user': instance.user?.toJson(),
    'session': instance.session?.toJson(),
  };
}
