part of 'matchmaking_shell_screen.dart';

class TripDetailsPage extends StatelessWidget {
  final MatchmakingTrip trip;
  final bool canOpenGroup;
  final bool canRequest;
  final UserCurrency currency;
  final double currencyRate;
  final VoidCallback onBack, onRequest, onOpenGroup;
  const TripDetailsPage({
    super.key,
    required this.trip,
    required this.canOpenGroup,
    this.canRequest = true,
    this.currency = UserCurrency.myr,
    this.currencyRate = 1,
    required this.onBack,
    required this.onRequest,
    required this.onOpenGroup,
  });
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TravelImage(url: trip.imageUrl),
                Positioned(top: 16, left: 16, child: RoundBack(onTap: onBack)),
                if (!trip.isOwned)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: UserSafetyActionsButton(
                        targetUserId: trip.hostId,
                        targetDisplayName: trip.hostName,
                        onBlocked: onBack,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.destination, style: _heading),
                const SizedBox(height: 5),
                Text(_dateRange(trip.startDate, trip.endDate), style: _label),
                if (trip.galleryImageUrls.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const FieldLabel('TRIP PHOTOS'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: trip.galleryImageUrls.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: 150,
                        child: TravelImage(
                          url: trip.galleryImageUrls[index],
                          radius: 10,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                InfoRows(
                  trip: trip,
                  currency: currency,
                  currencyRate: currencyRate,
                ),
                const SizedBox(height: 24),
                const FieldLabel('TRIP HOST'),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _OtherUserAvatar(
                      enabled: !trip.isOwned,
                      userId: trip.hostId,
                      displayName: trip.hostName,
                      child: Avatar(
                        letter: trip.hostInitials,
                        size: 46,
                        color: const Color(0xFFB59BF1),
                        imageUrl: trip.hostProfilePhotoUrl,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      trip.hostName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (trip.verifiedHost) const VerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 24),
                const FieldLabel('TRAVEL STYLE'),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  children: trip.styles
                      .map((style) => ChipButton(label: style, active: true))
                      .toList(),
                ),
                const SizedBox(height: 24),
                const FieldLabel('ABOUT THIS TRIP'),
                const SizedBox(height: 9),
                Text(
                  trip.description,
                  style: TextStyle(height: 1.65, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canOpenGroup) ...[
              OutlinedButton.icon(
                onPressed: onOpenGroup,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Open trip timeline'),
              ),
            ] else
              PrimaryButton(
                onTap: trip.isDiscoverable && canRequest ? onRequest : null,
                label:
                    trip.unavailableReason ??
                    (canRequest ? 'Request to Join' : 'Join unavailable'),
              ),
          ],
        ),
      ),
    ],
  );
}
