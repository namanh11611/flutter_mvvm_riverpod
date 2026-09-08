import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/features/safety/model/emergency_service.dart';
import 'package:flutter_mvvm_riverpod/features/safety/repository/emergency_service_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps dispatch and service-specific API numbers', () {
    final result = EmergencyNumbers.fromApiJson({
      'data': {
        'Country': {'Name': 'Example', 'ISOCode': 'EX'},
        'Dispatch': {'All': ['999'], 'GSM': ['112']},
        'Police': {'All': ['100', '101']},
        'Ambulance': {'All': ['102']},
        'Fire': {'All': ['103']},
        'LocalOnly': false,
      }
    });

    expect(result.countryCode, 'EX');
    expect(result.services, hasLength(4));
    expect(result.preferredService!.type, EmergencyServiceType.dispatch);
    expect(result.preferredService!.numbers, ['999', '112']);
    expect(result.services[1].numbers, ['100', '101']);
  });

  test('handles missing services and empty phone values', () {
    final result = EmergencyNumbers.fromApiJson({
      'data': {
        'Country': {'Name': 'Japan', 'ISOCode': 'JP'},
        'Police': {'All': ['110', '', 'invalid']},
        'Fire': {'All': ['119']},
        'LocalOnly': false,
      }
    });

    expect(result.services, hasLength(2));
    expect(result.services.first.numbers, ['110']);
  });

  test('cache serialization preserves multiple numbers', () {
    const original = EmergencyNumbers(
      countryName: 'Singapore',
      countryCode: 'SG',
      services: [
        EmergencyService(
          type: EmergencyServiceType.police,
          numbers: ['999', '112'],
        ),
      ],
    );

    final restored = EmergencyNumbers.fromCacheJson(original.toJson());
    expect(restored.countryCode, 'SG');
    expect(restored.services.single.numbers, ['999', '112']);
  });

  test('offline package maps ISO country data into the app model', () async {
    const source = PackageEmergencyNumberSource();

    final malaysia = await source.getEmergencyNumbers('MY');
    final japan = await source.getEmergencyNumbers('JP');
    final unsupported = await source.getEmergencyNumbers('ZZ');

    expect(malaysia?.countryCode, 'MY');
    expect(
      malaysia?.services
          .firstWhere((service) => service.type == EmergencyServiceType.police)
          .numbers,
      ['999'],
    );
    expect(japan?.services, isNotEmpty);
    expect(unsupported, isNull);
  });

  test('repository uses fallback when remote API returns 502', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 502),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    final repository = ApiEmergencyServiceRepository(
      dio: dio,
      fallbackSource: const _FakeFallbackSource(),
    );

    final result = await repository.getEmergencyNumbers('US');

    expect(result.countryCode, 'US');
    expect(result.services.single.numbers, ['911']);
  });

  test('repository reports neutral error only when both sources fail', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    final repository = ApiEmergencyServiceRepository(
      dio: dio,
      fallbackSource: const _EmptyFallbackSource(),
    );

    expect(
      () => repository.getEmergencyNumbers('ZZ'),
      throwsA(
        isA<EmergencyServiceException>().having(
          (error) => error.message,
          'message',
          'Emergency numbers are temporarily unavailable. Please try again.',
        ),
      ),
    );
  });
}

class _FakeFallbackSource implements LocalEmergencyNumberSource {
  const _FakeFallbackSource();

  @override
  Future<EmergencyNumbers?> getEmergencyNumbers(String countryCode) async {
    return EmergencyNumbers(
      countryName: 'United States',
      countryCode: countryCode,
      services: const [
        EmergencyService(
          type: EmergencyServiceType.police,
          numbers: ['911'],
        ),
      ],
    );
  }
}

class _EmptyFallbackSource implements LocalEmergencyNumberSource {
  const _EmptyFallbackSource();

  @override
  Future<EmergencyNumbers?> getEmergencyNumbers(String countryCode) async =>
      null;
}
