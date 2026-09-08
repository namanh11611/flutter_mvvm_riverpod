import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/remote/supabase_client.dart';
import '../model/location_data.dart';
import '../model/shared_live_location.dart';

final liveLocationRepositoryProvider = Provider<LiveLocationRepository>(
  (ref) => SupabaseLiveLocationRepository(supabase),
);

abstract interface class LiveLocationRepository {
  Future<List<ShareableTrip>> getActiveTrips(String userId);
  Future<String> startShare({
    required String userId,
    required String tripId,
    required DateTime expiresAt,
    required LocationData location,
  });
  Future<void> updateLocation(String shareId, LocationData location);
  Future<void> stopShare(String shareId);
  Future<void> stopTripShare({required String userId, required String tripId});
  Stream<List<SharedLiveLocation>> watchTripShares(String tripId);
}

class SupabaseLiveLocationRepository implements LiveLocationRepository {
  const SupabaseLiveLocationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<ShareableTrip>> getActiveTrips(String userId) async {
    _requireUser(userId);
    final memberships = await _client
        .from('matchmaking_trip_members')
        .select('trip_id')
        .eq('user_id', userId);
    final memberIds = memberships
        .map((row) => row['trip_id'] as String)
        .toSet()
        .toList(growable: false);
    final owned = await _client
        .from('matchmaking_trips')
        .select('id,destination,end_date')
        .eq('owner_id', userId)
        .eq('status', 'active');
    final rows = <dynamic>[...owned];
    if (memberIds.isNotEmpty) {
      rows.addAll(await _client
          .from('matchmaking_trips')
          .select('id,destination,end_date')
          .inFilter('id', memberIds)
          .eq('status', 'active'));
    }
    final unique = <String, ShareableTrip>{};
    for (final row in rows) {
      final id = row['id'] as String;
      unique[id] = ShareableTrip(
        id: id,
        destination: row['destination'] as String,
        endDate: DateTime.parse(row['end_date'] as String),
      );
    }
    return unique.values.toList(growable: false);
  }

  @override
  Future<String> startShare({
    required String userId,
    required String tripId,
    required DateTime expiresAt,
    required LocationData location,
  }) async {
    _requireUser(userId);
    final row = await _client.from('live_location_shares').upsert({
      'user_id': userId,
      'trip_id': tripId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'recorded_at': location.timestamp.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'is_active': true,
    }, onConflict: 'user_id,trip_id').select('id').single();
    return row['id'] as String;
  }

  @override
  Future<void> updateLocation(String shareId, LocationData location) async {
    await _client.from('live_location_shares').update({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'recorded_at': location.timestamp.toUtc().toIso8601String(),
    }).eq('id', shareId).eq('user_id', _currentUserId());
  }

  @override
  Future<void> stopShare(String shareId) async {
    _currentUserId();
    await _client.rpc(
      'stop_live_location_share',
      params: {'p_share_id': shareId},
    );
  }

  @override
  Future<void> stopTripShare({
    required String userId,
    required String tripId,
  }) async {
    _requireUser(userId);
    try {
      await _client.rpc(
        'stop_trip_live_location_share',
        params: {'p_trip_id': tripId},
      );
    } on PostgrestException catch (error) {
      // Older deployments do not have the trip-scoped RPC yet. Resolve the
      // user's active share and use the existing single-share RPC so the stop
      // button remains functional while the migration is being rolled out.
      if (error.code != 'PGRST202') rethrow;
      final rows = await _client
          .from('live_location_shares')
          .select('id')
          .eq('user_id', userId)
          .eq('trip_id', tripId)
          .eq('is_active', true);
      for (final row in rows) {
        await stopShare(row['id'] as String);
      }
    }
  }

  @override
  Stream<List<SharedLiveLocation>> watchTripShares(String tripId) {
    final realtime = _client
        .from('live_location_shares')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .eq('is_active', true)
        .map(_activeShares);
    StreamSubscription<List<SharedLiveLocation>>? subscription;
    Timer? refreshTimer;
    var refreshInProgress = false;
    late final StreamController<List<SharedLiveLocation>> controller;

    Future<void> refresh() async {
      if (refreshInProgress || controller.isClosed) return;
      refreshInProgress = true;
      try {
        final rows = await _client
            .from('live_location_shares')
            .select()
            .eq('trip_id', tripId)
            .eq('is_active', true);
        if (!controller.isClosed) controller.add(_activeShares(rows));
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      } finally {
        refreshInProgress = false;
      }
    }

    controller = StreamController<List<SharedLiveLocation>>(
      onListen: () {
        subscription = realtime.listen(
          controller.add,
          onError: controller.addError,
        );
        // Re-query periodically as a fallback for mobile networks that miss a
        // realtime event while reconnecting.
        refreshTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => unawaited(refresh()),
        );
      },
      onCancel: () async {
        refreshTimer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  List<SharedLiveLocation> _activeShares(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final shares = rows
        .map(SharedLiveLocation.fromMap)
        .where((share) => share.isActiveAt(now))
        .toList(growable: false)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return shares;
  }

  void _requireUser(String userId) {
    if (_currentUserId() != userId) {
      throw StateError('Sign in to share your live location.');
    }
  }

  String _currentUserId() =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in to share your live location.'));
}
