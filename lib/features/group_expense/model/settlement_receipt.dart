class SettlementReceipt {
  const SettlementReceipt({
    this.receiptId,
    required this.settlementId,
    required this.imagePath,
    required this.uploadedAt,
  });

  final String? receiptId;
  final String settlementId;
  final String imagePath;
  final DateTime uploadedAt;

  Map<String, Object?> toMap() => {
        if (receiptId != null) 'receipt_id': receiptId,
        'settlement_id': settlementId,
        'image_path': imagePath,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  factory SettlementReceipt.fromMap(Map<String, Object?> map) =>
      SettlementReceipt(
        receiptId: map['receipt_id']!.toString(),
        settlementId: map['settlement_id']!.toString(),
        imagePath: map['image_path']! as String,
        uploadedAt: DateTime.parse(map['uploaded_at']! as String),
      );
}
