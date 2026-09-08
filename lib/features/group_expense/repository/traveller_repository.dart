import '../model/traveller.dart';

abstract interface class TravellerRepository {
  Future<List<Traveller>> getTravellersForTrip(String tripId);
  Future<Traveller?> getTravellerById(String tripId, String userId);
}
