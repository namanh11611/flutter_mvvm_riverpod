import 'matchmaking_models.dart';

class MatchmakingValidationException implements Exception {
  const MatchmakingValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class MatchmakingValidation {
  static const maximumRequestLength = 500;

  static String normalizeRequestMessage(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      throw const MatchmakingValidationException(
        'Add a message before sending your request.',
      );
    }
    if (normalized.length > maximumRequestLength) {
      throw const MatchmakingValidationException(
        'The request message must be 500 characters or fewer.',
      );
    }
    return normalized;
  }

  static void validateTrip(MatchmakingTrip trip, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    if (trip.destination.trim().isEmpty) {
      throw const MatchmakingValidationException('Destination is required.');
    }
    if (trip.startDate.isBefore(today)) {
      throw const MatchmakingValidationException(
        'The trip start date cannot be in the past.',
      );
    }
    if (trip.endDate.isBefore(trip.startDate)) {
      throw const MatchmakingValidationException(
        'The end date must be on or after the start date.',
      );
    }
    if (trip.budget <= 0 || trip.vacancies <= 0) {
      throw const MatchmakingValidationException(
        'Budget and vacancies must be greater than zero.',
      );
    }
    if (trip.minAge < 18 || trip.maxAge < trip.minAge) {
      throw const MatchmakingValidationException('Enter a valid age range.');
    }
    if (trip.description.length > 1000) {
      throw const MatchmakingValidationException(
        'Description must be 1000 characters or fewer.',
      );
    }
  }

  static void validateHostAvailability(
    MatchmakingTrip candidate,
    Iterable<MatchmakingTrip> hostedTrips,
  ) {
    final conflict = hostedTrips.any(
      (trip) =>
          trip.id != candidate.id &&
          trip.status != TripStatus.closed &&
          candidate.startsAt.isBefore(trip.endsAfter) &&
          trip.startsAt.isBefore(candidate.endsAfter),
    );
    if (conflict) {
      throw const MatchmakingValidationException(
        'You already host a trip during this time period.',
      );
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
