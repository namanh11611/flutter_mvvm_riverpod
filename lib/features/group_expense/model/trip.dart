class Trip {
  const Trip({
    required this.tripId,
    required this.destination,
    required this.startDate,
    required this.endDate,
  });

  final String tripId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  factory Trip.fromMap(Map<String, Object?> map) => Trip(
        tripId: map['trip_id']!.toString(),
        destination: map['destination']! as String,
        startDate: DateTime.parse(map['start_date']! as String),
        endDate: DateTime.parse(map['end_date']! as String),
      );
}
