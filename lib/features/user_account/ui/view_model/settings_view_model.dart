import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_mvvm_riverpod/core/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/view_model/group_collaboration_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';
import '../../repository/authentication_repository.dart';
import '../state/settings_state.dart';
import 'user_account_view_model.dart';

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
    );

class SettingsViewModel extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final preferences = await SharedPreferences.getInstance();
    return SettingsState(
      tripMatchNotificationsEnabled:
          preferences.getBool(Constants.tripMatchNotificationsKey) ?? true,
    );
  }

  Future<void> setTripMatchNotificationsEnabled(bool enabled) async {
    final current = state.value ?? const SettingsState();
    state = AsyncData(current.copyWith(tripMatchNotificationsEnabled: enabled));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(Constants.tripMatchNotificationsKey, enabled);
  }

  Future<bool> signOut() async {
    final current = state.value ?? const SettingsState();
    state = AsyncData(current.copyWith(isSigningOut: true, clearError: true));
    try {
      await ref.read(authenticationRepositoryProvider).signOut();
      // Matchmaking state belongs to the authenticated account and must not
      // survive into the next user's session.
      ref.invalidate(matchmakingViewModelProvider);
      ref.invalidate(groupCollaborationViewModelProvider);
      ref.invalidate(userAccountViewModelProvider);
      state = AsyncData(current.copyWith(isSigningOut: false));
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(isSigningOut: false, error: error.toString()),
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    final current = state.value ?? const SettingsState();
    state = AsyncData(
      current.copyWith(isDeletingAccount: true, clearError: true),
    );
    try {
      await ref.read(authenticationRepositoryProvider).deleteAccount();
      ref.invalidate(matchmakingViewModelProvider);
      ref.invalidate(groupCollaborationViewModelProvider);
      ref.invalidate(userAccountViewModelProvider);
      state = AsyncData(current.copyWith(isDeletingAccount: false));
      return true;
    } catch (error) {
      final message = error.toString();
      state = AsyncData(
        current.copyWith(
          isDeletingAccount: false,
          error: message.startsWith('Exception: ')
              ? message.substring('Exception: '.length)
              : message,
        ),
      );
      return false;
    }
  }
}
