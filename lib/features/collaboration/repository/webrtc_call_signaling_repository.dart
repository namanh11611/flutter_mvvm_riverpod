import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';

class TripCallSignal {
  const TripCallSignal({
    required this.id,
    required this.callId,
    required this.senderId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.targetId,
  });

  final String id;
  final String callId;
  final String senderId;
  final String? targetId;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory TripCallSignal.fromMap(Map<String, dynamic> map) => TripCallSignal(
    id: map['id'] as String,
    callId: map['call_id'] as String,
    senderId: map['sender_id'] as String,
    targetId: map['target_id'] as String?,
    type: map['signal_type'] as String,
    payload: Map<String, dynamic>.from(
      map['payload'] as Map? ?? const <String, dynamic>{},
    ),
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}

class TripCallParticipant {
  const TripCallParticipant({
    required this.callId,
    required this.userId,
    required this.displayName,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.status,
    required this.joinedAt,
    required this.updatedAt,
  });

  final String callId;
  final String userId;
  final String displayName;
  final bool micEnabled;
  final bool cameraEnabled;
  final String status;
  final DateTime joinedAt;
  final DateTime updatedAt;

  bool get isActive =>
      status == 'joined' &&
      updatedAt.isAfter(DateTime.now().subtract(const Duration(seconds: 45)));

  factory TripCallParticipant.fromMap(Map<String, dynamic> map) =>
      TripCallParticipant(
        callId: map['call_id'] as String,
        userId: map['user_id'] as String,
        displayName: map['display_name'] as String? ?? 'Trip member',
        micEnabled: map['mic_enabled'] as bool? ?? true,
        cameraEnabled: map['camera_enabled'] as bool? ?? false,
        status: map['status'] as String? ?? 'left',
        joinedAt: DateTime.parse(map['joined_at'] as String).toLocal(),
        updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      );
}

class WebRtcCallSignalingRepository {
  const WebRtcCallSignalingRepository();

  SupabaseClient get _client => supabase;

  Future<List<TripCallSignal>> loadSignals({
    required String callId,
    DateTime? since,
  }) async {
    var query = _client
        .from('trip_call_signals')
        .select()
        .eq('call_id', callId);
    if (since != null) {
      query = query.gte('created_at', since.toUtc().toIso8601String());
    }
    final rows = await query.order('created_at');
    return rows
        .map((row) => TripCallSignal.fromMap(row))
        .toList(growable: false);
  }

  Future<RealtimeChannel> subscribe({
    required String callId,
    required void Function(TripCallSignal signal) onSignal,
    required void Function(TripCallParticipant participant) onParticipant,
    required void Function() onCallEnded,
  }) async {
    final channel = _client
        .channel('trip-call-signals:$callId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trip_call_signals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'call_id',
            value: callId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onSignal(TripCallSignal.fromMap(payload.newRecord));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_call_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'call_id',
            value: callId,
          ),
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            if (record.isNotEmpty && record['updated_at'] != null) {
              onParticipant(TripCallParticipant.fromMap(record));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trip_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: callId,
          ),
          callback: (payload) {
            if (payload.newRecord['status'] == 'ended') onCallEnded();
          },
        );

    final ready = Completer<void>();
    channel.subscribe((status, error) {
      debugPrint(
        '[group_call] signaling_room_status call_id=$callId '
        'status=${status.name}${error == null ? '' : ' error=$error'}',
      );
      if (status == RealtimeSubscribeStatus.subscribed && !ready.isCompleted) {
        ready.complete();
      } else if ((status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut ||
              status == RealtimeSubscribeStatus.closed) &&
          !ready.isCompleted) {
        ready.completeError(
          StateError('Could not subscribe to group call signaling: $status'),
        );
      }
    });
    try {
      await ready.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      await _client.removeChannel(channel);
      rethrow;
    }
    return channel;
  }

  Future<List<TripCallParticipant>> loadParticipants({
    required String callId,
  }) async {
    final rows = await _client
        .from('trip_call_participants')
        .select()
        .eq('call_id', callId)
        .eq('status', 'joined')
        .gt(
          'updated_at',
          DateTime.now()
              .subtract(const Duration(seconds: 45))
              .toUtc()
              .toIso8601String(),
        )
        .order('joined_at');
    return rows
        .map((row) => TripCallParticipant.fromMap(row))
        .toList(growable: false);
  }

  Future<void> joinParticipant({
    required String callId,
    required String displayName,
    required bool micEnabled,
    required bool cameraEnabled,
  }) => _client.rpc(
    'upsert_trip_call_participant',
    params: {
      'p_call_id': callId,
      'p_display_name': displayName,
      'p_mic_enabled': micEnabled,
      'p_camera_enabled': cameraEnabled,
    },
  );

  Future<void> updateParticipantMedia({
    required String callId,
    required bool micEnabled,
    required bool cameraEnabled,
  }) => _client.rpc(
    'update_trip_call_participant_media',
    params: {
      'p_call_id': callId,
      'p_mic_enabled': micEnabled,
      'p_camera_enabled': cameraEnabled,
    },
  );

  Future<int> leaveParticipant({required String callId}) async {
    final result = await _client.rpc(
      'leave_trip_call',
      params: {'p_call_id': callId},
    );
    return result as int? ?? 0;
  }

  Future<void> send({
    required String callId,
    required String tripId,
    required String senderId,
    required String type,
    required Map<String, dynamic> payload,
    String? targetId,
  }) async {
    debugPrint(
      '[group_call] signaling_send_to_group call_id=$callId '
      'sender_id=$senderId target_id=${targetId ?? 'all'} type=$type',
    );
    await _client.from('trip_call_signals').insert({
      'call_id': callId,
      'trip_id': tripId,
      'sender_id': senderId,
      'target_id': targetId,
      'signal_type': type,
      'payload': payload,
    });
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
