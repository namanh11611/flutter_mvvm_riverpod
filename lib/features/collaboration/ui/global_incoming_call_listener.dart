import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/core/routing/router.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';

/// Keeps incoming group-call detection alive above every application route.
///
/// The trip workspace owns the audible ringtone and call dialog. This listener
/// makes sure a fresh call opens that workspace even when the recipient is on
/// Home, Trips, Profile, Expenses, or the generic Messages list.
class GlobalIncomingCallListener extends StatefulWidget {
  const GlobalIncomingCallListener({required this.child, super.key});

  final Widget child;

  @override
  State<GlobalIncomingCallListener> createState() =>
      _GlobalIncomingCallListenerState();
}

class _GlobalIncomingCallListenerState extends State<GlobalIncomingCallListener>
    with WidgetsBindingObserver {
  final Set<String> _routedCallIds = {};
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  int _listenerGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {
      unawaited(_restartListener());
    });
    unawaited(_restartListener());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForRecentCalls());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listenerGeneration++;
    _pollTimer?.cancel();
    _authSubscription?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(supabase.removeChannel(channel));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _restartListener() async {
    final generation = ++_listenerGeneration;
    _pollTimer?.cancel();
    final oldChannel = _channel;
    _channel = null;
    if (oldChannel != null) await supabase.removeChannel(oldChannel);
    if (!mounted || generation != _listenerGeneration) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _routedCallIds.clear();
      return;
    }

    final channel = supabase
        .channel('global-incoming-calls-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_calls',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            if (record.isNotEmpty) _handleCallRecord(record);
          },
        );
    _channel = channel;
    channel.subscribe((status, error) {
      debugPrint(
        '[group_call] global_listener_status user_id=$userId '
        'status=${status.name}${error == null ? '' : ' error=$error'}',
      );
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_checkForRecentCalls()),
    );
    await _checkForRecentCalls();
  }

  Future<void> _checkForRecentCalls() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(seconds: 30))
          .toUtc()
          .toIso8601String();
      final rows = await supabase
          .from('trip_calls')
          .select('id, trip_id, initiated_by, call_type, status, created_at')
          .eq('status', 'ringing')
          .gte('created_at', cutoff)
          .order('created_at', ascending: false)
          .limit(5)
          .timeout(const Duration(seconds: 5));
      for (final row in rows.reversed) {
        _handleCallRecord(row);
      }
    } catch (error) {
      debugPrint('[group_call] global_listener_poll_failed error=$error');
    }
  }

  void _handleCallRecord(Map<String, dynamic> record) {
    if (!mounted || record['status'] != 'ringing') return;
    final currentUserId = supabase.auth.currentUser?.id;
    final callId = record['id'] as String?;
    final tripId = record['trip_id'] as String?;
    final initiatedBy = record['initiated_by'] as String?;
    final createdAtText = record['created_at'] as String?;
    if (currentUserId == null ||
        callId == null ||
        tripId == null ||
        initiatedBy == null ||
        initiatedBy == currentUserId ||
        _routedCallIds.contains(callId)) {
      return;
    }
    final createdAt = DateTime.tryParse(createdAtText ?? '')?.toLocal();
    if (createdAt == null ||
        DateTime.now().difference(createdAt) > const Duration(seconds: 30)) {
      return;
    }

    _routedCallIds.add(callId);
    final currentPath = router.routeInformationProvider.value.uri.path;
    final timelinePath = Routes.tripTimeline(tripId);
    final messagesPath = Routes.tripMessages(tripId);
    debugPrint(
      '[group_call] global_incoming_call call_id=$callId trip_id=$tripId '
      'current_path=$currentPath',
    );
    if (currentPath == timelinePath || currentPath == messagesPath) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || supabase.auth.currentUser?.id != currentUserId) return;
      router.push(messagesPath);
    });
  }
}
