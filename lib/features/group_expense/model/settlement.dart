enum SettlementStatus { pending, completed, rejected }

class Settlement {
  const Settlement({
    this.settlementId,
    required this.tripId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    required this.paymentMethod,
    required this.settlementDate,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  final String? settlementId;
  final String tripId;
  final String payerId;
  final String payeeId;
  final double amount;
  final String paymentMethod;
  final DateTime settlementDate;
  final SettlementStatus status;
  final String? notes;
  final DateTime createdAt;

  Settlement copyWith({
    String? settlementId,
    String? tripId,
    String? payerId,
    String? payeeId,
    double? amount,
    String? paymentMethod,
    DateTime? settlementDate,
    SettlementStatus? status,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) =>
      Settlement(
        settlementId: settlementId ?? this.settlementId,
        tripId: tripId ?? this.tripId,
        payerId: payerId ?? this.payerId,
        payeeId: payeeId ?? this.payeeId,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        settlementDate: settlementDate ?? this.settlementDate,
        status: status ?? this.status,
        notes: clearNotes ? null : notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        if (settlementId != null) 'settlement_id': settlementId,
        'trip_id': tripId,
        'payer_id': payerId,
        'payee_id': payeeId,
        'amount': amount,
        'payment_method': paymentMethod,
        'settlement_date': settlementDate.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Settlement.fromMap(Map<String, Object?> map) => Settlement(
        settlementId: map['settlement_id']!.toString(),
        tripId: map['trip_id']!.toString(),
        payerId: map['payer_id']!.toString(),
        payeeId: map['payee_id']!.toString(),
        amount: (map['amount']! as num).toDouble(),
        paymentMethod: map['payment_method']! as String,
        settlementDate: DateTime.parse(map['settlement_date']! as String),
        status: SettlementStatus.values.byName(map['status']! as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
      );
}
