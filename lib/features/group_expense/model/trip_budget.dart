class TripBudget {
  const TripBudget({
    this.budgetId,
    required this.tripId,
    required this.budgetName,
    required this.budgetAmount,
    required this.baseCurrency,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? budgetId;
  final String tripId;
  final String budgetName;
  final double budgetAmount;
  final String baseCurrency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripBudget copyWith({
    String? budgetId,
    String? tripId,
    String? budgetName,
    double? budgetAmount,
    String? baseCurrency,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TripBudget(
        budgetId: budgetId ?? this.budgetId,
        tripId: tripId ?? this.tripId,
        budgetName: budgetName ?? this.budgetName,
        budgetAmount: budgetAmount ?? this.budgetAmount,
        baseCurrency: baseCurrency ?? this.baseCurrency,
        notes: clearNotes ? null : notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (budgetId != null) 'budget_id': budgetId,
        'trip_id': tripId,
        'budget_name': budgetName,
        'budget_amount': budgetAmount,
        'base_currency': baseCurrency,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TripBudget.fromMap(Map<String, Object?> map) => TripBudget(
        budgetId: map['budget_id']!.toString(),
        tripId: map['trip_id']!.toString(),
        budgetName: map['budget_name']! as String,
        budgetAmount: (map['budget_amount']! as num).toDouble(),
        baseCurrency: map['base_currency']! as String,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );
}
