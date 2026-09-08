class SharedLiveLocation {
  const SharedLiveLocation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    required this.expiresAt,
  });

  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime recordedAt;
  final DateTime expiresAt;

  bool isActiveAt(DateTime time) => expiresAt.isAfter(time);

  factory SharedLiveLocation.fromMap(Map<String, dynamic> map) =>
      SharedLiveLocation(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        accuracy: (map['accuracy'] as num).toDouble(),
        recordedAt: DateTime.parse(map['recorded_at'] as String).toLocal(),
        expiresAt: DateTime.parse(map['expires_at'] as String).toLocal(),
      );
}
