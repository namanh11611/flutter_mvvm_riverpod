import 'package:sqflite/sqflite.dart';

import '../model/expense.dart';
import '../model/expense_category.dart';
import '../model/expense_participant.dart';
import '../model/expense_receipt.dart';
import '../model/expense_split.dart';
import 'expense_repository.dart';

/// Legacy local/test adapter. Production wiring uses SupabaseExpenseRepository.
class SqliteExpenseRepository implements ExpenseRepository {
  const SqliteExpenseRepository(this.database);
  final Database database;

  @override
  Future<List<ExpenseCategory>> getCategories() async {
    final rows =
        await database.query('expense_categories', orderBy: 'category_id');
    return rows.map(ExpenseCategory.fromMap).toList(growable: false);
  }

  @override
  Future<List<Expense>> getExpensesForTrip(String tripId) async {
    final rows = await database.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'expense_date DESC, expense_id DESC',
    );
    return rows.map(Expense.fromMap).toList(growable: false);
  }

  @override
  Future<Expense?> getExpenseById(String tripId, String expenseId) async {
    final rows = await database.query(
      'expenses',
      where: 'trip_id = ? AND expense_id = ?',
      whereArgs: [tripId, expenseId],
      limit: 1,
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  @override
  Future<List<ExpenseParticipant>> getParticipants(
    String tripId,
    String expenseId,
  ) async {
    final rows = await database.rawQuery('''
      SELECT participant.* FROM expense_participants participant
      INNER JOIN expenses expense ON expense.expense_id = participant.expense_id
      WHERE expense.trip_id = ? AND expense.expense_id = ?
      ORDER BY participant.user_id
    ''', [tripId, expenseId]);
    return rows.map(ExpenseParticipant.fromMap).toList(growable: false);
  }

  @override
  Future<ExpenseReceipt?> getReceipt(
    String tripId,
    String expenseId,
  ) async {
    final rows = await database.rawQuery('''
      SELECT receipt.* FROM expense_receipts receipt
      INNER JOIN expenses expense ON expense.expense_id = receipt.expense_id
      WHERE expense.trip_id = ? AND expense.expense_id = ? LIMIT 1
    ''', [tripId, expenseId]);
    return rows.isEmpty ? null : ExpenseReceipt.fromMap(rows.first);
  }

  @override
  Future<String> createExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
    ExpenseReceipt? receipt,
  }) async {
    _validate(expense, participants);
    return database.transaction((transaction) async {
      final expenseId = await transaction.insert('expenses', expense.toMap());
      await _replaceParticipants(transaction, expenseId, participants);
      if (receipt != null) {
        await transaction.insert(
          'expense_receipts',
          _receiptMap(receipt, expenseId),
        );
      }
      return expenseId.toString();
    });
  }

  @override
  Future<void> updateExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
    ExpenseReceipt? receipt,
    bool removeReceipt = false,
  }) async {
    final expenseId = expense.expenseId;
    if (expenseId == null) throw ArgumentError('expenseId is required');
    _validate(expense, participants);
    await database.transaction((transaction) async {
      final updated = await transaction.update(
        'expenses',
        expense.toMap()..remove('expense_id'),
        where: 'trip_id = ? AND expense_id = ?',
        whereArgs: [expense.tripId, expenseId],
      );
      if (updated == 0) throw StateError('Expense not found');
      await _replaceParticipants(transaction, expenseId, participants);
      if (removeReceipt || receipt != null) {
        await transaction.delete(
          'expense_receipts',
          where: 'expense_id = ?',
          whereArgs: [expenseId],
        );
      }
      if (receipt != null) {
        await transaction.insert(
          'expense_receipts',
          _receiptMap(receipt, expenseId),
        );
      }
    });
  }

  @override
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await database.delete(
      'expenses',
      where: 'trip_id = ? AND expense_id = ?',
      whereArgs: [tripId, expenseId],
    );
  }

  @override
  Future<Map<String, double>> calculateNetExpenseBalances(String tripId) async {
    final paidRows = await database.rawQuery('''
      SELECT paid_by_user_id AS user_id, SUM(base_amount) AS total
      FROM expenses WHERE trip_id = ? GROUP BY paid_by_user_id
    ''', [tripId]);
    final owedRows = await database.rawQuery('''
      SELECT participant.user_id, SUM(participant.share_amount) AS total
      FROM expense_participants participant
      INNER JOIN expenses expense ON expense.expense_id = participant.expense_id
      WHERE expense.trip_id = ? GROUP BY participant.user_id
    ''', [tripId]);
    final cents = <String, int>{};
    for (final row in paidRows) {
      final userId = row['user_id']!.toString();
      cents[userId] = (cents[userId] ?? 0) +
          ((row['total']! as num).toDouble() * 100).round();
    }
    for (final row in owedRows) {
      final userId = row['user_id']!.toString();
      cents[userId] = (cents[userId] ?? 0) -
          ((row['total']! as num).toDouble() * 100).round();
    }
    return {
      for (final entry in cents.entries) entry.key: entry.value / 100,
    };
  }

  void _validate(Expense expense, List<ExpenseParticipant> participants) {
    if (expense.title.trim().isEmpty ||
        expense.originalAmount <= 0 ||
        expense.exchangeRate <= 0 ||
        expense.baseAmount <= 0) {
      throw ArgumentError('Invalid expense data');
    }
    ExpenseSplitCalculator.validateParticipants(
      baseAmount: expense.baseAmount,
      participants: participants,
    );
  }

  Future<void> _replaceParticipants(
    Transaction transaction,
    Object expenseId,
    List<ExpenseParticipant> participants,
  ) async {
    await transaction.delete(
      'expense_participants',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    for (final participant in participants) {
      await transaction.insert('expense_participants', {
        ...participant.toMap(),
        'expense_id': expenseId,
      });
    }
  }

  Map<String, Object?> _receiptMap(ExpenseReceipt receipt, Object expenseId) =>
      {
        'expense_id': expenseId,
        'image_path': receipt.imagePath,
        'uploaded_at': receipt.uploadedAt.toIso8601String(),
      };
}
