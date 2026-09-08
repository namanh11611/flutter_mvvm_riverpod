import '../model/matchmaking_models.dart';
import '../model/matchmaking_notification.dart';
import '../model/matchmaking_page.dart';

class MatchmakingState {
  const MatchmakingState({
    this.page = MatchmakingPage.discover,
    this.selectedFilter = 'All',
    this.availableFilters = const [],
    this.filters = const MatchmakingFilters(),
    this.trips = const [],
    this.applicants = const [],
    this.requests = const [],
    this.currentUserId = '',
    this.joinedTripIds = const {},
    this.dismissedGroupIds = const {},
    this.notifications = const [],
    this.savedTripIds = const {},
    this.savingTripIds = const {},
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.selectedTripId,
    this.selectedApplicantId,
    this.managedTripId,
  });
  final MatchmakingPage page;
  final String selectedFilter;
  final List<String> availableFilters;
  final MatchmakingFilters filters;
  final List<MatchmakingTrip> trips;
  final List<MatchmakingApplicant> applicants;
  final List<JoinRequest> requests;
  final String currentUserId;
  final Set<String> joinedTripIds;
  final Set<String> dismissedGroupIds;
  final List<MatchmakingNotification> notifications;
  final Set<String> savedTripIds;
  final Set<String> savingTripIds;
  List<MatchmakingTrip> get savedTrips => trips
      .where((trip) => savedTripIds.contains(trip.id))
      .toList(growable: false);

  bool hasJoinRequest(String tripId) => _hasActiveRequestFor(tripId);
  bool canRequestTrip(MatchmakingTrip trip) =>
      isAuthenticated &&
      !trip.isOwned &&
      trip.isDiscoverable &&
      !joinedTripIds.contains(trip.id) &&
      !_hasActiveRequestFor(trip.id);
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String? selectedTripId, selectedApplicantId, managedTripId;
  int get unreadNotificationCount =>
      notifications.where((notification) => notification.isUnread).length;
  bool get isAuthenticated => currentUserId.isNotEmpty;

  MatchmakingTrip? get selectedTrip => _tripById(selectedTripId);
  MatchmakingTrip? get managedTrip => _tripById(managedTripId);
  MatchmakingApplicant? get selectedApplicant =>
      applicants.where((item) => item.id == selectedApplicantId).firstOrNull;
  List<MatchmakingTrip> get ownedTrips =>
      trips.where((trip) => trip.isOwned).toList(growable: false);
  List<MatchmakingTrip> get joinedTrips => trips
      .where((trip) => joinedTripIds.contains(trip.id))
      .toList(growable: false);
  List<MatchmakingTrip> get removedTrips => trips
      .where(
        (trip) =>
            !trip.isOwned &&
            !dismissedGroupIds.contains(trip.id) &&
            wasRemovedFromTrip(trip.id),
      )
      .toList(growable: false);
  List<MatchmakingTrip> get groupTrips => trips
      .where(
        (trip) =>
            !dismissedGroupIds.contains(trip.id) &&
            (trip.isOwned ||
                joinedTripIds.contains(trip.id) ||
                wasRemovedFromTrip(trip.id)),
      )
      .toList(growable: false);
  List<JoinRequest> get myRequests => requests
      .where(
        (request) =>
            request.applicantId == currentUserId &&
            request.decision != ApplicantDecision.accepted &&
            request.decision != ApplicantDecision.cancelled,
      )
      .toList(growable: false);
  bool wasRemovedFromTrip(String tripId) {
    return notifications.any(
      (notification) =>
          notification.tripId == tripId &&
          notification.dismissedAt == null &&
          notification.title.toLowerCase().contains('removed'),
    );
  }

  List<MatchmakingTrip> get discoveryTrips => trips
      .where(
        (trip) =>
            !trip.isOwned &&
            trip.isDiscoverable &&
            !joinedTripIds.contains(trip.id) &&
            !_hasActiveRequestFor(trip.id) &&
            _matchesFilters(trip),
      )
      .toList(growable: false);

  bool _hasActiveRequestFor(String tripId) => requests.any(
    (request) =>
        request.tripId == tripId &&
        request.applicantId == currentUserId &&
        const {
          ApplicantDecision.pending,
          ApplicantDecision.held,
          ApplicantDecision.accepted,
        }.contains(request.decision),
  );
  List<JoinRequest> get managedRequests => requests
      .where(
        (request) =>
            request.tripId == managedTripId &&
            const {
              ApplicantDecision.pending,
              ApplicantDecision.held,
            }.contains(request.decision),
      )
      .toList(growable: false);
  MatchmakingTrip? _tripById(String? id) =>
      trips.where((trip) => trip.id == id).firstOrNull;

  bool _matchesFilters(MatchmakingTrip trip) {
    final query = filters.destination.trim().toLowerCase();
    if (query.isNotEmpty && !trip.destination.toLowerCase().contains(query)) {
      return false;
    }
    if (trip.budget < filters.minBudget || trip.budget > filters.maxBudget) {
      return false;
    }
    if (filters.startDate != null &&
        trip.endDate.isBefore(filters.startDate!)) {
      return false;
    }
    if (filters.endDate != null && trip.startDate.isAfter(filters.endDate!)) {
      return false;
    }
    if (trip.maxAge < filters.minAge || trip.minAge > filters.maxAge) {
      return false;
    }
    if (filters.gender != 'Any' &&
        trip.gender != 'Any' &&
        trip.gender != filters.gender) {
      return false;
    }
    if (filters.styles.isNotEmpty &&
        !trip.styles.any(filters.styles.contains)) {
      return false;
    }
    return selectedFilter == 'All' || trip.styles.contains(selectedFilter);
  }

  MatchmakingState copyWith({
    MatchmakingPage? page,
    String? selectedFilter,
    List<String>? availableFilters,
    MatchmakingFilters? filters,
    List<MatchmakingTrip>? trips,
    List<MatchmakingApplicant>? applicants,
    List<JoinRequest>? requests,
    String? currentUserId,
    Set<String>? joinedTripIds,
    Set<String>? dismissedGroupIds,
    List<MatchmakingNotification>? notifications,
    Set<String>? savedTripIds,
    Set<String>? savingTripIds,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? selectedTripId,
    String? selectedApplicantId,
    String? managedTripId,
    bool clearSelectedTrip = false,
    bool clearSelectedApplicant = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) => MatchmakingState(
    page: page ?? this.page,
    selectedFilter: selectedFilter ?? this.selectedFilter,
    availableFilters: availableFilters ?? this.availableFilters,
    filters: filters ?? this.filters,
    trips: trips ?? this.trips,
    applicants: applicants ?? this.applicants,
    requests: requests ?? this.requests,
    currentUserId: currentUserId ?? this.currentUserId,
    joinedTripIds: joinedTripIds ?? this.joinedTripIds,
    dismissedGroupIds: dismissedGroupIds ?? this.dismissedGroupIds,
    notifications: notifications ?? this.notifications,
    savedTripIds: savedTripIds ?? this.savedTripIds,
    savingTripIds: savingTripIds ?? this.savingTripIds,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    selectedTripId: clearSelectedTrip
        ? null
        : selectedTripId ?? this.selectedTripId,
    selectedApplicantId: clearSelectedApplicant
        ? null
        : selectedApplicantId ?? this.selectedApplicantId,
    managedTripId: managedTripId ?? this.managedTripId,
  );
}
