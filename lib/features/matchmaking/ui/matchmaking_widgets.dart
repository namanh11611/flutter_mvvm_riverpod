part of 'matchmaking_shell_screen.dart';

class FormPage extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  const FormPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
    children: [
      Row(
        children: [
          RoundBack(onTap: onBack),
          const SizedBox(width: 13),
          Text(title, style: _heading),
        ],
      ),
      const SizedBox(height: 28),
      child,
    ],
  );
}

class Avatar extends StatelessWidget {
  final String letter;
  final double size;
  final Color color;
  final String? imageUrl;
  const Avatar({
    super.key,
    required this.letter,
    required this.size,
    this.color = _violet,
    this.imageUrl,
  });
  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl?.trim();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      foregroundImage: resolvedImageUrl == null || resolvedImageUrl.isEmpty
          ? null
          : NetworkImage(resolvedImageUrl),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OtherUserAvatar extends ConsumerWidget {
  const _OtherUserAvatar({
    required this.userId,
    required this.displayName,
    required this.child,
    this.enabled = true,
  });

  final String userId;
  final String displayName;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;
    return Tooltip(
      message: 'User options',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showUserActionsSheet(
          context: context,
          ref: ref,
          targetUserId: userId,
          targetDisplayName: displayName,
        ),
        child: child,
      ),
    );
  }
}

