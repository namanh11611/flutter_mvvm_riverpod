import 'package:flutter_mvvm_riverpod/features/group_expense/model/budget_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetCalculator', () {
    test('calculates the seeded budget values', () {
      expect(BudgetCalculator.remaining(budget: 3000, spent: 2055), 945);
      expect(
        BudgetCalculator.usagePercentage(budget: 3000, spent: 2055),
        68.5,
      );
      expect(
        BudgetCalculator.status(budget: 3000, spent: 2055),
        BudgetStatus.normal,
      );
    });

    test('handles zero budget safely', () {
      expect(BudgetCalculator.usagePercentage(budget: 0, spent: 100), 0);
    });

    test('uses the required status thresholds', () {
      expect(
        BudgetCalculator.status(budget: 100, spent: 84.99),
        BudgetStatus.normal,
      );
      expect(
        BudgetCalculator.status(budget: 100, spent: 85),
        BudgetStatus.nearBudget,
      );
      expect(
        BudgetCalculator.status(budget: 100, spent: 100),
        BudgetStatus.nearBudget,
      );
      expect(
        BudgetCalculator.status(budget: 100, spent: 100.01),
        BudgetStatus.exceeded,
      );
    });
  });
}
