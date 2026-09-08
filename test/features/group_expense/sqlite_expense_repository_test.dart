import 'package:flutter_mvvm_riverpod/features/group_expense/model/expense.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/expense_participant.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/expense_receipt.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_database_schema.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late SqliteExpenseRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await GroupExpenseDatabaseSchema.createAndSeed(database);
    await database.delete('expenses');
    repository = SqliteExpenseRepository(database);
  });

  tearDown(() => database.close());

  test('creates expense, participants, and receipt atomically', () async {
    final expenseId = await repository.createExpense(
      expense: _expense(),
      participants: _participants('0'),
      receipt: ExpenseReceipt(
        expenseId: '0',
        imagePath: '/receipts/hotel.jpg',
        uploadedAt: DateTime(2025, 7, 20),
      ),
    );

    expect(await repository.getExpenseById('1', expenseId), isNotNull);
    expect(await repository.getParticipants('1', expenseId), hasLength(2));
    expect((await repository.getReceipt('1', expenseId))?.imagePath,
        '/receipts/hotel.jpg');
  });

  test('rolls back expense when participant persistence fails', () async {
    await expectLater(
      repository.createExpense(
        expense: _expense(title: 'Must rollback'),
        participants: const [
          ExpenseParticipant(
            expenseId: '0',
            userId: '999',
            shareAmount: 100,
          ),
        ],
      ),
      throwsA(anything),
    );
    final rows = await database.query(
      'expenses',
      where: 'title = ?',
      whereArgs: ['Must rollback'],
    );
    expect(rows, isEmpty);
  });

  test('updates participants and removes a receipt in one transaction',
      () async {
    final expenseId = await repository.createExpense(
      expense: _expense(),
      participants: _participants('0'),
      receipt: ExpenseReceipt(
        expenseId: '0',
        imagePath: '/receipts/old.jpg',
        uploadedAt: DateTime(2025),
      ),
    );
    await repository.updateExpense(
      expense: _expense(id: expenseId, amount: 120),
      participants: [
        ExpenseParticipant(
          expenseId: expenseId,
          userId: '1',
          shareAmount: 120,
        ),
      ],
      removeReceipt: true,
    );

    expect(await repository.getParticipants('1', expenseId), hasLength(1));
    expect(await repository.getReceipt('1', expenseId), isNull);
  });

  test('delete cascades and changes future budget totals', () async {
    final expenseId = await repository.createExpense(
      expense: _expense(),
      participants: _participants('0'),
      receipt: ExpenseReceipt(
        expenseId: '0',
        imagePath: '/receipts/hotel.jpg',
        uploadedAt: DateTime(2025),
      ),
    );
    expect(await spent(database), 100);

    await repository.deleteExpense('1', expenseId);

    expect(await repository.getParticipants('1', expenseId), isEmpty);
    expect(await repository.getReceipt('1', expenseId), isNull);
    expect(await spent(database), 0);
  });

  test('expense reads are scoped by both trip and expense UUID strings',
      () async {
    final expenseId = await repository.createExpense(
      expense: _expense(),
      participants: _participants('0'),
    );

    expect(await repository.getExpenseById('1', expenseId), isNotNull);
    expect(
        await repository.getExpenseById('different-trip', expenseId), isNull);
    expect(
      await repository.getParticipants('different-trip', expenseId),
      isEmpty,
    );
    expect(
      await repository.getReceipt('different-trip', expenseId),
      isNull,
    );
  });

  test('calculates net balances across multiple expenses dynamically',
      () async {
    final firstId = await repository.createExpense(
      expense: _expense(title: 'Hotel', amount: 580),
      participants: [
        for (var userId = 1; userId <= 4; userId++)
          ExpenseParticipant(
            expenseId: '0',
            userId: userId.toString(),
            shareAmount: 145,
          ),
      ],
    );
    expect(firstId, isNotEmpty);
    await repository.createExpense(
      expense: _expense(title: 'Dinner', amount: 100).copyWith(
        paidByUserId: '2',
        categoryId: 4,
      ),
      participants: [
        for (var userId = 1; userId <= 4; userId++)
          ExpenseParticipant(
            expenseId: '0',
            userId: userId.toString(),
            shareAmount: 25,
          ),
      ],
    );

    expect(await repository.calculateNetExpenseBalances('1'), {
      '1': 410,
      '2': -70,
      '3': -170,
      '4': -170,
    });
  });
}

Future<double> spent(Database database) async {
  final rows = await database.rawQuery(
    'SELECT COALESCE(SUM(base_amount), 0) AS total FROM expenses WHERE trip_id = 1',
  );
  return (rows.first['total']! as num).toDouble();
}

Expense _expense({String? id, String title = 'Hotel', double amount = 100}) {
  final date = DateTime(2025, 7, 20);
  return Expense(
    expenseId: id,
    tripId: '1',
    paidByUserId: '1',
    categoryId: 1,
    title: title,
    originalAmount: amount,
    currencyCode: 'MYR',
    exchangeRate: 1,
    baseAmount: amount,
    expenseDate: date,
    createdAt: date,
    updatedAt: date,
  );
}

List<ExpenseParticipant> _participants(String expenseId) => [
      ExpenseParticipant(
        expenseId: expenseId,
        userId: '1',
        shareAmount: 50,
      ),
      ExpenseParticipant(
        expenseId: expenseId,
        userId: '2',
        shareAmount: 50,
      ),
    ];
