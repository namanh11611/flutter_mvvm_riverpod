import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emergency_helpline/emergency_helpline.dart' as helpline;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/emergency_service.dart';
import '../model/location_data.dart';

final emergencyServiceRepositoryProvider = Provider<EmergencyServiceRepository>(
  (ref) => ApiEmergencyServiceRepository(
    fallbackSource: const PackageEmergencyNumberSource(),
  ),
);

class DetectedEmergencyLocation {
  const DetectedEmergencyLocation({
    required this.countryCode,
    required this.countryName,
    this.locality,
  });
  final String countryCode;
  final String countryName;
  final String? locality;
  String get label => locality == null || locality!.isEmpty
      ? '$countryName ($countryCode)'
      : '$locality, $countryCode';
}

abstract interface class EmergencyServiceRepository {
  Future<DetectedEmergencyLocation> detectLocation(LocationData location);
  Future<EmergencyNumbers?> getCachedEmergencyNumbers(String countryCode);
  Future<EmergencyNumbers> getEmergencyNumbers(String countryCode);
  Future<void> openDialler(String number);
  Future<void> composeAlert({
    required List<String> phoneNumbers,
    required String message,
  });
}

class EmergencyServiceException implements Exception {
  const EmergencyServiceException(this.message);
  final String message;
}

abstract interface class LocalEmergencyNumberSource {
  Future<EmergencyNumbers?> getEmergencyNumbers(String countryCode);
}

class PackageEmergencyNumberSource implements LocalEmergencyNumberSource {
  const PackageEmergencyNumberSource();

  @override
  Future<EmergencyNumbers?> getEmergencyNumbers(String countryCode) async {
    final packageData =
        await helpline.EmergencyHelpline.instance.getCountry(countryCode);
    if (packageData == null) return null;
    final services = <EmergencyService>[];
    _addService(services, EmergencyServiceType.police, packageData.police);
    _addService(
      services,
      EmergencyServiceType.ambulance,
      packageData.ambulance,
    );
    _addService(services, EmergencyServiceType.fire, packageData.fire);
    if (services.isEmpty) return null;
    return EmergencyNumbers(
      countryName: packageData.countryName.trim().isEmpty
          ? countryCode.toUpperCase()
          : packageData.countryName.trim(),
      countryCode: countryCode.toUpperCase(),
      services: services,
    );
  }

  static void _addService(
    List<EmergencyService> services,
    EmergencyServiceType type,
    String rawNumber,
  ) {
    final numbers = rawNumber
        .split(RegExp(r'[,/;]'))
        .map((number) => number.trim())
        .where((number) => RegExp(r'^\+?[0-9]+$').hasMatch(number))
        .toSet()
        .toList(growable: false);
    if (numbers.isNotEmpty) {
      services.add(EmergencyService(type: type, numbers: numbers));
    }
  }
}

class ApiEmergencyServiceRepository implements EmergencyServiceRepository {
  ApiEmergencyServiceRepository({
    Dio? dio,
    LocalEmergencyNumberSource? fallbackSource,
  })  : _fallbackSource =
            fallbackSource ?? const PackageEmergencyNumberSource(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://emergencynumberapi.com/api',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {'Accept': 'application/json'},
            ));

  final Dio _dio;
  final LocalEmergencyNumberSource _fallbackSource;
  static const _cachePrefix = 'safety_emergency_numbers_v1_';

  @override
  Future<DetectedEmergencyLocation> detectLocation(LocationData location) async {
    final places = await Geocoding().placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (places.isEmpty) {
      throw const EmergencyServiceException('Could not identify your country.');
    }
    final place = places.first;
    final code = place.isoCountryCode?.trim().toUpperCase();
    if (code == null || code.length != 2) {
      throw const EmergencyServiceException('Could not identify your country.');
    }
    return DetectedEmergencyLocation(
      countryCode: code,
      countryName: place.country?.trim().isNotEmpty == true
          ? place.country!.trim()
          : code,
      locality: place.locality?.trim(),
    );
  }

  @override
  Future<EmergencyNumbers?> getCachedEmergencyNumbers(String code) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString('$_cachePrefix${code.toUpperCase()}');
      if (value == null) return null;
      return EmergencyNumbers.fromCacheJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EmergencyNumbers> getEmergencyNumbers(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) {
      throw const EmergencyServiceException(
        'Emergency numbers are temporarily unavailable. Please try again.',
      );
    }
    try {
      final result = await _getRemoteEmergencyNumbers(code);
      debugPrint('Emergency numbers loaded from remote API for $code.');
      return result;
    } catch (error) {
      debugPrint('Remote emergency-number lookup failed for $code: $error');
      try {
        final fallback = await _fallbackSource.getEmergencyNumbers(code);
        if (fallback != null && fallback.services.isNotEmpty) {
          debugPrint('Using offline emergency-number fallback for $code.');
          return fallback;
        }
      } catch (fallbackError) {
        debugPrint(
          'Offline emergency-number fallback failed for $code: $fallbackError',
        );
      }
      throw const EmergencyServiceException(
        'Emergency numbers are temporarily unavailable. Please try again.',
      );
    }
  }

  Future<EmergencyNumbers> _getRemoteEmergencyNumbers(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    try {
      final response = await _dio.get<Map<String, dynamic>>('/country/$code');
      final json = response.data;
      if (json == null || json['error'] != null) {
        throw const EmergencyServiceException(
          'Emergency numbers are unavailable for this country.',
        );
      }
      final result = EmergencyNumbers.fromApiJson(json);
      if (result.services.isEmpty && !result.localOnly) {
        throw const EmergencyServiceException(
          'Emergency numbers are unavailable for this country.',
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_cachePrefix$code',
        jsonEncode(result.toJson()),
      );
      return result;
    } on EmergencyServiceException {
      rethrow;
    } on DioException {
      throw const EmergencyServiceException(
        'Could not update emergency numbers. Check your connection and retry.',
      );
    } on FormatException {
      throw const EmergencyServiceException(
        'The emergency-number service returned invalid data.',
      );
    } catch (_) {
      throw const EmergencyServiceException(
        'Emergency numbers are temporarily unavailable.',
      );
    }
  }

  @override
  Future<void> openDialler(String number) async {
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(number)) {
      throw const EmergencyServiceException('This phone number is invalid.');
    }
    if (!await launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    )) {
      throw EmergencyServiceException(
        'Could not open the phone dialler. Call $number manually.',
      );
    }
  }

  @override
  Future<void> composeAlert({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    if (phoneNumbers.isEmpty) return;
    try {
      // An sms: URI can be claimed by WhatsApp and Telegram, but those apps
      // may misinterpret an SMS-formatted or multi-recipient phone number as an
      // unregistered account. A text share lets the selected app choose one of
      // its own chats and works consistently across messaging applications.
      await Share.share(message, subject: 'GoBuddy Emergency SOS');
    } catch (_) {
      throw const EmergencyServiceException(
        'Could not open your messaging apps.',
      );
    }
  }
}
