import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../common/ui/widgets/app_module_navigation.dart';
import '../../common/remote/supabase_client.dart';
import '../../../core/routing/routes.dart';
import '../model/matchmaking_models.dart';
import '../model/matchmaking_validation.dart';
import '../model/matchmaking_notification.dart';
import '../model/matchmaking_page.dart';
import '../model/user_currency.dart';
import '../repository/destination_image_service.dart';
import '../repository/currency_conversion_provider.dart';
import '../repository/location_search_service.dart';
import 'matchmaking_state.dart';
import 'matchmaking_view_model.dart';
import '../../safety/repository/safety_check_in_configuration_repository.dart';
import '../../safety/ui/widgets/user_safety_actions.dart';
import '../../user_account/ui/view_model/user_account_view_model.dart';
import '../../common/ui/widgets/verified_access_gate.dart';

part 'discover_page.dart';
part 'filter_page.dart';
part 'trip_details_page.dart';
part 'trip_form_page.dart';
part 'my_trips_page.dart';
part 'request_pages.dart';
part 'management_pages.dart';
part 'matchmaking_widgets.dart';

const _ink = Color(0xFF281950);
const _violet = Color(0xFF7C3AED);
const _border = Color(0xFFD5CFEF);
const _muted = Color(0xFF686082);
const _lavender = Color(0xFFEDE9FE);

class MatchmakingShellScreen extends ConsumerStatefulWidget {
  const MatchmakingShellScreen({super.key});

  @override
  ConsumerState<MatchmakingShellScreen> createState() =>
      _MatchmakingShellScreenState();
}

