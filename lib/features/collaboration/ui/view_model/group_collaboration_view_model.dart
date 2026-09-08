import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/model/collaboration_models.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/repository/collaboration_repository.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';

final groupCollaborationViewModelProvider =
    AsyncNotifierProvider.family<
      GroupCollaborationViewModel,
      GroupCollaborationState,
      String
    >(GroupCollaborationViewModel.new);

class GroupCollaborationViewModel
    extends AsyncNotifier<GroupCollaborationState> {
  GroupCollaborationViewModel(this._tripId);

  final String _tripId;
  late CollaborationRepository _repository;
  RealtimeChannel? _channel;

  @override
  Future<GroupCollaborationState> build() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Please sign in before opening a trip workspace.');
    }
    _repository = ref.read(collaborationRepositoryProvider);
    final channel = await _repository.subscribe(
      _tripId,
      () => ref.invalidateSelf(),
    );
    _channel = channel;
    ref.onDispose(() {
      supabase.removeChannel(channel);
      if (identical(_channel, channel)) _channel = null;
    });
    try {
      // Load after the room subscription is live so an invitation cannot land
      // in the old snapshot-before-subscribe race window.
      return await _repository
          .loadWorkspace(tripId: _tripId, currentUserId: userId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'The trip workspace took too long to load. Check your Supabase connection and trip membership.',
            ),
          );
    } catch (_) {
      await supabase.removeChannel(channel);
      if (identical(_channel, channel)) _channel = null;
      rethrow;
    }
  }

  GroupCollaborationState? get _current {
    final currentState = state;
    return switch (currentState) {
      AsyncData<GroupCollaborationState>(:final value) => value,
      _ => null,
    };
  }

  Future<void> sendMessage(String body) async {
    final current = _current;
    if (current == null || body.trim().isEmpty) {
      return;
    }
    final activeUserId = supabase.auth.currentUser?.id;
    if (activeUserId == null) {
      throw StateError('Please sign in before sending a message.');
    }
    if (activeUserId != current.currentUserId) {
      // Never send with identity cached from a previous account. Rebuilding
      // also fixes which messages are labelled as "You".
      ref.invalidateSelf();
      throw StateError(
        'Your account changed. The group was refreshed; please send again.',
      );
    }
    if (current.isMuted) {
      throw StateError(
        'You are muted until the trip creator enables chat again.',
      );
    }
    await _repository.sendMessage(current.tripId, activeUserId, body.trim());
    await _repository.setTyping(
      tripId: current.tripId,
      userId: activeUserId,
      isTyping: false,
    );
    // Show the sender's message immediately after a successful insert.
    // Realtime remains useful for other members; the sender does not need a reply.
    ref.invalidateSelf();
  }

  Future<void> muteMember(String memberId, Duration duration) async {
    final current = _requireMemberManager();
    await _repository.setMutedUntil(
      tripId: current.tripId,
      memberId: memberId,
      mutedUntil: DateTime.now().add(duration),
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'member_muted',
      summary:
          '${_memberName(current, current.currentUserId)} muted ${_memberName(current, memberId)}.',
    );
    ref.invalidateSelf();
  }

  Future<void> unmuteMember(String memberId) async {
    final current = _requireMemberManager();
    await _repository.setMutedUntil(
      tripId: current.tripId,
      memberId: memberId,
      mutedUntil: null,
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'member_unmuted',
      summary:
          '${_memberName(current, current.currentUserId)} unmuted ${_memberName(current, memberId)}.',
    );
    ref.invalidateSelf();
  }

  Future<void> removeMember(String memberId) async {
    final current = _requireMemberManager();
    if (memberId == current.creatorId) {
      throw StateError('The trip creator cannot be removed.');
    }
    await _repository.removeMember(current.tripId, memberId);
    // Update the owner's traveller count immediately. Other sessions receive
    // the same membership deletion through Supabase Realtime.
    unawaited(ref.read(matchmakingViewModelProvider.notifier).refresh());
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'member_removed',
      summary:
          '${_memberName(current, current.currentUserId)} removed ${_memberName(current, memberId)} from the group.',
    );
    ref.invalidateSelf();
  }

  Future<void> makeAdmin(String memberId) async {
    final current = _requireCreator();
    if (memberId == current.creatorId) {
      throw StateError('The trip creator already has admin permissions.');
    }
    await _repository.makeAdmin(tripId: current.tripId, memberId: memberId);
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'admin_assigned',
      summary:
          '${_memberName(current, current.currentUserId)} made ${_memberName(current, memberId)} an admin.',
    );
    ref.invalidateSelf();
  }

  Future<void> removeAdmin(String memberId) async {
    final current = _requireCreator();
    await _repository.removeAdmin(tripId: current.tripId, memberId: memberId);
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'admin_removed',
      summary:
          '${_memberName(current, current.currentUserId)} removed admin access from ${_memberName(current, memberId)}.',
    );
    ref.invalidateSelf();
  }

  Future<void> addActivity({
    required String title,
    required DateTime startTime,
    String? location,
  }) async {
    final current = _requireMemberManager();
    await _repository.addActivity(
      tripId: current.tripId,
      title: title,
      startTime: startTime,
      location: location,
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'activity_created',
      summary: 'An activity was added to the timeline: ${title.trim()}.',
    );
    ref.invalidateSelf();
  }

  Future<bool> proposeActivity({
    required String title,
    required DateTime startTime,
    String? location,
  }) async {
    final current = _current;
    if (current == null) return false;
    if (current.canManageMembers) {
      throw StateError('Admins should add activities directly.');
    }
    final submitted = await _repository.submitActivityProposal(
      tripId: current.tripId,
      proposedBy: current.currentUserId,
      title: title,
      startTime: startTime,
      location: location,
    );
    if (!submitted) return false;
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'activity_proposal_submitted',
      summary: 'An activity was proposed for admin review: ${title.trim()}.',
    );
    ref.invalidateSelf();
    return true;
  }

  Future<bool> reviewActivityProposal(
    TripActivityProposal proposal, {
    required bool accept,
  }) async {
    final current = _requireMemberManager();
    final reviewed = await _repository.reviewActivityProposal(
      proposalId: proposal.id,
      accept: accept,
    );
    if (!reviewed) return false;
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: accept
          ? 'activity_proposal_accepted'
          : 'activity_proposal_rejected',
      summary: accept
          ? 'Activity proposal approved: ${proposal.title}.'
          : 'Activity proposal rejected: ${proposal.title}.',
    );
    ref.invalidateSelf();
    return true;
  }

  Future<void> addTimelineDay(DateTime day) async {
    final current = _requireMemberManager();
    final selectedDay = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isBefore(today)) {
      throw StateError('Past dates cannot be added to the trip schedule.');
    }
    final alreadyExists =
        current.timelineDays.any(
          (existing) => _sameCalendarDay(existing, selectedDay),
        ) ||
        current.activities.any(
          (activity) => _sameCalendarDay(activity.startTime, selectedDay),
        );
    if (alreadyExists) {
      throw StateError('This date is already in the trip itinerary.');
    }
    try {
      await _repository.addTimelineDay(current.tripId, selectedDay);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw StateError('This date is already in the trip itinerary.');
      }
      rethrow;
    }
    ref.invalidateSelf();
  }

  Future<int> deleteTimelineDay(DateTime day) async {
    final current = _requireMemberManager();
    final selectedDay = DateTime(day.year, day.month, day.day);
    DateTime? persistedDay;
    for (final candidate in current.timelineDays) {
      if (_sameCalendarDay(candidate, selectedDay)) {
        persistedDay = candidate;
        break;
      }
    }
    if (persistedDay == null) {
      ref.invalidateSelf();
      throw StateError(
        'This timeline day no longer exists. The schedule has been refreshed.',
      );
    }

    late final int deletedActivities;
    try {
      deletedActivities = await _repository.deleteTimelineDay(
        current.tripId,
        persistedDay,
      );
    } on PostgrestException catch (error) {
      if (error.code == 'P0001' &&
          error.message.toLowerCase().contains('timeline day not found')) {
        ref.invalidateSelf();
        throw StateError(
          'This timeline day no longer exists. The schedule has been refreshed.',
        );
      }
      rethrow;
    }
    final dateLabel =
        '${selectedDay.day}/${selectedDay.month}/${selectedDay.year}';
    try {
      await _repository.sendMessage(
        current.tripId,
        current.currentUserId,
        '[system]Schedule day removed: $dateLabel'
        '${deletedActivities == 0 ? '' : ' ($deletedActivities activities removed)'}',
      );
    } catch (_) {
      // Day deletion is already committed; a muted member may not post chat.
    }
    try {
      await _repository.recordEvent(
        tripId: current.tripId,
        actorId: current.currentUserId,
        type: 'activity_removed',
        summary:
            'Schedule day $dateLabel was removed with $deletedActivities activities.',
      );
    } catch (_) {
      // Realtime day/activity changes still update every workspace member.
    }
    ref.invalidateSelf();
    return deletedActivities;
  }

  Future<void> togglePin(TripActivity activity) async {
    final current = _requireMemberManager();
    await _repository.updateActivity(activity.id, {
      'is_pinned': !activity.isPinned,
    });
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'activity_pinned',
      summary:
          '${activity.title} was ${activity.isPinned ? 'unpinned' : 'pinned'}.',
    );
    ref.invalidateSelf();
  }

  Future<void> createActivityPoll({
    required String question,
    required List<String> options,
  }) async {
    final current = _current;
    final cleanedOptions = options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    if (current == null ||
        question.trim().isEmpty ||
        cleanedOptions.length < 2) {
      throw StateError('Enter a question and at least two poll options.');
    }
    await _repository.createPoll(
      tripId: current.tripId,
      question: question.trim(),
      options: cleanedOptions,
    );
    ref.invalidateSelf();
  }

  Future<void> editActivity({
    required TripActivity activity,
    required String title,
    required DateTime startTime,
    String? location,
  }) async {
    final current = _requireMemberManager();
    await _repository.updateActivity(activity.id, {
      'title': title,
      'start_time': startTime.toUtc().toIso8601String(),
      'location': location,
    });
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'activity_edited',
      summary: 'Activity updated: ${title.trim()}.',
    );
    ref.invalidateSelf();
  }

  Future<void> deleteActivity(TripActivity activity) async {
    final current = _requireMemberManager();
    await _repository.deleteActivity(activity.id);
    await _repository.sendMessage(
      current.tripId,
      current.currentUserId,
      '[system]Activity removed: ${activity.title}',
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'activity_removed',
      summary: 'Activity removed: ${activity.title}.',
    );
    ref.invalidateSelf();
  }

  Future<void> shareActivityToChat(TripActivity activity) async {
    final current = _current;
    if (current == null) return;
    final location = activity.location?.trim();
    await _repository.sendMessage(
      current.tripId,
      current.currentUserId,
      '[activity_share]${activity.id}|${activity.title}|${activity.startTime.toIso8601String()}|${location ?? ''}',
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'activity_shared',
      summary: 'Shared ${activity.title} to the group chat.',
    );
    ref.invalidateSelf();
  }

  Future<void> castVote(String pollId, String optionId) async {
    final current = _current;
    if (current == null) return;
    await _repository.castVote(pollId: pollId, optionId: optionId);
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'vote_cast',
      summary: 'A member voted in an activity poll.',
    );
    ref.invalidateSelf();
  }

  Future<void> setActivityRsvp({
    required String activityId,
    required String status,
  }) async {
    final current = _current;
    if (current == null) return;
    await _repository.setActivityRsvp(
      tripId: current.tripId,
      activityId: activityId,
      userId: current.currentUserId,
      status: status,
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'rsvp_updated',
      summary:
          '${_memberName(current, current.currentUserId)} responded "$status" to an activity.',
    );
    ref.invalidateSelf();
  }

  Future<void> setTyping(bool isTyping) async {
    final current = _current;
    if (current == null) return;
    await _repository.setTyping(
      tripId: current.tripId,
      userId: current.currentUserId,
      isTyping: isTyping,
    );
  }

  Future<void> markMessagesRead() async {
    final current = _current;
    if (current == null) return;
    await _repository.markMessagesRead(current.tripId);
  }

  Future<void> markCollaborationNotificationsRead() async {
    final current = _current;
    if (current == null || current.unreadNotifications.isEmpty) return;
    await _repository.markCollaborationNotificationsRead(current.tripId);
    ref.invalidateSelf();
  }

  Future<void> pickAndShareFile() async {
    final current = _current;
    if (current == null) return;
    final picked = await FilePicker.platform.pickFiles(withData: true);
    final file = picked == null || picked.files.isEmpty
        ? null
        : picked.files.first;
    if (file == null || file.bytes == null) return;
    await _repository.uploadFile(
      tripId: current.tripId,
      userId: current.currentUserId,
      fileName: file.name,
      bytes: file.bytes!,
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'file_shared',
      summary: 'A file was shared with the group: ${file.name}.',
    );
    ref.invalidateSelf();
  }

  Future<void> takeAndSharePhoto() async {
    final current = _current;
    if (current == null) return;
    if (current.isMuted) {
      throw StateError(
        'You are muted until the trip creator enables chat again.',
      );
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final url = await _repository.uploadFile(
      tripId: current.tripId,
      userId: current.currentUserId,
      fileName: image.name.isEmpty ? 'photo.jpg' : image.name,
      bytes: bytes,
    );
    await _repository.sendMessage(
      current.tripId,
      current.currentUserId,
      '[photo]$url',
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'file_shared',
      summary: 'A photo was shared with the group.',
    );
    ref.invalidateSelf();
  }

  Future<void> shareVoiceMessage(
    Uint8List bytes, {
    String fileExtension = 'm4a',
  }) async {
    final current = _current;
    if (current == null || bytes.isEmpty) return;
    if (current.isMuted) {
      throw StateError(
        'You are muted until the trip creator enables chat again.',
      );
    }
    final url = await _repository.uploadFile(
      tripId: current.tripId,
      userId: current.currentUserId,
      fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
      bytes: bytes,
    );
    await _repository.sendMessage(
      current.tripId,
      current.currentUserId,
      '[voice]$url',
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'file_shared',
      summary: 'A voice message was shared with the group.',
    );
    ref.invalidateSelf();
  }

  Future<TripCall?> startCall(String type) async {
    final current = _current;
    if (current == null) return null;
    final call = await _repository.startCall(
      tripId: current.tripId,
      type: type,
    );
    try {
      await _repository.broadcastCallInvite(
        tripId: current.tripId,
        call: call,
        callerName: _memberName(current, current.currentUserId),
      );
    } catch (error) {
      // The persisted trip_calls row remains a reliable fallback invitation.
      debugPrint(
        '[group_call] signaling_send_to_group failed '
        'trip_id=${current.tripId} call_id=${call.id} error=$error',
      );
    }
    debugPrint(
      '[group_call] room_joined_members call_id=${call.id} '
      'invited_members=${current.members.length}',
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'call_started',
      summary: 'A ${type.trim()} call was started.',
    );
    ref.invalidateSelf();
    return call;
  }

  Future<TripCall?> joinCall(TripCall call) async {
    final current = _current;
    if (current == null || call.status == 'ended') return null;
    if (call.status == 'ringing') {
      await _repository.joinCall(call.id);
    }
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'call_joined',
      summary: 'A member joined a ${call.callType} call.',
    );
    ref.invalidateSelf();
    return call.copyWith(
      status: 'active',
      connectedAt: call.connectedAt ?? DateTime.now(),
    );
  }

  Future<void> markCallVideoUsed(TripCall call) async {
    await _repository.markCallVideoUsed(call.id);
    ref.invalidateSelf();
  }

  Future<void> leaveCall(
    TripCall call, {
    required String reason,
    required bool hadVideo,
    required Duration duration,
  }) async {
    final current = _current;
    if (current == null) return;
    final remainingParticipants = await _repository.leaveCall(call.id);
    if (remainingParticipants == 0) {
      await endCall(
        call,
        reason: reason,
        hadVideo: hadVideo,
        duration: duration,
      );
      return;
    }
    ref.invalidateSelf();
  }

  Future<void> endCall(
    TripCall call, {
    String? reason,
    bool? hadVideo,
    Duration? duration,
  }) async {
    final current = _current;
    if (current == null) return;
    final completedDuration =
        duration ??
        (call.connectedAt == null
            ? Duration.zero
            : DateTime.now().difference(call.connectedAt!));
    final finalReason =
        reason ??
        (call.status == 'active'
            ? 'completed'
            : call.initiatedBy == current.currentUserId
            ? 'cancelled'
            : 'missed');
    final ended = await _repository.finishCall(
      callId: call.id,
      reason: finalReason,
      hadVideo: hadVideo ?? call.isVideo,
      duration: completedDuration,
    );
    if (!ended) return;
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'call_ended',
      summary:
          '${_memberName(current, current.currentUserId)} ended a ${(hadVideo ?? call.isVideo) ? 'video' : 'voice'} call.',
    );
    ref.invalidateSelf();
  }

  Future<void> deleteFile(SharedTripFile file) async {
    final current = _current;
    if (current == null ||
        (file.uploadedBy != current.currentUserId &&
            !current.canManageMembers)) {
      throw StateError('Only the uploader or an admin can delete this file.');
    }
    await _repository.deleteFile(file);
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'file_deleted',
      summary:
          '${_memberName(current, current.currentUserId)} removed ${file.name}.',
    );
    ref.invalidateSelf();
  }

  Future<void> addActivityComment({
    required String activityId,
    required String body,
  }) async {
    final current = _current;
    if (current == null || body.trim().isEmpty) return;
    await _repository.addActivityComment(
      tripId: current.tripId,
      activityId: activityId,
      authorId: current.currentUserId,
      body: body.trim(),
    );
    await _repository.recordEvent(
      tripId: current.tripId,
      actorId: current.currentUserId,
      type: 'comment_added',
      summary: 'A new activity comment was added.',
    );
    ref.invalidateSelf();
  }

  GroupCollaborationState _requireMemberManager() {
    final current = _current;
    if (current == null || !current.canManageMembers) {
      throw StateError(
        'Only the trip creator or an admin can perform this action.',
      );
    }
    return current;
  }

  GroupCollaborationState _requireCreator() {
    final current = _current;
    if (current == null || !current.isCreator) {
      throw StateError('Only the trip creator can lock an activity.');
    }
    return current;
  }

  String _memberName(GroupCollaborationState state, String userId) {
    if (userId == state.currentUserId) return 'You';
    return state.members
            .where((member) => member.userId == userId)
            .map((member) => member.displayName)
            .whereType<String>()
            .firstOrNull ??
        'A member';
  }
}

bool _sameCalendarDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
