enum BudgetStatus { normal, nearBudget, exceeded }

class BudgetCalculator {
  BudgetCalculator._();

  static double remaining({required double budget, required double spent}) =>
      budget - spent;

  static double usagePercentage({
    required double budget,
    required double spent,
  }) =>
      budget <= 0 ? 0 : spent / budget * 100;

  static BudgetStatus status({
    required double budget,
    required double spent,
  }) {
    final usage = usagePercentage(budget: budget, spent: spent);
    if (usage > 100) return BudgetStatus.exceeded;
    if (usage >= 85) return BudgetStatus.nearBudget;
    return BudgetStatus.normal;
  }
}
