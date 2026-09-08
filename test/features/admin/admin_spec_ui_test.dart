import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_mvvm_riverpod/features/admin/model/moderation.dart';
import 'package:flutter_mvvm_riverpod/features/admin/repository/admin_repository.dart';
import 'package:flutter_mvvm_riverpod/features/admin/ui/admin_screen.dart';
import 'package:flutter_mvvm_riverpod/features/admin/ui/view_model/admin_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/admin/ui/widgets/admin_widgets.dart';

class SpecRepository extends AdminRepository {
  final queries = <Map<String, dynamic>>[];
  final decisions = <Map<String, dynamic>>[];
  Completer<void>? pending;
  final reportRow = <String, dynamic>{
    'id': '00000000-0000-0000-0000-000000000003',
    'reporter_id': 'reporter',
    'reported_user_id': 'target',
    'reporter_name': 'John Tan',
    'reported_user_name': 'Alex Lee',
    'reason': 'harassment',
    'status': 'reviewing',
    'description': 'Messages continued after I asked them to stop.',
    'created_at': '2026-09-05T06:21:00Z',
    'account_status': 'active',
    'previous_reports': 3,
    'warning_count': 1,
  };
  @override
  Future<Map<String, dynamic>> dashboard() async => {
    'counts': {
      'pending': 12,
      'reviewing': 4,
      'suspended': 5,
      'banned': 3,
      'today': 6,
      'resolved': 18,
    },
    'recent': [reportRow],
    'activity': <dynamic>[],
  };
  @override
  Future<List<ModerationItem>> list({
    required bool reports,
    required int page,
    required String filter,
  }) async {
    queries.add({...jsonDecode(filter) as Map<String, dynamic>, 'page': page});
    return [
      ModerationItem.fromJson(
        reports
            ? reportRow
            : {
                'id': 'target',
                'display_name': 'Alex Lee',
                'email': 'alex@example.test',
                'account_status': 'active',
                'report_count': 4,
                'warning_count': 1,
              },
        reports,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> report(String id) async => {
    'report': reportRow,
    'history': <dynamic>[],
  };
  @override
  Future<Map<String, dynamic>> activity(String filter) async => {
    'items': <dynamic>[],
    'admins': <dynamic>[],
  };
  @override
  Future<void> decide(
    String targetId,
    String decision,
    String note, {
    String? reportId,
    int? days,
  }) async {
    decisions.add({
      'targetId': targetId,
      'decision': decision,
      'note': note,
      'reportId': reportId,
      'days': days,
    });
    if (pending != null) await pending!.future;
  }
}

Future<void> setup(
  WidgetTester tester,
  SpecRepository repository,
  Widget home, {
  Size size = const Size(1280, 900),
  GlobalKey? capture,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (Platform.environment['ADMIN_FONT_PATH'] case final String fontPath) {
    await tester.runAsync(() async {
      final bytes = await File(fontPath).readAsBytes();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    });
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF7C3AED),
        ),
        home: RepaintBoundary(key: capture, child: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'desktop follows sidebar, summary cards and report table layout',
    (tester) async {
      final key = GlobalKey();
      await setup(tester, SpecRepository(), const AdminScreen(), capture: key);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Activity Logs'), findsOneWidget);
      expect(find.text('Review Verification'), findsOneWidget);
      expect(find.text('Suspended Users'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Report ID'), findsOneWidget);
      expect(find.text('Reported User'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['ADMIN_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/admin-preview').create(recursive: true);
          await File(
            'build/admin-preview/dashboard.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
  testWidgets('mobile reports use cards and send searches to the server', (
    tester,
  ) async {
    final repository = SpecRepository();
    await setup(
      tester,
      repository,
      const AdminScreen(section: 1),
      size: const Size(390, 844),
    );
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Alex Lee'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repository.queries.last['search'], 'Alex');
    expect(repository.queries.last['page'], 0);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Activity Logs'), findsOneWidget);
    expect(find.text('Review Verification'), findsOneWidget);
    expect(find.textContaining('Safety'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'suspension requires note and confirmation, cancellation does not submit',
    (tester) async {
      final repository = SpecRepository();
      await setup(
        tester,
        repository,
        const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AdminDecisionForm(
                targetId: 'target',
                reportId: 'report',
                actions: ['dismiss', 'warning', 'suspend', 'ban'],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextField),
        'Repeated harassment after review',
      );
      await tester.tap(find.text('Suspend user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save decision / Close case'));
      await tester.pumpAndSettle();
      expect(
        find.text('The account will be restricted for 7 days.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.decisions, isEmpty);
      await tester.tap(find.text('Save decision / Close case'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm decision'));
      await tester.pumpAndSettle();
      expect(repository.decisions.single, {
        'targetId': 'target',
        'decision': 'suspend',
        'note': 'Repeated harassment after review',
        'reportId': 'report',
        'days': 7,
      });
    },
  );
  testWidgets('dashboard card opens reports with its status filter', (
    tester,
  ) async {
    final repository = SpecRepository();
    final router = GoRouter(
      initialLocation: '/admin',
      routes: [
        GoRoute(path: '/admin', builder: (_, state) => const AdminScreen()),
        GoRoute(
          path: '/admin/reports',
          builder: (_, state) => AdminScreen(
            section: 1,
            status: state.uri.queryParameters['status'] ?? 'all',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending Reports'));
    await tester.pumpAndSettle();
    expect(repository.queries.last['status'], 'pending');
  });
  test(
    'busy decisions reject duplicate submission and validate duration',
    () async {
      final repository = SpecRepository()..pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final vm = container.read(adminViewModelProvider.notifier);
      await expectLater(
        vm.decide('target', 'suspend', 'Reviewed', days: 2),
        throwsArgumentError,
      );
      expect(repository.decisions, isEmpty);
      final first = vm.decide('target', 'warning', 'Reviewed');
      await vm.decide('target', 'warning', 'Reviewed');
      expect(repository.decisions.length, 1);
      repository.pending!.complete();
      await first;
      expect(container.read(adminViewModelProvider), isFalse);
    },
  );
  test('account actions respect status and protect administrators', () {
    expect(accountDecisions('banned'), ['reactivate']);
    expect(accountDecisions('suspended'), ['ban', 'reactivate']);
    expect(accountDecisions('active', isAdmin: true), isEmpty);
  });
}
