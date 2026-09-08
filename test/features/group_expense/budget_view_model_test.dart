import 'package:flutter_mvvm_riverpod/features/group_expense/model/trip.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/trip_budget.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/expense_constants.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/budget_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/trip_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/budget_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetViewModel', () {
    late _FakeBudgetRepository budgetRepository;
    late ProviderContainer container;

    setUp(() {
      budgetRepository = _FakeBudgetRepository();
      container = ProviderContainer(
        overrides: [
          budgetRepositoryProvider.overrideWith(
            (ref) async => budgetRepository,
          ),
          tripRepositoryProvider.overrideWith(
            (ref) async => const _FakeTripRepository(),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('creates a valid budget and exposes calculated totals', () async {
      await container.read(budgetViewModelProvider('7').future);

      final created = await container
          .read(budgetViewModelProvider('7').notifier)
          .createBudget(
            name: 'Penang Trip',
            amount: '3000',
            currency: 'MYR',
            notes: 'Food weekend',
          );

      final state = container.read(budgetViewModelProvider('7')).value!;
      expect(created, isTrue);
      expect(state.budget?.budgetName, 'Penang Trip');
      expect(state.remaining, 945);
      expect(state.usagePercentage, 68.5);
      expect(state.successMessage, 'Budget Created!');
    });

    test('rejects invalid input without writing', () async {
      await container.read(budgetViewModelProvider('7').future);

      final created = await container
          .read(budgetViewModelProvider('7').notifier)
          .createBudget(name: '', amount: '0', currency: '');

      final state = container.read(budgetViewModelProvider('7')).value!;
      expect(created, isFalse);
      expect(budgetRepository.createCalls, 0);
      expect(state.errorMessage, 'Budget name is required');
    });

    test('creates budgets in every shared supported currency', () async {
      for (final currency in ExpenseConstants.supportedCurrencies) {
        final repository = _FakeBudgetRepository();
        final currencyContainer = ProviderContainer(
          overrides: [
            budgetRepositoryProvider.overrideWith((ref) async => repository),
            tripRepositoryProvider.overrideWith(
              (ref) async => const _FakeTripRepository(),
            ),
          ],
        );
        addTearDown(currencyContainer.dispose);
        await currencyContainer.read(budgetViewModelProvider(currency).future);

        final created = await currencyContainer
            .read(budgetViewModelProvider(currency).notifier)
            .createBudget(
              name: '$currency Trip',
              amount: '1000',
              currency: currency,
            );

        expect(created, isTrue, reason: currency);
        expect(repository.budget?.baseCurrency, currency);

        final updated = await currencyContainer
            .read(budgetViewModelProvider(currency).notifier)
            .updateBudget(amount: '1200');
        expect(updated, isTrue, reason: '$currency edit');
        expect(repository.budget?.baseCurrency, currency);
      }
    });

    test('updates amount and removes blank notes', () async {
      budgetRepository.budget = _budget(amount: 3000, notes: 'Old notes');
      await container.read(budgetViewModelProvider('7').future);

      final updated = await container
          .read(budgetViewModelProvider('7').notifier)
          .updateBudget(amount: '3500', notes: '   ');

      final state = container.read(budgetViewModelProvider('7')).value!;
      expect(updated, isTrue);
      expect(state.budget?.budgetAmount, 3500);
      expect(state.budget?.notes, isNull);
      expect(state.successMessage, 'Budget updated successfully');
    });
  });
}

TripBudget _budget({required double amount, String? notes}) => TripBudget(
  budgetId: '1',
  tripId: '7',
  budgetName: 'Penang Trip',
  budgetAmount: amount,
  baseCurrency: 'MYR',
  notes: notes,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

class _FakeBudgetRepository implements BudgetRepository {
  TripBudget? budget;
  int createCalls = 0;

  @override
  Future<String> createBudget(TripBudget budget) async {
    createCalls++;
    this.budget = budget.copyWith(budgetId: '1');
    return '1';
  }

  @override
  Future<TripBudget?> getBudgetForTrip(String tripId) async => budget;

  @override
  Future<double> getTotalSpent(String tripId) async => 2055;

  @override
  Future<void> updateBudget(TripBudget budget) async {
    this.budget = budget;
  }
}

class _FakeTripRepository implements TripRepository {
  const _FakeTripRepository();

  @override
  Future<Trip?> getTripById(String tripId) async => Trip(
    tripId: tripId,
    destination: 'Penang, Malaysia',
    startDate: DateTime(2025, 8, 1),
    endDate: DateTime(2025, 8, 3),
  );
}
