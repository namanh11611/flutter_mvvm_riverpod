import '../model/expense.dart';
import '../model/expense_participant.dart';
import '../model/expense_receipt.dart';
import '../model/expense_category.dart';

abstract interface class ExpenseRepository {
  Future<List<Expense>> getExpensesForTrip(String tripId);
  Future<List<ExpenseCategory>> getCategories();
  Future<Expense?> getExpenseById(String tripId, String expenseId);
  Future<ExpenseReceipt?> getReceipt(String tripId, String expenseId);
  Future<String> createExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
    ExpenseReceipt? receipt,
  });
  Future<void> updateExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
    ExpenseReceipt? receipt,
    bool removeReceipt = false,
  });
  Future<void> deleteExpense(String tripId, String expenseId);
  Future<List<ExpenseParticipant>> getParticipants(
    String tripId,
    String expenseId,
  );
  Future<Map<String, double>> calculateNetExpenseBalances(String tripId);
}
