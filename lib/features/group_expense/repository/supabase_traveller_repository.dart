import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/traveller.dart';
import 'traveller_repository.dart';

/// Read-only adapter over shared trip membership and user accounts.
class SupabaseTravellerRepository implements TravellerRepository {
  const SupabaseTravellerRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<Traveller>> getTravellersForTrip(String tripId) async {
    final membershipRows = await client
        .from('trip_members')
        .select('user_id')
        .eq('trip_id', tripId);
    final userIds = [
      for (final row in membershipRows) row['user_id'] as String,
    ];
    if (userIds.isEmpty) return const [];

    final accountRows = await client
        .from('user_accounts')
        .select('id,display_name,profile_photo_path')
        .inFilter('id', userIds);
    final accountsById = {
      for (final row in accountRows) row['id'] as String: row,
    };
    return [
      for (final userId in userIds)
        if (accountsById[userId] case final account?) _fromAccount(account),
    ];
  }

  @override
  Future<Traveller?> getTravellerById(String tripId, String userId) async {
    final membership = await client
        .from('trip_members')
        .select('user_id')
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .maybeSingle();
    if (membership == null) return null;
    final row = await client
        .from('user_accounts')
        .select('id,display_name,profile_photo_path')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : _fromAccount(row);
  }

  Traveller _fromAccount(Map<String, dynamic> row) {
    final displayName = row['display_name'] as String;
    return Traveller(
      userId: row['id'] as String,
      displayName: displayName,
      profilePhotoUrl: row['profile_photo_path'] as String?,
      initials: _initials(displayName),
    );
  }

  String _initials(String displayName) => displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
