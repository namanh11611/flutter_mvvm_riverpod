import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement_receipt.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/traveller.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/traveller_balance.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/trip.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/trip_budget.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/budget_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/expense_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/settlement_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/traveller_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/trip_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/balance_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composes traveller balances and suggestions from repositories',
      () async {
    final container = ProviderContainer(overrides: [
      expenseRepositoryProvider.overrideWith(
        (ref) async => _BalanceExpenseRepository(),
      ),
      settlementRepositoryProvider.overrideWith(
        (ref) async => _BalanceSettlementRepository(),
      ),
      travellerRepositoryProvider.overrideWith(
        (ref) async => _BalanceTravellerRepository(),
      ),
      budgetRepositoryProvider.overrideWith(
        (ref) async => _BalanceBudgetRepository(),
      ),
      tripRepositoryProvider.overrideWith(
        (ref) async => _BalanceTripRepository(),
      ),
      authenticatedUserIdProvider.overrideWithValue('1'),
    ]);
    addTearDown(container.dispose);

    final state = await container.read(balanceViewModelProvider('1').future);

    expect(state.owedToYou, 286.50);
    expect(state.youOwe, 0);
    expect(state.suggestions, hasLength(2));
    expect(
      state.balances[1].status,
      TravellerBalanceStatus.pendingConfirmation,
    );
    expect(state.balances[3].status, TravellerBalanceStatus.settled);
  });
}

class _BalanceExpenseRepository implements ExpenseRepository {
  @override
  Future<Map<String, double>> calculateNetExpenseBalances(
          String tripId) async =>
      {'1': 287, '2': -143.75, '3': -143.25, '4': 0};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BalanceSettlementRepository implements SettlementRepository {
  @override
  Future<void> deleteSettlement(String tripId, String settlementId) =>
      throw UnimplementedError();

  @override
  Future<List<Settlement>> getCompletedSettlements(String tripId) async => [
        Settlement(
          tripId: tripId,
          payerId: '2',
          payeeId: '1',
          amount: 0.50,
          paymentMethod: 'Cash',
          settlementDate: DateTime(2025),
          status: SettlementStatus.completed,
          createdAt: DateTime(2025),
        ),
      ];

  @override
  Future<List<Settlement>> getPendingSettlements(String tripId) async => [
        Settlement(
          tripId: tripId,
          payerId: '2',
          payeeId: '1',
          amount: 10,
          paymentMethod: 'Cash',
          settlementDate: DateTime(2025),
          status: SettlementStatus.pending,
          createdAt: DateTime(2025),
        ),
      ];

  @override
  Future<SettlementReceipt?> getReceipt(
    String tripId,
    String settlementId,
  ) async =>
      null;

  @override
  Future<Map<String, SettlementReceipt>> getReceiptsForTrip(
    String tripId,
  ) async =>
      const {};

  @override
  Future<String> createSettlement(Settlement settlement,
          {SettlementReceipt? receipt}) =>
      throw UnimplementedError();
  @override
  Future<List<Settlement>> getSettlementsForTrip(String tripId) =>
      throw UnimplementedError();
  @override
  Future<void> updateSettlement(Settlement settlement,
          {SettlementReceipt? receipt, bool removeReceipt = false}) =>
      throw UnimplementedError();
}

class _BalanceTravellerRepository implements TravellerRepository {
  @override
  Future<Traveller?> getTravellerById(String tripId, String userId) async =>
      null;

  @override
  Future<List<Traveller>> getTravellersForTrip(String tripId) async => const [
        Traveller(userId: '1', displayName: 'Ahmad', initials: 'AF'),
        Traveller(userId: '2', displayName: 'Sarah', initials: 'SL'),
        Traveller(userId: '3', displayName: 'Ravi', initials: 'RK'),
        Traveller(userId: '4', displayName: 'Nurul', initials: 'NA'),
      ];
}

class _BalanceBudgetRepository implements BudgetRepository {
  @override
  Future<TripBudget?> getBudgetForTrip(String tripId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BalanceTripRepository implements TripRepository {
  @override
  Future<Trip?> getTripById(String tripId) async => null;
}
