import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'authentication_state.freezed.dart';

part 'authentication_state.g.dart';

class AuthResponseConverter
    implements JsonConverter<AuthResponse?, Map<String, dynamic>?> {
  const AuthResponseConverter();

  @override
  AuthResponse? fromJson(Map<String, dynamic>? json) {
    return json == null ? null : AuthResponse.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AuthResponse? instance) {
    if (instance == null) return null;
    return {
      'user': instance.user?.toJson(),
      'session': instance.session?.toJson(),
    };
  }
}

@freezed
abstract class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState({
    @AuthResponseConverter() AuthResponse? authResponse,
    @Default(false) bool isRegisterSuccessfully,
    @Default(false) bool isSignInSuccessfully,
  }) = _AuthenticationState;

  factory AuthenticationState.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationStateFromJson(json);
}
