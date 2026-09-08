import 'money_utils.dart';

class SettlementValidation {
  SettlementValidation._();

  static String? validate({
    required String? payerId,
    required String? payeeId,
    required String amount,
    required double outstandingAmount,
    required String paymentMethod,
    required DateTime? settlementDate,
  }) {
    if (payerId == null) return 'Payer is required';
    if (payeeId == null) return 'Payee is required';
    if (payerId == payeeId) return 'Payer and payee must be different';
    final parsedAmount = double.tryParse(amount.trim());
    if (parsedAmount == null ||
        !parsedAmount.isFinite ||
        MoneyUtils.toCents(parsedAmount) <= 0) {
      return 'Settlement amount must be greater than zero';
    }
    if (MoneyUtils.toCents(parsedAmount) >
        MoneyUtils.toCents(outstandingAmount)) {
      return 'Settlement amount cannot exceed the outstanding debt';
    }
    if (paymentMethod.trim().isEmpty) return 'Payment method is required';
    if (settlementDate == null) return 'Settlement date is required';
    return null;
  }
}
