import 'package:dio/dio.dart';

class DestinationImageService {
  DestinationImageService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://commons.wikimedia.org',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'GoBuddy/1.0 (trip destination cover search)',
              },
            ),
          );

  final Dio _dio;

  Future<String?> findImageUrl(String destination) async {
    final query = destination.trim();
    if (query.length < 3) return null;
    final placeParts = query
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final primaryPlace = placeParts.first;
    final country = placeParts.length > 1 ? placeParts.last : '';
    final lowerPlace = primaryPlace.toLowerCase();
    final scenicTerm =
        lowerPlace.contains('island') ||
            lowerPlace.contains('pulau') ||
            lowerPlace.contains('beach') ||
            lowerPlace.contains('coast') ||
            lowerPlace.contains('bay')
        ? 'beach'
        : lowerPlace.contains('mount') ||
              lowerPlace.contains('hill') ||
              lowerPlace.contains('park') ||
              lowerPlace.contains('lake')
        ? 'landscape'
        : 'landmark skyline';
    if (country.isNotEmpty) {
      // Include the country so equally named places do not all receive the
      // photo belonging to the most famous one.
      return await _search(
            '$primaryPlace $country $scenicTerm',
            expectedPlace: primaryPlace,
          ) ??
          await _search('$primaryPlace $country', expectedPlace: primaryPlace);
    }
    return await _search(
          '$primaryPlace $scenicTerm',
          expectedPlace: primaryPlace,
        ) ??
        await _search(primaryPlace, expectedPlace: primaryPlace);
  }

  Future<String?> _search(String query, {required String expectedPlace}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/w/api.php',
      queryParameters: {
        'action': 'query',
        'format': 'json',
        'formatversion': 2,
        'generator': 'search',
        'gsrnamespace': 6,
        'gsrsearch': query,
        'gsrlimit': 10,
        'prop': 'imageinfo',
        'iiprop': 'url|mime',
        'iiurlwidth': 1200,
        'origin': '*',
      },
    );
    final result = response.data?['query'];
    final pages = result is Map ? result['pages'] : null;
    if (pages is! List) return null;
    final rankedPages = pages.whereType<Map>().toList()
      ..sort(
        (left, right) => ((left['index'] as num?) ?? 999).compareTo(
          (right['index'] as num?) ?? 999,
        ),
      );
    for (final page in rankedPages) {
      final title = page['title']?.toString().toLowerCase() ?? '';
      if (_looksLikeNonPhoto(title)) continue;
      final placeWords = expectedPlace
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((word) => word.length >= 4);
      if (placeWords.isNotEmpty && !placeWords.any(title.contains)) continue;
      final imageInfo = page['imageinfo'];
      if (imageInfo is! List || imageInfo.isEmpty || imageInfo.first is! Map) {
        continue;
      }
      final info = imageInfo.first as Map;
      final mime = info['mime']?.toString() ?? '';
      if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
        continue;
      }
      var url = info['thumburl']?.toString() ?? info['url']?.toString() ?? '';
      if (url.isEmpty) continue;
      if (url.startsWith('//')) url = 'https:$url';
      return url;
    }
    return null;
  }

  bool _looksLikeNonPhoto(String title) => const [
    'map',
    'satellite',
    ' esa',
    'flag',
    'logo',
    'diagram',
    'locator',
    'coat of arms',
    'banner',
    'chart',
    'sketch',
    'drawing',
    'manuscript',
    'atlas',
    'nautical',
    'navigation',
    'historical',
    'historic map',
  ].any(title.contains);
}
