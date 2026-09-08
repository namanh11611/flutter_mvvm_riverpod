import 'package:flutter_mvvm_riverpod/features/group_expense/model/balance_calculator.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement_receipt.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_database_schema.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_expense_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_settlement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late SqliteSettlementRepository repository;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await GroupExpenseDatabaseSchema.createAndSeed(database);
    repository = SqliteSettlementRepository(database);
  });
  tearDown(() => database.close());

  test('reads completed settlements for balance adjustments', () async {
    final completed = await repository.getCompletedSettlements('1');
    expect(completed, hasLength(3));
    expect(completed.every((item) => item.status.name == 'completed'), isTrue);
  });

  test('reads pending settlements separately for display status', () async {
    await database.insert('settlements', {
      'trip_id': 1,
      'payer_id': 2,
      'payee_id': 1,
      'amount': 10,
      'payment_method': 'Cash',
      'settlement_date': '2025-07-27T10:00:00.000',
      'status': 'pending',
      'created_at': '2025-07-27T10:00:00.000',
    });
    final pending = await repository.getPendingSettlements('1');
    expect(pending, hasLength(1));
    expect(pending.single.payerId, '2');
  });

  test('seeded expenses and completed settlements produce target balances',
      () async {
    final expenseBalances = await SqliteExpenseRepository(database)
        .calculateNetExpenseBalances('1');
    final completed = await repository.getCompletedSettlements('1');
    final net = BalanceCalculator.applyCompletedSettlements(
      expenseBalances: expenseBalances,
      settlements: completed,
    );
    expect(net, {'1': 286.50, '2': -143.25, '3': -143.25, '4': 0});
  });

  test('creates a valid settlement and receipt transactionally', () async {
    final id = await repository.createSettlement(
      _settlement(),
      receipt: SettlementReceipt(
        settlementId: '0',
        imagePath: '/receipts/payment.jpg',
        uploadedAt: DateTime(2025),
      ),
    );
    final records = await repository.getSettlementsForTrip('1');
    expect(records.any((item) => item.settlementId == id), isTrue);
    expect((await repository.getReceipt('1', id))?.imagePath,
        '/receipts/payment.jpg');
  });

  test('receipt can be replaced and removed', () async {
    final id = await repository.createSettlement(
      _settlement(),
      receipt: SettlementReceipt(
        settlementId: '0',
        imagePath: '/receipts/old.jpg',
        uploadedAt: DateTime(2025),
      ),
    );
    final settlement = (await repository.getSettlementsForTrip('1'))
        .firstWhere((item) => item.settlementId == id);
    await repository.updateSettlement(
      settlement,
      receipt: SettlementReceipt(
        settlementId: id,
        imagePath: '/receipts/new.jpg',
        uploadedAt: DateTime(2025),
      ),
    );
    expect(
        (await repository.getReceipt('1', id))?.imagePath, '/receipts/new.jpg');
    await repository.updateSettlement(settlement, removeReceipt: true);
    expect(await repository.getReceipt('1', id), isNull);
  });

  test('deleting settlement cascades to receipt', () async {
    final id = await repository.createSettlement(
      _settlement(),
      receipt: SettlementReceipt(
        settlementId: '0',
        imagePath: '/receipts/delete.jpg',
        uploadedAt: DateTime(2025),
      ),
    );
    await repository.deleteSettlement('1', id);
    expect(await repository.getReceipt('1', id), isNull);
  });
}

Settlement _settlement() => Settlement(
      tripId: '1',
      payerId: '2',
      payeeId: '1',
      amount: 20,
      paymentMethod: 'DuitNow',
      settlementDate: DateTime(2025, 7, 28),
      status: SettlementStatus.pending,
      createdAt: DateTime(2025, 7, 28),
    );
