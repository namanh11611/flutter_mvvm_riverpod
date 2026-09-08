class MatchmakingNotification {
  const MatchmakingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.tripId,
    this.readAt,
    this.dismissedAt,
    this.type,
  });

  final String id;
  final String title;
  final String body;
  final String? tripId;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final String? type;
  bool get isIdentityVerification => type == 'identity_verification';

  bool get isUnread => readAt == null;

  factory MatchmakingNotification.fromMap(Map<String, dynamic> map) =>
      MatchmakingNotification(
        id: map['id'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        tripId: map['trip_id'] as String?,
        type: (map['metadata'] as Map?)?['type'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        readAt: map['read_at'] == null
            ? null
            : DateTime.parse(map['read_at'] as String),
        dismissedAt: map['dismissed_at'] == null
            ? null
            : DateTime.parse(map['dismissed_at'] as String),
      );
}
