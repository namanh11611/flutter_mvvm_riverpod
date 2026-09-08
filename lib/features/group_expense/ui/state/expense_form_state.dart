import '../../model/expense.dart';
import '../../model/expense_category.dart';
import '../../model/expense_participant.dart';
import '../../model/expense_receipt.dart';
import '../../model/traveller.dart';

class ExpenseFormState {
  const ExpenseFormState({
    required this.tripId,
    required this.currentUserId,
    required this.baseCurrency,
    this.expense,
    this.categories = const [],
    this.travellers = const [],
    this.participants = const [],
    this.receipt,
    this.isSaving = false,
    this.savedExpenseId,
    this.isDeleted = false,
    this.errorMessage,
    this.successMessage,
  });

  final String tripId;
  final String? currentUserId;
  final String baseCurrency;
  final Expense? expense;
  final List<ExpenseCategory> categories;
  final List<Traveller> travellers;
  final List<ExpenseParticipant> participants;
  final ExpenseReceipt? receipt;
  final bool isSaving;
  final String? savedExpenseId;
  final bool isDeleted;
  final String? errorMessage;
  final String? successMessage;

  String? get defaultPayerId {
    final userId = currentUserId;
    if (userId == null) return null;
    return travellers.any((traveller) => traveller.userId == userId)
        ? userId
        : null;
  }

  ExpenseFormState copyWith({
    Expense? expense,
    List<ExpenseParticipant>? participants,
    ExpenseReceipt? receipt,
    bool clearReceipt = false,
    bool? isSaving,
    String? savedExpenseId,
    bool? isDeleted,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      ExpenseFormState(
        tripId: tripId,
        currentUserId: currentUserId,
        baseCurrency: baseCurrency,
        expense: expense ?? this.expense,
        categories: categories,
        travellers: travellers,
        participants: participants ?? this.participants,
        receipt: clearReceipt ? null : receipt ?? this.receipt,
        isSaving: isSaving ?? this.isSaving,
        savedExpenseId: savedExpenseId ?? this.savedExpenseId,
        isDeleted: isDeleted ?? this.isDeleted,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        successMessage:
            clearSuccess ? null : successMessage ?? this.successMessage,
      );
}
