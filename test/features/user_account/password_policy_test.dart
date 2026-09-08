import 'package:flutter_mvvm_riverpod/core/utils/password_policy.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/repository/password_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('all five password requirements have specific errors', () {
    final cases = <String?, String>{
      null: 'Password must be at least 8 characters',
      'Aa1!xyz': 'Password must be at least 8 characters',
      'abcde1!x': 'Password must contain an uppercase letter',
      'ABCDE1!X': 'Password must contain a lowercase letter',
      'Abcdefg!': 'Password must contain a number',
      'Abcdefg1': 'Password must contain a special character',
      'Abcdef1 ': 'Password must contain a special character',
    };
    for (final entry in cases.entries) {
      expect(validatePassword(entry.key), entry.value);
    }
    expect(validatePassword('Abcdef1!'), isNull);
  });

  test('only weak password errors show password requirements', () {
    expect(
      passwordErrorMessage(
        const AuthException('Weak password', code: 'weak_password'),
        fallback: 'Failed',
      ),
      passwordRequirementsMessage,
    );
    expect(
      passwordErrorMessage(
        const AuthException('Error updating password'),
        fallback: 'Failed',
      ),
      'Failed',
    );
    expect(
      passwordErrorMessage(
        const AuthException(
          'Password session expired',
          code: 'session_expired',
        ),
        fallback: 'Failed',
      ),
      contains('session is missing or expired'),
    );
    expect(
      passwordErrorMessage(
        const AuthException('Password unchanged', code: 'same_password'),
        fallback: 'Failed',
      ),
      'Your new password must be different from your old password.',
    );
    expect(
      passwordErrorMessage(
        const AuthException('Password update rejected', statusCode: '429'),
        fallback: 'Failed',
      ),
      contains('Too many attempts'),
    );
  });
}
