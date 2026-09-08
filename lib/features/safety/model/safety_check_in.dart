enum SafetyCheckInStatus { pending, safe, needsHelp, missed }

enum SafetyCheckInFrequency {
  fifteenMinutes(15, '15 minutes'),
  thirtyMinutes(30, '30 minutes'),
  oneHour(60, '1 hour'),
  twoHours(120, '2 hours'),
  custom(null, 'Custom');

  const SafetyCheckInFrequency(this.minutes, this.label);

  final int? minutes;
  final String label;
}

class SafetyCheckInConfiguration {
  const SafetyCheckInConfiguration({
    this.enabled = false,
    this.frequency = SafetyCheckInFrequency.oneHour,
    this.customIntervalMinutes = 60,
  });

  final bool enabled;
  final SafetyCheckInFrequency frequency;
  final int customIntervalMinutes;

  int get intervalMinutes => frequency.minutes ?? customIntervalMinutes;

  SafetyCheckInConfiguration copyWith({
    bool? enabled,
    SafetyCheckInFrequency? frequency,
    int? customIntervalMinutes,
  }) =>
      SafetyCheckInConfiguration(
        enabled: enabled ?? this.enabled,
        frequency: frequency ?? this.frequency,
        customIntervalMinutes:
            customIntervalMinutes ?? this.customIntervalMinutes,
      );
}

class SafetyCheckIn {
  const SafetyCheckIn({
    required this.id,
    required this.scheduledAt,
    required this.responseDeadline,
    required this.status,
    this.tripId,
    this.respondedAt,
  });

  final String id;
  final String? tripId;
  final DateTime scheduledAt;
  final DateTime responseDeadline;
  final DateTime? respondedAt;
  final SafetyCheckInStatus status;

  factory SafetyCheckIn.fromMap(Map<String, dynamic> map) => SafetyCheckIn(
        id: map['id'] as String,
        tripId: map['trip_id'] as String?,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        responseDeadline: DateTime.parse(map['response_deadline'] as String),
        respondedAt: map['responded_at'] == null
            ? null
            : DateTime.parse(map['responded_at'] as String),
        status: SafetyCheckInStatus.values.firstWhere(
          (value) => value.name == map['status'],
          orElse: () => SafetyCheckInStatus.pending,
        ),
      );
}
