import '../../model/emergency_service.dart';
import '../../model/location_data.dart';

class SosState {
  const SosState({
    this.isLocating = false,
    this.isRefreshing = false,
    this.isTriggering = false,
    this.location,
    this.countryCode,
    this.locationLabel,
    this.numbers,
    this.message,
    this.usingCache = false,
  });

  final bool isLocating;
  final bool isRefreshing;
  final bool isTriggering;
  final LocationData? location;
  final String? countryCode;
  final String? locationLabel;
  final EmergencyNumbers? numbers;
  final String? message;
  final bool usingCache;

  SosState copyWith({
    bool? isLocating,
    bool? isRefreshing,
    bool? isTriggering,
    LocationData? location,
    String? countryCode,
    String? locationLabel,
    EmergencyNumbers? numbers,
    String? message,
    bool? usingCache,
    bool clearMessage = false,
    bool clearEmergencyData = false,
  }) =>
      SosState(
        isLocating: isLocating ?? this.isLocating,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isTriggering: isTriggering ?? this.isTriggering,
        location: location ?? this.location,
        countryCode: clearEmergencyData ? null : countryCode ?? this.countryCode,
        locationLabel:
            clearEmergencyData ? null : locationLabel ?? this.locationLabel,
        numbers: clearEmergencyData ? null : numbers ?? this.numbers,
        message: clearMessage ? null : message ?? this.message,
        usingCache: clearEmergencyData ? false : usingCache ?? this.usingCache,
      );
}
