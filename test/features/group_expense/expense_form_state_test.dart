import 'package:flutter_mvvm_riverpod/features/group_expense/model/traveller.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/state/expense_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new expense defaults payer to current user, not first traveller', () {
    const state = ExpenseFormState(
      tripId: 'trip',
      currentUserId: 'user-a',
      baseCurrency: 'MYR',
      travellers: [
        Traveller(userId: 'user-b', displayName: 'B'),
        Traveller(userId: 'user-a', displayName: 'A'),
      ],
    );

    expect(state.defaultPayerId, 'user-a');
  });

  test('new expense does not default to a non-member payer', () {
    const state = ExpenseFormState(
      tripId: 'trip',
      currentUserId: 'missing-user',
      baseCurrency: 'MYR',
      travellers: [
        Traveller(userId: 'user-b', displayName: 'B'),
      ],
    );

    expect(state.defaultPayerId, isNull);
  });
}
