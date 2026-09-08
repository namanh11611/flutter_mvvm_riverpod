import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_models.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_notification.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/repository/matchmaking_repository.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_state.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/saved_trip_card.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/saved_trips_screen.dart';

MatchmakingTrip trip() => MatchmakingTrip(
  id: 'trip',
  destination: 'Penang',
  startDate: DateTime.now().add(const Duration(days: 10)),
  endDate: DateTime.now().add(const Duration(days: 12)),
  budget: 500,
  styles: const {'Food'},
  hostId: 'host',
  hostName: 'Host',
  hostInitials: 'H',
  imageUrl: '',
  gender: 'Any',
  minAge: 18,
  maxAge: 80,
  vacancies: 2,
  description: 'Explore Penang.',
);

void main() {
  test('saved list includes full and started trips outside discovery', () {
    final full = trip().copyWith(joined: 2);
    final state = MatchmakingState(
      currentUserId: 'user',
      trips: [full],
      savedTripIds: const {'trip'},
    );
    expect(state.savedTrips, [full]);
    expect(state.discoveryTrips, isEmpty);
    expect(full.unavailableReason, 'Full');
    expect(state.canRequestTrip(full), false);
    expect(
      trip()
          .copyWith(
            startDate: DateTime.now().subtract(const Duration(hours: 1)),
          )
          .unavailableReason,
      'Trip started',
    );
    expect(
      trip().copyWith(status: TripStatus.closed).unavailableReason,
      'Trip closed',
    );
  });

  test(
    'saving persists without joining and failed removal rolls back',
    () async {
      final repo = SavedRepository();
      final container = ProviderContainer(
        overrides: [matchmakingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final vm = container.read(matchmakingViewModelProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(await vm.toggleSavedTrip('trip'), true);
      expect(repo.saved, {'trip'});
      expect(repo.sent, 0);
      expect(container.read(matchmakingViewModelProvider).requests, isEmpty);
      repo.failSave = true;
      expect(await vm.setTripSaved('trip', saved: false), false);
      expect(container.read(matchmakingViewModelProvider).savedTripIds, {
        'trip',
      });
      repo.failSave = false;
      expect(await vm.setTripSaved('trip', saved: false), true);
      expect(repo.saved, isEmpty);
    },
  );

  test('rapid taps do not create overlapping writes', () async {
    final repo = SavedRepository()..writeGate = Completer<void>();
    final container = ProviderContainer(
      overrides: [matchmakingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final vm = container.read(matchmakingViewModelProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final first = vm.toggleSavedTrip('trip');
    expect(await vm.toggleSavedTrip('trip'), false);
    repo.writeGate!.complete();
    expect(await first, true);
    expect(repo.saved, {'trip'});
    expect(container.read(matchmakingViewModelProvider).savingTripIds, isEmpty);
  });

  test('joining rechecks capacity and prevents duplicate requests', () async {
    final repo = SavedRepository()..saved.add('trip');
    final container = ProviderContainer(
      overrides: [matchmakingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final vm = container.read(matchmakingViewModelProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    repo.currentTrip = trip().copyWith(joined: 2);
    expect(await vm.joinSavedTrip('trip', 'I would like to join.'), false);
    expect(repo.sent, 0);
    expect(container.read(matchmakingViewModelProvider).errorMessage, 'Full');
    repo.currentTrip = trip();
    expect(await vm.joinSavedTrip('trip', 'I would like to join.'), true);
    expect(repo.sent, 1);
    expect(repo.saved, {'trip'});
    expect(await vm.joinSavedTrip('trip', 'Another request'), false);
    expect(repo.sent, 1);
  });

  testWidgets(
    'unavailable card stays grey, keeps details/remove, disables join',
    (tester) async {
      var details = 0;
      var removed = 0;
      var joined = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedTripCard(
              trip: trip().copyWith(joined: 2),
              canJoin: true,
              onDetails: () => details++,
              onRemove: () => removed++,
              onJoin: () => joined++,
            ),
          ),
        ),
      );
      expect(find.text('Full'), findsOneWidget);
      expect(
        tester.widget<Card>(find.byType(Card)).color,
        const Color(0xFFEEEEEE),
      );
      await tester.tap(find.text('View Details'));
      await tester.tap(find.text('Remove Saved Trip'));
      expect(details, 1);
      expect(removed, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(joined, 0);
    },
  );

  testWidgets('saved page opens trip details and removes saved trip', (
    tester,
  ) async {
    final repo = SavedRepository()..saved.add('trip');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [matchmakingRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SavedTripsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Penang'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('Trip Details'), findsOneWidget);
    expect(find.text('Explore Penang.'), findsOneWidget);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Saved Trip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No saved trips yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class SavedRepository extends MatchmakingRepository {
  final Set<String> saved = {};
  final List<JoinRequest> requests = [];
  MatchmakingTrip currentTrip = trip();
  bool failSave = false;
  int sent = 0;
  Completer<void>? writeGate;
  @override
  bool get hasAuthenticatedUser => true;
  @override
  String get currentUserId => 'user';
  @override
  Future<List<MatchmakingTrip>> fetchTrips() async => [currentTrip];
  @override
  Future<Set<String>> fetchSavedTripIds() async => {...saved};
  @override
  Future<List<JoinRequest>> fetchJoinRequests() async => [...requests];
  @override
  Future<Set<String>> fetchJoinedTripIds() async => {};
  @override
  Future<Set<String>> fetchDismissedGroupIds() async => {};
  @override
  Future<List<MatchmakingApplicant>> fetchApplicants() async => [];
  @override
  Future<List<MatchmakingNotification>> fetchNotifications() async => [];
  @override
  Future<void> setTripSaved(String id, {required bool saved}) async {
    if (writeGate != null) await writeGate!.future;
    if (failSave) throw Exception('Unable to save');
    saved ? this.saved.add(id) : this.saved.remove(id);
  }

  @override
  Future<void> sendJoinRequest(String tripId, String message) async {
    sent++;
    requests.add(
      JoinRequest(
        id: 'request',
        tripId: tripId,
        applicantId: 'user',
        message: message,
      ),
    );
  }
}
