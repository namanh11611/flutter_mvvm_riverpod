class ExpenseFormValidation {
  ExpenseFormValidation._();

  static String? title(String value) =>
      value.trim().isEmpty ? 'Expense title is required' : null;

  static String? amount(String value) {
    final amount = double.tryParse(value.trim());
    return amount == null || !amount.isFinite || amount <= 0
        ? 'Enter an amount greater than zero'
        : null;
  }

  static String? requiredSelection(Object? value, String label) =>
      value == null ? '$label is required' : null;

  static String? currency(String value, Iterable<String> supported) {
    if (value.trim().isEmpty) return 'Currency is required';
    if (!supported.contains(value)) return 'Select a supported currency';
    return null;
  }
}
