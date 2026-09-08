import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../model/matchmaking_models.dart';
import 'matchmaking_shell_screen.dart';
import 'matchmaking_view_model.dart';
import 'saved_trip_card.dart';

class SavedTripsScreen extends ConsumerStatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  ConsumerState<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends ConsumerState<SavedTripsScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  String? _detailsId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) _refresh();
    });
  }

  Future<void> _refresh() =>
      ref.read(matchmakingViewModelProvider.notifier).refreshSavedTrips();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _join(MatchmakingTrip trip) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _SavedTripJoinDialog(trip: trip),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request sent. Waiting for the host to respond.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchmakingViewModelProvider);
    final notifier = ref.read(matchmakingViewModelProvider.notifier);
    final details = state.trips
        .where((trip) => trip.id == _detailsId)
        .firstOrNull;
    final missingIds = state.savedTripIds.difference(
      state.trips.map((trip) => trip.id).toSet(),
    );
    return PopScope(
      canPop: _detailsId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _detailsId = null);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5FB),
        appBar: AppBar(
          title: Text(_detailsId == null ? 'Saved Trips' : 'Trip Details'),
          leading: _detailsId == null
              ? null
              : BackButton(onPressed: () => setState(() => _detailsId = null)),
          actions: [
            IconButton(
              tooltip: 'Refresh saved trips',
              onPressed: state.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: _detailsId != null
                  ? details == null
                        ? const Center(
                            child: Text('This trip is no longer available.'),
                          )
                        : TripDetailsPage(
                            trip: details,
                            canOpenGroup:
                                details.isOwned ||
                                state.joinedTripIds.contains(details.id),
                            canRequest:
                                state.canRequestTrip(details) &&
                                !state.isLoading,
                            onBack: () => setState(() => _detailsId = null),
                            onRequest: () => _join(details),
                            onOpenGroup: () =>
                                context.push(Routes.tripTimeline(details.id)),
                          )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Trips you are interested in. Saving a trip does not send a join request.',
                          ),
                          const SizedBox(height: 16),
                          if (!state.isAuthenticated && !state.isLoading)
                            const Text('Sign in to view your saved trips.')
                          else if (state.savedTripIds.isEmpty &&
                              !state.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Text(
                                'No saved trips yet. Tap the heart on a trip to save it for later.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          for (final trip in state.savedTrips)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SavedTripCard(
                                trip: trip,
                                canJoin:
                                    state.canRequestTrip(trip) &&
                                    !state.isLoading,
                                joinLabel: state.joinedTripIds.contains(trip.id)
                                    ? 'Already joined'
                                    : state.hasJoinRequest(trip.id)
                                    ? 'Request sent'
                                    : 'Join Trip',
                                removing: state.savingTripIds.contains(trip.id),
                                onDetails: () =>
                                    setState(() => _detailsId = trip.id),
                                onRemove: () => notifier.setTripSaved(
                                  trip.id,
                                  saved: false,
                                ),
                                onJoin: () => _join(trip),
                              ),
                            ),
                          for (final id in missingIds)
                            Card(
                              color: const Color(0xFFF0F0F0),
                              child: ListTile(
                                title: const Text('Trip unavailable'),
                                subtitle: const Text(
                                  'This saved trip was removed or is no longer accessible.',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove saved trip',
                                  onPressed: state.savingTripIds.contains(id)
                                      ? null
                                      : () => notifier.setTripSaved(
                                          id,
                                          saved: false,
                                        ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTripJoinDialog extends ConsumerStatefulWidget {
  const _SavedTripJoinDialog({required this.trip});
  final MatchmakingTrip trip;
  @override
  ConsumerState<_SavedTripJoinDialog> createState() =>
      _SavedTripJoinDialogState();
}

class _SavedTripJoinDialogState extends ConsumerState<_SavedTripJoinDialog> {
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final sent = await ref
        .read(matchmakingViewModelProvider.notifier)
        .joinSavedTrip(widget.trip.id, _message.text);
    if (!mounted) return;
    if (sent) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _sending = false;
      _error =
          ref.read(matchmakingViewModelProvider).errorMessage ??
          'Unable to send the request. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: AlertDialog(
      title: Text('Join ${widget.trip.destination}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introduce yourself to the host. Your place is confirmed after the host accepts your request.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              enabled: !_sending,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message to host'),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Sending...' : 'Send join request'),
        ),
      ],
    ),
  );
}
