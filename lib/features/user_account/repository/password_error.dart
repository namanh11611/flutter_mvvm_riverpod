import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/password_policy.dart';

String passwordErrorMessage(AuthException error, {required String fallback}) {
  final message = error.message.toLowerCase();
  if (error.code == 'same_password' ||
      message.contains('same password') ||
      message.contains('different from the old')) {
    return 'Your new password must be different from your old password.';
  }
  if (error.code == 'weak_password' ||
      message.contains('weak password') ||
      message.contains('password should be at least') ||
      message.contains('password must contain')) {
    return passwordRequirementsMessage;
  }
  if (error.code == 'over_request_rate_limit' || error.statusCode == '429') {
    return 'Too many attempts. Please wait before trying again.';
  }
  if (error.code == 'reauthentication_needed' ||
      error.code == 'reauthentication_not_valid' ||
      error.code == 'session_not_found' ||
      error.code == 'session_expired' ||
      error.code == 'bad_jwt' ||
      error.code == 'otp_expired') {
    return 'Your verification session is missing or expired. Please sign in again or request a new reset link.';
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'Unable to connect. Check your internet connection and try again.';
  }
  return fallback;
}
