import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/remote/supabase_client.dart';
import '../model/safety_check_in.dart';

final safetyCheckInRepositoryProvider = Provider<SafetyCheckInRepository>(
  (ref) => SupabaseSafetyCheckInRepository(supabase),
);

abstract interface class SafetyCheckInRepository {
  Future<SafetyCheckIn> createPrompt({String? tripId});
  Future<void> respond(String checkInId, SafetyCheckInStatus status);
}

class SafetyCheckInException implements Exception {
  const SafetyCheckInException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SupabaseSafetyCheckInRepository implements SafetyCheckInRepository {
  const SupabaseSafetyCheckInRepository(this._client);
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const SafetyCheckInException('Sign in to use safety check-ins.');
    }
    return id;
  }

  @override
  Future<SafetyCheckIn> createPrompt({String? tripId}) async {
    final row = await _client
        .from('safety_check_ins')
        .insert({'user_id': _userId, 'trip_id': tripId})
        .select()
        .single();
    return SafetyCheckIn.fromMap(row);
  }

  @override
  Future<void> respond(
    String checkInId,
    SafetyCheckInStatus status,
  ) async {
    if (status != SafetyCheckInStatus.safe &&
        status != SafetyCheckInStatus.needsHelp) {
      throw const SafetyCheckInException('Invalid check-in response.');
    }
    await _client
        .from('safety_check_ins')
        .update({
          'status': status == SafetyCheckInStatus.needsHelp
              ? 'needsHelp'
              : status.name,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', checkInId)
        .eq('user_id', _userId)
        .eq('status', 'pending');
  }
}
