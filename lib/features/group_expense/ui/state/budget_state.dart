import '../../model/budget_calculator.dart';
import '../../model/trip.dart';
import '../../model/trip_budget.dart';

class BudgetState {
  const BudgetState({
    required this.tripId,
    this.trip,
    this.budget,
    this.totalSpent = 0,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  final String tripId;
  final Trip? trip;
  final TripBudget? budget;
  final double totalSpent;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  double get remaining => BudgetCalculator.remaining(
        budget: budget?.budgetAmount ?? 0,
        spent: totalSpent,
      );

  double get usagePercentage => BudgetCalculator.usagePercentage(
        budget: budget?.budgetAmount ?? 0,
        spent: totalSpent,
      );

  BudgetStatus get status => BudgetCalculator.status(
        budget: budget?.budgetAmount ?? 0,
        spent: totalSpent,
      );

  BudgetState copyWith({
    Trip? trip,
    TripBudget? budget,
    double? totalSpent,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
    bool clearSuccessMessage = false,
    bool clearErrorMessage = false,
  }) =>
      BudgetState(
        tripId: tripId,
        trip: trip ?? this.trip,
        budget: budget ?? this.budget,
        totalSpent: totalSpent ?? this.totalSpent,
        isSaving: isSaving ?? this.isSaving,
        successMessage:
            clearSuccessMessage ? null : successMessage ?? this.successMessage,
        errorMessage:
            clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      );
}
