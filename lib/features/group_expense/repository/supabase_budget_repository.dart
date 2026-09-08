import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/trip_budget.dart';
import 'budget_repository.dart';
import 'group_expense_repository_exception.dart';

class SupabaseBudgetRepository implements BudgetRepository {
  const SupabaseBudgetRepository(this.client);
  final SupabaseClient client;

  @override
  Future<TripBudget?> getBudgetForTrip(String tripId) async {
    try {
      final row = await client
          .from('trip_budgets')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      return row == null ? null : _budget(row);
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  @override
  Future<String> createBudget(TripBudget budget) async {
    try {
      final row = await client
          .from('trip_budgets')
          .insert(_write(budget))
          .select()
          .single();
      return row['id'] as String;
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  @override
  Future<void> updateBudget(TripBudget budget) async {
    try {
      await client
          .from('trip_budgets')
          .update(_write(budget))
          .eq('id', budget.budgetId!)
          .eq('trip_id', budget.tripId);
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  @override
  Future<double> getTotalSpent(String tripId) async {
    try {
      final rows = await client
          .from('expenses')
          .select('base_amount')
          .eq('trip_id', tripId);
      return rows.fold<double>(
          0, (sum, row) => sum + (row['base_amount'] as num).toDouble());
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  TripBudget _budget(Map<String, dynamic> row) => TripBudget(
      budgetId: row['id'] as String,
      tripId: row['trip_id'] as String,
      budgetName: row['budget_name'] as String,
      budgetAmount: (row['budget_amount'] as num).toDouble(),
      baseCurrency: row['base_currency'] as String,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String));

  Map<String, Object?> _write(TripBudget value) => {
        'trip_id': value.tripId,
        'budget_name': value.budgetName,
        'budget_amount': value.budgetAmount,
        'base_currency': value.baseCurrency,
        'notes': value.notes,
      };
}
