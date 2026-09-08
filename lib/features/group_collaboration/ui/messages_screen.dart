import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/app_module_navigation.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_models.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  RealtimeChannel? _membershipChannel;
  StreamSubscription<AuthState>? _authSubscription;
  String? _subscribedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchmakingViewModelProvider.notifier).refresh();
    });
    _subscribeToGroupChanges(supabase.auth.currentUser?.id);
    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      _subscribeToGroupChanges(authState.session?.user.id);
    });
  }

  Future<void> _subscribeToGroupChanges(String? userId) async {
    if (!mounted || userId == _subscribedUserId) return;
    final previousChannel = _membershipChannel;
    _membershipChannel = null;
    _subscribedUserId = null;
    if (previousChannel != null) await supabase.removeChannel(previousChannel);
    if (!mounted || userId == null) return;

    _subscribedUserId = userId;
    _membershipChannel = supabase
        .channel('message-groups-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_trip_members',
          callback: (_) => _refreshGroups(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_members',
          callback: (_) => _refreshGroups(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matchmaking_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _refreshGroups(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _refreshGroups();
        });
  }

  void _refreshGroups() {
    if (mounted) ref.read(matchmakingViewModelProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    final channel = _membershipChannel;
    if (channel != null) supabase.removeChannel(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchmakingViewModelProvider);
    final trips = state.groupTrips;
    return Scaffold(
      appBar: AppBar(title: Text('Messages', style: AppTheme.title20)),
      body: trips.isEmpty
          ? const _EmptyMessages()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Your trip groups',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                final trip = trips[index - 1];
                return _TripConversationCard(
                  trip: trip,
                  wasRemoved:
                      !trip.isOwned && state.wasRemovedFromTrip(trip.id),
                );
              },
            ),
      bottomNavigationBar: const AppModuleNavigation(selectedIndex: 2),
    );
  }
}

class _TripConversationCard extends StatelessWidget {
  const _TripConversationCard({required this.trip, required this.wasRemoved});
  final MatchmakingTrip trip;
  final bool wasRemoved;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.brandSurface,
        child: Text(
          trip.hostInitials.isEmpty
              ? trip.destination.substring(0, 1)
              : trip.hostInitials.substring(0, 1),
        ),
      ),
      title: Text(
        trip.destination,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${_date(trip.startDate)} – ${_date(trip.endDate)} • '
        '${trip.groupMemberCount} '
        '${trip.groupMemberCount == 1 ? 'member' : 'members'}',
      ),
      trailing: wasRemoved
          ? const Chip(
              avatar: Icon(Icons.person_remove_outlined, size: 18),
              label: Text('Removed from group'),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () {
        final path = wasRemoved
            ? '${Routes.tripMessages(trip.id)}?removed=true'
            : Routes.tripTimeline(trip.id);
        context.push(path);
      },
    ),
  );

  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: AppColors.brandSurface,
          ),
          const SizedBox(height: 16),
          Text('No trip chats yet', style: AppTheme.title20),
          const SizedBox(height: 8),
          Text(
            'Trips you create or join will appear here.',
            textAlign: TextAlign.center,
            style: AppTheme.body16.copyWith(color: AppColors.brandTextMuted),
          ),
        ],
      ),
    ),
  );
}
