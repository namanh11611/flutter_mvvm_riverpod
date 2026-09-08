import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../model/location_data.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

abstract interface class LocationService {
  Future<void> requestPermission({bool background = false});
  Future<LocationData> getCurrentLocation();
  Stream<LocationData> watchLocation();
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message, {this.openSettings = false});
  final String message;
  final bool openSettings;

  @override
  String toString() => message;
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<void> requestPermission({bool background = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(
        'Turn on your device location service and try again.',
        openSettings: true,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is required to share your live location.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is disabled. Allow it in app settings.',
        openSettings: true,
      );
    }
    if (background && permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        throw const LocationServiceException(
          'Choose "Allow all the time" in location settings so your trip '
          'group can see updates while your screen is locked.',
          openSettings: true,
        );
      }
    }
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    await requestPermission();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return _toLocationData(position);
    } catch (_) {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        throw const LocationServiceException(
          'Your location is unavailable. Emergency calling is still available.',
        );
      }
      return _toLocationData(position);
    }
  }

  @override
  Stream<LocationData> watchLocation() => Geolocator.getPositionStream(
        locationSettings: _liveLocationSettings(),
      ).map(_toLocationData);

  LocationSettings _liveLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        intervalDuration: Duration(seconds: 5),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Live location sharing is on',
          notificationText:
              'GoBuddy is sharing your location with your trip group.',
          notificationChannelName: 'Live location sharing',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );
  }

  LocationData _toLocationData(Position position) => LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
}
