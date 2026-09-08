import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../model/budget_validation.dart';
import '../../model/trip_budget.dart';
import '../../repository/budget_repository.dart';
import '../../repository/group_expense_providers.dart';
import '../../repository/trip_repository.dart';
import '../state/budget_state.dart';
import 'analytics_view_model.dart';
import 'expense_dashboard_view_model.dart';

part 'budget_view_model.g.dart';

@riverpod
class BudgetViewModel extends _$BudgetViewModel {
  late BudgetRepository _budgetRepository;
  late TripRepository _tripRepository;

  @override
  Future<BudgetState> build(String tripId) async {
    final budgetRepositoryFuture = ref.watch(budgetRepositoryProvider.future);
    final tripRepositoryFuture = ref.watch(tripRepositoryProvider.future);
    _budgetRepository = await budgetRepositoryFuture;
    _tripRepository = await tripRepositoryFuture;
    final trip = await _tripRepository.getTripById(tripId);
    final budget = await _budgetRepository.getBudgetForTrip(tripId);
    final totalSpent = await _budgetRepository.getTotalSpent(tripId);
    return BudgetState(
      tripId: tripId,
      trip: trip,
      budget: budget,
      totalSpent: totalSpent,
    );
  }

  Future<bool> createBudget({
    required String name,
    required String amount,
    required String currency,
    String? notes,
  }) async {
    final current = state.value;
    if (current == null) return false;
    final validationError = _validate(
      name: name,
      amount: amount,
      currency: currency,
    );
    if (validationError != null) {
      state = AsyncData(current.copyWith(
        errorMessage: validationError,
        clearSuccessMessage: true,
      ));
      return false;
    }
    if (current.budget != null) {
      state = AsyncData(current.copyWith(
        errorMessage: 'This trip already has a budget',
        clearSuccessMessage: true,
      ));
      return false;
    }

    state = AsyncData(current.copyWith(
      isSaving: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
    try {
      final now = DateTime.now();
      await _budgetRepository.createBudget(TripBudget(
        tripId: current.tripId,
        budgetName: name.trim(),
        budgetAmount: double.parse(amount.trim()),
        baseCurrency: currency,
        notes: _optionalText(notes),
        createdAt: now,
        updatedAt: now,
      ));
      await _reload(successMessage: 'Budget Created!');
      _invalidateSummaries(current.tripId);
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(
        errorMessage: 'Unable to create the budget. Please try again.',
        clearSuccessMessage: true,
      ));
      return false;
    }
  }

  Future<bool> updateBudget({
    required String amount,
    String? notes,
  }) async {
    final current = state.value;
    final existing = current?.budget;
    if (current == null || existing == null) return false;
    final amountError = BudgetValidation.amount(amount);
    if (amountError != null) {
      state = AsyncData(current.copyWith(
        errorMessage: amountError,
        clearSuccessMessage: true,
      ));
      return false;
    }

    state = AsyncData(current.copyWith(
      isSaving: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
    try {
      await _budgetRepository.updateBudget(existing.copyWith(
        budgetAmount: double.parse(amount.trim()),
        notes: _optionalText(notes),
        clearNotes: _optionalText(notes) == null,
        updatedAt: DateTime.now(),
      ));
      await _reload(successMessage: 'Budget updated successfully');
      _invalidateSummaries(current.tripId);
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(
        errorMessage: 'Unable to update the budget. Please try again.',
        clearSuccessMessage: true,
      ));
      return false;
    }
  }

  void clearFeedback() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ));
    }
  }

  Future<void> _reload({String? successMessage}) async {
    final current = state.value!;
    final budget = await _budgetRepository.getBudgetForTrip(current.tripId);
    final spent = await _budgetRepository.getTotalSpent(current.tripId);
    state = AsyncData(current.copyWith(
      budget: budget,
      totalSpent: spent,
      isSaving: false,
      successMessage: successMessage,
      clearErrorMessage: true,
    ));
  }

  String? _validate({
    required String name,
    required String amount,
    required String currency,
  }) =>
      BudgetValidation.name(name) ??
      BudgetValidation.amount(amount) ??
      BudgetValidation.currency(currency);

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _invalidateSummaries(String tripId) {
    ref.invalidate(expenseDashboardViewModelProvider(tripId));
    ref.invalidate(analyticsViewModelProvider(tripId));
  }
}
