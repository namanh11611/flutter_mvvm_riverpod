import 'dart:io';

import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement_receipt.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_database_schema.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/group_expense_providers.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/local_trip_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/local_traveller_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/receipt_file_service.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_budget_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_expense_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/repository/sqlite_settlement_repository.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/settlement_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/balance_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late ProviderContainer container;

  ProviderContainer createContainer({
    required String currentUserId,
    ReceiptFileService? receiptFiles,
  }) => ProviderContainer(
    overrides: [
      authenticatedUserIdProvider.overrideWithValue(currentUserId),
      expenseRepositoryProvider.overrideWith(
        (ref) async => SqliteExpenseRepository(database),
      ),
      settlementRepositoryProvider.overrideWith(
        (ref) async => SqliteSettlementRepository(database),
      ),
      travellerRepositoryProvider.overrideWith(
        (ref) async => LocalTravellerRepository(database),
      ),
      tripRepositoryProvider.overrideWith(
        (ref) async => LocalTripRepository(database),
      ),
      budgetRepositoryProvider.overrideWith(
        (ref) async => SqliteBudgetRepository(database),
      ),
      receiptFileServiceProvider.overrideWith(
        (ref) => receiptFiles ?? _FakeReceiptFiles(),
      ),
    ],
  );

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await GroupExpenseDatabaseSchema.createAndSeed(database);
    container = createContainer(currentUserId: '2');
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test(
    'payer submission stays pending and reserves outstanding debt',
    () async {
      final provider = settlementViewModelProvider('1');
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      final initial = await container.read(provider.future);
      expect(initial.outstandingFor('2', '1'), 143.25);

      final saved = await container
          .read(provider.notifier)
          .createSettlement(
            payerId: '2',
            payeeId: '1',
            amount: '43.25',
            paymentMethod: 'DuitNow',
            settlementDate: DateTime(2025, 7, 29),
            selectedReceiptPath: '/picker/payment.jpg',
          );

      final state = container.read(provider).value!;
      expect(saved, isTrue);
      expect(
        state.settlements.any(
          (item) =>
              item.amount == 43.25 && item.status == SettlementStatus.pending,
        ),
        isTrue,
      );
      expect(state.suggestions.first.amount, 143.25);
      expect(state.outstandingFor('2', '1'), 100);
      expect(
        state.receipts.values.any(
          (item) => item.imagePath == '/stored/payment.jpg',
        ),
        isTrue,
      );
    },
  );

  test('rejects an amount above the live outstanding debt', () async {
    final provider = settlementViewModelProvider('1');
    final subscription = container.listen(provider, (_, __) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    final saved = await container
        .read(provider.notifier)
        .createSettlement(
          payerId: '2',
          payeeId: '1',
          amount: '143.26',
          paymentMethod: 'Cash',
          settlementDate: DateTime(2025, 7, 29),
        );
    expect(saved, isFalse);
    expect(
      container.read(provider).value!.errorMessage,
      'Settlement amount cannot exceed the outstanding debt',
    );
  });

  test(
    'only payee confirmation completes payment and updates balances',
    () async {
      final payerProvider = settlementViewModelProvider('1');
      final payerSubscription = container.listen(payerProvider, (_, __) {});
      addTearDown(payerSubscription.close);
      await container.read(payerProvider.future);
      expect(
        await container
            .read(payerProvider.notifier)
            .createSettlement(
              payerId: '2',
              payeeId: '1',
              amount: '43.25',
              paymentMethod: 'DuitNow',
              settlementDate: DateTime(2025, 7, 29),
            ),
        isTrue,
      );
      final settlementId = container
          .read(payerProvider)
          .value!
          .settlements
          .firstWhere((item) => item.status == SettlementStatus.pending)
          .settlementId!;

      expect(
        await container
            .read(payerProvider.notifier)
            .confirmPaymentReceived(settlementId),
        isFalse,
      );

      final payeeContainer = createContainer(currentUserId: '1');
      addTearDown(payeeContainer.dispose);
      final payeeProvider = settlementViewModelProvider('1');
      final payeeSubscription = payeeContainer.listen(
        payeeProvider,
        (_, __) {},
      );
      addTearDown(payeeSubscription.close);
      await payeeContainer.read(payeeProvider.future);
      final balanceProvider = balanceViewModelProvider('1');
      final balanceSubscription = payeeContainer.listen(
        balanceProvider,
        (_, __) {},
      );
      addTearDown(balanceSubscription.close);
      final balanceBefore = await payeeContainer.read(balanceProvider.future);
      expect(balanceBefore.owedToYou, 286.50);
      expect(balanceBefore.youOwe, 0);

      expect(
        await payeeContainer
            .read(payeeProvider.notifier)
            .confirmPaymentReceived(settlementId),
        isTrue,
      );
      final state = payeeContainer.read(payeeProvider).value!;
      expect(
        state.settlements
            .firstWhere((item) => item.settlementId == settlementId)
            .status,
        SettlementStatus.completed,
      );
      expect(state.suggestions.first.amount, 100);
      final balanceAfter = await payeeContainer.read(balanceProvider.future);
      expect(balanceAfter.owedToYou, 243.25);
      expect(balanceAfter.youOwe, 0);
    },
  );

  test('a user cannot submit a settlement for another payer', () async {
    final provider = settlementViewModelProvider('1');
    final subscription = container.listen(provider, (_, __) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    final saved = await container
        .read(provider.notifier)
        .createSettlement(
          payerId: '3',
          payeeId: '1',
          amount: '10',
          paymentMethod: 'Cash',
          settlementDate: DateTime(2025, 7, 29),
        );

    expect(saved, isFalse);
    expect(
      container.read(provider).value!.errorMessage,
      'Only the payer can submit this settlement',
    );
  });

  test('rejects unsupported payment methods before persistence', () async {
    final provider = settlementViewModelProvider('1');
    final subscription = container.listen(provider, (_, __) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    final saved = await container
        .read(provider.notifier)
        .createSettlement(
          payerId: '2',
          payeeId: '1',
          amount: '10',
          paymentMethod: 'Cryptocurrency',
          settlementDate: DateTime(2025, 7, 29),
        );

    expect(saved, isFalse);
    expect(
      container.read(provider).value!.errorMessage,
      'Select a supported payment method',
    );
  });

  test(
    'local receipt cleanup failure does not undo database deletion',
    () async {
      final repository = SqliteSettlementRepository(database);
      final settlementId = await repository.createSettlement(
        Settlement(
          tripId: '1',
          payerId: '2',
          payeeId: '1',
          amount: 10,
          paymentMethod: 'Cash',
          settlementDate: DateTime(2025, 7, 29),
          status: SettlementStatus.pending,
          createdAt: DateTime(2025, 7, 29),
        ),
        receipt: SettlementReceipt(
          settlementId: '0',
          imagePath: '/stored/unremovable.jpg',
          uploadedAt: DateTime(2025, 7, 29),
        ),
      );
      container.dispose();
      container = createContainer(
        currentUserId: '2',
        receiptFiles: _ThrowingReceiptFiles(),
      );
      final provider = settlementViewModelProvider('1');
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      await container.read(provider.future);

      final deleted = await container
          .read(provider.notifier)
          .deleteSettlement(settlementId);

      expect(deleted, isTrue);
      expect(
        (await repository.getSettlementsForTrip(
          '1',
        )).any((item) => item.settlementId == settlementId),
        isFalse,
      );
    },
  );
}

class _FakeReceiptFiles implements ReceiptFileService {
  @override
  Future<void> deleteReceipt(String path) async {}

  @override
  Future<String> persistReceipt(String sourcePath) async =>
      '/stored/payment.jpg';
}

class _ThrowingReceiptFiles extends _FakeReceiptFiles {
  @override
  Future<void> deleteReceipt(String path) => throw const FileSystemException();
}
