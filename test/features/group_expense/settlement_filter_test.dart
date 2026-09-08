import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settlements = [
    _settlement('1', '2', SettlementStatus.completed),
    _settlement('2', '1', SettlementStatus.pending),
    _settlement('3', '1', SettlementStatus.rejected),
  ];
  const names = {'1': 'Ahmad Faiz', '2': 'Sarah Lim', '3': 'Ravi Kumar'};

  test('filters settlements by every supported status', () {
    for (final filter in SettlementFilter.values) {
      final result = SettlementFilterHelper.apply(
        settlements: settlements,
        filter: filter,
        query: '',
        travellerName: (id) => names[id]!,
      );
      expect(result, hasLength(filter == SettlementFilter.all ? 3 : 1));
    }
  });

  test('searches both payer and payee names case-insensitively', () {
    final result = SettlementFilterHelper.apply(
      settlements: settlements,
      filter: SettlementFilter.all,
      query: 'rAvI',
      travellerName: (id) => names[id]!,
    );
    expect(result, hasLength(1));
    expect(result.single.payerId, '3');
  });
}

Settlement _settlement(
        String payerId, String payeeId, SettlementStatus status) =>
    Settlement(
      tripId: '1',
      payerId: payerId,
      payeeId: payeeId,
      amount: 10,
      paymentMethod: 'Cash',
      settlementDate: DateTime(2025),
      status: status,
      createdAt: DateTime(2025),
    );
