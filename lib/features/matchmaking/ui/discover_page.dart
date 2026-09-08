part of 'matchmaking_shell_screen.dart';

class MatchmakingNotificationsDialog extends StatelessWidget {
  const MatchmakingNotificationsDialog({
    super.key,
    required this.notifications,
  });

  final List<MatchmakingNotification> notifications;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Notifications'),
    content: SizedBox(
      width: 420,
      child: notifications.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No notifications yet.'),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: notifications.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    notification.isUnread
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: notification.isUnread ? _violet : _muted,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isUnread
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(notification.body),
                  trailing: notification.isIdentityVerification
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: notification.isIdentityVerification
                      ? () {
                          final navigation = GoRouter.of(context);
                          Navigator.pop(context);
                          navigation.push(Routes.identityVerification);
                        }
                      : null,
                );
              },
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

class DiscoverPage extends StatelessWidget {
  final bool isAuthenticated, isLoading;
  final bool isVerified;
  final String? errorMessage;
  final String filter;
  final List<MatchmakingTrip> trips;
  final Set<String> savedTripIds;
  final List<String> filters;
  final List<MatchmakingNotification> notifications;
  final int unreadNotificationCount;
  final String? profilePhotoUrl;
  final UserCurrency currency;
  final double currencyRate;
  final Future<void> Function() onNotificationsRead;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onFilter;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onDetails, onRequest, onSave;
  const DiscoverPage({
    super.key,
    required this.isAuthenticated,
    required this.isLoading,
    required this.isVerified,
    required this.errorMessage,
    required this.filter,
    required this.trips,
    required this.savedTripIds,
    required this.filters,
    required this.notifications,
    required this.unreadNotificationCount,
    required this.profilePhotoUrl,
    required this.currency,
    this.currencyRate = 1,
    required this.onNotificationsRead,
    required this.onRetry,
    required this.onFilter,
    required this.onOpenFilters,
    required this.onDetails,
    required this.onRequest,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF7F5FB),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
          child: Row(
            children: [
              const Text(
                'GoBuddy',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.8,
                  fontSize: 29,
                  color: _ink,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune_rounded, color: _ink),
              ),
              IconButton(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => MatchmakingNotificationsDialog(
                      notifications: notifications,
                    ),
                  );
                  await onNotificationsRead();
                },
                icon: Badge(
                  isLabelVisible: unreadNotificationCount > 0,
                  label: Text(
                    unreadNotificationCount > 99
                        ? '99+'
                        : '$unreadNotificationCount',
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: _ink,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.push(Routes.userAccount),
                customBorder: const CircleBorder(),
                child: Avatar(letter: 'M', size: 34, imageUrl: profilePhotoUrl),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filters
                .map(
                  (x) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChipButton(
                      label: x,
                      active: x == filter,
                      onTap: () => onFilter(x),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
            children: [
              for (final trip in trips) ...[
                TripCard(
                  trip: trip,
                  currency: currency,
                  currencyRate: currencyRate,
                  saved: savedTripIds.contains(trip.id),
                  interactionsEnabled: isVerified,
                  onSave: () => onSave(trip.id),
                  onDetails: () => onDetails(trip.id),
                  onRequest: () => onRequest(trip.id),
                ),
                const SizedBox(height: 18),
              ],
              if (!isAuthenticated)
                const _DiscoveryMessage(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to discover trips',
                  message:
                      'Matchmaking uses your account to keep requests and memberships separate.',
                )
              else if (isLoading && trips.isEmpty)
                const _DiscoveryLoading()
              else if (errorMessage != null && trips.isEmpty)
                _DiscoveryMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load trips',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: onRetry,
                )
              else if (trips.isEmpty)
                const _NoTripsFound(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NoTripsFound extends StatelessWidget {
  const _NoTripsFound();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 48, color: _muted),
        const SizedBox(height: 14),
        const Text('No trips found', style: _heading),
        const SizedBox(height: 7),
        Text(
          'No active trips match your current filters.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted.withValues(alpha: .9)),
        ),
      ],
    ),
  );
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 80),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _DiscoveryMessage extends StatelessWidget {
  const _DiscoveryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 48, color: _muted),
        const SizedBox(height: 14),
        Text(title, style: _heading, textAlign: TextAlign.center),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted.withValues(alpha: .9)),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class TripCard extends StatelessWidget {
  final MatchmakingTrip trip;
  final VoidCallback onDetails, onRequest, onSave;
  final bool saved;
  final bool interactionsEnabled;
  final UserCurrency currency;
  final double currencyRate;
  const TripCard({
    super.key,
    required this.trip,
    required this.onDetails,
    required this.onRequest,
    required this.onSave,
    required this.saved,
    this.interactionsEnabled = true,
    this.currency = UserCurrency.myr,
    this.currencyRate = 1,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: _cardDecoration(radius: 24, feed: true),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TripCardImageCarousel(trip: trip),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _OtherUserAvatar(
                    enabled: interactionsEnabled && !trip.isOwned,
                    userId: trip.hostId,
                    displayName: trip.hostName,
                    child: Avatar(
                      letter: trip.hostInitials,
                      size: 40,
                      color: const Color(0xFFB59BF1),
                      imageUrl: trip.hostProfilePhotoUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.hostName,
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Trip organizer',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currency.format(trip.budget * currencyRate),
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ...trip.styles.map(
                    (style) => ChipButton(label: style, small: true),
                  ),
                  SlotChip(spots: trip.spotsLeft),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                trip.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(height: 1.45, fontSize: 14, color: _muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: interactionsEnabled ? onSave : null,
                tooltip: saved ? 'Remove saved trip' : 'Save trip for later',
                icon: Icon(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _violet,
                ),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: _border),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: SmallOutline(
                  label: interactionsEnabled ? 'View Details' : 'Verify to view',
                  onTap: interactionsEnabled ? onDetails : null,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: SmallPrimary(
                  label: interactionsEnabled ? 'Request to Join' : 'Locked',
                  onTap: interactionsEnabled ? onRequest : null,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TripCardImageCarousel extends StatefulWidget {
  const _TripCardImageCarousel({required this.trip});

  final MatchmakingTrip trip;

  @override
  State<_TripCardImageCarousel> createState() => _TripCardImageCarouselState();
}

class _TripCardImageCarouselState extends State<_TripCardImageCarousel> {
  int _currentImage = 0;

  List<String> get _images => {
    if (widget.trip.imageUrl.trim().isNotEmpty) widget.trip.imageUrl,
    ...widget.trip.galleryImageUrls.where((url) => url.trim().isNotEmpty),
  }.toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return SizedBox(
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const ColoredBox(
              color: _lavender,
              child: Icon(Icons.landscape_outlined, size: 48, color: _muted),
            )
          else
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _currentImage = index),
              itemBuilder: (context, index) => TravelImage(url: images[index]),
            ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC171025)],
                ),
              ),
            ),
          ),
          if (images.isNotEmpty)
            Positioned(
              top: 14,
              right: 14,
              child: _Counter(current: _currentImage + 1, total: images.length),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.destination,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _dateRange(widget.trip.startDate, widget.trip.endDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
