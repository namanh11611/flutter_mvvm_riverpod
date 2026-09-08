import 'package:flutter_mvvm_riverpod/core/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/repository/authentication_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/ui/view_model/settings_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      Constants.tripMatchNotificationsKey: true,
    });
  });

  test('persists Trip Matches preference and delegates Supabase sign-out',
      () async {
    final repository = _FakeAuthenticationRepository();
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    final notifier = container.read(settingsViewModelProvider.notifier);

    await notifier.setTripMatchNotificationsEnabled(false);
    expect(
      container
          .read(settingsViewModelProvider)
          .value!
          .tripMatchNotificationsEnabled,
      isFalse,
    );

    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(Constants.tripMatchNotificationsKey),
      isFalse,
    );

    expect(await notifier.signOut(), isTrue);
    expect(repository.didSignOut, isTrue);
  });

  test('delegates confirmed account deletion to authentication repository',
      () async {
    final repository = _FakeAuthenticationRepository();
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    final deleted = await container
        .read(settingsViewModelProvider.notifier)
        .deleteAccount();

    expect(deleted, isTrue);
    expect(repository.didDeleteAccount, isTrue);
    expect(
      container
          .read(settingsViewModelProvider)
          .value!
          .isDeletingAccount,
      isFalse,
    );
  });
}

class _FakeAuthenticationRepository extends AuthenticationRepository {
  bool didSignOut = false;
  bool didDeleteAccount = false;

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }

  @override
  Future<void> deleteAccount() async {
    didDeleteAccount = true;
  }
}
