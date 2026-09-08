import 'money_utils.dart';
import 'settlement.dart';
import 'settlement_suggestion.dart';

class BalanceReconciliationException implements Exception {
  const BalanceReconciliationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BalanceCalculator {
  BalanceCalculator._();

  static Map<String, double> applyCompletedSettlements({
    required Map<String, double> expenseBalances,
    required List<Settlement> settlements,
  }) {
    final cents = {
      for (final entry in expenseBalances.entries)
        entry.key: MoneyUtils.toCents(entry.value),
    };
    for (final settlement in settlements) {
      if (settlement.status != SettlementStatus.completed) continue;
      final amount = MoneyUtils.toCents(settlement.amount);
      cents[settlement.payerId] = (cents[settlement.payerId] ?? 0) + amount;
      cents[settlement.payeeId] = (cents[settlement.payeeId] ?? 0) - amount;
    }
    return {
      for (final entry in cents.entries)
        entry.key: MoneyUtils.fromCents(entry.value),
    };
  }

  static List<SettlementSuggestion> suggestions(
    Map<String, double> balances, {
    int toleranceCents = 1,
  }) {
    final creditors = <_BalanceEntry>[];
    final debtors = <_BalanceEntry>[];
    for (final entry in balances.entries) {
      final cents = MoneyUtils.toCents(entry.value);
      if (cents > 0) creditors.add(_BalanceEntry(entry.key, cents));
      if (cents < 0) debtors.add(_BalanceEntry(entry.key, -cents));
    }
    creditors.sort((a, b) => a.userId.compareTo(b.userId));
    debtors.sort((a, b) => a.userId.compareTo(b.userId));
    final creditTotal = creditors.fold<int>(0, (sum, item) => sum + item.cents);
    final debtTotal = debtors.fold<int>(0, (sum, item) => sum + item.cents);
    final difference = creditTotal - debtTotal;
    if (difference.abs() > toleranceCents) {
      throw const BalanceReconciliationException(
        'Creditor and debtor balances do not reconcile',
      );
    }
    // A one-cent input discrepancy can occur when external balances have
    // already been rounded. Absorb it into the final deterministic entry.
    if (difference > 0 && creditors.isNotEmpty) {
      creditors.last.cents -= difference;
    } else if (difference < 0 && debtors.isNotEmpty) {
      debtors.last.cents += difference;
    }

    final result = <SettlementSuggestion>[];
    var debtorIndex = 0;
    var creditorIndex = 0;
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount =
          debtor.cents < creditor.cents ? debtor.cents : creditor.cents;
      if (amount > 0) {
        result.add(SettlementSuggestion(
          payerId: debtor.userId,
          payeeId: creditor.userId,
          amount: MoneyUtils.fromCents(amount),
        ));
      }
      debtor.cents -= amount;
      creditor.cents -= amount;
      if (debtor.cents == 0) debtorIndex++;
      if (creditor.cents == 0) creditorIndex++;
    }
    return result;
  }
}

class _BalanceEntry {
  _BalanceEntry(this.userId, this.cents);
  final String userId;
  int cents;
}
