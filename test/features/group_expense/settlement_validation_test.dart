import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? validate({
    String? payerId = '2',
    String? payeeId = '1',
    String amount = '50',
    double outstanding = 100,
  }) =>
      SettlementValidation.validate(
        payerId: payerId,
        payeeId: payeeId,
        amount: amount,
        outstandingAmount: outstanding,
        paymentMethod: 'DuitNow',
        settlementDate: DateTime(2025),
      );

  test('accepts a valid settlement within outstanding debt', () {
    expect(validate(), isNull);
  });

  test('payer cannot equal payee', () {
    expect(validate(payerId: '1', payeeId: '1'),
        'Payer and payee must be different');
  });

  test('rejects zero and negative amounts', () {
    expect(validate(amount: '0'), isNotNull);
    expect(validate(amount: '-10'), isNotNull);
  });

  test('rejects amount above known outstanding debt', () {
    expect(validate(amount: '100.01'),
        'Settlement amount cannot exceed the outstanding debt');
  });
}
