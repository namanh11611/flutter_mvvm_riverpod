import 'dart:async';

import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('auth-dependent Group Expense providers rebuild on session changes',
      () async {
    final authChanges = StreamController<AuthState>();
    var userId = 'user-a';
    final container = ProviderContainer(
      overrides: [
        groupExpenseAuthChangesProvider.overrideWith(
          (ref) => authChanges.stream,
        ),
        authenticatedUserIdProvider.overrideWith(
          (ref) {
            ref.watch(groupExpenseAuthChangesProvider);
            return userId;
          },
        ),
      ],
    );

    final subscription = container.listen(
      authenticatedUserIdProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await authChanges.close();
    });
    expect(container.read(authenticatedUserIdProvider), 'user-a');

    userId = 'user-b';
    authChanges.add(const AuthState(AuthChangeEvent.signedIn, null));
    await pumpEventQueue();

    expect(container.read(authenticatedUserIdProvider), 'user-b');
  });
}
