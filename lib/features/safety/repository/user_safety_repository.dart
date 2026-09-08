import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/remote/supabase_client.dart';
import '../model/user_safety.dart';

final userSafetyRepositoryProvider = Provider<UserSafetyRepository>(
  (ref) => SupabaseUserSafetyRepository(supabase),
);

final isUserBlockedProvider = FutureProvider.family<bool, String>(
  (ref, targetUserId) =>
      ref.read(userSafetyRepositoryProvider).isUserBlocked(targetUserId),
);

abstract interface class UserSafetyRepository {
  Future<List<BlockedUser>> getBlockedUsers();
  Future<bool> isUserBlocked(String targetUserId);
  Future<void> blockUser(String targetUserId);
  Future<void> unblockUser(String targetUserId);
  Future<UserReport> reportUser({
    required String targetUserId,
    required UserReportReason reason,
    String? description,
  });
}

class UserSafetyException implements Exception {
  const UserSafetyException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SupabaseUserSafetyRepository implements UserSafetyRepository {
  const SupabaseUserSafetyRepository(this._client);
  final SupabaseClient _client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const UserSafetyException('Sign in to use this safety feature.');
    }
    return id;
  }

  @override
  Future<bool> isUserBlocked(String targetUserId) async {
    final rows = await _client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', _currentUserId)
        .eq('blocked_id', targetUserId)
        .limit(1);
    return rows.isNotEmpty;
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    final rows = await _client.rpc<List<dynamic>>('get_blocked_users');
    return rows
        .map((value) {
          final row = Map<String, dynamic>.from(value as Map);
          return BlockedUser(
            userId: row['user_id'] as String,
            displayName: row['display_name'] as String? ?? 'GoBuddy user',
            avatarUrl: row['avatar_url'] as String?,
            blockedAt: DateTime.parse(row['blocked_at'] as String).toLocal(),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (targetUserId.isEmpty || targetUserId == currentUserId) {
      throw const UserSafetyException('You cannot block this user.');
    }
    await _client
        .from('user_blocks')
        .upsert(
          {'blocker_id': currentUserId, 'blocked_id': targetUserId},
          onConflict: 'blocker_id,blocked_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', _currentUserId)
        .eq('blocked_id', targetUserId);
  }

  @override
  Future<UserReport> reportUser({
    required String targetUserId,
    required UserReportReason reason,
    String? description,
  }) async {
    final currentUserId = _currentUserId;
    final cleanDescription = description?.trim();
    if (targetUserId.isEmpty || targetUserId == currentUserId) {
      throw const UserSafetyException('You cannot report this user.');
    }
    final validation = UserReportReason.validate(reason, description);
    if (validation != null) throw UserSafetyException(validation);
    try {
      final row = await _client
          .from('user_reports')
          .insert({
            'reporter_id': currentUserId,
            'reported_user_id': targetUserId,
            'reason': reason.name,
            'description': cleanDescription?.isEmpty ?? true
                ? null
                : cleanDescription,
          })
          .select()
          .single();
      return UserReport(
        id: row['id'] as String,
        reporterId: row['reporter_id'] as String,
        reportedUserId: row['reported_user_id'] as String,
        reason: UserReportReason.values.byName(row['reason'] as String),
        description: row['description'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        status: row['status'] as String,
      );
    } catch (_) {
      throw const UserSafetyException(
        'Unable to submit your report. Please try again.',
      );
    }
  }
}
