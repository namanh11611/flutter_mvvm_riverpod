import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/core/routing/account_access_redirect.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';

void main() {
  test('suspended accounts are restricted until access is restored', () {
    expect(
      accountAccessRedirect('suspended', Routes.main),
      Routes.accountBanned,
    );
    expect(accountAccessRedirect('suspended', Routes.accountBanned), isNull);
    expect(accountAccessRedirect('user', Routes.accountBanned), Routes.main);
  });

  test('admins enter their UI and skip traveller onboarding', () {
    expect(accountAccessRedirect('admin', Routes.main), Routes.admin);
    expect(
      accountAccessRedirect('admin', Routes.profileOnboarding),
      Routes.admin,
    );
    expect(
      accountAccessRedirect('admin', '${Routes.admin}/users/example'),
      isNull,
    );
  });
  test('normal and signed-out users cannot deep link into admin', () {
    expect(
      accountAccessRedirect('user', '${Routes.admin}/users/example'),
      Routes.main,
    );
    expect(accountAccessRedirect('anonymous', Routes.admin), Routes.login);
    expect(accountAccessRedirect('user', Routes.main), isNull);
    expect(accountAccessRedirect('user', Routes.profileOnboarding), isNull);
  });
  test('banned users are redirected without a redirect loop', () {
    expect(accountAccessRedirect('banned', Routes.main), Routes.accountBanned);
    expect(accountAccessRedirect('banned', Routes.admin), Routes.accountBanned);
    expect(accountAccessRedirect('banned', Routes.accountBanned), isNull);
    expect(accountAccessRedirect('user', Routes.accountBanned), Routes.main);
  });
}
