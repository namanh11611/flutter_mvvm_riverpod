import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/ui/settings/change_password_screen.dart';

void main() {
  group('validateNewPassword', () {
    test('requires at least eight characters', () {
      expect(validateNewPassword('Aa!123'), isNotNull);
    });

    test('requires uppercase, lowercase, a number, and a special character', () {
      expect(validateNewPassword('password!'), isNotNull);
      expect(validateNewPassword('PASSWORD!'), isNotNull);
      expect(validateNewPassword('Password!'), isNotNull);
      expect(validateNewPassword('Password1'), isNotNull);
    });

    test('accepts a strong password', () {
      expect(validateNewPassword('NewPass!1'), isNull);
    });
  });
}
