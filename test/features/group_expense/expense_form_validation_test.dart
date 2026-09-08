import 'package:flutter_mvvm_riverpod/features/group_expense/model/expense_form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseFormValidation', () {
    test('requires a title', () {
      expect(ExpenseFormValidation.title('  '), isNotNull);
      expect(ExpenseFormValidation.title('Hotel Stay'), isNull);
    });

    test('requires a positive amount', () {
      expect(ExpenseFormValidation.amount(''), isNotNull);
      expect(ExpenseFormValidation.amount('0'), isNotNull);
      expect(ExpenseFormValidation.amount('-5'), isNotNull);
      expect(ExpenseFormValidation.amount('580.00'), isNull);
    });

    test('requires payer and category selections', () {
      expect(
        ExpenseFormValidation.requiredSelection(null, 'Payer'),
        'Payer is required',
      );
      expect(ExpenseFormValidation.requiredSelection(1, 'Category'), isNull);
    });

    test('accepts only supported currencies', () {
      const supported = ['MYR', 'USD'];
      expect(
        ExpenseFormValidation.currency('', supported),
        'Currency is required',
      );
      expect(
        ExpenseFormValidation.currency('GBP', supported),
        'Select a supported currency',
      );
      expect(ExpenseFormValidation.currency('MYR', supported), isNull);
    });
  });
}
