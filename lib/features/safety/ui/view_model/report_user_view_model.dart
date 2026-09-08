import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/user_safety.dart';
import '../../repository/user_safety_repository.dart';

final reportUserViewModelProvider = NotifierProvider<ReportUserViewModel, bool>(
  ReportUserViewModel.new,
);

class ReportUserViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> submit(
    String targetId,
    UserReportReason? reason,
    String description,
  ) async {
    if (state) {
      throw const UserSafetyException('A report is already being submitted.');
    }
    final validation = UserReportReason.validate(reason, description);
    if (validation != null) throw UserSafetyException(validation);
    state = true;
    try {
      await ref
          .read(userSafetyRepositoryProvider)
          .reportUser(
            targetUserId: targetId,
            reason: reason!,
            description: description.trim(),
          );
    } catch (_) {
      throw const UserSafetyException(
        'Unable to submit your report. Please try again.',
      );
    } finally {
      state = false;
    }
  }
}
