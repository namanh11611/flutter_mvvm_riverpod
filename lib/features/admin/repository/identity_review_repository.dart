import 'package:supabase_flutter/supabase_flutter.dart';

class AdminIdentityReviewRepository {
  const AdminIdentityReviewRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        'admin-moderation',
        body: body,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        throw AdminIdentityReviewException(details['error'] as String);
      }
      throw const AdminIdentityReviewException(
        'The identity review request could not be completed.',
      );
    }
  }

  Future<bool> isAdmin() async {
    try {
      final access = await _client.rpc<String>('get_account_access');
      return access == 'admin';
    } on PostgrestException {
      return false;
    }
  }

  Future<AdminIdentityReviewQueue> fetchQueue() async {
    final data = await _invoke({'action': 'identityReviews'});
    final items = (data['items'] as List? ?? const [])
        .map(
          (item) => AdminIdentityReview.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    return AdminIdentityReviewQueue(
      items: items,
      unmatchedCount: (data['unmatchedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<AdminIdentityReviewDetails> fetchDetails(String verificationId) async {
    final data = await _invoke({
      'action': 'identityReview',
      'targetId': verificationId,
    });
    return AdminIdentityReviewDetails(
      review: AdminIdentityReview.fromJson({
        ...Map<String, dynamic>.from(data['account'] as Map),
        ...Map<String, dynamic>.from(data['attempt'] as Map),
      }),
      decision: Map<String, dynamic>.from(data['decision'] as Map),
    );
  }

  Future<void> submitDecision({
    required String verificationId,
    required String decision,
    required String reason,
  }) async {
    await _invoke({
      'action': 'identityDecision',
      'targetId': verificationId,
      'decision': decision,
      'reason': reason,
    });
  }
}

class AdminIdentityReviewQueue {
  const AdminIdentityReviewQueue({
    required this.items,
    required this.unmatchedCount,
  });

  final List<AdminIdentityReview> items;
  final int unmatchedCount;
}

class AdminIdentityReview {
  const AdminIdentityReview({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.sessionId,
    required this.providerStatus,
    required this.submittedAt,
  });

  factory AdminIdentityReview.fromJson(Map<String, dynamic> json) =>
      AdminIdentityReview(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String? ?? 'Unknown user',
        sessionId: json['provider_session_id'] as String,
        providerStatus: json['provider_status'] as String? ?? 'In Review',
        submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? ''),
      );

  final String id;
  final String userId;
  final String displayName;
  final String sessionId;
  final String providerStatus;
  final DateTime? submittedAt;
}

class AdminIdentityReviewDetails {
  const AdminIdentityReviewDetails({
    required this.review,
    required this.decision,
  });

  final AdminIdentityReview review;
  final Map<String, dynamic> decision;
}

class AdminIdentityReviewException implements Exception {
  const AdminIdentityReviewException(this.message);
  final String message;
  @override
  String toString() => message;
}
