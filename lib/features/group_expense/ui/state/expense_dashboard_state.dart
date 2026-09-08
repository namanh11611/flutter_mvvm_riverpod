import '../../model/expense.dart';
import '../../model/money_utils.dart';
import '../../model/trip.dart';
import '../../model/trip_budget.dart';

class ExpenseDashboardState {
  const ExpenseDashboardState({
    required this.tripId,
    required this.trip,
    required this.travellerCount,
    required this.budget,
    required this.totalSpent,
    required this.currency,
    required this.youOwe,
    required this.owedToYou,
    this.expenses = const [],
  });

  final String tripId;
  final Trip? trip;
  final int travellerCount;
  final TripBudget? budget;
  final double totalSpent;
  final String currency;
  final double youOwe;
  final double owedToYou;
  final List<Expense> expenses;

  double get budgetAmount => budget?.budgetAmount ?? 0;

  double get remaining => MoneyUtils.roundMoney(budgetAmount - totalSpent);

  double get usagePercentage => budgetAmount <= 0
      ? 0
      : MoneyUtils.roundMoney(totalSpent * 100 / budgetAmount);

  bool get hasBudget => budget != null;
}
