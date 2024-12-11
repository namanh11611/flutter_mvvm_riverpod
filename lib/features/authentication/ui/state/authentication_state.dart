import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'authentication_state.freezed.dart';

part 'authentication_state.g.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState({
    @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson) AuthResponse? authResponse,
    @Default(false) bool isRegisterSuccessfully,
    @Default(false) bool isSignInSuccessfully,
  }) = _AuthenticationState;

  factory AuthenticationState.fromJson(Map<String, Object?> json) =>
      _$AuthenticationStateFromJson(json);
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
