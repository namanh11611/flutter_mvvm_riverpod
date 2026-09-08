import 'dart:async';

import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_models.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_notification.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_page.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/repository/matchmaking_repository.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late MatchmakingViewModel notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(matchmakingViewModelProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('does not show fixture trips without a database session', () {
    final state = container.read(matchmakingViewModelProvider);

    expect(state.trips, isEmpty);
    expect(state.discoveryTrips, isEmpty);
    expect(state.applicants, isEmpty);
    expect(state.requests, isEmpty);
  });

  test('cannot create a local-only join request while signed out', () {
    expect(notifier.sendRequest('missing-trip', 'Please add me.'), isFalse);
    expect(container.read(matchmakingViewModelProvider).requests, isEmpty);
  });

  test('navigation and discovery filters remain local UI state', () {
    notifier.goTo(MatchmakingPage.filters);
    notifier.selectFilter('Culture');

    final state = container.read(matchmakingViewModelProvider);
    expect(state.page, MatchmakingPage.filters);
    expect(state.selectedFilter, 'Culture');
  });

  test('accepting the final traveller removes other open requests', () async {
    final repository = _FullTripRepository();
    final connectedContainer = ProviderContainer(
      overrides: [matchmakingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(connectedContainer.dispose);
    final connectedNotifier = connectedContainer.read(
      matchmakingViewModelProvider.notifier,
    );
    await connectedNotifier.refresh();
    repository.connected = false;

    connectedNotifier.decideRequest(
      'accepted-request',
      ApplicantDecision.accepted,
    );

    final state = connectedContainer.read(matchmakingViewModelProvider);
    expect(state.trips.single.spotsLeft, 0);
    expect(
      state.requests.map((request) => request.id),
      contains('accepted-request'),
    );
    expect(
      state.requests.map((request) => request.id),
      isNot(contains('other-request')),
    );
  });

  test('an older refresh cannot overwrite a newer trip snapshot', () async {
    final repository = _DelayedRefreshRepository();
    final connectedContainer = ProviderContainer(
      overrides: [matchmakingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(connectedContainer.dispose);
    final connectedNotifier = connectedContainer.read(
      matchmakingViewModelProvider.notifier,
    );
    repository.connected = true;

    final olderRefresh = connectedNotifier.refresh();
    final newerRefresh = connectedNotifier.refresh();

    repository.tripReads[1].complete([repository.trip(joined: 2)]);
    await newerRefresh;
    expect(
      connectedContainer
          .read(matchmakingViewModelProvider)
          .trips
          .single
          .spotsLeft,
      0,
    );

    repository.tripReads[0].complete([repository.trip(joined: 0)]);
    await olderRefresh;
    expect(
      connectedContainer
          .read(matchmakingViewModelProvider)
          .trips
          .single
          .spotsLeft,
      0,
    );
  });
}

class _DelayedRefreshRepository extends MatchmakingRepository {
  bool connected = false;
  final List<Completer<List<MatchmakingTrip>>> tripReads = [];

  @override
  bool get hasAuthenticatedUser => connected;

  @override
  String get currentUserId => 'owner-id';

  MatchmakingTrip trip({required int joined}) => MatchmakingTrip(
    id: 'trip-id',
    destination: 'Osaka, Japan',
    startDate: DateTime(2026, 9, 10),
    endDate: DateTime(2026, 9, 12),
    budget: 1000,
    styles: const {'Culture'},
    hostId: 'owner-id',
    hostName: 'Owner',
    hostInitials: 'O',
    imageUrl: '',
    gender: 'Any',
    minAge: 18,
    maxAge: 60,
    vacancies: 2,
    joined: joined,
    description: '',
    isOwned: true,
  );

  @override
  Future<List<MatchmakingTrip>> fetchTrips() {
    final read = Completer<List<MatchmakingTrip>>();
    tripReads.add(read);
    return read.future;
  }

  @override
  Future<Set<String>> fetchSavedTripIds() async => {};

  @override
  Future<List<JoinRequest>> fetchJoinRequests() async => [];

  @override
  Future<Set<String>> fetchJoinedTripIds() async => {};

  @override
  Future<Set<String>> fetchDismissedGroupIds() async => {};

  @override
  Future<List<MatchmakingApplicant>> fetchApplicants() async => [];

  @override
  Future<List<MatchmakingNotification>> fetchNotifications() async => [];
}

class _FullTripRepository extends MatchmakingRepository {
  _FullTripRepository();

  bool connected = true;

  @override
  bool get hasAuthenticatedUser => connected;

  @override
  String get currentUserId => 'owner-id';

  @override
  Future<List<MatchmakingTrip>> fetchTrips() async => [
    MatchmakingTrip(
      id: 'trip-id',
      destination: 'Osaka, Japan',
      startDate: DateTime(2026, 9, 10),
      endDate: DateTime(2026, 9, 12),
      budget: 1000,
      styles: const {'Culture'},
      hostId: 'owner-id',
      hostName: 'Owner',
      hostInitials: 'O',
      imageUrl: '',
      gender: 'Any',
      minAge: 18,
      maxAge: 60,
      vacancies: 1,
      description: '',
      isOwned: true,
    ),
  ];

  @override
  Future<List<JoinRequest>> fetchJoinRequests() async => const [
    JoinRequest(
      id: 'accepted-request',
      tripId: 'trip-id',
      applicantId: 'applicant-one',
      message: 'Please add me.',
    ),
    JoinRequest(
      id: 'other-request',
      tripId: 'trip-id',
      applicantId: 'applicant-two',
      message: 'I would also like to join.',
    ),
  ];

  @override
  Future<Set<String>> fetchSavedTripIds() async => {};

  @override
  Future<Set<String>> fetchJoinedTripIds() async => {};

  @override
  Future<Set<String>> fetchDismissedGroupIds() async => {};

  @override
  Future<List<MatchmakingApplicant>> fetchApplicants() async => [];

  @override
  Future<List<MatchmakingNotification>> fetchNotifications() async => [];

  @override
  Future<void> decideJoinRequest(
    String requestId,
    ApplicantDecision decision,
  ) async {}
}
