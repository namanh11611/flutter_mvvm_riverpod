import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/push_notification_service.dart';
import '../../model/safety_check_in.dart';
import '../../repository/safety_check_in_configuration_repository.dart';

final safetyCheckInSettingsViewModelProvider = AsyncNotifierProvider<
    SafetyCheckInSettingsViewModel, SafetyCheckInConfiguration>(
  SafetyCheckInSettingsViewModel.new,
);

class SafetyCheckInSettingsViewModel
    extends AsyncNotifier<SafetyCheckInConfiguration> {
  SafetyCheckInConfigurationRepository get _repository =>
      ref.read(safetyCheckInConfigurationRepositoryProvider);

  @override
  Future<SafetyCheckInConfiguration> build() => _repository.load();

  Future<bool> setEnabled(bool enabled) async {
    final current = state.value ?? const SafetyCheckInConfiguration();
    final updated = current.copyWith(enabled: enabled);

    if (enabled &&
        !await PushNotificationService.scheduleSafetyCheckIns(updated)) {
      return false;
    }

    state = AsyncData(updated);
    await _repository.save(updated);
    if (!enabled) {
      await PushNotificationService.scheduleSafetyCheckIns(updated);
    }
    return true;
  }

  Future<void> setFrequency(SafetyCheckInFrequency frequency) =>
      _update((current) => current.copyWith(frequency: frequency));

  Future<void> setCustomInterval(int minutes) => _update(
        (current) => current.copyWith(customIntervalMinutes: minutes),
      );

  Future<void> _update(
    SafetyCheckInConfiguration Function(SafetyCheckInConfiguration) change,
  ) async {
    final current = state.value ?? const SafetyCheckInConfiguration();
    final updated = change(current);
    state = AsyncData(updated);
    await _repository.save(updated);
    await PushNotificationService.scheduleSafetyCheckIns(updated);
  }
}
