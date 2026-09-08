import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_database_schema.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_analytics_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_budget_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/analytics_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late ProviderContainer container;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await GroupExpenseDatabaseSchema.createAndSeed(database);
    container = ProviderContainer(overrides: [
      analyticsRepositoryProvider.overrideWith(
        (ref) async => SqliteAnalyticsRepository(database),
      ),
      budgetRepositoryProvider.overrideWith(
        (ref) async => SqliteBudgetRepository(database),
      ),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('RM3000 budget and RM2055 expenses produce required summary', () async {
    final state = await container.read(analyticsViewModelProvider('1').future);

    expect(state.totalBudget, 3000);
    expect(state.totalExpenses, 2055);
    expect(state.remaining, 945);
    expect(state.usagePercentage, 68.5);
  });

  test('category totals and percentages reconcile', () async {
    final state = await container.read(analyticsViewModelProvider('1').future);

    final categoryTotal = state.categories.fold<double>(
      0,
      (total, category) => total + category.amount,
    );
    final percentageTotal = state.categories.fold<double>(
      0,
      (total, category) => total + category.percentage,
    );
    expect(categoryTotal, state.totalExpenses);
    expect(percentageTotal, closeTo(100, 0.0001));
  });

  test('highest spending category is identified correctly', () async {
    final state = await container.read(analyticsViewModelProvider('1').future);

    expect(state.highestSpendingCategory?.categoryName, 'Flight');
    expect(state.highestSpendingCategory?.amount, 760);
  });

  test('category aggregation uses base amount for foreign currencies',
      () async {
    await database.insert('expenses', {
      'trip_id': 1,
      'paid_by_user_id': 1,
      'category_id': 11,
      'title': 'Foreign currency expense',
      'original_amount': 10.0,
      'currency_code': 'USD',
      'exchange_rate': 4.6,
      'base_amount': 46.0,
      'expense_date': '2025-07-27T12:00:00.000',
      'created_at': '2025-07-27T12:00:00.000',
      'updated_at': '2025-07-27T12:00:00.000',
    });

    final categories =
        await SqliteAnalyticsRepository(database).getCategorySpending('1');

    expect(
      categories
          .firstWhere((category) => category.categoryName == 'Others')
          .amount,
      46,
    );
  });

  test('spending trend is ordered by expense date', () async {
    final state = await container.read(analyticsViewModelProvider('1').future);

    for (var index = 1; index < state.trend.length; index++) {
      expect(
        state.trend[index - 1].date.isAfter(state.trend[index].date),
        isFalse,
      );
    }
  });

  test('empty analytics state is handled safely', () async {
    container.dispose();
    await database.delete('expenses');
    container = ProviderContainer(overrides: [
      analyticsRepositoryProvider.overrideWith(
        (ref) async => SqliteAnalyticsRepository(database),
      ),
      budgetRepositoryProvider.overrideWith(
        (ref) async => SqliteBudgetRepository(database),
      ),
    ]);

    final state = await container.read(analyticsViewModelProvider('1').future);

    expect(state.isEmpty, isTrue);
    expect(state.totalExpenses, 0);
    expect(state.categories, isEmpty);
    expect(state.trend, isEmpty);
    expect(state.highestSpendingCategory, isNull);
    expect(state.usagePercentage, 0);
  });
}
