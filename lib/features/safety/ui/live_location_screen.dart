import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/ui/widgets/common_header.dart';
import 'state/live_location_state.dart';
import 'view_model/live_location_view_model.dart';

class LiveLocationScreen extends ConsumerWidget {
  const LiveLocationScreen({super.key});

  static const _durations = [
    Duration(hours: 1),
    Duration(hours: 8),
    untilTripEndsDuration,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveLocationViewModelProvider);
    final viewModel = ref.read(liveLocationViewModelProvider.notifier);
    ref.listen(
      liveLocationViewModelProvider.select((value) => value.error),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
        viewModel.clearError();
      },
    );

    return Scaffold(
      body: Column(
        children: [
          const CommonHeader(header: 'Share live location'),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Your selected trip group can see your latest location until you stop sharing or the timer expires.',
                        style: AppTheme.body14,
                      ),
                      const SizedBox(height: 12),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.notifications_active_outlined),
                          title: Text('Background sharing'),
                          subtitle: Text(
                            'GoBuddy shows a sharing notification or system '
                            'location indicator while location sharing remains '
                            'active with the screen locked.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (state.trips.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('You need an active trip before you can share your location.'),
                          ),
                        )
                      else ...[
                        DropdownButtonFormField<String>(
                          initialValue: state.selectedTripId,
                          decoration: const InputDecoration(
                            labelText: 'Share with trip group',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                          items: state.trips
                              .map((trip) => DropdownMenuItem(
                                    value: trip.id,
                                    child: Text(trip.destination),
                                  ))
                              .toList(growable: false),
                          onChanged: state.isSharing
                              ? null
                              : (value) {
                                  if (value != null) viewModel.selectTrip(value);
                                },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<Duration>(
                          initialValue: state.duration,
                          decoration: const InputDecoration(
                            labelText: 'Sharing duration',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          items: _durations
                              .map((duration) => DropdownMenuItem(
                                    value: duration,
                                    child: Text(_durationLabel(duration)),
                                  ))
                              .toList(growable: false),
                          onChanged: state.isSharing
                              ? null
                              : (value) {
                                  if (value != null) viewModel.setDuration(value);
                                },
                        ),
                        const SizedBox(height: 28),
                        if (state.isSharing) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Location sharing is on', style: AppTheme.title16),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.location == null
                                        ? 'Waiting for location…'
                                        : '${state.location!.latitude.toStringAsFixed(5)}, ${state.location!.longitude.toStringAsFixed(5)}\nAccuracy: ${state.location!.accuracy.toStringAsFixed(0)} m',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: viewModel.stopSharing,
                            icon: const Icon(Icons.location_off_outlined),
                            label: const Text('Stop sharing'),
                          ),
                        ] else
                          FilledButton.icon(
                            onPressed: state.isStarting
                                ? null
                                : () async {
                                    if (await _confirmBackgroundSharing(
                                      context,
                                    )) {
                                      await viewModel.startSharing();
                                    }
                                  },
                            icon: state.isStarting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.location_on_outlined),
                            label: Text(state.isStarting
                                ? 'Getting your location…'
                                : 'Allow location & start sharing'),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _durationLabel(Duration duration) {
    if (duration == untilTripEndsDuration) return 'Until trip ends';
    if (duration.inMinutes < 60) return '${duration.inMinutes} minutes';
    return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
  }

  static Future<bool> _confirmBackgroundSharing(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: const Text('Allow background location?'),
        content: const Text(
          'To keep your trip group updated when your screen is locked or you '
          'use another app, choose precise location and "Allow all the time". '
          'A visible system notification or location indicator will remain '
          'while sharing is active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
