import '../model/trip.dart';

abstract interface class TripRepository {
  Future<Trip?> getTripById(String tripId);
}
