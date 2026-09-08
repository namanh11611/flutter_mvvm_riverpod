class CollaborationMember {
  const CollaborationMember({
    required this.userId,
    this.displayName,
    this.profilePhotoUrl,
    this.mutedUntil,
    this.isAdmin = false,
  });

  final String userId;
  final String? displayName;
  final String? profilePhotoUrl;
  final DateTime? mutedUntil;
  final bool isAdmin;

  bool get isMuted => mutedUntil?.isAfter(DateTime.now()) ?? false;

  factory CollaborationMember.fromMap(
    Map<String, dynamic> map, {
    String? displayName,
    String? profilePhotoUrl,
    bool isAdmin = false,
  }) => CollaborationMember(
    userId: map['user_id'] as String,
    displayName: displayName,
    profilePhotoUrl: profilePhotoUrl,
    isAdmin: isAdmin,
    mutedUntil: map['muted_until'] == null
        ? null
        : DateTime.parse(map['muted_until'] as String).toLocal(),
  );
}

class TripCall {
  const TripCall({
    required this.id,
    required this.initiatedBy,
    required this.callType,
    required this.status,
    required this.createdAt,
    this.initiatedByName,
    this.connectedAt,
    this.endedAt,
    this.endReason,
    this.durationSeconds,
    this.hadVideo = false,
  });

  final String id;
  final String initiatedBy;
  final String callType;
  final String status;
  final DateTime createdAt;
  final String? initiatedByName;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final String? endReason;
  final int? durationSeconds;
  final bool hadVideo;

  bool get isVideo => hadVideo || callType == 'video';

  TripCall copyWith({
    String? callType,
    String? status,
    DateTime? connectedAt,
    bool? hadVideo,
  }) => TripCall(
    id: id,
    initiatedBy: initiatedBy,
    callType: callType ?? this.callType,
    status: status ?? this.status,
    createdAt: createdAt,
    initiatedByName: initiatedByName,
    connectedAt: connectedAt ?? this.connectedAt,
    endedAt: endedAt,
    endReason: endReason,
    durationSeconds: durationSeconds,
    hadVideo: hadVideo ?? this.hadVideo,
  );

  factory TripCall.fromMap(
    Map<String, dynamic> map, {
    String? initiatedByName,
  }) => TripCall(
    id: map['id'] as String,
    initiatedBy: map['initiated_by'] as String,
    callType: map['call_type'] as String,
    status: map['status'] as String,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    initiatedByName: initiatedByName,
    connectedAt: map['connected_at'] == null
        ? null
        : DateTime.parse(map['connected_at'] as String).toLocal(),
    endedAt: map['ended_at'] == null
        ? null
        : DateTime.parse(map['ended_at'] as String).toLocal(),
    endReason: map['end_reason'] as String?,
    durationSeconds: map['duration_seconds'] as int?,
    hadVideo: map['had_video'] as bool? ?? false,
  );
}

class TripMessage {
  const TripMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.senderName,
    this.readByCount = 0,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final String? senderName;
  final int readByCount;

  factory TripMessage.fromMap(
    Map<String, dynamic> map, {
    String? senderName,
    int readByCount = 0,
  }) => TripMessage(
    id: map['id'] as String,
    senderId: map['sender_id'] as String,
    body: map['body'] as String,
    sentAt: DateTime.parse(map['sent_at'] as String).toLocal(),
    senderName: senderName,
    readByCount: readByCount,
  );
}

class TripActivity {
  const TripActivity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.location,
    required this.isPinned,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final String? location;
  final bool isPinned;

  factory TripActivity.fromMap(Map<String, dynamic> map) => TripActivity(
    id: map['id'] as String,
    title: map['title'] as String,
    startTime: DateTime.parse(map['start_time'] as String).toLocal(),
    location: map['location'] as String?,
    isPinned: map['is_pinned'] as bool? ?? false,
  );
}

class ActivityRsvp {
  const ActivityRsvp({
    required this.activityId,
    required this.userId,
    required this.status,
  });

  final String activityId;
  final String userId;
  final String status;

  factory ActivityRsvp.fromMap(Map<String, dynamic> map) => ActivityRsvp(
    activityId: map['activity_id'] as String,
    userId: map['user_id'] as String,
    status: map['status'] as String,
  );
}

class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.voterIds,
  });

  final String id;
  final String label;
  final List<String> voterIds;
}

class ActivityPoll {
  const ActivityPoll({
    required this.id,
    required this.question,
    required this.options,
  });

  final String id;
  final String question;
  final List<PollOption> options;
}

