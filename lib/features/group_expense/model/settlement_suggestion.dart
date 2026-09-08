class SettlementSuggestion {
  const SettlementSuggestion({
    required this.payerId,
    required this.payeeId,
    required this.amount,
  });

  final String payerId;
  final String payeeId;
  final double amount;
}
