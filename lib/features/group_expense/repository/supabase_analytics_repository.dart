import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/category_spending.dart';
import '../model/spending_trend_point.dart';
import 'analytics_repository.dart';
import 'group_expense_repository_exception.dart';

class SupabaseAnalyticsRepository implements AnalyticsRepository {
  const SupabaseAnalyticsRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<CategorySpending>> getCategorySpending(String tripId) async {
    try {
      final expenses = await client
          .from('expenses')
          .select('category_id,base_amount')
          .eq('trip_id', tripId);
      final categories =
          await client.from('expense_categories').select('id,name,icon_name');
      final byId = {for (final row in categories) row['id'] as int: row};
      final totals = <int, double>{};
      for (final row in expenses) {
        final id = row['category_id'] as int;
        totals[id] = (totals[id] ?? 0) + (row['base_amount'] as num).toDouble();
      }
      final result = [
        for (final entry in totals.entries)
          if (byId[entry.key] case final category?)
            CategorySpending(
                categoryId: entry.key,
                categoryName: category['name'] as String,
                iconName: category['icon_name'] as String,
                amount: entry.value)
      ];
      result.sort((a, b) => b.amount.compareTo(a.amount));
      return result;
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  @override
  Future<List<SpendingTrendPoint>> getSpendingTrend(String tripId) async {
    try {
      final rows = await client
          .from('expenses')
          .select('expense_date,base_amount')
          .eq('trip_id', tripId)
          .order('expense_date');
      final totals = <String, double>{};
      for (final row in rows) {
        final date = row['expense_date'] as String;
        totals[date] =
            (totals[date] ?? 0) + (row['base_amount'] as num).toDouble();
      }
      return [
        for (final entry in totals.entries)
          SpendingTrendPoint(
              date: DateTime.parse(entry.key), amount: entry.value)
      ];
    } catch (error) {
      groupExpenseFailure(error);
    }
  }
}
