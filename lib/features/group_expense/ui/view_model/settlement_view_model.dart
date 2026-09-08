import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../model/balance_calculator.dart';
import '../../model/expense_constants.dart';
import '../../model/settlement.dart';
import '../../model/settlement_filter.dart';
import '../../model/settlement_receipt.dart';
import '../../model/settlement_suggestion.dart';
import '../../model/settlement_validation.dart';
import '../../repository/expense_repository.dart';
import '../../repository/group_expense_providers.dart';
import '../../repository/receipt_file_service.dart';
import '../../repository/settlement_repository.dart';
import '../state/settlement_state.dart';
import 'balance_view_model.dart';
import 'expense_dashboard_view_model.dart';

part 'settlement_view_model.g.dart';

@riverpod
class SettlementViewModel extends _$SettlementViewModel {
  late SettlementRepository _repository;
  late ExpenseRepository _expenseRepository;
  late ReceiptFileService _receiptFileService;

  @override
  Future<SettlementState> build(String tripId) async {
    final currentUserId = ref.watch(authenticatedUserIdProvider);
    if (currentUserId == null) {
      throw StateError('Authentication is required for settlements');
    }
    final settlementRepositoryFuture =
        ref.watch(settlementRepositoryProvider.future);
    final expenseRepositoryFuture = ref.watch(expenseRepositoryProvider.future);
    final travellerRepositoryFuture =
        ref.watch(travellerRepositoryProvider.future);
    final budgetRepositoryFuture = ref.watch(budgetRepositoryProvider.future);
    _receiptFileService = ref.watch(receiptFileServiceProvider);
    _repository = await settlementRepositoryFuture;
    _expenseRepository = await expenseRepositoryFuture;
    final travellerRepository = await travellerRepositoryFuture;
    final budgetRepository = await budgetRepositoryFuture;
    final travellers = await travellerRepository.getTravellersForTrip(tripId);
    final budget = await budgetRepository.getBudgetForTrip(tripId);
    final derived = await _derived(tripId, travellers.map((e) => e.userId));
    return SettlementState(
      tripId: tripId,
      currency: budget?.baseCurrency ?? 'MYR',
      currentUserId: currentUserId,
      travellers: travellers,
      settlements: await _repository.getSettlementsForTrip(tripId),
      receipts: await _repository.getReceiptsForTrip(tripId),
      suggestions: derived,
    );
  }

