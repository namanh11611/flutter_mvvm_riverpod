import 'category_spending.dart';
import 'money_utils.dart';
import 'spending_trend_point.dart';

class AnalyticsCalculator {
  AnalyticsCalculator._();

  static List<CategorySpending> categoryBreakdown(
    List<CategorySpending> categories,
  ) {
    final totalCents = categories.fold<int>(
      0,
      (total, category) => total + MoneyUtils.toCents(category.amount),
    );
    final breakdown = totalCents == 0
        ? categories
            .map((category) => category.copyWith(percentage: 0))
            .toList()
        : categories
            .map(
              (category) => category.copyWith(
                percentage:
                    MoneyUtils.toCents(category.amount) * 100 / totalCents,
              ),
            )
            .toList();
    breakdown.sort((left, right) {
      final amountOrder = right.amount.compareTo(left.amount);
      return amountOrder != 0
          ? amountOrder
          : left.categoryName.compareTo(right.categoryName);
    });
    return List.unmodifiable(breakdown);
  }

  static List<SpendingTrendPoint> orderedTrend(
    List<SpendingTrendPoint> points,
  ) {
    final ordered = [...points]..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(ordered);
  }
}
