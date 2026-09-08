import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_repository_exception.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/supabase_receipt_storage_service.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/supabase_settlement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('expense receipt object path is trip and entity scoped', () {
    expect(
      SupabaseReceiptStorageService.expenseObjectPath(
        tripId: 'trip-uuid',
        expenseId: 'expense-uuid',
        receiptId: 'receipt-uuid',
        extension: '.jpg',
      ),
      'trips/trip-uuid/expenses/expense-uuid/receipt-uuid.jpg',
    );
  });

  test('settlement receipt object path is trip and entity scoped', () {
    expect(
      SupabaseReceiptStorageService.settlementObjectPath(
        tripId: 'trip-uuid',
        settlementId: 'settlement-uuid',
        receiptId: 'receipt-uuid',
        extension: '.png',
      ),
      'trips/trip-uuid/settlements/settlement-uuid/receipt-uuid.png',
    );
  });

  test('authorization database errors map without leaking raw SQL', () {
    expect(
      () => groupExpenseFailure(
        const PostgrestException(
            message: 'sensitive database detail', code: '42501'),
      ),
      throwsA(
        isA<GroupExpenseRepositoryException>()
            .having((error) => error.code, 'code', 'unauthorized')
            .having((error) => error.message, 'message',
                isNot(contains('sensitive'))),
      ),
    );
  });

  test('zero-row settlement delete is not reported as successful', () {
    expect(
      () => SupabaseSettlementRepository.requireDeletedSettlement(const []),
      throwsA(
        isA<GroupExpenseRepositoryException>().having(
          (error) => error.code,
          'code',
          'delete_failed',
        ),
      ),
    );
  });
}
