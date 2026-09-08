class ModerationItem {
  const ModerationItem(
    this.id,
    this.title,
    this.details,
    this.banned,
    this.targetId, {
    this.data = const {},
  });
  final String id, title, details, targetId;
  final bool banned;
  final Map<String, dynamic> data;
  factory ModerationItem.fromJson(
    Map<String, dynamic> row,
    bool reports,
  ) => ModerationItem(
    row['id'] as String,
    reports
        ? '${row['reason']} - ${row['status']}'
        : '${row['display_name'] ?? 'Unnamed user'}',
    reports
        ? '${row['description'] ?? 'No details'}\nReporter: ${_userLabel(row['reporter_name'], row['reporter_id'])}\nReported: ${_userLabel(row['reported_user_name'], row['reported_user_id'])}\n${row['created_at']}'
        : row['id'] as String,
    row['banned'] == true,
    (reports ? row['reported_user_id'] : row['id']) as String,
    data: row,
  );

  static String _userLabel(Object? name, Object? id) {
    final username = (name as String?)?.trim();
    return '${username == null || username.isEmpty ? 'Unknown user' : username} ($id)';
  }
}

class ModerationImage {
  const ModerationImage(this.bucket, this.path, this.url);
  final String bucket, path, url;
}

class ModerationProfile {
  const ModerationProfile(
    this.id,
    this.fields,
    this.images,
    this.banned, {
    this.history = const [],
    this.reports = const [],
  });
  final List<Map<String, dynamic>> history, reports;
  final String id;
  final Map<String, String> fields;
  final List<ModerationImage> images;
  final bool banned;
  factory ModerationProfile.fromJson(Map<String, dynamic> json) {
    final profile = Map<String, dynamic>.from(json['profile'] as Map);
    return ModerationProfile(
      profile['id'] as String,
      profile.map(
        (key, value) => MapEntry(key, value?.toString() ?? 'Not available'),
      ),
      (json['images'] as List)
          .map(
            (i) => ModerationImage(
              i['bucket'] as String,
              i['path'] as String,
              i['url'] as String,
            ),
          )
          .toList(),
      profile['account_status'] == 'banned' || profile['banned'] == true,
      history: (json['history'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      reports: (json['reports'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
