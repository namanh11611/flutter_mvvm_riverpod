class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
}

class ShareableTrip {
  const ShareableTrip({
    required this.id,
    required this.destination,
    required this.endDate,
  });

  final String id;
  final String destination;
  final DateTime endDate;
}
