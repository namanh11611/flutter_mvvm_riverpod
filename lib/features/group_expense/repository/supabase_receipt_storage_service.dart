import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'group_expense_repository_exception.dart';
import 'receipt_file_service.dart';
import 'receipt_storage_service.dart';

class SupabaseReceiptStorageService
    implements ReceiptStorageService, ReceiptFileService {
  SupabaseReceiptStorageService(this.client);
  final SupabaseClient client;
  static const bucket = 'group-expense-receipts';
  static const _uuid = Uuid();

  @override
  Future<String> persistReceipt(String sourcePath) async => sourcePath;

  @override
  Future<String> uploadExpenseReceipt(
          {required String tripId,
          required String expenseId,
          required String sourcePath}) =>
      _upload(
          expenseObjectPath(
            tripId: tripId,
            expenseId: expenseId,
            receiptId: _uuid.v4(),
            extension: _extension(sourcePath),
          ),
          sourcePath);

  @override
  Future<String> uploadSettlementReceipt(
          {required String tripId,
          required String settlementId,
          required String sourcePath}) =>
      _upload(
          settlementObjectPath(
            tripId: tripId,
            settlementId: settlementId,
            receiptId: _uuid.v4(),
            extension: _extension(sourcePath),
          ),
          sourcePath);

  static String expenseObjectPath(
          {required String tripId,
          required String expenseId,
          required String receiptId,
          required String extension}) =>
      'trips/$tripId/expenses/$expenseId/$receiptId$extension';

  static String settlementObjectPath(
          {required String tripId,
          required String settlementId,
          required String receiptId,
          required String extension}) =>
      'trips/$tripId/settlements/$settlementId/$receiptId$extension';

  Future<String> _upload(String objectPath, String sourcePath) async {
    try {
      await client.storage.from(bucket).upload(objectPath, File(sourcePath));
      return objectPath;
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  @override
  Future<void> deleteReceipt(String objectPath) async {
    if (!objectPath.startsWith('trips/')) return;
    try {
      await client.storage.from(bucket).remove([objectPath]);
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  @override
  Future<String> createSignedUrl(String objectPath) async {
    try {
      return await client.storage.from(bucket).createSignedUrl(objectPath, 600);
    } catch (error) {
      groupExpenseFailure(error);
    }
  }

  String _extension(String sourcePath) {
    final value = path.extension(sourcePath).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(value) ? value : '.jpg';
  }
}
