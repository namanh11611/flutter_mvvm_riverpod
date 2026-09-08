enum EmergencyServiceType { dispatch, police, ambulance, fire }

class EmergencyService {
  const EmergencyService({required this.type, required this.numbers});
  final EmergencyServiceType type;
  final List<String> numbers;

  String get label => switch (type) {
        EmergencyServiceType.dispatch => 'General emergency',
        EmergencyServiceType.police => 'Police',
        EmergencyServiceType.ambulance => 'Ambulance',
        EmergencyServiceType.fire => 'Fire & Rescue',
      };
}

class EmergencyNumbers {
  const EmergencyNumbers({
    required this.countryName,
    required this.countryCode,
    required this.services,
    this.localOnly = false,
  });

  final String countryName;
  final String countryCode;
  final List<EmergencyService> services;
  final bool localOnly;

  EmergencyService? get preferredService {
    for (final type in EmergencyServiceType.values) {
      for (final service in services) {
        if (service.type == type && service.numbers.isNotEmpty) return service;
      }
    }
    return null;
  }

  factory EmergencyNumbers.fromApiJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final country = payload['Country'] is Map
        ? Map<String, dynamic>.from(payload['Country'] as Map)
        : const <String, dynamic>{};
    final services = <EmergencyService>[];
    for (final entry in const [
      ('Dispatch', EmergencyServiceType.dispatch),
      ('Police', EmergencyServiceType.police),
      ('Ambulance', EmergencyServiceType.ambulance),
      ('Fire', EmergencyServiceType.fire),
    ]) {
      final numbers = _readNumbers(payload[entry.$1]);
      if (numbers.isNotEmpty) {
        services.add(EmergencyService(type: entry.$2, numbers: numbers));
      }
    }
    final code = (country['ISOCode'] ?? '').toString().trim().toUpperCase();
    if (code.length != 2) throw const FormatException('Missing country code');
    return EmergencyNumbers(
      countryName: (country['Name'] ?? code).toString(),
      countryCode: code,
      services: services,
      localOnly: payload['LocalOnly'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'countryName': countryName,
        'countryCode': countryCode,
        'localOnly': localOnly,
        'services': services
            .map((service) => {
                  'type': service.type.name,
                  'numbers': service.numbers,
                })
            .toList(),
      };

  factory EmergencyNumbers.fromCacheJson(Map<String, dynamic> json) =>
      EmergencyNumbers(
        countryName: json['countryName'] as String,
        countryCode: json['countryCode'] as String,
        localOnly: json['localOnly'] == true,
        services: (json['services'] as List? ?? const [])
            .whereType<Map>()
            .map((value) {
              final map = Map<String, dynamic>.from(value);
              return EmergencyService(
                type: EmergencyServiceType.values.firstWhere(
                  (type) => type.name == map['type'],
                ),
                numbers: (map['numbers'] as List? ?? const [])
                    .map((number) => number.toString())
                    .toList(),
              );
            })
            .toList(),
      );

  static List<String> _readNumbers(Object? value) {
    if (value is! Map) return const [];
    final map = Map<String, dynamic>.from(value);
    final numbers = <String>{};
    for (final key in const ['All', 'GSM', 'Fixed']) {
      final values = map[key];
      if (values is List) {
        numbers.addAll(values.map((item) => item.toString().trim()).where(
              (number) => RegExp(r'^\+?[0-9]+$').hasMatch(number),
            ));
      }
    }
    return numbers.toList(growable: false);
  }
}
