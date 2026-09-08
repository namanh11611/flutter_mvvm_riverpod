class ExpenseReceipt {
  const ExpenseReceipt({
    this.receiptId,
    required this.expenseId,
    required this.imagePath,
    required this.uploadedAt,
  });

  final String? receiptId;
  final String expenseId;
  final String imagePath;
  final DateTime uploadedAt;

  Map<String, Object?> toMap() => {
        if (receiptId != null) 'receipt_id': receiptId,
        'expense_id': expenseId,
        'image_path': imagePath,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  factory ExpenseReceipt.fromMap(Map<String, Object?> map) => ExpenseReceipt(
        receiptId: map['receipt_id']!.toString(),
        expenseId: map['expense_id']!.toString(),
        imagePath: map['image_path']! as String,
        uploadedAt: DateTime.parse(map['uploaded_at']! as String),
      );
}
