import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/expense.dart';
import '../model/expense_category.dart';
import '../model/expense_participant.dart';
import '../model/expense_receipt.dart';
import 'expense_repository.dart';
import 'group_expense_repository_exception.dart';
import 'receipt_mutation_workflow.dart';
import 'receipt_storage_service.dart';

class SupabaseExpenseRepository implements ExpenseRepository {
  const SupabaseExpenseRepository(this.client, this.receipts);
  final SupabaseClient client;
  final ReceiptStorageService receipts;

  @override
  Future<List<Expense>> getExpensesForTrip(String tripId) => _guard(() async {
        final rows = await client
            .from('expenses')
            .select()
            .eq('trip_id', tripId)
            .order('expense_date', ascending: false);
        return rows.map(_expense).toList(growable: false);
      });

  @override
  Future<List<ExpenseCategory>> getCategories() => _guard(() async {
        final rows =
            await client.from('expense_categories').select().order('id');
        return rows
            .map((row) => ExpenseCategory(
                categoryId: row['id'] as int,
                name: row['name'] as String,
                iconName: row['icon_name'] as String))
            .toList(growable: false);
      });

  @override
  Future<Expense?> getExpenseById(String tripId, String expenseId) =>
      _guard(() async {
        final row = await client
            .from('expenses')
            .select()
            .eq('trip_id', tripId)
            .eq('id', expenseId)
            .maybeSingle();
        return row == null ? null : _expense(row);
      });

  @override
  Future<List<ExpenseParticipant>> getParticipants(
          String tripId, String expenseId) =>
      _guard(() async {
        final visible = await getExpenseById(tripId, expenseId);
        if (visible == null) {
          return const [];
        }
        final rows = await client
            .from('expense_participants')
            .select()
            .eq('expense_id', expenseId);
        return rows.map(_participant).toList(growable: false);
      });

  @override
  Future<ExpenseReceipt?> getReceipt(String tripId, String expenseId) =>
      _guard(() async {
        final visible = await getExpenseById(tripId, expenseId);
        if (visible == null) return null;
        final row = await client
            .from('expense_receipts')
            .select()
            .eq('expense_id', expenseId)
            .maybeSingle();
        return row == null ? null : _receipt(row);
      });

  @override
  Future<String> createExpense(
          {required Expense expense,
          required List<ExpenseParticipant> participants,
          ExpenseReceipt? receipt}) =>
      _guard(() async {
        final id = await client.rpc(
            'group_expense_create_expense_with_participants',
            params: _rpc(expense, participants)) as String;
        if (receipt != null) {
          String? objectPath;
          try {
            objectPath = await receipts.uploadExpenseReceipt(
                tripId: expense.tripId,
                expenseId: id,
                sourcePath: receipt.imagePath);
            await upsertReceipt(id, objectPath);
          } catch (_) {
            if (objectPath != null) {
              await receipts.deleteReceipt(objectPath);
            }
            await client.from('expenses').delete().eq('id', id);
            rethrow;
          }
        }
        return id;
      });

  @override
  Future<void> updateExpense(
          {required Expense expense,
          required List<ExpenseParticipant> participants,
          ExpenseReceipt? receipt,
          bool removeReceipt = false}) =>
      _guard(() async {
        final id = expense.expenseId!;
        await client.rpc('group_expense_update_expense_with_participants',
            params: {'p_expense_id': id, ..._rpc(expense, participants)});
        final old = await getReceipt(expense.tripId, id);
        if (removeReceipt) {
          if (old != null) {
            await ReceiptMutationWorkflow.remove(
              objectPath: old.imagePath,
              deleteObject: receipts.deleteReceipt,
              deleteMetadata: () => removeReceiptMetadata(expense.tripId, id),
            );
          }
        }
        if (receipt != null) {
          await ReceiptMutationWorkflow.replace(
            oldObjectPath: old?.imagePath,
            upload: () => receipts.uploadExpenseReceipt(
              tripId: expense.tripId,
              expenseId: id,
              sourcePath: receipt.imagePath,
            ),
            updateMetadata: (path) => upsertReceipt(id, path),
            deleteObject: receipts.deleteReceipt,
          );
        }
      });

  Future<void> upsertReceipt(String expenseId, String objectPath) =>
      _guard(() async {
        await client.from('expense_receipts').upsert(
            {'expense_id': expenseId, 'object_path': objectPath},
            onConflict: 'expense_id');
      });

  Future<void> removeReceiptMetadata(String tripId, String expenseId) =>
      _guard(() async {
        final visible = await getExpenseById(tripId, expenseId);
        if (visible != null) {
          await client
              .from('expense_receipts')
              .delete()
              .eq('expense_id', expenseId);
        }
      });

  @override
  Future<void> deleteExpense(String tripId, String expenseId) =>
      _guard(() async {
        final receipt = await getReceipt(tripId, expenseId);
        if (receipt != null) await receipts.deleteReceipt(receipt.imagePath);
        await client
            .from('expenses')
            .delete()
            .eq('trip_id', tripId)
            .eq('id', expenseId);
      });

  @override
  Future<Map<String, double>> calculateNetExpenseBalances(String tripId) =>
      _guard(() async {
        final expenses = await getExpensesForTrip(tripId);
        final result = <String, double>{};
        for (final expense in expenses) {
          result[expense.paidByUserId] =
              (result[expense.paidByUserId] ?? 0) + expense.baseAmount;
          for (final participant
              in await getParticipants(tripId, expense.expenseId!)) {
            result[participant.userId] =
                (result[participant.userId] ?? 0) - participant.shareAmount;
          }
        }
        return result;
      });

  Map<String, Object?> _rpc(Expense e, List<ExpenseParticipant> participants) =>
      {
        'p_trip_id': e.tripId,
        'p_paid_by_user_id': e.paidByUserId,
        'p_category_id': e.categoryId,
        'p_title': e.title,
        'p_original_amount': e.originalAmount,
        'p_currency_code': e.currencyCode,
        'p_exchange_rate': e.exchangeRate,
        'p_base_amount': e.baseAmount,
        'p_expense_date': _date(e.expenseDate),
        'p_notes': e.notes,
        'p_participants': [
          for (final p in participants)
            {
              'user_id': p.userId,
              'share_amount': p.shareAmount,
              'share_percentage': p.sharePercentage
            }
        ],
      };

  Expense _expense(Map<String, dynamic> r) => Expense(
      expenseId: r['id'] as String,
      tripId: r['trip_id'] as String,
      paidByUserId: r['paid_by_user_id'] as String,
      categoryId: r['category_id'] as int,
      title: r['title'] as String,
      originalAmount: (r['original_amount'] as num).toDouble(),
      currencyCode: r['currency_code'] as String,
      exchangeRate: (r['exchange_rate'] as num).toDouble(),
      baseAmount: (r['base_amount'] as num).toDouble(),
      expenseDate: DateTime.parse(r['expense_date'] as String),
      notes: r['notes'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String));
  ExpenseParticipant _participant(Map<String, dynamic> r) => ExpenseParticipant(
      expenseId: r['expense_id'] as String,
      userId: r['user_id'] as String,
      shareAmount: (r['share_amount'] as num).toDouble(),
      sharePercentage: (r['share_percentage'] as num?)?.toDouble());
  ExpenseReceipt _receipt(Map<String, dynamic> r) => ExpenseReceipt(
      receiptId: r['id'] as String,
      expenseId: r['expense_id'] as String,
      imagePath: r['object_path'] as String,
      uploadedAt: DateTime.parse(r['uploaded_at'] as String));
  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      groupExpenseFailure(error);
    }
  }
}
