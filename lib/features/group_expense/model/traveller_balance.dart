enum TravellerBalanceStatus { needsPayment, pendingConfirmation, settled, owed }

class TravellerBalance {
  const TravellerBalance({
    required this.userId,
    required this.name,
    required this.initials,
    required this.netBalance,
    required this.status,
  });

  final String userId;
  final String name;
  final String initials;
  final double netBalance;
  final TravellerBalanceStatus status;

  bool get shouldReceive => netBalance > 0;
  bool get owes => netBalance < 0;
  bool get isSettled => netBalance == 0;
}
