import 'package:dio/dio.dart';

class LocationSearchService {
  LocationSearchService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://photon.komoot.io',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'GoBuddy/1.0 (travel destination search)',
              },
            ),
          );

  final Dio _dio;

  Future<List<String>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final displayLimit = switch (trimmed.length) {
      <= 3 => 6,
      <= 6 => 5,
      <= 10 => 4,
      _ => 3,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api',
      // Fetch extra candidates because Photon also returns hotels, shops and
      // other records which are removed below.
      queryParameters: {'q': trimmed, 'limit': 12, 'lang': 'en'},
    );
    final features = response.data?['features'];
    if (features is! List) return const [];

    final results = <String>[];
    String? preferredCountryCode;
    for (final feature in features) {
      if (feature is! Map) continue;
      final properties = feature['properties'];
      if (properties is! Map) continue;
      if (!_isTravelDestination(properties)) continue;
      final countryCode = properties['countrycode']?.toString().toUpperCase();
      preferredCountryCode ??= countryCode;
      if (preferredCountryCode != null &&
          countryCode != null &&
          countryCode != preferredCountryCode) {
        continue;
      }
      final label = _format(properties);
      if (label.isNotEmpty && !results.contains(label)) results.add(label);
      if (results.length == displayLimit) break;
    }
    return results;
  }

  Future<List<String>> searchCities(
    String query,
    String countryCode, {
    required String countryName,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '/api',
      queryParameters: {
        'q': trimmed,
        'countrycode': countryCode.toUpperCase(),
        'layer': 'city',
        'limit': 50,
        'lang': 'en',
      },
    );
    final features = response.data?['features'];
    if (features is! List) return const [];
    final results = <String>[];
    for (final feature in features) {
      if (feature is! Map || feature['properties'] is! Map) continue;
      final properties = feature['properties'] as Map;
      if (properties['countrycode']?.toString().toUpperCase() !=
          countryCode.toUpperCase()) {
        continue;
      }
      final type = properties['osm_value']?.toString().toLowerCase();
      if (!const {
        'city',
        'town',
        'municipality',
        'village',
        'state',
      }.contains(type)) {
        continue;
      }
      final name = properties['name']?.toString().trim() ?? '';
      if (!name.toLowerCase().startsWith(trimmed.toLowerCase())) continue;
      if (name.isNotEmpty && !results.contains(name)) results.add(name);
      if (results.length == 15) break;
    }
    return results;
  }

  bool _isTravelDestination(Map properties) {
    final key = properties['osm_key']?.toString().toLowerCase() ?? '';
    final value = properties['osm_value']?.toString().toLowerCase() ?? '';
    if (key == 'boundary' && value == 'administrative') return true;
    if (key != 'place') return false;
    return const {
      'country',
      'state',
      'province',
      'region',
      'city',
      'town',
      'municipality',
      'island',
      'islet',
      'archipelago',
    }.contains(value);
  }

  String _format(Map properties) {
    final parts = <String>[];
    void add(Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && !parts.contains(text)) parts.add(text);
    }

    add(properties['name']);
    final placeType = properties['osm_value']?.toString().toLowerCase() ?? '';
    final isIsland = const {
      'island',
      'islet',
      'archipelago',
    }.contains(placeType);
    final street = properties['street']?.toString().trim() ?? '';
    final houseNumber = properties['housenumber']?.toString().trim() ?? '';
    if (street.isNotEmpty && !parts.contains(street)) {
      add(houseNumber.isEmpty ? street : '$houseNumber $street');
    }
    // An island can be administratively assigned to a village. Showing that
    // village as if it were the island's city creates confusing labels.
    if (!isIsland) {
      add(properties['district']);
      add(properties['city']);
    }
    add(properties['county']);
    add(properties['state']);
    add(properties['country']);
    return parts.join(', ');
  }
}
