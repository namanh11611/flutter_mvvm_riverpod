class Traveller {
  const Traveller({
    required this.userId,
    required this.displayName,
    this.profilePhotoUrl,
    String? initials,
  }) : initials = initials ?? '';

  final String userId;
  final String displayName;
  final String? profilePhotoUrl;
  final String initials;

  factory Traveller.fromMap(Map<String, Object?> map) => Traveller(
        userId: map['user_id']!.toString(),
        displayName: (map['display_name'] ?? map['name'])! as String,
        profilePhotoUrl:
            (map['profile_photo_url'] ?? map['profile_photo']) as String?,
        initials: map['initials'] as String?,
      );
}
