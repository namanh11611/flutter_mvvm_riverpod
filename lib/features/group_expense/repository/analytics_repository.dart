import '../model/category_spending.dart';
import '../model/spending_trend_point.dart';

abstract interface class AnalyticsRepository {
  Future<List<CategorySpending>> getCategorySpending(String tripId);
  Future<List<SpendingTrendPoint>> getSpendingTrend(String tripId);
}
