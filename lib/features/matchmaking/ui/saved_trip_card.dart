import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/matchmaking_models.dart';

class SavedTripCard extends StatelessWidget {
  const SavedTripCard({
    super.key,
    required this.trip,
    required this.canJoin,
    required this.onDetails,
    required this.onRemove,
    required this.onJoin,
    this.joinLabel = 'Join Trip',
    this.removing = false,
  });

  final MatchmakingTrip trip;
  final bool canJoin, removing;
  final String joinLabel;
  final VoidCallback onDetails, onRemove, onJoin;

  @override
  Widget build(BuildContext context) {
    final reason = trip.unavailableReason;
    final unavailable = reason != null;
    final ink = unavailable ? const Color(0xFF666666) : const Color(0xFF281950);
    return Card(
      color: unavailable ? const Color(0xFFEEEEEE) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trip.imageUrl.isNotEmpty)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                unavailable ? Colors.grey : Colors.transparent,
                unavailable ? BlendMode.saturation : BlendMode.srcOver,
              ),
              child: Image.network(
                trip.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 80,
                  child: Center(
                    child: Icon(Icons.landscape_outlined, size: 40),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destination,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${DateFormat.yMMMd().format(trip.startDate)} – ${DateFormat.yMMMd().format(trip.endDate)}',
                  style: TextStyle(color: ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hosted by ${trip.hostName} · RM ${trip.budget}',
                  style: TextStyle(color: ink),
                ),
                const SizedBox(height: 10),
                Text(
                  reason ?? '${trip.spotsLeft} spots available',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: onDetails,
                      child: const Text('View Details'),
                    ),
                    TextButton.icon(
                      onPressed: removing ? null : onRemove,
                      icon: const Icon(Icons.favorite),
                      label: const Text('Remove Saved Trip'),
                    ),
                    FilledButton(
                      onPressed: canJoin && !unavailable ? onJoin : null,
                      child: Text(joinLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