class ChipButton extends StatelessWidget {
  final String label;
  final bool active, small;
  final VoidCallback? onTap;
  const ChipButton({
    super.key,
    required this.label,
    this.active = false,
    this.small = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 9 : 14,
        vertical: small ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: active ? _violet : Colors.white,
        border: Border.all(color: active ? _violet : _border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : _muted,
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class VerifiedBadge extends StatelessWidget {
  final bool glass;
  const VerifiedBadge({super.key, this.glass = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: glass ? Colors.white.withValues(alpha: .2) : _lavender,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_rounded,
          size: 13,
          color: glass ? Colors.white : _violet,
        ),
        const SizedBox(width: 3),
        Text(
          'Verified',
          style: TextStyle(
            color: glass ? Colors.white : _violet,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class SlotChip extends StatelessWidget {
  final int spots;
  const SlotChip({super.key, this.spots = 3});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$spots ${spots == 1 ? 'spot' : 'spots'} left',
      style: const TextStyle(
        color: Color(0xFF16803B),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const PrimaryButton({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const OutlineButton({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        side: const BorderSide(color: _border),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class SmallPrimary extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const SmallPrimary({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _violet,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class SmallOutline extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const SmallOutline({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: const BorderSide(color: _border),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class AppField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final int lines;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  const AppField({
    super.key,
    required this.hint,
    this.icon,
    this.lines = 1,
    this.controller,
    this.onChanged,
    this.maxLength,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    maxLength: maxLength,
    buildCounter:
        (_, {required currentLength, required isFocused, maxLength}) => null,
    maxLines: lines,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 14),
      suffixIcon: icon == null ? null : Icon(icon, size: 19, color: _muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
    ),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, style: _label);
}

class RangeTitle extends StatelessWidget {
  final String left, right;
  const RangeTitle({super.key, required this.left, required this.right});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        Text(
          right,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      ],
    ),
  );
}

class RoundBack extends StatelessWidget {
  final VoidCallback onTap;
  const RoundBack({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .94),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: const SizedBox(
        width: 38,
        height: 38,
        child: Icon(Icons.arrow_back, color: _ink, size: 20),
      ),
    ),
  );
}

class InfoRows extends StatelessWidget {
  final MatchmakingTrip trip;
  final UserCurrency currency;
  final double currencyRate;
  const InfoRows({
    super.key,
    required this.trip,
    this.currency = UserCurrency.myr,
    this.currencyRate = 1,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      InfoRow(
        icon: Icons.payments_outlined,
        label: 'Budget',
        value: currency.format(trip.budget * currencyRate),
      ),
      InfoRow(
        icon: Icons.group_outlined,
        label: 'Available slots',
        value: '${trip.spotsLeft} of ${trip.vacancies}',
      ),
      InfoRow(
        icon: Icons.person_outline,
        label: 'Preferred gender',
        value: trip.gender,
      ),
      InfoRow(
        icon: Icons.cake_outlined,
        label: 'Preferred age',
        value: '${trip.minAge} — ${trip.maxAge}',
      ),
    ],
  );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _violet, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: _muted)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class CompactTrip extends StatelessWidget {
  final String destination;
  final String dates;
  final String members;
  final String image;
  final String status;
  final VoidCallback? onManage;
  final VoidCallback? onEdit;
  final VoidCallback? onFinish;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;
  const CompactTrip({
    super.key,
    required this.destination,
    required this.dates,
    required this.members,
    this.image = _tokyo,
    this.status = 'Active',
    this.onManage,
    this.onEdit,
    this.onFinish,
    this.onRemove,
    this.onOpen,
  });

  Future<void> _confirmFinish(BuildContext context) async {
    if (onFinish == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish trip?'),
        content: Text(
          'Mark $destination as finished? It will no longer appear in Discovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish trip'),
          ),
        ],
      ),
    );
    if (confirmed == true) onFinish?.call();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: _cardDecoration(),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: TravelImage(url: image, radius: 10),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              destination,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          _Status(label: status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(dates, style: _label),
                      const SizedBox(height: 9),
                      Text(
                        members,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(onPressed: onEdit, child: const Text('Edit')),
              ),
              Expanded(
                child: TextButton(
                  onPressed: onManage,
                  child: const Text('Requests'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed:
                      onRemove ??
                      (onFinish == null ? null : () => _confirmFinish(context)),
                  child: Text(
                    onRemove != null
                        ? 'Remove'
                        : onFinish == null
                        ? 'Finished'
                        : 'Finish trip',
                    style: onRemove != null
                        ? const TextStyle(color: Color(0xFFDC2626))
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ApplicantCard extends StatelessWidget {
  final MatchmakingApplicant applicant;
  final String message;
  final String status;
  final VoidCallback? onTap;
  final ValueChanged<ApplicantDecision>? onDecision;
  const ApplicantCard({
    super.key,
    required this.applicant,
    required this.message,
    this.status = 'Pending',
    this.onTap,
    this.onDecision,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _OtherUserAvatar(
              userId: applicant.id,
              displayName: applicant.name,
              child: Avatar(
                letter: applicant.initials,
                size: 46,
                color: const Color(0xFFBB9AF2),
                imageUrl: applicant.profilePhotoUrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          applicant.name,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (applicant.verified) const VerifiedBadge(),
                      ],
                    ),
                    Text(
                      '${applicant.age} · ${applicant.gender}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            _Status(label: status),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: applicant.styles
              .map((value) => ChipButton(label: value, small: true))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          '“$message”',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: _muted,
            height: 1.45,
          ),
        ),
        if (status == 'Pending') ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatusButton(
                  label: 'Accept',
                  color: Color(0xFFDCFCE7),
                  text: Color(0xFF16A34A),
                  onTap: () => onDecision?.call(ApplicantDecision.accepted),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatusButton(
                  label: 'Hold',
                  color: Color(0xFFFEF9C3),
                  text: Color(0xFFD97706),
                  onTap: () => onDecision?.call(ApplicantDecision.held),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatusButton(
                  label: 'Decline',
                  color: Color(0xFFFEE2E2),
                  text: Color(0xFFDC2626),
                  onTap: () => onDecision?.call(ApplicantDecision.declined),
                ),
              ),
            ],
          ),
        ] else if (status == 'Held') ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatusButton(
                  label: 'Accept',
                  color: const Color(0xFFDCFCE7),
                  text: const Color(0xFF16A34A),
                  onTap: () => onDecision?.call(ApplicantDecision.accepted),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatusButton(
                  label: 'Delete',
                  color: const Color(0xFFFEE2E2),
                  text: const Color(0xFFDC2626),
                  onTap: () => onDecision?.call(ApplicantDecision.declined),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class StatusButton extends StatelessWidget {
  final String label;
  final Color color, text;
  final VoidCallback? onTap;
  const StatusButton({
    super.key,
    required this.label,
    required this.color,
    required this.text,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: color,
        foregroundColor: text,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  final String label;
  const _Status({required this.label});
  @override
  Widget build(BuildContext context) {
    final c = label == 'Active'
        ? const Color(0xFF16A34A)
        : label == 'Draft' || label == 'Held'
        ? const Color(0xFFD97706)
        : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .22),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$current / $total',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class TravelImage extends StatelessWidget {
  final String url;
  final double? radius;
  const TravelImage({super.key, required this.url, this.radius});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: radius == null
        ? BorderRadius.zero
        : BorderRadius.circular(radius!),
    child: CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, url) => const ColoredBox(color: Color(0xFFEDE9FE)),
      errorWidget: (_, url, error) => const ColoredBox(
        color: Color(0xFFEDE9FE),
        child: Icon(Icons.image_not_supported_outlined),
      ),
    ),
  );
}

class _GalleryPhoto extends StatelessWidget {
  const _GalleryPhoto({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: SizedBox(
      width: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class Stat extends StatelessWidget {
  final String number, label;
  const Stat({super.key, required this.number, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        number,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 22,
          color: _ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(label, style: _label),
    ],
  );
}

BoxDecoration _cardDecoration({double radius = 16, bool feed = false}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: (feed ? _ink : Colors.black).withValues(
            alpha: feed ? .12 : .08,
          ),
          blurRadius: feed ? 40 : 25,
          offset: feed ? const Offset(0, 8) : const Offset(0, 2),
        ),
      ],
    );
const _display = TextStyle(
  fontFamily: 'Georgia',
  color: _ink,
  fontSize: 29,
  fontWeight: FontWeight.w600,
  letterSpacing: -.9,
);
const _heading = TextStyle(
  fontFamily: 'Georgia',
  color: _ink,
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -.6,
);
const _label = TextStyle(
  color: _muted,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: .5,
);

String _dateInput(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _dateRange(DateTime start, DateTime end) =>
    '${_dateInput(start)} — ${_dateInput(end)}';

String _lifecycleLabel(MatchmakingTrip trip) => switch (trip.lifecycle) {
  TripLifecycle.upcoming => 'Upcoming',
  TripLifecycle.ongoing => 'Ongoing',
  TripLifecycle.finished => 'Finished',
};
const _tokyo =
    'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=1200&q=85';

String _decisionLabel(ApplicantDecision? decision) => switch (decision) {
  ApplicantDecision.accepted => 'Accepted',
  ApplicantDecision.held => 'Held',
  ApplicantDecision.declined => 'Declined',
  ApplicantDecision.cancelled => 'Cancelled',
  _ => 'Pending',
};
