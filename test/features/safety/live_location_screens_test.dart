import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/live_location_screen.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/trip_live_locations_screen.dart';

void main() {
  test('live location screens can be constructed', () {
    expect(const LiveLocationScreen(), isA<Widget>());
    expect(
      const TripLiveLocationsScreen(
        tripId: 'trip-id',
        members: [],
        currentUserId: 'user-id',
      ),
      isA<Widget>(),
    );
  });
}
