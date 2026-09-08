import 'package:flutter_mvvm_riverpod/features/matchmaking/model/user_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves profile nationality to its currency', () {
    expect(UserCurrency.fromNationality('Malaysian').code, 'MYR');
    expect(UserCurrency.fromNationality('Peru').code, 'PEN');
    expect(UserCurrency.fromNationality('French').code, 'EUR');
    expect(UserCurrency.fromNationality('American').code, 'USD');
  });

  test('formats amounts with the resolved currency symbol', () {
    expect(UserCurrency.fromNationality('Malaysian').format(1800), 'RM 1,800');
    expect(UserCurrency.fromNationality('Peruvian').format(500), r'S/ 500');
  });
}