class _MatchmakingShellScreenState
    extends ConsumerState<MatchmakingShellScreen> {
  SupabaseClient? _realtimeClient;
  RealtimeChannel? _tripsChannel;
  StreamSubscription<AuthState>? _authSubscription;
  String? _subscribedUserId;
  int _subscriptionRevision = 0;
  Timer? _realtimeRefreshTimer;
  Timer? _tripStartTimer;
  bool _checkingTripStarts = false;
  bool _tripStartSyncPending = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<MatchmakingState>(
      matchmakingViewModelProvider,
      (_, next) => unawaited(_syncTripStartPrompts(next)),
      fireImmediately: true,
    );
    try {
      final client = supabase;
      _realtimeClient = client;
      _subscribeToTrips(client.auth.currentUser?.id);
      _authSubscription = client.auth.onAuthStateChange.listen((authState) {
        _subscribeToTrips(authState.session?.user.id);
      });
    } catch (_) {
      // Supabase is initialized by the app bootstrap. Keeping realtime optional
      // here also lets the shell render in isolated widget tests and previews.
    }
  }

  Future<void> _subscribeToTrips(String? userId) async {
    final client = _realtimeClient;
    if (!mounted || client == null || userId == _subscribedUserId) return;
    final subscriptionRevision = ++_subscriptionRevision;

    final previousChannel = _tripsChannel;
    _tripsChannel = null;
    _subscribedUserId = null;
    if (previousChannel != null) {
      await client.removeChannel(previousChannel);
    }
    if (!mounted ||
        subscriptionRevision != _subscriptionRevision ||
        userId == null) {
      return;
    }

    _subscribedUserId = userId;
    void refreshForCurrentSubscription() {
      if (mounted &&
          subscriptionRevision == _subscriptionRevision &&
          userId == _subscribedUserId) {
        _scheduleTripsRefresh();
      }
    }

    final channel = client
        .channel('matchmaking-trips-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_trips',
          callback: (_) => refreshForCurrentSubscription(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_trip_styles',
          callback: (_) => refreshForCurrentSubscription(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_saved_trips',
          callback: (_) => refreshForCurrentSubscription(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_join_requests',
          callback: (_) => refreshForCurrentSubscription(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => refreshForCurrentSubscription(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_trip_members',
          callback: (_) => refreshForCurrentSubscription(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_members',
          callback: (_) => refreshForCurrentSubscription(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Close the gap between the initial query and channel readiness.
            refreshForCurrentSubscription();
          }
        });
    if (!mounted || subscriptionRevision != _subscriptionRevision) {
      await client.removeChannel(channel);
      return;
    }
    _tripsChannel = channel;
  }

  void _scheduleTripsRefresh() {
    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) ref.read(matchmakingViewModelProvider.notifier).refresh();
    });
  }

  Future<void> _syncTripStartPrompts(MatchmakingState state) async {
    _tripStartTimer?.cancel();
    _tripStartTimer = null;
    if (_checkingTripStarts) {
      _tripStartSyncPending = true;
      return;
    }
    if (!mounted || !state.isAuthenticated) return;

    _checkingTripStarts = true;
    try {
      final involvedTrips = state.trips.where(
        (trip) =>
            trip.status == TripStatus.active &&
            (trip.isOwned || state.joinedTripIds.contains(trip.id)),
      );
      final now = DateTime.now();
      final startedTrips =
          involvedTrips
              .where(
                (trip) =>
                    !trip.startsAt.isAfter(now) && now.isBefore(trip.endsAfter),
              )
              .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      final preferences = await SharedPreferences.getInstance();

      for (final trip in startedTrips) {
        final promptKey = _tripStartPromptKey(state.currentUserId, trip.id);
        if (preferences.getBool(promptKey) == true) continue;

        // Persist before opening the dialog so realtime refreshes and app
        // rebuilds cannot enqueue a duplicate prompt for this user and trip.
        await preferences.setBool(promptKey, true);
        await _offerSafetyCheckIn();
        if (!mounted || state.currentUserId != _subscribedUserId) return;
      }

      final nextStart = involvedTrips
          .map((trip) => trip.startsAt)
          .where((start) => start.isAfter(now))
          .fold<DateTime?>(
            null,
            (earliest, start) =>
                earliest == null || start.isBefore(earliest) ? start : earliest,
          );
      if (nextStart != null && mounted) {
        _tripStartTimer = Timer(
          nextStart.difference(DateTime.now()),
          () => _syncTripStartPrompts(ref.read(matchmakingViewModelProvider)),
        );
      }
    } finally {
      _checkingTripStarts = false;
      if (_tripStartSyncPending && mounted) {
        _tripStartSyncPending = false;
        unawaited(
          _syncTripStartPrompts(ref.read(matchmakingViewModelProvider)),
        );
      }
    }
  }

  String _tripStartPromptKey(String userId, String tripId) =>
      'safety_check_in_trip_start_prompt:$userId:$tripId';

  Future<void> _offerSafetyCheckIn() async {
    final configuration = await ref
        .read(safetyCheckInConfigurationRepositoryProvider)
        .load();
    if (!mounted || configuration.enabled) return;

    final enableNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn on safety check-ins?'),
        content: const Text(
          'Get regular reminders during your trip to confirm that you are safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (enableNow == true) {
      await context.push(Routes.safetyCheckInSettings);
    } else if (enableNow == false) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'You can turn on Safety Check-In anytime in the Settings.',
            ),
          ),
        );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tripStartTimer?.cancel();
    _realtimeRefreshTimer?.cancel();
    _subscriptionRevision++;
    final channel = _tripsChannel;
    final client = _realtimeClient;
    if (channel != null && client != null) client.removeChannel(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      matchmakingViewModelProvider.select((state) => state.successMessage),
      (previous, next) {
        if (next != null && next != previous) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next)));
          Future<void>.microtask(
            () => ref
                .read(matchmakingViewModelProvider.notifier)
                .clearSuccessMessage(),
          );
        }
      },
    );
    final state = ref.watch(matchmakingViewModelProvider);
    final accountState = state.isAuthenticated
        ? ref.watch(userAccountViewModelProvider)
        : null;
    final currency = UserCurrency.fromNationality(
      accountState?.user?.nationality,
    );
    final currencyRate =
        ref
            .watch(
              currencyConversionRateProvider((from: 'MYR', to: currency.code)),
            )
            .value ??
        1;
    final viewModel = ref.read(matchmakingViewModelProvider.notifier);
    final isVerified = accountState?.user?.isVerified == true;
    final page = state.page;
    final content = switch (page) {
      MatchmakingPage.discover => DiscoverPage(
        isAuthenticated: state.isAuthenticated,
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        filter: state.selectedFilter,
        trips: state.discoveryTrips,
        savedTripIds: state.savedTripIds,
        filters: state.availableFilters,
        notifications: state.notifications,
        unreadNotificationCount: state.unreadNotificationCount,
        profilePhotoUrl: accountState?.user?.profilePhoto,
        isVerified: isVerified,
        currency: currency,
        currencyRate: currencyRate,
        onNotificationsRead: viewModel.markNotificationsRead,
        onRetry: viewModel.refresh,
        onFilter: viewModel.selectFilter,
        onOpenFilters: () => viewModel.goTo(MatchmakingPage.filters),
        onDetails: (id) => viewModel.openTrip(id, MatchmakingPage.details),
        onRequest: (id) => viewModel.openTrip(id, MatchmakingPage.request),
        onSave: viewModel.toggleSavedTrip,
      ),
      MatchmakingPage.filters => InteractiveFilterPage(
        currency: currency,
        currencyRate: currencyRate,
        initialFilters: state.filters,
        onBack: () => viewModel.goTo(MatchmakingPage.discover),
        onApply: viewModel.applyFilters,
        onReset: viewModel.resetFilters,
      ),
      MatchmakingPage.details => TripDetailsPage(
        currency: currency,
        currencyRate: currencyRate,
        trip: state.selectedTrip!,
        canOpenGroup:
            state.selectedTrip!.isOwned ||
            state.joinedTripIds.contains(state.selectedTrip!.id),
        onBack: () => viewModel.goTo(MatchmakingPage.discover),
        onRequest: () => viewModel.goTo(MatchmakingPage.request),
        onOpenGroup: () =>
            context.push(Routes.tripTimeline(state.selectedTrip!.id)),
      ),
      MatchmakingPage.create => InteractiveTripFormPage(
        currency: currency,
        currencyRate: currencyRate,
        hostedTrips: state.ownedTrips,
        onBack: () => viewModel.goTo(MatchmakingPage.discover),
        onPublish: viewModel.saveTrip,
        onUploadImage: viewModel.uploadTripCover,
        onUploadGalleryImage: viewModel.uploadTripGalleryPhoto,
      ),
      MatchmakingPage.edit => InteractiveTripFormPage(
        currency: currency,
        currencyRate: currencyRate,
        edit: true,
        hostedTrips: state.ownedTrips,
        initialTrip: state.selectedTrip,
        onBack: () => viewModel.goTo(MatchmakingPage.myTrips),
        onPublish: viewModel.saveTrip,
        onUploadImage: viewModel.uploadTripCover,
        onUploadGalleryImage: viewModel.uploadTripGalleryPhoto,
        onDelete: () => viewModel.deleteTrip(state.selectedTrip!.id),
      ),
      MatchmakingPage.myTrips => VerifiedAccessGate(
        featureName: 'My Trips',
        child: MyTripsPage(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        trips: state.ownedTrips,
        joinedTrips: state.joinedTrips,
        removedTrips: state.removedTrips,
        allTrips: state.trips,
        requests: state.myRequests,
        onBack: () => viewModel.goTo(MatchmakingPage.discover),
        onCreate: () => viewModel.goTo(MatchmakingPage.create),
        onRetry: viewModel.refresh,
        onManage: viewModel.openRequests,
        onEdit: (id) => viewModel.openTrip(id, MatchmakingPage.edit),
        onFinish: viewModel.finishTrip,
        onRemoveHosted: viewModel.deleteTrip,
        onLeaveTrip: viewModel.leaveTrip,
        onDismissRemovedTrip: viewModel.dismissRemovedTrip,
        onOpenTimeline: (id) => context.push(Routes.tripTimeline(id)),
          onRemoveRequest: viewModel.removeRequest,
        ),
      ),
      MatchmakingPage.request => RequestPage(
        trip: state.selectedTrip!,
        onCancel: () => viewModel.goTo(MatchmakingPage.details),
        onSend: (message) =>
            viewModel.sendRequest(state.selectedTrip!.id, message),
      ),
      MatchmakingPage.sent => RequestSentPage(
        onBack: () => viewModel.goTo(MatchmakingPage.discover),
      ),
      MatchmakingPage.manage => ManageRequestsPage(
        trip: state.managedTrip!,
        requests: state.managedRequests,
        applicants: state.applicants,
        onBack: () => viewModel.goTo(MatchmakingPage.myTrips),
        onApplicant: viewModel.openApplicant,
        onDecision: viewModel.decideRequest,
      ),
      MatchmakingPage.applicant => ApplicantPage(
        applicant: state.selectedApplicant!,
        request: state.managedRequests.firstWhere(
          (item) => item.applicantId == state.selectedApplicantId,
        ),
        onDecision: (id, decision) {
          viewModel.decideRequest(id, decision);
          viewModel.goTo(MatchmakingPage.manage);
        },
        onBack: () => viewModel.goTo(MatchmakingPage.manage),
      ),
      MatchmakingPage.profile => const ProfilePage(),
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(minHeight: 3),
            if (state.errorMessage != null)
              Material(
                color: const Color(0xFFFFE8E8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not sync with Supabase: '
                          '${state.errorMessage}',
                        ),
                      ),
                      TextButton(
                        onPressed: viewModel.refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: content),
          ],
        ),
      ),
      bottomNavigationBar:
          page == MatchmakingPage.discover || page == MatchmakingPage.myTrips
          ? AppModuleNavigation(
              selectedIndex: page == MatchmakingPage.myTrips ? 1 : 0,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    viewModel.goTo(MatchmakingPage.discover);
                  case 1:
                    viewModel.goTo(MatchmakingPage.myTrips);
                  case 2:
                    context.go(Routes.messages);
                  case 3:
                    _showExpenseTripPicker(state.groupTrips);
                  default:
                    context.push(Routes.userAccount);
                }
              },
            )
          : null,
      floatingActionButton:
          page == MatchmakingPage.discover && state.isAuthenticated && isVerified
          ? FloatingActionButton(
              onPressed: () => viewModel.goTo(MatchmakingPage.create),
              backgroundColor: _violet,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showExpenseTripPicker(List<MatchmakingTrip> trips) async {
    if (trips.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Create or join a trip before adding expenses.'),
          ),
        );
      return;
    }
    final tripId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Choose a trip for expenses')),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: trips.length,
                itemBuilder: (_, index) {
                  final trip = trips[index];
                  return ListTile(
                    leading: const Icon(Icons.luggage_outlined),
                    title: Text(trip.destination),
                    subtitle: Text(trip.isOwned ? 'Hosting' : 'Joined'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(sheetContext, trip.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || tripId == null) return;
    context.push('${Routes.groupExpense}/${Uri.encodeComponent(tripId)}');
  }
}
