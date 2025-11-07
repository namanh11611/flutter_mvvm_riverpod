import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/constants.dart';
import '../../../../features/profile/ui/view_model/profile_view_model.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../repository/authentication_repository.dart';
import '../../ui/state/authentication_state.dart';

part 'authentication_view_model.g.dart';

@riverpod
class AuthenticationViewModel extends _$AuthenticationViewModel {
  late AuthenticationRepository _repository;

  @override
  FutureOr<AuthenticationState> build() async {
    _repository = ref.read(authenticationRepositoryProvider);
    return const AuthenticationState();
  }

  Future<void> signInWithMagicLink(String email) async {
    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => _repository.signInWithMagicLink(email));

    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    state = const AsyncData(AuthenticationState());
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.verifyOtp(
        email: email,
        token: token,
        isRegister: isRegister,
      ),
    );
    handleResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repository.signInWithGoogle);
    handleResult(result);
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repository.signInWithApple);
    handleResult(result);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repository.signOut);

    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    state = const AsyncData(AuthenticationState());
  }

  void handleResult(AsyncValue result) async {
    debugPrint(
        '${Constants.tag} [AuthenticationViewModel.handleResult] result: $result');
    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    final AuthResponse? authResponse = result.value;
    debugPrint(
        '${Constants.tag} [AuthenticationViewModel.handleResult] authResponse: ${authResponse?.user?.toJson()}');
    if (authResponse == null) {
      state = AsyncError(LocaleKeys.unexpectedErrorOccurred.tr(), StackTrace.current);
      return;
    }

    // TODO: fake data, remove this when connect to real auth
    final isExistAccount = await _repository.isExistAccount();
    if (!isExistAccount) {
      _repository.setIsExistAccount(true);
    }
    if (authResponse.user != null) {
      updateProfile(authResponse.user!);
    }
    _repository.setIsLogin(true);
    // END TODO

    state = AsyncData(
      AuthenticationState(
        authResponse: authResponse,
        isRegisterSuccessfully: !isExistAccount,
        isSignInSuccessfully: true,
      ),
    );
  }

  Future<void> updateProfile(User user) async {
    String? name;
    String? avatar;
    final metaData = user.userMetadata;
    if (metaData != null) {
      name = metaData['full_name'];
      avatar = metaData['avatar_url'];
    }
    ref.read(profileViewModelProvider.notifier).updateProfile(
      email: user.email,
      name: name,
      avatar: avatar,
    );
  }
}
