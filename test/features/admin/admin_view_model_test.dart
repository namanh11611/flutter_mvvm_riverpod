import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/admin/ui/admin_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mvvm_riverpod/features/admin/repository/admin_repository.dart';
import 'package:flutter_mvvm_riverpod/features/admin/model/moderation.dart';
import 'package:flutter_mvvm_riverpod/features/admin/ui/view_model/admin_view_model.dart';

class FakeAdminRepository extends AdminRepository {
  bool fail = false;
  final List<String> actions = [];
  int listCalls = 0;
  @override
  Future<Map<String, dynamic>> dashboard() async => {
    'counts': {
      'pending': 7,
      'reviewing': 2,
      'resolved': 4,
      'dismissed': 1,
      'users': 20,
      'banned': 3,
      'suspended': 2,
      'today': 1,
    },
    'recent': <dynamic>[],
  };
  @override
  Future<Map<String, dynamic>> report(String id) async => {
    'report': {
      'id': id,
      'reported_user_id': 'target',
      'reporter_id': 'reporter',
      'reason': 'Spam',
      'status': 'resolved',
    },
    'history': <dynamic>[],
  };
  @override
  Future<List<ModerationItem>> list({
    required bool reports,
    required int page,
    required String filter,
  }) async {
    listCalls++;
    if (fail) throw Exception('Report service unavailable');
    return [];
  }

  @override
  Future<void> moderate(
    String action,
    String targetId,
    String reason, {
    String? status,
    ModerationImage? image,
  }) async {
    actions.add('$action:$targetId:$reason:$status');
    if (fail) throw Exception('Denied');
  }
}

void main() {
  testWidgets(
    'dashboard uses server counts and excludes deferred destinations',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
          ],
          child: const MaterialApp(home: AdminScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.textContaining('Emergency'), findsNothing);
      expect(find.text('Remove image'), findsNothing);
    },
  );
  testWidgets('completed reports cannot be reviewed again', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
        ],
        child: const MaterialApp(home: AdminReportScreen(reportId: 'report')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start review'), findsNothing);
    expect(find.text('Resolve report'), findsNothing);
    expect(find.text('Dismiss report'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Case history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Case history'), findsOneWidget);
  });

  testWidgets('report failures stay visible until an explicit retry', (
    tester,
  ) async {
    final repository = FakeAdminRepository()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AdminScreen(section: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load data. Please try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(repository.listCalls, 1);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);
    expect(find.text('No results.'), findsOneWidget);
  });
  test(
    'report action forwards target and resolution; clears busy state',
    () async {
      final repository = FakeAdminRepository();
      final container = ProviderContainer(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container
          .read(adminViewModelProvider.notifier)
          .moderate('review', 'report-id', 'Investigated', status: 'resolved');
      expect(repository.actions, ['review:report-id:Investigated:resolved']);
      expect(container.read(adminViewModelProvider), false);
    },
  );

  test('failed moderation is surfaced and leaves actions usable', () async {
    final repository = FakeAdminRepository()..fail = true;
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await expectLater(
      container
          .read(adminViewModelProvider.notifier)
          .moderate('ban', 'user-id', 'Spam'),
      throwsException,
    );
    expect(container.read(adminViewModelProvider), false);
    repository.fail = false;
    await container
        .read(adminViewModelProvider.notifier)
        .moderate('unban', 'user-id', 'Appeal accepted');
    expect(repository.actions.length, 2);
  });

  test('report profile target is the reported user, not the reporter', () {
    final item = ModerationItem.fromJson({
      'id': 'report',
      'reporter_id': 'reporter',
      'reported_user_id': 'target',
      'reason': 'scam',
      'status': 'pending',
    }, true);
    expect(item.targetId, 'target');
  });
}
