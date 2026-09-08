enum TripStatus { active, closed, draft }

enum TripLifecycle { upcoming, ongoing, finished }

enum ApplicantDecision { pending, accepted, held, declined, cancelled }

class MatchmakingTrip {
  const MatchmakingTrip({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.startTime,
    required this.budget,
    required this.styles,
    required this.hostId,
    required this.hostName,
    required this.hostInitials,
    this.hostProfilePhotoUrl,
    required this.imageUrl,
    this.galleryImageUrls = const [],
    required this.gender,
    required this.minAge,
    required this.maxAge,
    required this.vacancies,
    required this.description,
    this.joined = 0,
    this.groupMemberCount = 0,
    this.verifiedHost = true,
    this.status = TripStatus.active,
    this.isOwned = false,
  });

  final String id, destination, hostId, hostName, hostInitials, imageUrl;
  final List<String> galleryImageUrls;
  final String? hostProfilePhotoUrl;
  final DateTime startDate, endDate;
  final DateTime? startTime;
  final int budget, minAge, maxAge, vacancies, joined, groupMemberCount;
  final Set<String> styles;
  final String gender, description;
  final bool verifiedHost, isOwned;
  final TripStatus status;

  int get spotsLeft => (vacancies - joined).clamp(0, vacancies);
  DateTime get startsAt => startTime ?? startDate;
  DateTime get endsAfter =>
      DateTime(endDate.year, endDate.month, endDate.day + 1);
  TripLifecycle lifecycleAt([DateTime? value]) {
    final now = value ?? DateTime.now();
    if (status == TripStatus.closed || !now.isBefore(endsAfter)) {
      return TripLifecycle.finished;
    }
    return now.isBefore(startsAt)
        ? TripLifecycle.upcoming
        : TripLifecycle.ongoing;
  }

  TripLifecycle get lifecycle => lifecycleAt();
  bool get isDiscoverable {
    return status == TripStatus.active &&
        lifecycle == TripLifecycle.upcoming &&
        spotsLeft > 0;
  }

  String? get unavailableReason {
    if (status == TripStatus.draft) return 'Unavailable';
    if (status == TripStatus.closed) return 'Trip closed';
    if (lifecycle == TripLifecycle.finished) return 'Trip ended';
    if (lifecycle == TripLifecycle.ongoing) return 'Trip started';
    if (spotsLeft == 0) return 'Full';
    return null;
  }

  MatchmakingTrip copyWith({
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startTime,
    int? budget,
    Set<String>? styles,
    String? gender,
    int? minAge,
    int? maxAge,
    int? vacancies,
    String? description,
    int? joined,
    int? groupMemberCount,
    TripStatus? status,
    List<String>? galleryImageUrls,
  }) => MatchmakingTrip(
    id: id,
    destination: destination ?? this.destination,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    startTime: startTime ?? this.startTime,
    budget: budget ?? this.budget,
    styles: styles ?? this.styles,
    hostId: hostId,
    hostName: hostName,
    hostInitials: hostInitials,
    hostProfilePhotoUrl: hostProfilePhotoUrl,
    imageUrl: imageUrl,
    galleryImageUrls: galleryImageUrls ?? this.galleryImageUrls,
    gender: gender ?? this.gender,
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    vacancies: vacancies ?? this.vacancies,
    description: description ?? this.description,
    joined: joined ?? this.joined,
    groupMemberCount: groupMemberCount ?? this.groupMemberCount,
    verifiedHost: verifiedHost,
    status: status ?? this.status,
    isOwned: isOwned,
  );
}

class MatchmakingApplicant {
  const MatchmakingApplicant({
    required this.id,
    required this.name,
    required this.initials,
    required this.age,
    required this.gender,
    required this.languages,
    required this.styles,
    required this.bio,
    required this.introduction,
    required this.trips,
    required this.rating,
    this.profilePhotoUrl,
    this.verified = true,
  });
  final String id, name, initials, gender, bio, introduction;
  final String? profilePhotoUrl;
  final int age, trips;
  final double rating;
  final Set<String> languages, styles;
  final bool verified;
}

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.tripId,
    required this.applicantId,
    required this.message,
    this.decision = ApplicantDecision.pending,
  });
  final String id, tripId, applicantId, message;
  final ApplicantDecision decision;
  JoinRequest copyWith({ApplicantDecision? decision}) => JoinRequest(
    id: id,
    tripId: tripId,
    applicantId: applicantId,
    message: message,
    decision: decision ?? this.decision,
  );
}

class MatchmakingFilters {
  const MatchmakingFilters({
    this.destination = '',
    this.startDate,
    this.endDate,
    this.minBudget = 0,
    this.maxBudget = 10000,
    this.minAge = 18,
    this.maxAge = 80,
    this.gender = 'Any',
    this.styles = const {},
  });
  final String destination;
  final DateTime? startDate, endDate;
  final int minBudget, maxBudget, minAge, maxAge;
  final String gender;
  final Set<String> styles;
}
