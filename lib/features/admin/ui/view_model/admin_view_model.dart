import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/moderation.dart';
import '../../repository/admin_repository.dart';

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
  retry: (_, error) => null,
);
final adminReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) => ref.watch(adminRepositoryProvider).report(id),
      retry: (_, error) => null,
    );

final adminActivityProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, filter) => ref.watch(adminRepositoryProvider).activity(filter),
      retry: (_, error) => null,
    );

typedef AdminQuery = ({bool reports, int page, String filter});
final adminItemsProvider = FutureProvider.autoDispose
    .family<List<ModerationItem>, AdminQuery>(
      (ref, query) => ref
          .watch(adminRepositoryProvider)
          .list(reports: query.reports, page: query.page, filter: query.filter),
      retry: (retryCount, error) => null,
    );
final adminProfileProvider = FutureProvider.autoDispose
    .family<ModerationProfile, String>(
      (ref, id) => ref.watch(adminRepositoryProvider).profile(id),
      retry: (retryCount, error) => null,
    );
final adminViewModelProvider = NotifierProvider<AdminViewModel, bool>(
  AdminViewModel.new,
);

class AdminViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> moderate(
    String action,
    String targetId,
    String reason, {
    String? status,
    ModerationImage? image,
  }) async {
    if (state) return;
    state = true;
    try {
      await ref
          .read(adminRepositoryProvider)
          .moderate(action, targetId, reason, status: status, image: image);
    } finally {
      ref.invalidate(adminActivityProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminReportProvider);
      ref.invalidate(adminItemsProvider);
      ref.invalidate(adminProfileProvider);
      state = false;
    }
  }

  Future<void> decide(
    String targetId,
    String decision,
    String note, {
    String? reportId,
    int? days,
  }) async {
    if (state) return;
    if (note.trim().isEmpty || note.trim().length > 1000) {
      throw ArgumentError('Enter an internal note (1-1000 characters).');
    }
    if (decision == 'suspend' && ![1, 3, 7, 30].contains(days)) {
      throw ArgumentError('Select a suspension duration.');
    }
    state = true;
    try {
      await ref
          .read(adminRepositoryProvider)
          .decide(
            targetId,
            decision,
            note.trim(),
            reportId: reportId,
            days: days,
          );
    } finally {
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminReportProvider);
      ref.invalidate(adminItemsProvider);
      ref.invalidate(adminProfileProvider);
      ref.invalidate(adminActivityProvider);
      state = false;
    }
  }

  Future<void> signOut() => ref.read(adminRepositoryProvider).signOut();
}
