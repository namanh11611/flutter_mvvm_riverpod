import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_models.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_notification.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_validation.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MatchmakingTrip trip({
    String id = 'trip',
    DateTime? startDate,
    DateTime? endDate,
    int vacancies = 3,
    int joined = 0,
    TripStatus status = TripStatus.active,
    bool isOwned = false,
  }) {
    final start = startDate ?? DateTime(2030, 1, 10);
    return MatchmakingTrip(
      id: id,
      destination: 'Penang, Malaysia',
      startDate: start,
      endDate: endDate ?? start.add(const Duration(days: 4)),
      budget: 900,
      styles: const {'Foodie'},
      hostId: 'host',
      hostName: 'Traveller',
      hostInitials: 'T',
      imageUrl: '',
      gender: 'Any',
      minAge: 21,
      maxAge: 40,
      vacancies: vacancies,
      joined: joined,
      description: 'A relaxed food and culture trip.',
      status: status,
      isOwned: isOwned,
    );
  }

  test('normalizes valid request messages and rejects invalid messages', () {
    expect(MatchmakingValidation.normalizeRequestMessage('  Hello  '), 'Hello');
    expect(
      () => MatchmakingValidation.normalizeRequestMessage('   '),
      throwsA(isA<MatchmakingValidationException>()),
    );
    expect(
      () => MatchmakingValidation.normalizeRequestMessage(
        List.filled(501, 'x').join(),
      ),
      throwsA(isA<MatchmakingValidationException>()),
    );
  });

  test('rejects past and reversed trip dates', () {
    expect(
      () => MatchmakingValidation.validateTrip(
        trip(startDate: DateTime(2029, 12, 31)),
        now: DateTime(2030, 1, 1),
      ),
      throwsA(isA<MatchmakingValidationException>()),
    );
    expect(
      () => MatchmakingValidation.validateTrip(
        trip(startDate: DateTime(2030, 1, 10), endDate: DateTime(2030, 1, 9)),
        now: DateTime(2030, 1, 1),
      ),
      throwsA(isA<MatchmakingValidationException>()),
    );
  });

  test('allows a trip without a description', () {
    final withoutDescription = trip().copyWith(description: '');

    expect(
      () => MatchmakingValidation.validateTrip(
        withoutDescription,
        now: DateTime(2030, 1, 1),
      ),
      returnsNormally,
    );
  });

  test(
    'discovery excludes full, closed, owned, joined, and requested trips',
    () {
      final available = trip();
      final requested = trip(
        id: 'requested',
      ).copyWith(destination: 'Requested trip');
      final joined = trip(id: 'joined').copyWith(destination: 'Joined trip');
      final state = MatchmakingState(
        currentUserId: 'member',
        joinedTripIds: {joined.id},
        requests: [
          JoinRequest(
            id: 'request',
            tripId: requested.id,
            applicantId: 'member',
            message: 'Please add me.',
          ),
        ],
        trips: [
          available,
          trip(vacancies: 2, joined: 2),
          trip(status: TripStatus.closed),
          requested,
          joined,
          MatchmakingTrip(
            id: 'owned',
            destination: available.destination,
            startDate: available.startDate,
            endDate: available.endDate,
            budget: available.budget,
            styles: available.styles,
            hostId: available.hostId,
            hostName: available.hostName,
            hostInitials: available.hostInitials,
            imageUrl: available.imageUrl,
            gender: available.gender,
            minAge: available.minAge,
            maxAge: available.maxAge,
            vacancies: available.vacancies,
            description: available.description,
            isOwned: true,
          ),
        ],
      );

      expect(state.discoveryTrips.map((item) => item.id), ['trip']);
    },
  );

  test(
    'group chats include owned and joined trips for the current account',
    () {
      final state = MatchmakingState(
        trips: [
          trip(id: 'owned', isOwned: true),
          trip(id: 'joined'),
          trip(id: 'unrelated'),
        ],
        joinedTripIds: const {'joined'},
      );

      expect(state.groupTrips.map((item) => item.id), ['owned', 'joined']);
    },
  );

  test('trip lifecycle changes at its start time and after its final day', () {
    final timedTrip = trip(
      startDate: DateTime(2030, 1, 10),
      endDate: DateTime(2030, 1, 12),
    ).copyWith(startTime: DateTime(2030, 1, 10, 9, 30));

    expect(
      timedTrip.lifecycleAt(DateTime(2030, 1, 10, 9, 29)),
      TripLifecycle.upcoming,
    );
    expect(
      timedTrip.lifecycleAt(DateTime(2030, 1, 10, 9, 30)),
      TripLifecycle.ongoing,
    );
    expect(
      timedTrip.lifecycleAt(DateTime(2030, 1, 12, 23, 59)),
      TripLifecycle.ongoing,
    );
    expect(
      timedTrip.lifecycleAt(DateTime(2030, 1, 13)),
      TripLifecycle.finished,
    );
  });

  test('accepted and cancelled requests do not clutter My Trips', () {
    final state = MatchmakingState(
      currentUserId: 'member',
      requests: const [
        JoinRequest(
          id: 'pending',
          tripId: 'one',
          applicantId: 'member',
          message: 'Pending',
        ),
        JoinRequest(
          id: 'accepted',
          tripId: 'two',
          applicantId: 'member',
          message: 'Accepted',
          decision: ApplicantDecision.accepted,
        ),
        JoinRequest(
          id: 'cancelled',
          tripId: 'three',
          applicantId: 'member',
          message: 'Cancelled',
          decision: ApplicantDecision.cancelled,
        ),
      ],
    );

    expect(state.myRequests.map((request) => request.id), ['pending']);
  });

  test('host cannot create same-day or overlapping trips', () {
    final hosted = trip(
      id: 'hosted',
      startDate: DateTime(2030, 3, 10),
      endDate: DateTime(2030, 3, 12),
      isOwned: true,
    );

    expect(
      () => MatchmakingValidation.validateHostAvailability(
        trip(
          id: 'same-day',
          startDate: DateTime(2030, 3, 10),
          endDate: DateTime(2030, 3, 10),
        ),
        [hosted],
      ),
      throwsA(isA<MatchmakingValidationException>()),
    );
    expect(
      () => MatchmakingValidation.validateHostAvailability(
        trip(
          id: 'overlap',
          startDate: DateTime(2030, 3, 12),
          endDate: DateTime(2030, 3, 14),
        ),
        [hosted],
      ),
      throwsA(isA<MatchmakingValidationException>()),
    );
  });

  test('host may create after a trip ends and may edit the same trip', () {
    final hosted = trip(
      id: 'hosted',
      startDate: DateTime(2030, 3, 10),
      endDate: DateTime(2030, 3, 12),
      isOwned: true,
    );

    expect(
      () => MatchmakingValidation.validateHostAvailability(
        trip(
          id: 'next-trip',
          startDate: DateTime(2030, 3, 13),
          endDate: DateTime(2030, 3, 15),
        ),
        [hosted],
      ),
      returnsNormally,
    );
    expect(
      () => MatchmakingValidation.validateHostAvailability(
        hosted.copyWith(endDate: DateTime(2030, 3, 13)),
        [hosted],
      ),
      returnsNormally,
    );
  });

  test('dismissed removed trips no longer appear in My Trips', () {
    final removed = trip(id: 'removed');
    final state = MatchmakingState(
      trips: [removed],
      dismissedGroupIds: const {'removed'},
      notifications: [
        MatchmakingNotification(
          id: 'notice',
          title: 'Removed from collaboration group',
          body: 'You were removed.',
          tripId: 'removed',
          createdAt: DateTime(2030, 1, 1),
        ),
      ],
    );

    expect(state.removedTrips, isEmpty);
  });

  test(
    'server-dismissed removal notification stays hidden on a new session',
    () {
      final removed = trip(id: 'removed');
      final state = MatchmakingState(
        trips: [removed],
        notifications: [
          MatchmakingNotification(
            id: 'notice',
            title: 'Removed from collaboration group',
            body: 'You were removed.',
            tripId: 'removed',
            createdAt: DateTime(2030, 1, 1),
            dismissedAt: DateTime(2030, 1, 2),
          ),
        ],
      );

      expect(state.removedTrips, isEmpty);
      expect(state.wasRemovedFromTrip('removed'), isFalse);
    },
  );
}
