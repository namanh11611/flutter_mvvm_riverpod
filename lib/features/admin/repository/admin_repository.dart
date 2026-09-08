import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../common/remote/supabase_client.dart';
import '../model/moderation.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

class AdminRepository {
  Future<String> access() async {
    if (supabase.auth.currentUser == null) return 'anonymous';
    return await supabase.rpc<String>('get_account_access');
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> body) async {
    try {
      final result = await supabase.functions
          .invoke('admin-moderation', body: body)
          .timeout(const Duration(seconds: 20));
      return Map<String, dynamic>.from(result.data as Map);
    } on TimeoutException {
      throw Exception(
        'The admin request timed out. Refresh to check the current state before retrying.',
      );
    } on FunctionException catch (error) {
      throw Exception(
        error.details is Map ? error.details['error'] : 'Admin request failed.',
      );
    }
  }

  Future<List<ModerationItem>> list({
    required bool reports,
    required int page,
    required String filter,
  }) async {
    final result = await _request({
      'action': reports ? 'reports' : 'users',
      'page': page,
      if (filter.startsWith('{'))
        ...Map<String, dynamic>.from(jsonDecode(filter) as Map)
      else if (reports)
        'status': filter
      else
        'search': filter,
    });
    final rows = (result['items'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return rows
        .map(
          (row) => ModerationItem.fromJson(
            Map<String, dynamic>.from(row as Map),
            reports,
          ),
        )
        .toList();
  }

  Future<ModerationProfile> profile(String id) async =>
      ModerationProfile.fromJson(
        await _request({'action': 'profile', 'targetId': id}),
      );

  Future<void> moderate(
    String action,
    String targetId,
    String reason, {
    String? status,
    ModerationImage? image,
  }) async {
    await _request({
      'action': action,
      'targetId': targetId,
      'reason': reason,
      'status': status,
      'bucket': image?.bucket,
      'path': image?.path,
    });
  }

  Future<Map<String, dynamic>> dashboard() {
    final now = DateTime.now();
    return _request({
      'action': 'dashboard',
      'since': DateTime(now.year, now.month, now.day).toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> report(String id) =>
      _request({'action': 'report', 'targetId': id});

  Future<Map<String, dynamic>> activity(String filter) => _request({
    'action': 'activity',
    ...Map<String, dynamic>.from(jsonDecode(filter) as Map),
  });
  Future<void> decide(
    String targetId,
    String decision,
    String note, {
    String? reportId,
    int? days,
  }) async {
    await _request({
      'action': 'decision',
      'targetId': targetId,
      'decision': decision,
      'reason': note,
      'reportId': reportId,
      'days': days,
    });
  }

  Future<void> signOut() => supabase.auth.signOut();
}
