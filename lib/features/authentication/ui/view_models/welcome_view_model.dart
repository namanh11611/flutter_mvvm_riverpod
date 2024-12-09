import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/extensions/string_extension.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/repository/authentication_repository.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/ui/state/welcome_state.dart';
import 'package:flutter_mvvm_riverpod/features/profile/ui/view_models/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'welcome_view_model.g.dart';

@riverpod
class WelcomeViewModel extends _$WelcomeViewModel {
  @override
  FutureOr<WelcomeState> build() async {
    return const WelcomeState();
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.loginWithGoogle);
    handleResult(result.value);
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.loginWithApple);
    handleResult(result.value);
  }

  void handleResult(AuthResponse? result) async {
    debugPrint('${Constants.tag} [WelcomeViewModel.handleResult] $result');
    if (result == null) {
      state = AsyncError('unexpected_error_occurred'.tr(), StackTrace.current);
      return;
    }

    final isExistAccount =
        await ref.read(authenticationRepositoryProvider).isExistAccount();
    if (!isExistAccount) {
      ref.read(authenticationRepositoryProvider).setIsExistAccount(true);
    }

    ref.read(authenticationRepositoryProvider).setIsLogin(true);
    ref
        .read(profileViewModelProvider.notifier)
        .updateProfile(email: result.user?.email.orEmpty());

    state = AsyncData(
      WelcomeState(
        authResponse: result,
        isRegisterSuccessfully: !isExistAccount,
        isLoginSuccessfully: true,
      ),
    );
  }
}
