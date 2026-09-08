import 'package:flutter_mvvm_riverpod/features/group_expense/model/balance_calculator.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BalanceCalculator', () {
    test('RM580 equal split gives the required expense balances', () {
      const balances = {'1': 435.0, '2': -145.0, '3': -145.0, '4': -145.0};
      expect(balances['1'], 435);
      expect(balances.values.fold<double>(0, (a, b) => a + b), 0);
    });

    test('combines multiple expense balances without losing cents', () {
      const first = {'1': 435.0, '2': -145.0, '3': -145.0, '4': -145.0};
      const second = {'1': -25.0, '2': 75.0, '3': -25.0, '4': -25.0};
      final combined = {
        for (final userId in first.keys)
          userId: first[userId]! + second[userId]!,
      };
      expect(combined, {'1': 410, '2': -70, '3': -170, '4': -170});
      expect(combined.values.fold<double>(0, (a, b) => a + b), 0);
    });

    test('completed settlement increases payer and decreases payee', () {
      final result = BalanceCalculator.applyCompletedSettlements(
        expenseBalances: const {'1': 435, '2': -145, '3': -145, '4': -145},
        settlements: [
          _settlement(
            payerId: '2',
            payeeId: '1',
            amount: 100,
            status: SettlementStatus.completed,
          ),
        ],
      );
      expect(result, {'1': 335, '2': -45, '3': -145, '4': -145});
    });

    test('ignores pending and rejected settlements', () {
      final result = BalanceCalculator.applyCompletedSettlements(
        expenseBalances: const {'1': 50, '2': -50},
        settlements: [
          _settlement(
            payerId: '2',
            payeeId: '1',
            amount: 25,
            status: SettlementStatus.pending,
          ),
          _settlement(
            payerId: '2',
            payeeId: '1',
            amount: 25,
            status: SettlementStatus.rejected,
          ),
        ],
      );
      expect(result, {'1': 50, '2': -50});
    });

    test('generates deterministic requested settlement suggestions', () {
      final result = BalanceCalculator.suggestions(const {
        '1': 286.50,
        '2': -143.25,
        '3': -143.25,
        '4': 0,
      });
      expect(result, hasLength(2));
      expect((result[0].payerId, result[0].payeeId, result[0].amount),
          ('2', '1', 143.25));
      expect((result[1].payerId, result[1].payeeId, result[1].amount),
          ('3', '1', 143.25));
    });

    test('fully settled travellers generate no suggestions', () {
      expect(BalanceCalculator.suggestions(const {'1': 0, '2': 0}), isEmpty);
    });

    test('absorbs a one-cent rounding difference deterministically', () {
      final result = BalanceCalculator.suggestions(
        const {'1': 10, '2': -5, '3': -4.99},
      );
      expect(result.map((item) => item.amount), [5, 4.99]);
    });

    test('rejects balances outside reconciliation tolerance', () {
      expect(
        () => BalanceCalculator.suggestions(const {'1': 10, '2': -9.98}),
        throwsA(isA<BalanceReconciliationException>()),
      );
    });
  });
}

Settlement _settlement({
  required String payerId,
  required String payeeId,
  required double amount,
  required SettlementStatus status,
}) =>
    Settlement(
      tripId: '1',
      payerId: payerId,
      payeeId: payeeId,
      amount: amount,
      paymentMethod: 'Cash',
      settlementDate: DateTime(2025),
      status: status,
      createdAt: DateTime(2025),
    );
