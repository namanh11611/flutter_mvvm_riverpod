part of 'matchmaking_shell_screen.dart';

class ManageRequestsPage extends StatelessWidget {
  final VoidCallback onBack;
  final MatchmakingTrip trip;
  final List<JoinRequest> requests;
  final List<MatchmakingApplicant> applicants;
  final ValueChanged<String> onApplicant;
  final void Function(String, ApplicantDecision) onDecision;
  const ManageRequestsPage({
    super.key,
    required this.onBack,
    required this.onApplicant,
    required this.trip,
    required this.requests,
    required this.applicants,
    required this.onDecision,
  });

  MatchmakingApplicant _applicant(String id) =>
      applicants.firstWhere((item) => item.id == id);
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
    children: [
      Row(
        children: [
          RoundBack(onTap: onBack),
          const SizedBox(width: 13),
          const Text('Requests', style: _display),
        ],
      ),
      const SizedBox(height: 7),
      Text(
        '${trip.destination} · ${requests.length} applicants',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 22),
      if (requests.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: Text('No pending requests.')),
        ),
      for (final request in requests) ...[
        ApplicantCard(
          applicant: _applicant(request.applicantId),
          message: request.message,
          onTap: () => onApplicant(request.applicantId),
          status: _decisionLabel(request.decision),
          onDecision: (decision) => onDecision(request.id, decision),
        ),
        const SizedBox(height: 14),
      ],
    ],
  );
}

class ApplicantPage extends StatelessWidget {
  final MatchmakingApplicant applicant;
  final JoinRequest request;
  final VoidCallback onBack;
  final void Function(String, ApplicantDecision) onDecision;
  const ApplicantPage({
    super.key,
    required this.applicant,
    required this.request,
    required this.onBack,
    required this.onDecision,
  });
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_lavender, Color(0xFFF3E8FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RoundBack(onTap: onBack),
                    const Spacer(),
                    UserSafetyActionsButton(
                      targetUserId: applicant.id,
                      targetDisplayName: applicant.name,
                      onBlocked: onBack,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: _OtherUserAvatar(
                    userId: applicant.id,
                    displayName: applicant.name,
                    child: Avatar(
                      letter: applicant.initials,
                      size: 80,
                      color: _violet,
                      imageUrl: applicant.profilePhotoUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(applicant.name, style: _heading)),
                const SizedBox(height: 6),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (applicant.verified) const VerifiedBadge(),
                      const SizedBox(width: 7),
                      Text(
                        '${applicant.age} · ${applicant.gender}',
                        style: const TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Stat(number: '${applicant.trips}', label: 'TRIPS'),
                    Stat(number: '${applicant.rating}', label: 'RATING'),
                    Stat(
                      number: '${applicant.languages.length}',
                      label: 'LANGUAGES',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel('LANGUAGES'),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: applicant.languages
                      .map((value) => ChipButton(label: value))
                      .toList(),
                ),
                SizedBox(height: 24),
                FieldLabel('TRAVEL STYLE'),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: applicant.styles
                      .map((value) => ChipButton(label: value, active: true))
                      .toList(),
                ),
                SizedBox(height: 24),
                FieldLabel('REQUEST MESSAGE'),
                SizedBox(height: 8),
                Text(
                  request.message,
                  style: TextStyle(color: _muted, height: 1.65),
                ),
                SizedBox(height: 24),
                FieldLabel('ABOUT'),
                SizedBox(height: 8),
                Text(
                  applicant.bio,
                  style: TextStyle(color: _muted, height: 1.65),
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
        child: Row(
          children: [
            Expanded(
              child: StatusButton(
                label: 'Accept',
                color: Color(0xFFDCFCE7),
                text: Color(0xFF16A34A),
                onTap: () => onDecision(request.id, ApplicantDecision.accepted),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatusButton(
                label: 'Hold',
                color: Color(0xFFFEF9C3),
                text: Color(0xFFD97706),
                onTap: () => onDecision(request.id, ApplicantDecision.held),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatusButton(
                label: 'Decline',
                color: Color(0xFFFEE2E2),
                text: Color(0xFFDC2626),
                onTap: () => onDecision(request.id, ApplicantDecision.declined),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Avatar(letter: 'M', size: 80, color: _violet),
        const SizedBox(height: 14),
        const Text('Morgan Lee', style: _heading),
        const SizedBox(height: 4),
        const Text('morgan@gobuddy.app', style: TextStyle(color: _muted)),
        const SizedBox(height: 26),
        SizedBox(
          width: 260,
          child: OutlineButton(
            label: 'Open account',
            onTap: () => context.push(Routes.userAccount),
          ),
        ),
      ],
    ),
  );
}
