import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../repository/group_expense_providers.dart';
import '../state/expense_dashboard_state.dart';
import 'analytics_view_model.dart';
import 'balance_view_model.dart';

part 'expense_dashboard_view_model.g.dart';

@riverpod
class ExpenseDashboardViewModel extends _$ExpenseDashboardViewModel {
  @override
  Future<ExpenseDashboardState> build(String tripId) async {
    final tripRepositoryFuture = ref.watch(tripRepositoryProvider.future);
    final travellerRepositoryFuture =
        ref.watch(travellerRepositoryProvider.future);
    final budgetRepositoryFuture = ref.watch(budgetRepositoryProvider.future);
    final expenseRepositoryFuture = ref.watch(expenseRepositoryProvider.future);
    final balancesFuture = ref.watch(balanceViewModelProvider(tripId).future);
    final tripRepository = await tripRepositoryFuture;
    final travellerRepository = await travellerRepositoryFuture;
    final budgetRepository = await budgetRepositoryFuture;
    final expenseRepository = await expenseRepositoryFuture;
    final trip = await tripRepository.getTripById(tripId);
    final travellers = await travellerRepository.getTravellersForTrip(tripId);
    final budget = await budgetRepository.getBudgetForTrip(tripId);
    final totalSpent = await budgetRepository.getTotalSpent(tripId);
    final expenses = await expenseRepository.getExpensesForTrip(tripId);
    final balances = await balancesFuture;
    return ExpenseDashboardState(
      tripId: tripId,
      trip: trip,
      travellerCount: travellers.length,
      budget: budget,
      totalSpent: totalSpent,
      currency: budget?.baseCurrency ?? 'MYR',
      youOwe: balances.youOwe,
      owedToYou: balances.owedToYou,
      expenses: expenses,
    );
  }

  Future<void> refresh() async {
    ref.invalidate(balanceViewModelProvider(tripId));
    ref.invalidate(analyticsViewModelProvider(tripId));
    ref.invalidateSelf();
  }
}
