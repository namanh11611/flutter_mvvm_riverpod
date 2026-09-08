import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/remote/supabase_client.dart';
import '../model/travel_footprint.dart';

final travelFootprintRepositoryProvider = Provider(
  (ref) => const TravelFootprintRepository(),
);

final travelFootprintProvider = FutureProvider<TravelFootprint>((ref) async {
  return ref.read(travelFootprintRepositoryProvider).fetch();
});

class TravelFootprintRepository {
  const TravelFootprintRepository();

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Sign in to manage your travel footprint.');
    }
    return id;
  }

  Future<TravelFootprint> fetch() async {
    final userId = _userId;
    final results = await Future.wait([
      supabase
          .from('visited_countries')
          .select()
          .eq('user_id', userId)
          .order('country_name'),
      supabase
          .from('visited_cities')
          .select()
          .eq('user_id', userId)
          .order('city_name'),
    ]);
    final cities = results[1];
    return TravelFootprint([
      for (final country in results[0])
        VisitedCountry(
          id: country['id'] as String,
          name: country['country_name'] as String,
          code: country['country_code'] as String,
          cities: [
            for (final city in cities)
              if (city['country_id'] == country['id'])
                VisitedCity(
                  id: city['id'] as String,
                  name: city['city_name'] as String,
                ),
          ],
        ),
    ]);
  }

  Future<void> addCountry(String name, String code) =>
      supabase.from('visited_countries').insert({
        'user_id': _userId,
        'country_name': name.trim(),
        'country_code': code.trim().toUpperCase(),
      });

  Future<void> updateCountry(String id, String name, String code) => supabase
      .from('visited_countries')
      .update({
        'country_name': name.trim(),
        'country_code': code.trim().toUpperCase(),
      })
      .eq('id', id)
      .eq('user_id', _userId);

  Future<void> removeCountry(String id) => supabase
      .from('visited_countries')
      .delete()
      .eq('id', id)
      .eq('user_id', _userId);

  Future<void> addCity(String countryId, String name) =>
      supabase.from('visited_cities').insert({
        'user_id': _userId,
        'country_id': countryId,
        'city_name': name.trim(),
      });

  Future<void> renameCity(String id, String name) => supabase
      .from('visited_cities')
      .update({'city_name': name.trim()})
      .eq('id', id)
      .eq('user_id', _userId);

  Future<void> removeCity(String id) => supabase
      .from('visited_cities')
      .delete()
      .eq('id', id)
      .eq('user_id', _userId);
}
