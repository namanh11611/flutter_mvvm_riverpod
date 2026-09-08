import 'expense_participant.dart';
import 'money_utils.dart';

enum ExpenseSplitMethod { equal, custom, percentage }

class ExpenseSplitException implements Exception {
  const ExpenseSplitException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ExpenseSplitCalculator {
  ExpenseSplitCalculator._();

  static List<ExpenseParticipant> equal({
    required String expenseId,
    required double baseAmount,
    required List<String> userIds,
  }) {
    if (userIds.isEmpty) {
      throw const ExpenseSplitException('Select at least one participant');
    }
    final totalCents = MoneyUtils.toCents(baseAmount);
    if (totalCents <= 0) {
      throw const ExpenseSplitException('Expense amount must be positive');
    }
    final centsPerPerson = totalCents ~/ userIds.length;
    final remainder = totalCents % userIds.length;
    return [
      for (var index = 0; index < userIds.length; index++)
        ExpenseParticipant(
          expenseId: expenseId,
          userId: userIds[index],
          shareAmount: MoneyUtils.fromCents(
            centsPerPerson + (index < remainder ? 1 : 0),
          ),
          sharePercentage: 100 / userIds.length,
        ),
    ];
  }

  static List<ExpenseParticipant> custom({
    required String expenseId,
    required double baseAmount,
    required Map<String, double> shares,
  }) {
    if (shares.isEmpty) {
      throw const ExpenseSplitException('Select at least one participant');
    }
    if (shares.values.any((share) => !share.isFinite || share < 0)) {
      throw const ExpenseSplitException('Custom shares cannot be negative');
    }
    final expected = MoneyUtils.toCents(baseAmount);
    final actual = shares.values.fold<int>(
      0,
      (total, share) => total + MoneyUtils.toCents(share),
    );
    if (actual != expected) {
      throw const ExpenseSplitException(
        'Custom shares must equal the expense amount',
      );
    }
    return shares.entries
        .map((entry) => ExpenseParticipant(
              expenseId: expenseId,
              userId: entry.key,
              shareAmount: MoneyUtils.roundMoney(entry.value),
            ))
        .toList(growable: false);
  }

  static List<ExpenseParticipant> percentage({
    required String expenseId,
    required double baseAmount,
    required Map<String, double> percentages,
  }) {
    if (percentages.isEmpty) {
      throw const ExpenseSplitException('Select at least one participant');
    }
    if (percentages.values
        .any((percentage) => !percentage.isFinite || percentage < 0)) {
      throw const ExpenseSplitException('Percentages cannot be negative');
    }
    final percentageTotal = percentages.values.fold<double>(0, (a, b) => a + b);
    if ((percentageTotal - 100).abs() > 0.0001) {
      throw const ExpenseSplitException('Percentages must total 100%');
    }
    final totalCents = MoneyUtils.toCents(baseAmount);
    final entries = percentages.entries.toList(growable: false);
    final allocations = <({int index, int cents, double remainder})>[
      for (var index = 0; index < entries.length; index++)
        (() {
          final exact = totalCents * entries[index].value / 100;
          final cents = exact.floor();
          return (index: index, cents: cents, remainder: exact - cents);
        })(),
    ];
    final centsByIndex = [for (final item in allocations) item.cents];
    final assignedCents =
        centsByIndex.fold<int>(0, (total, cents) => total + cents);
    final remaining = totalCents - assignedCents;
    final remainderOrder = [...allocations]..sort((left, right) {
        final order = right.remainder.compareTo(left.remainder);
        return order != 0 ? order : left.index.compareTo(right.index);
      });
    for (var index = 0; index < remaining; index++) {
      centsByIndex[remainderOrder[index % remainderOrder.length].index]++;
    }
    return [
      for (var index = 0; index < entries.length; index++)
        ExpenseParticipant(
          expenseId: expenseId,
          userId: entries[index].key,
          shareAmount: MoneyUtils.fromCents(centsByIndex[index]),
          sharePercentage: entries[index].value,
        ),
    ];
  }

  static void validateParticipants({
    required double baseAmount,
    required List<ExpenseParticipant> participants,
  }) {
    if (participants.isEmpty) {
      throw const ExpenseSplitException('Select at least one participant');
    }
    if (participants.any((participant) => participant.shareAmount < 0)) {
      throw const ExpenseSplitException(
          'Participant shares cannot be negative');
    }
    final total = participants.fold<int>(
      0,
      (sum, participant) => sum + MoneyUtils.toCents(participant.shareAmount),
    );
    if (total != MoneyUtils.toCents(baseAmount)) {
      throw const ExpenseSplitException(
        'Participant shares must equal the expense amount',
      );
    }
  }
}
