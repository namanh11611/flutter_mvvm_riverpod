import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../model/safety_check_in.dart';
import 'view_model/safety_check_in_settings_view_model.dart';

class SafetyCheckInSettingsScreen extends ConsumerStatefulWidget {
  const SafetyCheckInSettingsScreen({super.key});

  @override
  ConsumerState<SafetyCheckInSettingsScreen> createState() =>
      _SafetyCheckInSettingsScreenState();
}

class _SafetyCheckInSettingsScreenState
    extends ConsumerState<SafetyCheckInSettingsScreen> {
  final _customIntervalController = TextEditingController();

  @override
  void dispose() {
    _customIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(safetyCheckInSettingsViewModelProvider);

    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      appBar: AppBar(
        title: Text('Safety Check-In', style: AppTheme.title20),
        backgroundColor: context.secondaryBackgroundColor,
        foregroundColor: context.primaryTextColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (configuration) {
          if (!_customIntervalController.selection.isValid) {
            _customIntervalController.text =
                configuration.customIntervalMinutes.toString();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              _SettingsCard(
                child: SwitchListTile(
                  secondary: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.brandSurface,
                  ),
                  title: Text('Safety Check-In', style: AppTheme.title16),
                  subtitle: Text(
                    'Ring like an alarm until I confirm that I am safe.',
                    style: AppTheme.body14.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  value: configuration.enabled,
                  activeThumbColor: AppColors.brandBackground,
                  activeTrackColor: AppColors.brandSurface,
                  onChanged: (enabled) async {
                    final granted = await ref
                        .read(
                          safetyCheckInSettingsViewModelProvider.notifier,
                        )
                        .setEnabled(enabled);
                    if (!granted && context.mounted) {
                      context.showErrorSnackBar(
                        'Notification permission is required for safety '
                        'check-ins. Allow notifications in device settings '
                        'and try again.',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
              Text('CHECK-IN FREQUENCY', style: AppTheme.title16),
              const SizedBox(height: 10),
              AnimatedOpacity(
                opacity: configuration.enabled ? 1 : 0.45,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !configuration.enabled,
                  child: _SettingsCard(
                    child: RadioGroup<SafetyCheckInFrequency>(
                      groupValue: configuration.frequency,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(
                                safetyCheckInSettingsViewModelProvider.notifier,
                              )
                              .setFrequency(value);
                        }
                      },
                      child: Column(
                        children: [
                          for (final frequency
                              in SafetyCheckInFrequency.values) ...[
                            RadioListTile<SafetyCheckInFrequency>(
                              title: Text(frequency.label),
                              value: frequency,
                            ),
                            if (frequency != SafetyCheckInFrequency.values.last)
                              Divider(height: 1, color: context.dividerColor),
                          ],
                          if (configuration.frequency ==
                              SafetyCheckInFrequency.custom)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              child: TextField(
                                controller: _customIntervalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Custom interval',
                                  suffixText: 'minutes',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: _saveCustomInterval,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SettingsCard(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('How it works', style: AppTheme.title16),
                  subtitle: Text(
                    'At each interval, an alarm stays active until you tap I\'m safe or Need help.',
                    style: AppTheme.body14.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveCustomInterval(String value) {
    final minutes = int.tryParse(value.trim());
    if (minutes == null || minutes <= 0) {
      context.showErrorSnackBar('Enter an interval greater than 0 minutes.');
      return;
    }
    ref
        .read(safetyCheckInSettingsViewModelProvider.notifier)
        .setCustomInterval(minutes);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.secondaryWidgetColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerColor),
        ),
        child: child,
      );
}
