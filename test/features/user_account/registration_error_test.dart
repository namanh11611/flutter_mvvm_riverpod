import 'package:flutter_mvvm_riverpod/features/user_account/repository/authentication_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('email rate limits are not reported as invalid addresses', () {
    for (final error in [
      const AuthException('Email rate limit exceeded'),
      const AuthException(
        'Request rejected',
        code: 'over_email_send_rate_limit',
      ),
      const AuthException('Request rejected', statusCode: '429'),
    ]) {
      expect(friendlyRegistrationError(error), contains('Please wait'));
    }
  });

  test('restricted email delivery explains the delivery failure', () {
    expect(
      friendlyRegistrationError(
        const AuthException(
          'Email address is not authorized',
          code: 'email_address_not_authorized',
        ),
      ),
      contains('cannot send verification emails'),
    );
  });

  test('mail server errors do not blame the email format', () {
    expect(
      friendlyRegistrationError(const AuthException('Error sending email')),
      'Unable to send the verification link. Please try again.',
    );
  });

  test('invalid email errors still identify invalid addresses', () {
    expect(
      friendlyRegistrationError(
        const AuthException('Rejected', code: 'email_address_invalid'),
      ),
      'Please enter a valid email address.',
    );
  });
}