  void setFilter(SettlementFilter filter) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(filter: filter));
  }

  void search(String query) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(query: query));
  }

  Future<bool> createSettlement({
    required String? payerId,
    required String? payeeId,
    required String amount,
    required String paymentMethod,
    required DateTime? settlementDate,
    String? notes,
    String? selectedReceiptPath,
  }) async {
    final current = state.value;
    if (current == null) return false;
    if (payerId != current.currentUserId) {
      return _fail(current, 'Only the payer can submit this settlement');
    }
    if (!ExpenseConstants.paymentMethods.contains(paymentMethod)) {
      return _fail(current, 'Select a supported payment method');
    }
    final outstanding = payerId == null || payeeId == null
        ? 0.0
        : current.outstandingFor(payerId, payeeId);
    final error = SettlementValidation.validate(
      payerId: payerId,
      payeeId: payeeId,
      amount: amount,
      outstandingAmount: outstanding,
      paymentMethod: paymentMethod,
      settlementDate: settlementDate,
    );
    if (error != null) return _fail(current, error);

    String? persistedPath;
    state = AsyncData(current.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      if (selectedReceiptPath != null) {
        persistedPath =
            await _receiptFileService.persistReceipt(selectedReceiptPath);
      }
      final now = DateTime.now();
      final settlement = Settlement(
        tripId: current.tripId,
        payerId: payerId!,
        payeeId: payeeId!,
        amount: double.parse(amount.trim()),
        paymentMethod: paymentMethod,
        settlementDate: settlementDate!,
        status: SettlementStatus.pending,
        notes: _optionalText(notes),
        createdAt: now,
      );
      await _repository.createSettlement(
        settlement,
        receipt: persistedPath == null
            ? null
            : SettlementReceipt(
                settlementId: '',
                imagePath: persistedPath,
                uploadedAt: now,
              ),
      );
      await _reload(
        successMessage: 'Payment submitted. Waiting for payee confirmation.',
      );
      return true;
    } catch (_) {
      if (persistedPath != null) {
        await _deleteReceiptBestEffort(persistedPath);
      }
      return _fail(
          current, 'Unable to record the settlement. Please try again.');
    }
  }

  Future<bool> confirmPaymentReceived(String settlementId) async {
    final current = state.value;
    if (current == null) return false;
    final settlement = _findSettlement(current, settlementId);
    if (settlement == null) return false;
    if (settlement.status != SettlementStatus.pending) {
      return _fail(current, 'Only pending settlements can be confirmed');
    }
    if (settlement.payeeId != current.currentUserId) {
      return _fail(current, 'Only the payee can confirm payment received');
    }
    try {
      await _repository.updateSettlement(
        settlement.copyWith(status: SettlementStatus.completed),
      );
      await _reload(successMessage: 'Payment confirmed as received');
      return true;
    } catch (_) {
      return _fail(current, 'Unable to confirm the payment.');
    }
  }

  Future<bool> rejectPayment(String settlementId) async {
    final current = state.value;
    if (current == null) return false;
    final settlement = _findSettlement(current, settlementId);
    if (settlement == null) return false;
    if (settlement.status != SettlementStatus.pending) {
      return _fail(current, 'Only pending settlements can be rejected');
    }
    if (settlement.payeeId != current.currentUserId) {
      return _fail(current, 'Only the payee can reject this payment');
    }
    try {
      await _repository.updateSettlement(
        settlement.copyWith(status: SettlementStatus.rejected),
      );
      await _reload(successMessage: 'Payment submission rejected');
      return true;
    } catch (_) {
      return _fail(current, 'Unable to reject the payment.');
    }
  }

  Future<bool> replaceReceipt(String settlementId, String sourcePath) async {
    final current = state.value;
    if (current == null) return false;
    final settlement = _findSettlement(current, settlementId);
    if (settlement == null) return false;
    if (!_canPayerModify(current, settlement)) {
      return _fail(
        current,
        'Only the payer can edit a pending payment submission',
      );
    }
    String? newPath;
    try {
      newPath = await _receiptFileService.persistReceipt(sourcePath);
      await _repository.updateSettlement(
        settlement,
        receipt: SettlementReceipt(
          settlementId: settlementId,
          imagePath: newPath,
          uploadedAt: DateTime.now(),
        ),
      );
      final old = current.receipts[settlementId];
      if (old != null) await _deleteReceiptBestEffort(old.imagePath);
      await _reload(successMessage: 'Receipt updated successfully');
      return true;
    } catch (_) {
      if (newPath != null) await _deleteReceiptBestEffort(newPath);
      return _fail(current, 'Unable to update the receipt.');
    }
  }

  Future<bool> removeReceipt(String settlementId) async {
    final current = state.value;
    if (current == null) return false;
    final settlement = _findSettlement(current, settlementId);
    if (settlement == null) return false;
    if (!_canPayerModify(current, settlement)) {
      return _fail(
        current,
        'Only the payer can edit a pending payment submission',
      );
    }
    try {
      await _repository.updateSettlement(settlement, removeReceipt: true);
      final old = current.receipts[settlementId];
      if (old != null) await _deleteReceiptBestEffort(old.imagePath);
      await _reload(successMessage: 'Receipt removed');
      return true;
    } catch (_) {
      return _fail(current, 'Unable to remove the receipt.');
    }
  }

  Future<bool> deleteSettlement(String settlementId) async {
    final current = state.value;
    if (current == null) return false;
    final settlement = _findSettlement(current, settlementId);
    if (settlement == null) return false;
    if (!_canPayerModify(current, settlement)) {
      return _fail(
        current,
        'Only the payer can delete a pending payment submission',
      );
    }
    try {
      await _repository.deleteSettlement(current.tripId, settlementId);
      final receipt = current.receipts[settlementId];
      if (receipt != null) {
        await _deleteReceiptBestEffort(receipt.imagePath);
      }
      await _reload(successMessage: 'Settlement deleted');
      return true;
    } catch (_) {
      return _fail(current, 'Unable to delete the settlement.');
    }
  }

  Future<void> refresh() => _reload();

  Future<List<SettlementSuggestion>> _derived(
    String tripId,
    Iterable<String> travellerIds,
  ) async {
    final expenses =
        await _expenseRepository.calculateNetExpenseBalances(tripId);
    final completed = await _repository.getCompletedSettlements(tripId);
    final balances = BalanceCalculator.applyCompletedSettlements(
      expenseBalances: {
        for (final id in travellerIds) id: expenses[id] ?? 0,
      },
      settlements: completed,
    );
    return BalanceCalculator.suggestions(balances);
  }

  Future<void> _reload({String? successMessage}) async {
    final current = state.value!;
    final suggestions = await _derived(
      current.tripId,
      current.travellers.map((item) => item.userId),
    );
    state = AsyncData(current.copyWith(
      settlements: await _repository.getSettlementsForTrip(current.tripId),
      receipts: await _repository.getReceiptsForTrip(current.tripId),
      suggestions: suggestions,
      isSaving: false,
      successMessage: successMessage,
      clearError: true,
    ));
    ref.invalidate(balanceViewModelProvider(current.tripId));
    ref.invalidate(expenseDashboardViewModelProvider(current.tripId));
  }

  bool _fail(SettlementState current, String message) {
    state = AsyncData(current.copyWith(
      isSaving: false,
      errorMessage: message,
      clearSuccess: true,
    ));
    return false;
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Settlement? _findSettlement(SettlementState current, String settlementId) {
    for (final settlement in current.settlements) {
      if (settlement.settlementId == settlementId) return settlement;
    }
    return null;
  }

  bool _canPayerModify(SettlementState current, Settlement settlement) =>
      settlement.status == SettlementStatus.pending &&
      settlement.payerId == current.currentUserId;

  Future<void> _deleteReceiptBestEffort(String path) async {
    try {
      await _receiptFileService.deleteReceipt(path);
    } catch (_) {
      // SQLite is authoritative; local file cleanup must not reverse a
      // successful settlement write or display a misleading failure.
    }
  }
}