class SharedTripFile {
  const SharedTripFile({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadedBy,
    required this.createdAt,
    required this.storagePath,
    this.uploadedByName,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final String url;
  final String uploadedBy;
  final String? uploadedByName;
  final int? sizeBytes;
  final DateTime createdAt;
  final String storagePath;

  factory SharedTripFile.fromMap(
    Map<String, dynamic> map, {
    String? uploadedByName,
  }) => SharedTripFile(
    id: map['id'] as String,
    name: map['file_name'] as String,
    url: map['file_url'] as String,
    storagePath: map['storage_path'] as String,
    uploadedBy: map['uploaded_by'] as String,
    uploadedByName: uploadedByName,
    sizeBytes: map['file_size_bytes'] as int?,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}

class ActivityComment {
  const ActivityComment({
    required this.id,
    required this.activityId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String activityId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory ActivityComment.fromMap(Map<String, dynamic> map) => ActivityComment(
    id: map['id'] as String,
    activityId: map['activity_id'] as String,
    authorId: map['author_id'] as String,
    body: map['body'] as String,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}

class CollaborationNotification {
  const CollaborationNotification({
    required this.id,
    required this.actorId,
    required this.eventType,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String eventType;
  final String summary;
  final DateTime createdAt;

  factory CollaborationNotification.fromMap(Map<String, dynamic> map) =>
      CollaborationNotification(
        id: map['id'] as String,
        actorId: map['actor_id'] as String,
        eventType: map['event_type'] as String,
        summary: map['summary'] as String,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

class TripActivityProposal {
  const TripActivityProposal({
    required this.id,
    required this.tripId,
    required this.proposedBy,
    required this.title,
    required this.startTime,
    required this.status,
    required this.createdAt,
    this.proposedByName,
    this.location,
  });

  final String id;
  final String tripId;
  final String proposedBy;
  final String? proposedByName;
  final String title;
  final String? location;
  final DateTime startTime;
  final String status;
  final DateTime createdAt;

  bool get isPending => status == 'pending_approval';

  factory TripActivityProposal.fromMap(
    Map<String, dynamic> map, {
    String? proposedByName,
  }) => TripActivityProposal(
    id: map['id'] as String,
    tripId: map['trip_id'] as String,
    proposedBy: map['proposed_by'] as String,
    proposedByName: proposedByName,
    title: map['title'] as String,
    location: map['location'] as String?,
    startTime: DateTime.parse(map['start_time'] as String).toLocal(),
    status: map['status'] as String,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}

class GroupCollaborationState {
  const GroupCollaborationState({
    required this.tripId,
    this.tripTitle = 'Trip',
    this.tripStartDate,
    this.tripEndDate,
    required this.currentUserId,
    required this.creatorId,
    required this.isAdmin,
    required this.members,
    required this.messages,
    required this.activities,
    this.activityProposals = const [],
    this.timelineDays = const [],
    required this.polls,
    required this.files,
    required this.comments,
    required this.notifications,
    this.readNotificationIds = const {},
    required this.calls,
    required this.rsvps,
    required this.typingMemberNames,
  });

  final String tripId;
  final String tripTitle;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final String currentUserId;
  final String creatorId;
  final bool isAdmin;
  final List<CollaborationMember> members;
  final List<TripMessage> messages;
  final List<TripActivity> activities;
  final List<TripActivityProposal> activityProposals;
  final List<DateTime> timelineDays;
  final List<ActivityPoll> polls;
  final List<SharedTripFile> files;
  final List<ActivityComment> comments;
  final List<CollaborationNotification> notifications;
  final Set<String> readNotificationIds;
  final List<TripCall> calls;
  final List<ActivityRsvp> rsvps;
  final List<String> typingMemberNames;

  bool get isCreator => currentUserId == creatorId;
  List<TripActivityProposal> get pendingActivityProposals => activityProposals
      .where((proposal) => proposal.isPending)
      .toList(growable: false);
  int? get tripDurationDays {
    final start = tripStartDate;
    final end = tripEndDate;
    if (start == null || end == null) return null;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final duration = endDay.difference(startDay).inDays + 1;
    return duration < 1 ? 1 : duration;
  }

  List<CollaborationNotification> get unreadNotifications => notifications
      .where((notification) => !readNotificationIds.contains(notification.id))
      .toList(growable: false);
  bool get canManageMembers => isCreator || isAdmin;
  bool get isMuted => members
      .where((member) => member.userId == currentUserId)
      .any((member) => member.isMuted);
}
