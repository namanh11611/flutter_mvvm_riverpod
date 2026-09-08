part of 'matchmaking_shell_screen.dart';

class MyTripsPage extends StatelessWidget {
  final VoidCallback onBack, onCreate;
  final Future<void> Function() onRetry;
  final List<MatchmakingTrip> trips, joinedTrips, removedTrips, allTrips;
  final List<JoinRequest> requests;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onManage, onEdit, onFinish, onRemoveHosted;
  final ValueChanged<String> onOpenTimeline;
  final Future<void> Function(String) onLeaveTrip, onRemoveRequest;
  final Future<void> Function(String) onDismissRemovedTrip;
  const MyTripsPage({
    super.key,
    required this.trips,
    required this.joinedTrips,
    required this.removedTrips,
    required this.allTrips,
    required this.requests,
    required this.onBack,
    required this.onCreate,
    required this.onRetry,
    required this.isLoading,
    required this.errorMessage,
    required this.onManage,
    required this.onFinish,
    required this.onRemoveHosted,
    required this.onEdit,
    required this.onOpenTimeline,
    required this.onLeaveTrip,
    required this.onDismissRemovedTrip,
    required this.onRemoveRequest,
  });
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
    children: [
      Row(
        children: [
          RoundBack(onTap: onBack),
          const SizedBox(width: 13),
          const Text('My trips', style: _display),
        ],
      ),
      const SizedBox(height: 7),
      const Text(
        'Your adventures, all in one place.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 16),
      OutlineButton(label: '+ Create a new trip', onTap: onCreate),
      const SizedBox(height: 24),
      if (isLoading &&
          trips.isEmpty &&
          joinedTrips.isEmpty &&
          removedTrips.isEmpty &&
          requests.isEmpty)
        const _DiscoveryLoading()
      else if (errorMessage != null &&
          trips.isEmpty &&
          joinedTrips.isEmpty &&
          removedTrips.isEmpty &&
          requests.isEmpty)
        _DiscoveryMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load your trips',
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: onRetry,
        )
      else if (trips.isEmpty &&
          joinedTrips.isEmpty &&
          removedTrips.isEmpty &&
          requests.isEmpty)
        const _NoTripsFound(),
      if (trips.isNotEmpty) ...[
        const Text('Hosting', style: _heading),
        const SizedBox(height: 12),
      ],
      for (final trip in trips) ...[
        CompactTrip(
          destination: trip.destination,
          dates: _dateRange(trip.startDate, trip.endDate),
          members: '${trip.groupMemberCount} joined',
          image: trip.imageUrl,
          status: _lifecycleLabel(trip),
          onOpen: () => onOpenTimeline(trip.id),
          onEdit: () => onEdit(trip.id),
          onManage: () => onManage(trip.id),
          onFinish: trip.lifecycle == TripLifecycle.finished
              ? null
              : () => onFinish(trip.id),
          onRemove: trip.lifecycle == TripLifecycle.finished
              ? () async {
                  if (await _confirm(
                    context,
                    title: 'Remove hosted trip?',
                    message:
                        'Permanently remove ${trip.destination} and its trip data?',
                    action: 'Remove',
                  )) {
                    onRemoveHosted(trip.id);
                  }
                }
              : null,
        ),
        const SizedBox(height: 14),
      ],
      if (joinedTrips.isNotEmpty || removedTrips.isNotEmpty) ...[
        const SizedBox(height: 18),
        const Text('Joined trips', style: _heading),
        const SizedBox(height: 12),
        for (final trip in joinedTrips)
          Card(
            child: ListTile(
              leading: const Icon(Icons.group_outlined, color: _violet),
              title: Text(trip.destination),
              subtitle: Text(_dateRange(trip.startDate, trip.endDate)),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Open messages',
                    onPressed: () => context.push(Routes.tripMessages(trip.id)),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  IconButton(
                    tooltip: 'Remove joined trip',
                    onPressed: () async {
                      if (await _confirm(
                        context,
                        title: 'Remove joined trip?',
                        message:
                            'Leave ${trip.destination} and remove it from My Trips?',
                        action: 'Leave and remove',
                      )) {
                        await onLeaveTrip(trip.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              onTap: () => onOpenTimeline(trip.id),
            ),
          ),
        for (final trip in removedTrips)
          Card(
            child: ListTile(
              leading: const Icon(Icons.group_off_outlined, color: _muted),
              title: Text(trip.destination),
              subtitle: Text(
                '${_dateRange(trip.startDate, trip.endDate)}\nRemoved from group',
              ),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () async {
                  if (await _confirm(
                    context,
                    title: 'Remove trip from list?',
                    message:
                        'Permanently remove ${trip.destination} from My Trips?',
                    action: 'Remove',
                  )) {
                    await onDismissRemovedTrip(trip.id);
                  }
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            ),
          ),
      ],
      if (requests.isNotEmpty) ...[
        const SizedBox(height: 18),
        const Text('Join requests', style: _heading),
        const SizedBox(height: 12),
        for (final request in requests)
          Builder(
            builder: (context) {
              final trip = allTrips
                  .where((trip) => trip.id == request.tripId)
                  .firstOrNull;
              final destination = trip?.destination ?? 'Trip unavailable';
              return Card(
                child: ListTile(
                  title: Text(destination),
                  subtitle: Text(
                    trip == null
                        ? '${_decisionLabel(request.decision)} · This trip may have been removed.'
                        : _decisionLabel(request.decision),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final active = const {
                        ApplicantDecision.pending,
                        ApplicantDecision.held,
                      }.contains(request.decision);
                      if (await _confirm(
                        context,
                        title: active ? 'Cancel request?' : 'Remove request?',
                        message: active
                            ? 'Cancel your request to join $destination?'
                            : 'Remove this request from your list?',
                        action: active ? 'Cancel request' : 'Remove',
                      )) {
                        await onRemoveRequest(request.id);
                      }
                    },
                    child: Text(
                      const {
                            ApplicantDecision.pending,
                            ApplicantDecision.held,
                          }.contains(request.decision)
                          ? 'Cancel'
                          : 'Remove',
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ],
  );
}
