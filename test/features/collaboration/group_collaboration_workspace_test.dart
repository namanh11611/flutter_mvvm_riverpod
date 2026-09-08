import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/model/collaboration_models.dart';

void main() {
  GroupCollaborationState workspace({
    String currentUserId = 'owner',
    String creatorId = 'owner',
    bool isAdmin = false,
  }) => GroupCollaborationState(
    tripId: 'trip-1',
    currentUserId: currentUserId,
    creatorId: creatorId,
    isAdmin: isAdmin,
    members: const [],
    messages: const [],
    activities: const [],
    polls: const [],
    files: const [],
    comments: const [],
    notifications: const [],
    calls: const [],
    rsvps: const [],
    typingMemberNames: const [],
  );

  test('only the creator or an admin can manage members', () {
    expect(workspace().canManageMembers, isTrue);
    expect(
      workspace(
        currentUserId: 'admin',
        creatorId: 'owner',
        isAdmin: true,
      ).canManageMembers,
      isTrue,
    );
    expect(
      workspace(currentUserId: 'member', creatorId: 'owner').canManageMembers,
      isFalse,
    );
  });

  test('keeps selected trip metadata and trip-specific navigation paths', () {
    final state = GroupCollaborationState(
      tripId: 'trip/one',
      tripTitle: 'Kyoto Autumn Trip',
      tripStartDate: DateTime(2026, 10, 4),
      tripEndDate: DateTime(2026, 10, 8),
      currentUserId: 'owner',
      creatorId: 'owner',
      isAdmin: false,
      members: const [],
      messages: const [],
      activities: const [],
      polls: const [],
      files: const [],
      comments: const [],
      notifications: const [],
      calls: const [],
      rsvps: const [],
      typingMemberNames: const [],
    );

    expect(state.tripTitle, 'Kyoto Autumn Trip');
    expect(state.tripStartDate, DateTime(2026, 10, 4));
    expect(state.tripDurationDays, 5);
    expect(Routes.tripTimeline(state.tripId), '/trip/trip%2Fone/timeline');
    expect(Routes.tripMessages(state.tripId), '/trip/trip%2Fone/messages');
  });

  test('real workspace member roles and mute state are represented', () {
    final member = CollaborationMember(
      userId: 'member',
      displayName: 'Aina',
      isAdmin: true,
      mutedUntil: DateTime.now().add(const Duration(minutes: 30)),
    );

    expect(member.displayName, 'Aina');
    expect(member.isAdmin, isTrue);
    expect(member.isMuted, isTrue);
  });

  test('keeps pending activity proposals out of official activities', () {
    final proposal = TripActivityProposal.fromMap({
      'id': 'proposal-1',
      'trip_id': 'trip-1',
      'proposed_by': 'member',
      'title': 'Sunrise hike',
      'location': 'Mount Batur',
      'start_time': '2026-10-05T22:00:00.000Z',
      'status': 'pending_approval',
      'created_at': '2026-09-02T12:00:00.000Z',
    }, proposedByName: 'Aina');
    final state = GroupCollaborationState(
      tripId: 'trip-1',
      currentUserId: 'admin',
      creatorId: 'owner',
      isAdmin: true,
      members: const [],
      messages: const [],
      activities: const [],
      activityProposals: [proposal],
      polls: const [],
      files: const [],
      comments: const [],
      notifications: const [],
      calls: const [],
      rsvps: const [],
      typingMemberNames: const [],
    );

    expect(state.activities, isEmpty);
    expect(state.pendingActivityProposals, [proposal]);
    expect(proposal.proposedByName, 'Aina');
  });

  test('maps a Supabase call-history row for the shared RTC call', () {
    final call = TripCall.fromMap({
      'id': 'call-1',
      'initiated_by': 'owner',
      'call_type': 'video',
      'status': 'ringing',
      'created_at': '2026-08-25T12:00:00.000Z',
    }, initiatedByName: 'Thai Hong');

    expect(call.isVideo, isTrue);
    expect(call.initiatedByName, 'Thai Hong');
    expect(call.status, 'ringing');
  });

  test('maps a live collaboration event from Supabase', () {
    final event = CollaborationNotification.fromMap({
      'id': 'event-1',
      'actor_id': 'member',
      'event_type': 'file_shared',
      'summary': 'A file was shared with the group: booking.pdf.',
      'created_at': '2026-08-25T12:00:00.000Z',
    });

    expect(event.eventType, 'file_shared');
    expect(event.summary, contains('booking.pdf'));
  });

  test('represents RSVP and typing status from the real workspace', () {
    final rsvp = ActivityRsvp.fromMap({
      'activity_id': 'activity-1',
      'user_id': 'member',
      'status': 'going',
    });
    final state = workspace();

    expect(rsvp.status, 'going');
    expect(rsvp.activityId, 'activity-1');
    expect(state.typingMemberNames, isEmpty);
  });

  test('shared file includes metadata used by uploader/admin controls', () {
    final file = SharedTripFile.fromMap({
      'id': 'file-1',
      'file_name': 'booking.pdf',
      'file_url': 'https://example.com/booking.pdf',
      'storage_path': 'trip-1/booking.pdf',
      'uploaded_by': 'member',
      'file_size_bytes': 2048,
      'created_at': '2026-08-25T12:00:00.000Z',
    }, uploadedByName: 'Aina');

    expect(file.uploadedByName, 'Aina');
    expect(file.sizeBytes, 2048);
    expect(file.storagePath, 'trip-1/booking.pdf');
  });
}
