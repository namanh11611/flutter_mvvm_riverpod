import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../model/analytics_calculator.dart';
import '../../repository/group_expense_providers.dart';
import '../state/analytics_state.dart';

part 'analytics_view_model.g.dart';

@riverpod
class AnalyticsViewModel extends _$AnalyticsViewModel {
  @override
  Future<AnalyticsState> build(String tripId) async {
    final budgetRepositoryFuture = ref.watch(budgetRepositoryProvider.future);
    final analyticsRepositoryFuture =
        ref.watch(analyticsRepositoryProvider.future);
    final budgetRepository = await budgetRepositoryFuture;
    final analyticsRepository = await analyticsRepositoryFuture;
    final budget = await budgetRepository.getBudgetForTrip(tripId);
    final totalExpenses = await budgetRepository.getTotalSpent(tripId);
    final categories = AnalyticsCalculator.categoryBreakdown(
      await analyticsRepository.getCategorySpending(tripId),
    );
    final trend = AnalyticsCalculator.orderedTrend(
      await analyticsRepository.getSpendingTrend(tripId),
    );
    return AnalyticsState(
      tripId: tripId,
      currency: budget?.baseCurrency ?? 'MYR',
      totalBudget: budget?.budgetAmount ?? 0,
      totalExpenses: totalExpenses,
      categories: categories,
      trend: trend,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
