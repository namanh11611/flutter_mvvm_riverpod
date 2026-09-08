import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../collaboration/model/collaboration_models.dart';
import '../model/shared_live_location.dart';
import '../repository/live_location_repository.dart';
import 'state/live_location_state.dart';
import 'view_model/live_location_view_model.dart';

class TripLiveLocationsScreen extends ConsumerStatefulWidget {
  const TripLiveLocationsScreen({
    required this.tripId,
    required this.members,
    required this.currentUserId,
    super.key,
  });

  final String tripId;
  final List<CollaborationMember> members;
  final String currentUserId;

  @override
  ConsumerState<TripLiveLocationsScreen> createState() =>
      _TripLiveLocationsScreenState();
}

class _TripLiveLocationsScreenState
    extends ConsumerState<TripLiveLocationsScreen> {
  Timer? _freshnessTimer;
  Timer? _autoFollowTimer;
  late final Stream<List<SharedLiveLocation>> _locations;
  final MapController _mapController = MapController();
  String? _selectedUserId;
  LatLng? _lastFollowedPoint;
  SharedLiveLocation? _latestSelectedShare;
  bool _autoFollowPaused = false;
  bool _isStoppingShare = false;
  bool _shareStoppedLocally = false;

  @override
  void initState() {
    super.initState();
    _locations = ref
        .read(liveLocationRepositoryProvider)
        .watchTripShares(widget.tripId)
        .asBroadcastStream();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _freshnessTimer?.cancel();
    _autoFollowTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharingState = ref.watch(liveLocationViewModelProvider);
    final sharingViewModel = ref.read(liveLocationViewModelProvider.notifier);
    ref.listen(
      liveLocationViewModelProvider.select((value) => value.error),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
        sharingViewModel.clearError();
      },
    );
    final tripCanShare = sharingState.trips.any(
      (trip) => trip.id == widget.tripId,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Live locations')),
      bottomNavigationBar: StreamBuilder<List<SharedLiveLocation>>(
        stream: _locations,
        builder: (context, snapshot) {
          final hasPersistedShare = snapshot.data?.any(
                (share) =>
                    share.userId == widget.currentUserId &&
                    share.isActiveAt(DateTime.now()),
              ) ??
              false;
          final sharingThisTrip =
              (hasPersistedShare && !_shareStoppedLocally) ||
              (sharingState.isSharing &&
                  sharingState.selectedTripId == widget.tripId);
          final sharingAnotherTrip =
              sharingState.isSharing && !sharingThisTrip;
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: !snapshot.hasData ||
                      sharingState.isLoading ||
                      sharingState.isStarting ||
                      _isStoppingShare ||
                      sharingAnotherTrip ||
                      (!tripCanShare && !sharingThisTrip)
                  ? null
                  : sharingThisTrip
                      ? () => _stopSharing(sharingViewModel)
                      : () => _startSharing(
                          sharingViewModel,
                          sharingState.duration,
                        ),
              icon: sharingState.isStarting || _isStoppingShare
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      sharingThisTrip
                          ? Icons.location_off_outlined
                          : Icons.location_on_outlined,
                    ),
              label: Text(
                _isStoppingShare
                    ? 'Stopping sharing…'
                    : sharingState.isStarting
                    ? 'Getting your location…'
                    : sharingThisTrip
                        ? 'Stop sharing my location'
                        : sharingAnotherTrip
                            ? 'Stop your other share first'
                            : !tripCanShare
                                ? 'This trip is not active'
                                : 'Start sharing my location',
              ),
            ),
          );
        },
      ),
      body: StreamBuilder<List<SharedLiveLocation>>(
        stream: _locations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load live locations: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final active = snapshot.data!
              .where(
                (share) =>
                    share.isActiveAt(now) &&
                    !(_shareStoppedLocally &&
                        share.userId == widget.currentUserId),
              )
              .toList(growable: false);
          if (active.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined, size: 52),
                    SizedBox(height: 12),
                    Text(
                      'No trip members are sharing their live location.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final selected = active.where(
            (share) => share.userId == _selectedUserId,
          ).firstOrNull;
          final initialShare = selected ?? active.first;
          if (selected != null) _followSelected(selected);
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _point(initialShare),
                        initialZoom: 16,
                        onPointerDown: (_, _) => _pauseAutoFollow(),
                        onPositionChanged: (_, hasGesture) {
                          if (hasGesture) _pauseAutoFollow();
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.henry.flutter_mvvm_riverpod',
                        ),
                        _AnimatedLocationMarkers(
                          shares: active,
                          members: widget.members,
                          currentUserId: widget.currentUserId,
                          selectedUserId: _selectedUserId,
                          onSelected: _selectShare,
                        ),
                      ],
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _autoFollowPaused && _selectedUserId != null
                            ? const Chip(
                                key: ValueKey('auto-follow-paused'),
                                avatar: Icon(Icons.pan_tool_outlined, size: 16),
                                label: Text('Auto-follow paused'),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: _openOpenStreetMapCopyright,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: active.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _LocationCard(
                    share: active[index],
                    member: _member(active[index].userId),
                    isCurrentUser:
                        active[index].userId == widget.currentUserId,
                    isSelected: active[index].userId == _selectedUserId,
                    onSelected: () => _selectShare(active[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  CollaborationMember? _member(String userId) => widget.members
      .where((member) => member.userId == userId)
      .firstOrNull;

  LatLng _point(SharedLiveLocation share) =>
      LatLng(share.latitude, share.longitude);

  void _selectShare(SharedLiveLocation share) {
    _autoFollowTimer?.cancel();
    setState(() {
      _selectedUserId = share.userId;
      _autoFollowPaused = false;
    });
    _latestSelectedShare = share;
    _moveToShare(share);
  }

  void _followSelected(SharedLiveLocation share) {
    _latestSelectedShare = share;
    if (_autoFollowPaused) return;
    final point = _point(share);
    if (point == _lastFollowedPoint) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_autoFollowPaused) _moveToShare(share);
    });
  }

  void _moveToShare(SharedLiveLocation share) {
    final point = _point(share);
    _lastFollowedPoint = point;
    // Recenter without changing the zoom level chosen by the user.
    _mapController.move(point, _mapController.camera.zoom);
  }

  void _pauseAutoFollow() {
    if (_selectedUserId == null) return;
    _autoFollowTimer?.cancel();
    if (!_autoFollowPaused && mounted) {
      setState(() => _autoFollowPaused = true);
    }
    _autoFollowTimer = Timer(const Duration(minutes: 3), () {
      if (!mounted) return;
      setState(() => _autoFollowPaused = false);
      final share = _latestSelectedShare;
      if (share != null) _moveToShare(share);
    });
  }

  Future<void> _openOpenStreetMapCopyright() => launchUrl(
    Uri.parse('https://www.openstreetmap.org/copyright'),
    mode: LaunchMode.externalApplication,
  );

  Future<void> _startSharing(
    LiveLocationViewModel viewModel,
    Duration currentDuration,
  ) async {
    var selectedDuration = currentDuration;
    final duration = await showDialog<Duration>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.location_on_outlined),
          title: const Text('Share with this trip group?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GoBuddy will share your precise location, including while '
                'the screen is locked. You can stop sharing here at any time.',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Duration>(
                initialValue: selectedDuration,
                decoration: const InputDecoration(
                  labelText: 'Sharing time',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: Duration(hours: 1),
                    child: Text('1 hour'),
                  ),
                  DropdownMenuItem(
                    value: Duration(hours: 8),
                    child: Text('8 hours'),
                  ),
                  DropdownMenuItem(
                    value: untilTripEndsDuration,
                    child: Text('Until trip ends'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedDuration = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, selectedDuration),
              child: const Text('Start sharing'),
            ),
          ],
        ),
      ),
    );
    if (duration != null && mounted) {
      setState(() => _shareStoppedLocally = false);
      viewModel.setDuration(duration);
      await viewModel.startSharing(tripId: widget.tripId);
    }
  }

  Future<void> _stopSharing(LiveLocationViewModel viewModel) async {
    setState(() => _isStoppingShare = true);
    final stopped = await viewModel.stopSharingForTrip(widget.tripId);
    if (!mounted) return;
    setState(() {
      _isStoppingShare = false;
      if (stopped) _shareStoppedLocally = true;
    });
  }
}

