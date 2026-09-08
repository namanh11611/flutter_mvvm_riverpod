import 'package:flutter_mvvm_riverpod/features/group_expense/model/money_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyUtils', () {
    test('rounds, compares, and converts money through cents', () {
      expect(MoneyUtils.toCents(100.005), 10001);
      expect(MoneyUtils.fromCents(14325), 143.25);
      expect(MoneyUtils.roundMoney(10.126), 10.13);
      expect(MoneyUtils.moneyEquals(10.001, 10.004), isTrue);
    });

    test('formats MYR using the requested display', () {
      expect(MoneyUtils.formatCurrency(3000), 'RM 3,000.00');
    });
  });
}
