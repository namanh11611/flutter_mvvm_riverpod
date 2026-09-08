import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/safety_check_in.dart';

final safetyCheckInConfigurationRepositoryProvider =
    Provider<SafetyCheckInConfigurationRepository>(
  (ref) => SharedPreferencesSafetyCheckInConfigurationRepository(),
);

abstract interface class SafetyCheckInConfigurationRepository {
  Future<SafetyCheckInConfiguration> load();
  Future<void> save(SafetyCheckInConfiguration configuration);
}

class SharedPreferencesSafetyCheckInConfigurationRepository
    implements SafetyCheckInConfigurationRepository {
  static const _enabledKey = 'safety_check_in_enabled';
  static const _frequencyKey = 'safety_check_in_frequency';
  static const _customIntervalKey = 'safety_check_in_custom_interval_minutes';

  @override
  Future<SafetyCheckInConfiguration> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedFrequency = preferences.getString(_frequencyKey);
    return SafetyCheckInConfiguration(
      enabled: preferences.getBool(_enabledKey) ?? false,
      frequency: SafetyCheckInFrequency.values.firstWhere(
        (frequency) => frequency.name == savedFrequency,
        orElse: () => SafetyCheckInFrequency.oneHour,
      ),
      customIntervalMinutes: preferences.getInt(_customIntervalKey) ?? 60,
    );
  }

  @override
  Future<void> save(SafetyCheckInConfiguration configuration) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_enabledKey, configuration.enabled),
      preferences.setString(_frequencyKey, configuration.frequency.name),
      preferences.setInt(
        _customIntervalKey,
        configuration.customIntervalMinutes,
      ),
    ]);
  }
}
