import '../model/trip_budget.dart';

abstract interface class BudgetRepository {
  Future<TripBudget?> getBudgetForTrip(String tripId);
  Future<String> createBudget(TripBudget budget);
  Future<void> updateBudget(TripBudget budget);
  Future<double> getTotalSpent(String tripId);
}
