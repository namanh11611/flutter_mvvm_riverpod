import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../common/remote/supabase_client.dart';
import '../../model/location_data.dart';
import '../../repository/live_location_repository.dart';
import '../../repository/location_service.dart';
import '../state/live_location_state.dart';

final liveLocationViewModelProvider =
    NotifierProvider<LiveLocationViewModel, LiveLocationState>(
  LiveLocationViewModel.new,
);

class LiveLocationViewModel extends Notifier<LiveLocationState> {
  StreamSubscription<LocationData>? _positionSubscription;
  Timer? _expiryTimer;
  String? _shareId;

  @override
  LiveLocationState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _expiryTimer?.cancel();
    });
    Future.microtask(loadTrips);
    return const LiveLocationState(isLoading: true);
  }

  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _userId();
      final trips = await ref
          .read(liveLocationRepositoryProvider)
          .getActiveTrips(userId);
      state = state.copyWith(
        trips: trips,
        selectedTripId: trips.isEmpty ? null : trips.first.id,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void selectTrip(String tripId) =>
      state = state.copyWith(selectedTripId: tripId, clearError: true);

  void setDuration(Duration duration) =>
      state = state.copyWith(duration: duration, clearError: true);

  Future<void> startSharing({String? tripId}) async {
    tripId ??= state.selectedTripId;
    if (tripId == null) {
      state = state.copyWith(error: 'Choose an active trip first.');
      return;
    }
    state = state.copyWith(isStarting: true, clearError: true);
    try {
      final service = ref.read(locationServiceProvider);
      await service.requestPermission(background: true);
      final firstLocation = await service.getCurrentLocation();
      final selectedTrip = state.trips.firstWhere((trip) => trip.id == tripId);
      final tripExpiry = DateTime(
        selectedTrip.endDate.year,
        selectedTrip.endDate.month,
        selectedTrip.endDate.day,
        23,
        59,
        59,
      );
      final expiresAt = state.duration == untilTripEndsDuration
          ? tripExpiry
          : _earlierOf(DateTime.now().add(state.duration), tripExpiry);
      if (!expiresAt.isAfter(DateTime.now())) {
        throw StateError('This trip has already ended.');
      }
      _shareId = await ref.read(liveLocationRepositoryProvider).startShare(
            userId: _userId(),
            tripId: tripId,
            expiresAt: expiresAt,
            location: firstLocation,
          );
      state = state.copyWith(
        selectedTripId: tripId,
        location: firstLocation,
        expiresAt: expiresAt,
        isStarting: false,
        isSharing: true,
      );
      _expiryTimer = Timer(expiresAt.difference(DateTime.now()), stopSharing);
      _positionSubscription = service.watchLocation().listen(
        _saveLocation,
        onError: (Object error) =>
            state = state.copyWith(error: 'Location update failed: $error'),
      );
    } on LocationServiceException catch (error) {
      state = state.copyWith(isStarting: false, error: error.message);
      if (error.openSettings) {
        await Geolocator.openAppSettings();
      }
    } catch (error) {
      state = state.copyWith(isStarting: false, error: error.toString());
    }
  }

  Future<void> _saveLocation(LocationData location) async {
    final shareId = _shareId;
    if (shareId == null || !state.isSharing) return;
    state = state.copyWith(location: location);
    try {
      await ref
          .read(liveLocationRepositoryProvider)
          .updateLocation(shareId, location);
    } catch (error) {
      state = state.copyWith(error: 'Could not publish location: $error');
    }
  }

  Future<void> stopSharing() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    final shareId = _shareId;
    if (shareId != null) {
      try {
        await ref.read(liveLocationRepositoryProvider).stopShare(shareId);
      } catch (error) {
        state = state.copyWith(error: 'Could not stop sharing: $error');
        return;
      }
      _shareId = null;
    }
    state = state.copyWith(
      isSharing: false,
      clearShare: true,
      clearError: true,
    );
  }

  Future<bool> stopSharingForTrip(String tripId) async {
    try {
      await ref.read(liveLocationRepositoryProvider).stopTripShare(
            userId: _userId(),
            tripId: tripId,
          );
      if (state.selectedTripId == tripId) {
        _expiryTimer?.cancel();
        _expiryTimer = null;
        await _positionSubscription?.cancel();
        _positionSubscription = null;
        _shareId = null;
      }
      state = state.copyWith(
        isSharing: false,
        clearShare: true,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(error: 'Could not stop sharing: $error');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  DateTime _earlierOf(DateTime first, DateTime second) =>
      first.isBefore(second) ? first : second;

  String _userId() => supabase.auth.currentUser?.id ??
      (throw StateError('Sign in to share your live location.'));
}
