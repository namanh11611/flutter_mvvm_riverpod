import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/model/user_account_model.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/repository/user_account_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/ui/identity_verification_screen.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/ui/view_model/user_account_view_model.dart';

void main() {
  testWidgets(
    'pending, approved and rejected states offer the correct actions',
    (tester) async {
      final repository = _VerificationRepository();
      final container = ProviderContainer(
        overrides: [
          userAccountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: IdentityVerificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verification pending'), findsOneWidget);
      expect(find.text('Continue Verification'), findsOneWidget);

      repository.status = IdentityVerificationStatus.verified;
      await tester.tap(find.text('Refresh status'));
      await tester.pumpAndSettle();
      expect(find.text('Identity verified'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Continue Verification'), findsNothing);

      repository.status = IdentityVerificationStatus.unverified;
      await container
          .read(userAccountViewModelProvider.notifier)
          .refreshVerificationStatus();
      await tester.pumpAndSettle();
      expect(find.text('Identity unverified'), findsOneWidget);
      expect(find.text('Verify Identity'), findsOneWidget);
      expect(
        find.textContaining('check your notifications for the reason'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _VerificationRepository extends UserAccountRepository {
  IdentityVerificationStatus status = IdentityVerificationStatus.pending;
  @override
  Future<UserAccount> fetchCurrentAccount() async => UserAccount(
    uid: 'user',
    email: 'user@example.com',
    phoneNumber: '',
    username: 'user',
    verificationStatus: status,
  );
  @override
  Future<IdentityVerificationStatus> fetchVerificationStatus() async => status;
}
