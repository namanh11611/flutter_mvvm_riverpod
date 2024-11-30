import 'package:freezed_annotation/freezed_annotation.dart';

part 'welcome_state.freezed.dart';

part 'welcome_state.g.dart';

@freezed
class WelcomeState with _$WelcomeState {
  const factory WelcomeState({
    @Default(false) bool isRegisterSuccessfully,
    @Default(false) bool isLoginWithGoogleSuccessfully,
    @Default(false) bool isLoginWithAppleSuccessfully,
  }) = _WelcomeState;

  factory WelcomeState.fromJson(Map<String, Object?> json) =>
      _$WelcomeStateFromJson(json);
}
