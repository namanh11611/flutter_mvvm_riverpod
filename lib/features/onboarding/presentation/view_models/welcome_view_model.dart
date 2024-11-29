import 'package:flutter_mvvm_riverpod/features/onboarding/presentation/state/welcome_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'welcome_view_model.g.dart';

@riverpod
class WelcomeViewModel extends _$WelcomeViewModel {
  @override
  FutureOr<WelcomeState> build() async {
    return const WelcomeState();
  }

  void loginWithGoogle() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(seconds: 2));

    state = const AsyncData(WelcomeState(isLoginWithGoogleSuccessfully: true));
  }

  void loginWithApple() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(seconds: 2));

    state = const AsyncData(WelcomeState(isLoginWithAppleSuccessfully: true));
  }
}
