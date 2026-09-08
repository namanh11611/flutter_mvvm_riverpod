class ExpenseParticipant {
  const ExpenseParticipant({
    required this.expenseId,
    required this.userId,
    required this.shareAmount,
    this.sharePercentage,
  });

  final String expenseId;
  final String userId;
  final double shareAmount;
  final double? sharePercentage;

  Map<String, Object?> toMap() => {
        'expense_id': expenseId,
        'user_id': userId,
        'share_amount': shareAmount,
        'share_percentage': sharePercentage,
      };

  factory ExpenseParticipant.fromMap(Map<String, Object?> map) =>
      ExpenseParticipant(
        expenseId: map['expense_id']!.toString(),
        userId: map['user_id']!.toString(),
        shareAmount: (map['share_amount']! as num).toDouble(),
        sharePercentage: (map['share_percentage'] as num?)?.toDouble(),
      );
}
