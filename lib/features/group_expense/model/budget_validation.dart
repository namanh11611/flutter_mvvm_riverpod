import 'expense_constants.dart';

class BudgetValidation {
  BudgetValidation._();

  static String? name(String value) {
    if (value.trim().isEmpty) return 'Budget name is required';
    return null;
  }

  static String? amount(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Enter a budget amount greater than zero';
    }
    return null;
  }

  static String? currency(String value) {
    if (value.trim().isEmpty) return 'Base currency is required';
    if (!ExpenseConstants.supportedCurrencies.contains(value)) {
      return 'Select a supported currency';
    }
    return null;
  }
}
