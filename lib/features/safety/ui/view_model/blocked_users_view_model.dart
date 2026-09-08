import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/user_safety.dart';
import '../../repository/user_safety_repository.dart';

final blockedUsersViewModelProvider =
    AsyncNotifierProvider<BlockedUsersViewModel, List<BlockedUser>>(
  BlockedUsersViewModel.new,
);

class BlockedUsersViewModel extends AsyncNotifier<List<BlockedUser>> {
  @override
  Future<List<BlockedUser>> build() =>
      ref.read(userSafetyRepositoryProvider).getBlockedUsers();

  Future<void> unblock(String userId) async {
    final previous = state.value ?? const <BlockedUser>[];
    state = AsyncData(
      previous.where((user) => user.userId != userId).toList(growable: false),
    );
    try {
      await ref.read(userSafetyRepositoryProvider).unblockUser(userId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
