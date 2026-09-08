enum UserReportReason {
  harassment(
    'Harassment or Bullying',
    'Repeated targeting, insults, intimidation, bullying, pressure, or persistent unwanted interaction.',
    1,
  ),
  hateSpeech(
    'Inappropriate or Offensive Behaviour',
    'Obscene, abusive, discriminatory, sexually inappropriate, or seriously offensive behaviour.',
    1,
  ),
  threatsSafetyConcerns(
    'Threats or Safety Concerns',
    'Threats, intimidation, possible physical harm, or behaviour that creates a direct personal safety concern, including meetup-related concerns.',
    2,
  ),
  spamUnwantedMessages(
    'Spam or Unwanted Messages',
    'Repeated unwanted messages, promotional messages, irrelevant messages, or similar spam behaviour.',
    0,
  ),
  impersonation(
    'Fake Account / Impersonation',
    'Pretending to be another person or deliberately misrepresenting identity.',
    0,
  ),
  scam(
    'Scam or Fraud',
    'Deceiving another user for money, personal information, account access, or another benefit.',
    1,
  ),
  inappropriateContent(
    'Inappropriate Content',
    'Explicit, disturbing, inappropriate, or seriously offensive images, text, links, or other shared content.',
    0,
  ),
  safetyFeatureMisuse(
    'Misuse of Safety / Emergency Features',
    'Deliberate abuse of GoBuddy safety/emergency functions, such as prank activation, repeated false activation, or using safety features to harass someone. Accidental activation must not automatically be treated as misuse.',
    1,
  ),
  suspiciousDangerousBehaviour(
    'Suspicious or Dangerous Behaviour',
    'Potentially dangerous real-world behaviour, especially behaviour related to meeting another GoBuddy user.',
    2,
  ),
  other(
    'Other',
    'Used when the issue does not reasonably fit the predefined categories. Please provide a description.',
    0,
  );

  const UserReportReason(this.label, this.description, this.attention);
  final String label, description;

  /// Review highlighting only; never an automatic moderation decision.
  final int attention;
  static UserReportReason? fromValue(String? value) {
    for (final reason in values) {
      if (reason.name == value) return reason;
    }
    return null;
  }

  static String? validate(UserReportReason? reason, String? description) {
    if (reason == null) return 'Select a report reason.';
    final text = description?.trim() ?? '';
    if (reason == other && text.isEmpty) {
      return 'Please describe what happened when selecting Other.';
    }
    if (text.length > 1000) {
      return 'Report details must be 1000 characters or fewer.';
    }
    return null;
  }
}

class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.displayName,
    required this.blockedAt,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime blockedAt;
}

class UserReport {
  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.description,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final UserReportReason reason;
  final String? description;
  final DateTime createdAt;
  final String status;
}
