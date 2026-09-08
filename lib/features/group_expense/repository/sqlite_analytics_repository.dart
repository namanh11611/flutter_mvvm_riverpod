import 'package:sqflite/sqflite.dart';

import '../model/category_spending.dart';
import '../model/spending_trend_point.dart';
import 'analytics_repository.dart';

/// Legacy local/test adapter. Production wiring uses SupabaseAnalyticsRepository.
class SqliteAnalyticsRepository implements AnalyticsRepository {
  const SqliteAnalyticsRepository(this.database);

  final Database database;

  @override
  Future<List<CategorySpending>> getCategorySpending(String tripId) async {
    final rows = await database.rawQuery('''
      SELECT category.category_id, category.name, category.icon_name,
             SUM(expense.base_amount) AS amount
      FROM expenses expense
      INNER JOIN expense_categories category
        ON category.category_id = expense.category_id
      WHERE expense.trip_id = ?
      GROUP BY category.category_id, category.name, category.icon_name
      ORDER BY amount DESC, category.name ASC
    ''', [tripId]);
    return rows
        .map(
          (row) => CategorySpending(
            categoryId: row['category_id']! as int,
            categoryName: row['name']! as String,
            iconName: row['icon_name']! as String,
            amount: (row['amount']! as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SpendingTrendPoint>> getSpendingTrend(String tripId) async {
    final rows = await database.rawQuery('''
      SELECT substr(expense_date, 1, 10) AS spending_date,
             SUM(base_amount) AS amount
      FROM expenses
      WHERE trip_id = ?
      GROUP BY substr(expense_date, 1, 10)
      ORDER BY spending_date ASC
    ''', [tripId]);
    return rows
        .map(
          (row) => SpendingTrendPoint(
            date: DateTime.parse(row['spending_date']! as String),
            amount: (row['amount']! as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }
}
