import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mvvm_riverpod/features/safety/model/user_safety.dart';
import 'package:flutter_mvvm_riverpod/features/safety/repository/user_safety_repository.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/view_model/report_user_view_model.dart';

class ReportRepository implements UserSafetyRepository {
  int calls = 0;
  final pending = Completer<UserReport>();
  @override
  Future<UserReport> reportUser({
    required String targetUserId,
    required UserReportReason reason,
    String? description,
  }) {
    calls++;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected operation: ${invocation.memberName}');
}

void main() {
  test('ten official reasons preserve legacy storage values and attention', () {
    expect(UserReportReason.values.length, 10);
    expect(
      UserReportReason.fromValue('hateSpeech')?.label,
      'Inappropriate or Offensive Behaviour',
    );
    expect(UserReportReason.threatsSafetyConcerns.attention, 2);
    expect(UserReportReason.suspiciousDangerousBehaviour.attention, 2);
    expect(
      UserReportReason.safetyFeatureMisuse.description,
      contains('Accidental activation must not automatically'),
    );
  });
  test('Other rejects empty and whitespace-only descriptions', () {
    for (final text in [null, '', ' \t\n ']) {
      expect(
        UserReportReason.validate(UserReportReason.other, text),
        isNotNull,
      );
    }
    expect(
      UserReportReason.validate(UserReportReason.other, ' Details '),
      isNull,
    );
    expect(UserReportReason.validate(null, 'Details'), isNotNull);
    expect(UserReportReason.validate(UserReportReason.scam, ''), isNull);
  });
  test(
    'duplicate submits are rejected; failure is safe and resets loading',
    () async {
      final repo = ReportRepository();
      final container = ProviderContainer(
        overrides: [userSafetyRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final vm = container.read(reportUserViewModelProvider.notifier);
      await expectLater(
        vm.submit('target', UserReportReason.other, ' \n'),
        throwsA(isA<UserSafetyException>()),
      );
      expect(repo.calls, 0);
      final first = vm.submit('target', UserReportReason.scam, 'Details');
      final result = expectLater(
        first,
        throwsA(
          isA<UserSafetyException>().having(
            (e) => e.message,
            'safe error',
            'Unable to submit your report. Please try again.',
          ),
        ),
      );
      await expectLater(
        vm.submit('target', UserReportReason.scam, 'Details'),
        throwsA(isA<UserSafetyException>()),
      );
      expect(repo.calls, 1);
      repo.pending.completeError(Exception('raw database secret'));
      await result;
      expect(container.read(reportUserViewModelProvider), false);
    },
  );
}
