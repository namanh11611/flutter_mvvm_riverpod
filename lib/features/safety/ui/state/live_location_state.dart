import '../../model/location_data.dart';

/// Sentinel used by the duration picker when sharing should last for the
/// remainder of the selected trip instead of a fixed amount of time.
const untilTripEndsDuration = Duration.zero;

class LiveLocationState {
  const LiveLocationState({
    this.trips = const [],
    this.selectedTripId,
    this.duration = const Duration(hours: 1),
    this.location,
    this.expiresAt,
    this.isLoading = false,
    this.isStarting = false,
    this.isSharing = false,
    this.error,
  });

  final List<ShareableTrip> trips;
  final String? selectedTripId;
  final Duration duration;
  final LocationData? location;
  final DateTime? expiresAt;
  final bool isLoading;
  final bool isStarting;
  final bool isSharing;
  final String? error;

  LiveLocationState copyWith({
    List<ShareableTrip>? trips,
    String? selectedTripId,
    Duration? duration,
    LocationData? location,
    DateTime? expiresAt,
    bool? isLoading,
    bool? isStarting,
    bool? isSharing,
    String? error,
    bool clearError = false,
    bool clearShare = false,
  }) =>
      LiveLocationState(
        trips: trips ?? this.trips,
        selectedTripId: selectedTripId ?? this.selectedTripId,
        duration: duration ?? this.duration,
        location: clearShare ? null : location ?? this.location,
        expiresAt: clearShare ? null : expiresAt ?? this.expiresAt,
        isLoading: isLoading ?? this.isLoading,
        isStarting: isStarting ?? this.isStarting,
        isSharing: isSharing ?? this.isSharing,
        error: clearError ? null : error ?? this.error,
      );
}