class _AnimatedLocationMarkers extends StatefulWidget {
  const _AnimatedLocationMarkers({
    required this.shares,
    required this.members,
    required this.currentUserId,
    required this.selectedUserId,
    required this.onSelected,
  });

  final List<SharedLiveLocation> shares;
  final List<CollaborationMember> members;
  final String currentUserId;
  final String? selectedUserId;
  final ValueChanged<SharedLiveLocation> onSelected;

  @override
  State<_AnimatedLocationMarkers> createState() =>
      _AnimatedLocationMarkersState();
}

class _AnimatedLocationMarkersState extends State<_AnimatedLocationMarkers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Map<String, LatLng> _from = {};
  final Map<String, LatLng> _to = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    for (final share in widget.shares) {
      final point = LatLng(share.latitude, share.longitude);
      _from[share.userId] = point;
      _to[share.userId] = point;
    }
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _AnimatedLocationMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    final progress = Curves.easeOut.transform(_controller.value);
    final activeIds = widget.shares.map((share) => share.userId).toSet();
    _from.removeWhere((id, _) => !activeIds.contains(id));
    _to.removeWhere((id, _) => !activeIds.contains(id));
    var moved = false;
    for (final share in widget.shares) {
      final target = LatLng(share.latitude, share.longitude);
      final previousTarget = _to[share.userId] ?? target;
      final displayed = _interpolate(
        _from[share.userId] ?? previousTarget,
        previousTarget,
        progress,
      );
      _from[share.userId] = displayed;
      _to[share.userId] = target;
      moved = moved || displayed != target;
    }
    if (moved) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final progress = Curves.easeOut.transform(_controller.value);
      return MarkerLayer(
        markers: widget.shares.map((share) {
          final point = _interpolate(
            _from[share.userId]!,
            _to[share.userId]!,
            progress,
          );
          final member = widget.members
              .where((item) => item.userId == share.userId)
              .firstOrNull;
          final name = share.userId == widget.currentUserId
              ? 'You'
              : member?.displayName ?? 'Trip member';
          final selected = share.userId == widget.selectedUserId;
          return Marker(
            point: point,
            width: selected ? 70 : 58,
            height: selected ? 70 : 58,
            child: Semantics(
              label: '$name live location',
              button: true,
              child: GestureDetector(
                onTap: () => widget.onSelected(share),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white70,
                      width: selected ? 4 : 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      );
    },
  );

  LatLng _interpolate(LatLng start, LatLng end, double progress) => LatLng(
    start.latitude + (end.latitude - start.latitude) * progress,
    start.longitude + (end.longitude - start.longitude) * progress,
  );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.share,
    required this.member,
    required this.isCurrentUser,
    required this.isSelected,
    required this.onSelected,
  });

  final SharedLiveLocation share;
  final CollaborationMember? member;
  final bool isCurrentUser;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final name = isCurrentUser
        ? 'You'
        : member?.displayName?.trim().isNotEmpty == true
        ? member!.displayName!
        : 'Trip member';
    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    foregroundImage: member?.profilePhotoUrl == null
                        ? null
                        : NetworkImage(member!.profilePhotoUrl!),
                    child: member?.profilePhotoUrl == null
                        ? Text(name.characters.first.toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Updated ${_relativeTime(share.recordedAt)} · '
                          'accurate to about ${share.accuracy.round()} m',
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.location_on, color: Colors.green),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openMaps(context),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${share.latitude},${share.longitude}',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the maps app.')),
      );
    }
  }

  static String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inSeconds < 45) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
}
