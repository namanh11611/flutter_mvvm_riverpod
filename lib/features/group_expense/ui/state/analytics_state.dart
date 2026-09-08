import '../../model/category_spending.dart';
import '../../model/money_utils.dart';
import '../../model/spending_trend_point.dart';

class AnalyticsState {
  const AnalyticsState({
    required this.tripId,
    required this.currency,
    required this.totalBudget,
    required this.totalExpenses,
    this.categories = const [],
    this.trend = const [],
  });

  final String tripId;
  final String currency;
  final double totalBudget;
  final double totalExpenses;
  final List<CategorySpending> categories;
  final List<SpendingTrendPoint> trend;

  double get remaining => MoneyUtils.roundMoney(totalBudget - totalExpenses);

  double get usagePercentage => totalBudget <= 0
      ? 0
      : MoneyUtils.roundMoney(totalExpenses * 100 / totalBudget);

  CategorySpending? get highestSpendingCategory =>
      categories.isEmpty ? null : categories.first;

  bool get isEmpty => MoneyUtils.toCents(totalExpenses) == 0;
}
