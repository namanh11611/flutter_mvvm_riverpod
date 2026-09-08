import 'package:sqflite/sqflite.dart';

import '../model/traveller.dart';
import 'traveller_repository.dart';

/// Development mirror only. Replace with the owning account/trip module.
/// Legacy local/test adapter. Production wiring reads trip_members/user_accounts.
class LocalTravellerRepository implements TravellerRepository {
  const LocalTravellerRepository(this.database);

  final Database database;

  @override
  Future<Traveller?> getTravellerById(String tripId, String userId) async {
    final members = await getTravellersForTrip(tripId);
    if (!members.any((traveller) => traveller.userId == userId)) return null;
    final rows = await database.query(
      'travellers',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Traveller.fromMap(rows.first);
  }

  @override
  Future<List<Traveller>> getTravellersForTrip(String tripId) async {
    final tripRows = await database.query(
      'trips',
      columns: ['trip_id'],
      where: 'trip_id = ?',
      whereArgs: [tripId],
      limit: 1,
    );
    if (tripRows.isEmpty) return const [];
    // Membership is supplied by the trip module later; all seeded travellers
    // belong to the one local development trip.
    final rows = await database.query('travellers', orderBy: 'user_id');
    return rows.map(Traveller.fromMap).toList(growable: false);
  }
}
