import 'package:flutter_mvvm_riverpod/features/group_expense/model/expense_split.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/money_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseSplitCalculator', () {
    test('splits RM580 equally between four participants', () {
      final result = ExpenseSplitCalculator.equal(
        expenseId: '1',
        baseAmount: 580,
        userIds: ['1', '2', '3', '4'],
      );
      expect(result.map((item) => item.shareAmount), everyElement(145));
    });

    test('assigns equal split rounding difference without losing a cent', () {
      final result = ExpenseSplitCalculator.equal(
        expenseId: '1',
        baseAmount: 100,
        userIds: ['1', '2', '3'],
      );
      expect(result.map((item) => item.shareAmount), [33.34, 33.33, 33.33]);
      expect(
        result.fold<int>(
          0,
          (sum, item) => sum + MoneyUtils.toCents(item.shareAmount),
        ),
        10000,
      );
    });

    test('accepts valid custom shares and rejects inconsistent totals', () {
      final valid = ExpenseSplitCalculator.custom(
        expenseId: '1',
        baseAmount: 100,
        shares: {'1': 40, '2': 60},
      );
      expect(valid.map((item) => item.shareAmount), [40, 60]);
      expect(
        () => ExpenseSplitCalculator.custom(
          expenseId: '1',
          baseAmount: 100,
          shares: {'1': 40, '2': 59.99},
        ),
        throwsA(isA<ExpenseSplitException>()),
      );
    });

    test('requires percentages to total exactly 100 within tolerance', () {
      expect(
        () => ExpenseSplitCalculator.percentage(
          expenseId: '1',
          baseAmount: 100,
          percentages: {'1': 40, '2': 59},
        ),
        throwsA(isA<ExpenseSplitException>()),
      );
    });

    test('percentage rounding preserves the final money total', () {
      final result = ExpenseSplitCalculator.percentage(
        expenseId: '1',
        baseAmount: 100,
        percentages: {'1': 33.33, '2': 33.33, '3': 33.34},
      );
      expect(
        result.fold<int>(
          0,
          (sum, item) => sum + MoneyUtils.toCents(item.shareAmount),
        ),
        10000,
      );
      expect(result.map((item) => item.shareAmount), [33.33, 33.33, 33.34]);
    });

    test('percentage rounding never creates a negative final share', () {
      final result = ExpenseSplitCalculator.percentage(
        expenseId: '1',
        baseAmount: 0.01,
        percentages: const {'1': 50, '2': 50, '3': 0},
      );

      expect(result.map((item) => item.shareAmount), [0.01, 0, 0]);
      expect(result.every((item) => item.shareAmount >= 0), isTrue);
      expect(
        result.fold<int>(
          0,
          (sum, item) => sum + MoneyUtils.toCents(item.shareAmount),
        ),
        1,
      );
    });
  });
}
