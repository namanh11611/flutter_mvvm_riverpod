import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_database_schema.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/local_traveller_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/local_trip_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_budget_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_expense_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_settlement_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/expense_dashboard_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late ProviderContainer container;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await GroupExpenseDatabaseSchema.createAndSeed(database);
    container = ProviderContainer(overrides: [
      authenticatedUserIdProvider.overrideWithValue('2'),
      expenseRepositoryProvider.overrideWith(
        (ref) async => SqliteExpenseRepository(database),
      ),
      settlementRepositoryProvider.overrideWith(
        (ref) async => SqliteSettlementRepository(database),
      ),
      travellerRepositoryProvider.overrideWith(
        (ref) async => LocalTravellerRepository(database),
      ),
      tripRepositoryProvider.overrideWith(
        (ref) async => LocalTripRepository(database),
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

  test('dashboard summary uses repository data correctly', () async {
    final subscription =
        container.listen(expenseDashboardViewModelProvider('1'), (_, __) {});
    addTearDown(subscription.close);
    final state =
        await container.read(expenseDashboardViewModelProvider('1').future);

    expect(state.trip?.destination, 'Kuala Lumpur, Malaysia');
    expect(state.travellerCount, 4);
    expect(state.budgetAmount, 3000);
    expect(state.totalSpent, 2055);
    expect(state.remaining, 945);
    expect(state.usagePercentage, 68.5);
    expect(state.expenses, hasLength(8));
    expect(state.expenses.first.title, 'Airport snacks');
    expect(state.youOwe, 143.25);
  });
}
