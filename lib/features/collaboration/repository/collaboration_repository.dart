import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/model/collaboration_models.dart';

bool _isActivityProposalSchemaMissing(PostgrestException error) =>
    error.code == 'PGRST205' ||
    error.code == 'PGRST204' ||
    error.code == '42P01' ||
    error.message.toLowerCase().contains('trip_activity_proposals');

final collaborationRepositoryProvider = Provider<CollaborationRepository>(
  (ref) => CollaborationRepository(supabase),
);

class CollaborationRepository {
  CollaborationRepository(this._client);

  final SupabaseClient _client;
  final Set<String> _activityProposalEnabledTrips = <String>{};

  Future<GroupCollaborationState> loadWorkspace({
    required String tripId,
    required String currentUserId,
  }) async {
    final hasAccess = await _client.rpc(
      'is_trip_member',
      params: {'p_trip_id': tripId},
    );
    if (hasAccess != true) {
      throw const CollaborationAccessRemovedException();
    }
    final trip = await _client
        .from('matchmaking_trips')
        .select('owner_id, destination, start_date, end_date')
        .eq('id', tripId)
        .single();
    final results = await Future.wait<dynamic>([
      _client
          .from('trip_members')
          .select('user_id, muted_until')
          .eq('trip_id', tripId),
      _client
          .from('trip_messages')
          .select('*, trip_message_reads(user_id)')
          .eq('trip_id', tripId)
          .order('sent_at'),
      _client
          .from('trip_activities')
          .select()
          .eq('trip_id', tripId)
          .order('start_time'),
      _client
          .from('trip_files')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false),
      _client.from('trip_polls').select('id, question').eq('trip_id', tripId),
      _client
          .from('trip_member_roles')
          .select('user_id, role')
          .eq('trip_id', tripId),
      _client
          .from('trip_activity_comments')
          .select()
          .eq('trip_id', tripId)
          .order('created_at'),
      _client
          .from('trip_activity_events')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false)
          .limit(20),
      _client
          .from('user_accounts')
          .select('id, display_name, profile_photo_path'),
      _client
          .from('trip_calls')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false)
          .limit(20),
      _client
          .from('trip_activity_rsvps')
          .select('activity_id, user_id, status')
          .eq('trip_id', tripId),
      _client
          .from('trip_typing_status')
          .select('user_id')
          .eq('trip_id', tripId)
          .gt(
            'updated_at',
            DateTime.now()
                .subtract(const Duration(seconds: 12))
                .toUtc()
                .toIso8601String(),
          ),
      _client
          .from('trip_activity_event_reads')
          .select('event_id')
          .eq('trip_id', tripId)
          .eq('user_id', currentUserId),
      _loadTimelineDays(tripId),
      _loadActivityProposals(tripId),
    ]);
    final profileNames = <String, String>{
      for (final profile in results[8] as List<dynamic>)
        (profile as Map<String, dynamic>)['id'] as String:
            profile['display_name'] as String,
    };
    final profilePhotoUrls = <String, String?>{
      for (final profile in results[8] as List<dynamic>)
        (profile as Map<String, dynamic>)['id'] as String:
            profile['profile_photo_path'] as String?,
    };
    final adminIds = (results[5] as List<dynamic>)
        .where((role) => (role as Map<String, dynamic>)['role'] == 'admin')
        .map((role) => (role as Map<String, dynamic>)['user_id'] as String)
        .toSet();
    final polls = <ActivityPoll>[];
    for (final rawPoll in results[4] as List<dynamic>) {
      final poll = rawPoll as Map<String, dynamic>;
      final options = await _client
          .from('trip_poll_options')
          .select('id, label, trip_poll_votes(user_id)')
          .eq('poll_id', poll['id'])
          .order('created_at');
      polls.add(
        ActivityPoll(
          id: poll['id'] as String,
          question: poll['question'] as String,
          options: (options as List<dynamic>).map((rawOption) {
            final option = rawOption as Map<String, dynamic>;
            final votes =
                option['trip_poll_votes'] as List<dynamic>? ?? const [];
            return PollOption(
              id: option['id'] as String,
              label: option['label'] as String,
              voterIds: votes
                  .map(
                    (vote) =>
                        (vote as Map<String, dynamic>)['user_id'] as String,
                  )
                  .toList(),
            );
          }).toList(),
        ),
      );
    }
    return GroupCollaborationState(
      tripId: tripId,
      tripTitle: trip['destination'] as String? ?? 'Trip',
      tripStartDate: trip['start_date'] == null
          ? null
          : DateTime.parse(trip['start_date'] as String),
      tripEndDate: trip['end_date'] == null
          ? null
          : DateTime.parse(trip['end_date'] as String),
      currentUserId: currentUserId,
      creatorId: trip['owner_id'] as String,
      isAdmin: adminIds.contains(currentUserId),
      members: (results[0] as List<dynamic>).map((member) {
        final row = member as Map<String, dynamic>;
        return CollaborationMember.fromMap(
          row,
          displayName: profileNames[row['user_id'] as String],
          profilePhotoUrl: profilePhotoUrls[row['user_id'] as String],
          isAdmin: adminIds.contains(row['user_id'] as String),
        );
      }).toList(),
      messages: (results[1] as List<dynamic>).map((message) {
        final row = message as Map<String, dynamic>;
        return TripMessage.fromMap(
          row,
          senderName: profileNames[row['sender_id'] as String],
          readByCount:
              (row['trip_message_reads'] as List<dynamic>? ?? const []).length,
        );
      }).toList(),
      activities: (results[2] as List<dynamic>)
          .map(
            (activity) =>
                TripActivity.fromMap(activity as Map<String, dynamic>),
          )
          .toList(),
      activityProposals: (results[14] as List<dynamic>).map((proposal) {
        final row = proposal as Map<String, dynamic>;
        return TripActivityProposal.fromMap(
          row,
          proposedByName: profileNames[row['proposed_by'] as String],
        );
      }).toList(),
      timelineDays: (results[13] as List<dynamic>)
          .map(
            (row) => DateTime.parse(
              (row as Map<String, dynamic>)['day_date'] as String,
            ),
          )
          .toList(),
      polls: polls,
      files: (results[3] as List<dynamic>).map((file) {
        final row = file as Map<String, dynamic>;
        return SharedTripFile.fromMap(
          row,
          uploadedByName: profileNames[row['uploaded_by'] as String],
        );
      }).toList(),
      comments: (results[6] as List<dynamic>)
          .map(
            (comment) =>
                ActivityComment.fromMap(comment as Map<String, dynamic>),
          )
          .toList(),
      notifications: (results[7] as List<dynamic>)
          .map(
            (event) => CollaborationNotification.fromMap(
              event as Map<String, dynamic>,
            ),
          )
          .toList(),
      readNotificationIds: {
        for (final read in results[12] as List<dynamic>)
          (read as Map<String, dynamic>)['event_id'] as String,
      },
      calls: (results[9] as List<dynamic>).map((call) {
        final row = call as Map<String, dynamic>;
        return TripCall.fromMap(
          row,
          initiatedByName: profileNames[row['initiated_by'] as String],
        );
      }).toList(),
      rsvps: (results[10] as List<dynamic>)
          .map((rsvp) => ActivityRsvp.fromMap(rsvp as Map<String, dynamic>))
          .toList(),
      typingMemberNames: (results[11] as List<dynamic>)
          .map(
            (typing) => (typing as Map<String, dynamic>)['user_id'] as String,
          )
          .where((userId) => userId != currentUserId)
          .map((userId) => profileNames[userId] ?? 'A trip member')
          .toList(),
    );
  }

  Future<List<dynamic>> _loadTimelineDays(String tripId) async {
    try {
      return await _client.rpc(
        'get_trip_timeline_days',
        params: {'p_trip_id': tripId},
      );
    } on PostgrestException catch (error) {
      // Older deployments do not have the member-validated read RPC yet.
      // Fall back to the table query until the migration reaches them.
      if (error.code == 'PGRST202' ||
          error.message.contains('get_trip_timeline_days')) {
        return await _client
            .from('trip_timeline_days')
            .select('trip_id, day_date')
            .eq('trip_id', tripId)
            .order('day_date');
      }
      // Keep existing workspaces usable while the optional timeline-days
      // migration is being deployed. Other collaboration data must not be
      // blocked by a missing new table.
      if (error.code == 'PGRST205' ||
          error.code == '42P01' ||
          error.message.contains('trip_timeline_days')) {
        return const [];
      }
      rethrow;
    }
  }

  Future<List<dynamic>> _loadActivityProposals(String tripId) async {
    try {
      final proposals = await _client
          .from('trip_activity_proposals')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 3));
      _activityProposalEnabledTrips.add(tripId);
      return proposals;
    } on PostgrestException catch (error) {
      // Proposals were added after the original collaboration workspace.
      // A deployment that has not applied that optional migration must still
      // be able to open the trip timeline and use the existing features.
      if (_isActivityProposalSchemaMissing(error)) {
        _activityProposalEnabledTrips.remove(tripId);
        return const [];
      }
      rethrow;
    } on TimeoutException {
      return const [];
    }
  }

  Future<RealtimeChannel> subscribe(
    String tripId,
    void Function() onChange,
  ) async {
    final channel =
        _client
            .channel('trip-workspace-$tripId')
            .onBroadcast(
              event: 'incoming_call',
              callback: (payload) {
                debugPrint(
                  '[group_call] signaling_send_to_group received '
                  'trip_id=$tripId call_id=${payload['callId']}',
                );
                onChange();
              },
            )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_polls',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_poll_votes',
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_activity_comments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_activity_events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_activities',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_timeline_days',
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              if (record['trip_id'] == tripId) onChange();
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'matchmaking_trip_members',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_member_roles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_poll_options',
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_files',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_calls',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (payload) {
              debugPrint(
                '[group_call] call_room_database_change trip_id=$tripId '
                'call_id=${payload.newRecord['id'] ?? payload.oldRecord['id']}',
              );
              onChange();
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_typing_status',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_message_reads',
            callback: (_) => onChange(),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'trip_activity_rsvps',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'trip_id',
              value: tripId,
            ),
            callback: (_) => onChange(),
          );

    if (_activityProposalEnabledTrips.contains(tripId)) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trip_activity_proposals',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'trip_id',
          value: tripId,
        ),
        callback: (_) => onChange(),
      );
    }

    channel.subscribe((status, error) {
      debugPrint(
        '[group_call] workspace_room_status trip_id=$tripId '
        'status=${status.name}${error == null ? '' : ' error=$error'}',
      );
    });
    // Realtime improves freshness but must never block the first render. The
    // initial database snapshot below remains authoritative, and later events
    // invalidate it once the channel reaches its subscribed state.
    return channel;
  }

  Future<void> broadcastCallInvite({
    required String tripId,
    required TripCall call,
    required String callerName,
  }) async {
    final channel = _client.channel('trip-workspace-$tripId');
    try {
      final response = await channel.sendBroadcastMessage(
        event: 'incoming_call',
        payload: {
          'roomId': call.id,
          'groupId': tripId,
          'callerName': callerName,
          'callType': call.callType,
          'callId': call.id,
          'trip_id': tripId,
          'call_id': call.id,
          'call_type': call.callType,
          'initiated_by': call.initiatedBy,
          'created_at': call.createdAt.toUtc().toIso8601String(),
        },
      );
      debugPrint(
        '[group_call] signaling_send_to_group trip_id=$tripId '
        'call_id=${call.id} response=$response',
      );
    } finally {
      await _client.removeChannel(channel);
    }
  }

  Future<void> sendMessage(String tripId, String userId, String body) => _client
      .from('trip_messages')
      .insert({'trip_id': tripId, 'sender_id': userId, 'body': body});

  Future<void> setMutedUntil({
    required String tripId,
    required String memberId,
    required DateTime? mutedUntil,
  }) => _client
      .from('trip_members')
      .update({'muted_until': mutedUntil?.toUtc().toIso8601String()})
      .eq('trip_id', tripId)
      .eq('user_id', memberId);

  Future<void> unmuteMember({
    required String tripId,
    required String memberId,
  }) => _client
      .from('trip_members')
      .update({'muted_until': null})
      .eq('trip_id', tripId)
      .eq('user_id', memberId);

  Future<void> removeMember(String tripId, String memberId) => _client.rpc(
    'remove_matchmaking_trip_member',
    params: {'p_trip_id': tripId, 'p_user_id': memberId},
  );

  Future<void> makeAdmin({required String tripId, required String memberId}) =>
      _client.from('trip_member_roles').upsert({
        'trip_id': tripId,
        'user_id': memberId,
        'role': 'admin',
      }, onConflict: 'trip_id,user_id,role');

  Future<void> removeAdmin({
    required String tripId,
    required String memberId,
  }) => _client
      .from('trip_member_roles')
      .delete()
      .eq('trip_id', tripId)
      .eq('user_id', memberId)
      .eq('role', 'admin');

  Future<void> addActivity({
    required String tripId,
    required String title,
    required DateTime startTime,
    String? location,
  }) => _client.from('trip_activities').insert({
    'trip_id': tripId,
    'title': title,
    'start_time': startTime.toUtc().toIso8601String(),
    'location': location,
  });

  Future<bool> submitActivityProposal({
    required String tripId,
    required String proposedBy,
    required String title,
    required DateTime startTime,
    String? location,
  }) async {
    try {
      await _client.from('trip_activity_proposals').insert({
        'trip_id': tripId,
        'proposed_by': proposedBy,
        'title': title.trim(),
        'start_time': startTime.toUtc().toIso8601String(),
        'location': (location?.trim().isEmpty ?? true)
            ? null
            : location!.trim(),
        'status': 'pending_approval',
      });
      _activityProposalEnabledTrips.add(tripId);
      return true;
    } on PostgrestException catch (error) {
      if (_isActivityProposalSchemaMissing(error)) {
        _activityProposalEnabledTrips.remove(tripId);
        debugPrint(
          '[activity_proposals] Schema unavailable; proposal was not submitted. '
          'code=${error.code}',
        );
        return false;
      }
      rethrow;
    }
  }

  Future<bool> reviewActivityProposal({
    required String proposalId,
    required bool accept,
  }) async {
    try {
      await _client.rpc(
        'review_trip_activity_proposal',
        params: {
          'p_proposal_id': proposalId,
          'p_decision': accept ? 'accepted' : 'rejected',
        },
      );
      return true;
    } on PostgrestException catch (error) {
      if (_isActivityProposalSchemaMissing(error) ||
          error.code == 'PGRST202' ||
          error.code == '42883' ||
          error.message.contains('review_trip_activity_proposal')) {
        debugPrint(
          '[activity_proposals] Review function unavailable. '
          'code=${error.code}',
        );
        return false;
      }
      rethrow;
    }
  }

  Future<void> addTimelineDay(
    String tripId,
    DateTime day,
  ) => _client.from('trip_timeline_days').insert({
    'trip_id': tripId,
    'day_date':
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
  });

  Future<int> deleteTimelineDay(String tripId, DateTime persistedDay) async {
    final dayStart = DateTime(
      persistedDay.year,
      persistedDay.month,
      persistedDay.day,
    );
    final dayEnd = DateTime(
      persistedDay.year,
      persistedDay.month,
      persistedDay.day + 1,
    );
    final dayDate =
        '${persistedDay.year.toString().padLeft(4, '0')}-'
        '${persistedDay.month.toString().padLeft(2, '0')}-'
        '${persistedDay.day.toString().padLeft(2, '0')}';
    final result = await _client.rpc(
      'delete_trip_timeline_day',
      params: {
        'p_trip_id': tripId,
        'p_day_date': dayDate,
        'p_day_start': dayStart.toUtc().toIso8601String(),
        'p_day_end': dayEnd.toUtc().toIso8601String(),
      },
    );
    return result as int? ?? 0;
  }

  Future<void> updateActivity(String activityId, Map<String, dynamic> values) =>
      _client.from('trip_activities').update(values).eq('id', activityId);

  Future<void> deleteActivity(String activityId) async {
    final deleted = await _client
        .from('trip_activities')
        .delete()
        .eq('id', activityId)
        .select('id');
    if ((deleted as List<dynamic>).isEmpty) {
      throw StateError(
        'The activity was not removed. Apply the latest Supabase migration and check your trip membership.',
      );
    }
  }

  Future<void> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
  }) async {
    final poll = await _client
        .from('trip_polls')
        .insert({'trip_id': tripId, 'question': question})
        .select('id')
        .single();
    final pollId = poll['id'] as String;
    await _client.from('trip_poll_options').insert([
      for (final option in options) {'poll_id': pollId, 'label': option},
    ]);
  }

  Future<void> castVote({required String pollId, required String optionId}) =>
      _client.rpc(
        'cast_trip_poll_vote',
        params: {'p_poll_id': pollId, 'p_option_id': optionId},
      );

  Future<String> uploadFile({
    required String tripId,
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final safeFileName = fileName
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final storagePath =
        '$tripId/${DateTime.now().microsecondsSinceEpoch}_${safeFileName.isEmpty ? 'attachment' : safeFileName}';
    await _client.storage
        .from('trip-documents')
        .uploadBinary(storagePath, bytes);
    final url = _client.storage
        .from('trip-documents')
        .getPublicUrl(storagePath);
    try {
      await _client.from('trip_files').insert({
        'trip_id': tripId,
        'file_name': fileName,
        'file_url': url,
        'storage_path': storagePath,
        'uploaded_by': userId,
        'file_size_bytes': bytes.length,
      });
    } catch (_) {
      await _client.storage.from('trip-documents').remove([storagePath]);
      rethrow;
    }
    return url;
  }

  Future<void> deleteFile(SharedTripFile file) async {
    await _client.storage.from('trip-documents').remove([file.storagePath]);
    await _client.from('trip_files').delete().eq('id', file.id);
  }

  Future<TripCall> startCall({
    required String tripId,
    required String type,
  }) async {
    final call = await _client
        .from('trip_calls')
        .insert({
          'trip_id': tripId,
          'call_type': type,
          'status': 'ringing',
          'had_video': type == 'video',
        })
        .select()
        .single();
    return TripCall.fromMap(call);
  }

  Future<void> joinCall(String callId) =>
      _client.rpc('join_trip_call', params: {'p_call_id': callId});

  Future<void> markCallVideoUsed(String callId) =>
      _client.rpc('mark_trip_call_video_used', params: {'p_call_id': callId});

  Future<int> leaveCall(String callId) async {
    final result = await _client.rpc(
      'leave_trip_call',
      params: {'p_call_id': callId},
    );
    return result as int? ?? 0;
  }

  Future<bool> finishCall({
    required String callId,
    required String reason,
    required bool hadVideo,
    required Duration duration,
  }) async {
    final result = await _client.rpc(
      'finish_trip_call',
      params: {
        'p_call_id': callId,
        'p_reason': reason,
        'p_had_video': hadVideo,
        'p_duration_seconds': duration.inSeconds,
      },
    );
    return result as bool? ?? false;
  }

  Future<void> setActivityRsvp({
    required String tripId,
    required String activityId,
    required String userId,
    required String status,
  }) => _client.from('trip_activity_rsvps').upsert({
    'trip_id': tripId,
    'activity_id': activityId,
    'user_id': userId,
    'status': status,
  }, onConflict: 'activity_id,user_id');

  Future<void> setTyping({
    required String tripId,
    required String userId,
    required bool isTyping,
  }) async {
    final query = _client.from('trip_typing_status');
    if (isTyping) {
      await query.upsert({
        'trip_id': tripId,
        'user_id': userId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'trip_id,user_id');
    } else {
      await query.delete().eq('trip_id', tripId).eq('user_id', userId);
    }
  }

  Future<void> markMessagesRead(String tripId) =>
      _client.rpc('mark_trip_messages_read', params: {'p_trip_id': tripId});

  Future<void> markCollaborationNotificationsRead(String tripId) => _client.rpc(
    'mark_trip_activity_events_read',
    params: {'p_trip_id': tripId},
  );

  Future<void> dismissRemovedGroup(String tripId) =>
      _client.rpc('dismiss_removed_trip_group', params: {'p_trip_id': tripId});

  Future<void> addActivityComment({
    required String tripId,
    required String activityId,
    required String authorId,
    required String body,
  }) => _client.from('trip_activity_comments').insert({
    'trip_id': tripId,
    'activity_id': activityId,
    'author_id': authorId,
    'body': body,
  });

  Future<void> recordEvent({
    required String tripId,
    required String actorId,
    required String type,
    required String summary,
  }) => _client.from('trip_activity_events').insert({
    'trip_id': tripId,
    'actor_id': actorId,
    'event_type': type,
    'summary': summary,
  });
}

class CollaborationAccessRemovedException implements Exception {
  const CollaborationAccessRemovedException();

  @override
  String toString() => 'You are no longer a member of this trip group.';
}
