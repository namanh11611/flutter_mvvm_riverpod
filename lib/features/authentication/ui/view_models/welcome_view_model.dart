import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/extensions/string_extension.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/repository/authentication_repository.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/ui/state/welcome_state.dart';
import 'package:flutter_mvvm_riverpod/features/profile/model/profile.dart';
import 'package:flutter_mvvm_riverpod/features/profile/repository/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'welcome_view_model.g.dart';

@riverpod
class WelcomeViewModel extends _$WelcomeViewModel {
  @override
  FutureOr<WelcomeState> build() async {
    return const WelcomeState();
  }

  void loginWithGoogle() async {
    state = const AsyncLoading();
    final result =
        await ref.read(authenticationRepositoryProvider).loginWithGoogle();
    handleResult(result);
  }

  void loginWithApple() async {
    state = const AsyncLoading();
    final result =
        await ref.read(authenticationRepositoryProvider).loginWithApple();
    handleResult(result);
  }

  void handleResult(AsyncValue? result) async {
    debugPrint('${Constants.tag} [WelcomeViewModel.handleResult] ${result?.value}');
    if (result is AsyncData && result.value is AuthResponse) {
      final response = result.value as AuthResponse;
      final isExistAccount = await ref.read(authenticationRepositoryProvider).isExistAccount();
      if (!isExistAccount) {
        ref.read(authenticationRepositoryProvider).setIsExistAccount(true);
      }

      ref.read(authenticationRepositoryProvider).setIsLogin(true);
      ref
          .read(profileRepositoryProvider)
          .update(Profile(email: response.user?.email.orEmpty()));

      state = AsyncData(
        WelcomeState(
          authResponse: response,
          isRegisterSuccessfully: !isExistAccount,
          isLoginSuccessfully: true,
        ),
      );
    } else {
      state = AsyncError(
        result?.error ?? 'unexpected_error_occurred'.tr(),
        StackTrace.current,
      );
    }
  }
}
