import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/trip.dart';
import 'trip_repository.dart';

/// Read-only adapter over the trip domain owned by matchmaking.
class SupabaseTripRepository implements TripRepository {
  const SupabaseTripRepository(this.client);

  final SupabaseClient client;

  @override
  Future<Trip?> getTripById(String tripId) async {
    final row = await client
        .from('matchmaking_trips')
        .select('id,destination,start_date,end_date')
        .eq('id', tripId)
        .maybeSingle();
    if (row == null) return null;
    return Trip.fromMap({
      'trip_id': row['id'],
      'destination': row['destination'],
      'start_date': row['start_date'],
      'end_date': row['end_date'],
    });
  }
}
