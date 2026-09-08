import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/generated/locale_keys.g.dart';
import '../../../collaboration/ui/view_model/group_collaboration_view_model.dart';
import '../../../matchmaking/ui/matchmaking_view_model.dart';
import '../../repository/authentication_repository.dart';
import '../state/authentication_state.dart';
import 'user_account_view_model.dart';

part 'authentication_view_model.g.dart';

@riverpod
class AuthenticationViewModel extends _$AuthenticationViewModel {
  late AuthenticationRepository _repository;

  @override
  FutureOr<AuthenticationState> build() async {
    _repository = ref.read(authenticationRepositoryProvider);
    return const AuthenticationState();
  }

  Future<bool> sendRegistrationLink(String email) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.sendRegistrationLink(email),
    );

    if (result case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return false;
    }

    state = const AsyncData(AuthenticationState());
    return true;
  }

  Future<bool> setPassword(String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.setPassword(password),
    );
    if (result case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return false;
    }
    state = const AsyncData(AuthenticationState());
    return true;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.sendPasswordResetEmail(email.trim()),
    );

    if (result case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return false;
    }

    state = const AsyncData(AuthenticationState());
    return true;
  }

  Future<bool> updateRecoveredPassword(String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.updateRecoveredPassword(password),
    );
    if (result case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return false;
    }
    state = const AsyncData(AuthenticationState());
    return true;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
    );
    if (result case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return false;
    }
    state = const AsyncData(AuthenticationState());
    return true;
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repository.signInWithGoogle);
    if (result case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return false;
    }
    state = const AsyncData(AuthenticationState());
    return true;
  }

  Future<bool> hasCurrentUserProfile() => _repository.hasCurrentUserProfile();

  Future<bool> hasCompletedProfileOnboarding() =>
      _repository.hasCompletedProfileOnboarding();

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repository.signOut);

    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    ref.invalidate(matchmakingViewModelProvider);
    ref.invalidate(groupCollaborationViewModelProvider);
    ref.invalidate(userAccountViewModelProvider);
    state = const AsyncData(AuthenticationState());
  }

  void handleResult(AsyncValue result) async {
    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    final AuthResponse? authResponse = result.value;
    if (authResponse == null) {
      state = AsyncError(
        LocaleKeys.unexpectedErrorOccurred.tr(),
        StackTrace.current,
      );
      return;
    }

    // TODO: fake data, remove this when connect to real auth
    final isExistAccount = await _repository.isExistAccount();
    if (!isExistAccount) {
      _repository.setIsExistAccount(true);
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

  Future<bool> isLogin() async {
    return _repository.isLogin();
  }

  Future<bool> isGuestMode() async {
    return _repository.isGuestMode();
  }

  Future<void> setIsGuestMode() async {
    await _repository.setIsGuestMode();
  }
}
