class Expense {
  const Expense({
    this.expenseId,
    required this.tripId,
    required this.paidByUserId,
    required this.categoryId,
    required this.title,
    required this.originalAmount,
    required this.currencyCode,
    required this.exchangeRate,
    required this.baseAmount,
    required this.expenseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? expenseId;
  final String tripId;
  final String paidByUserId;
  final int categoryId;
  final String title;
  final double originalAmount;
  final String currencyCode;
  final double exchangeRate;
  final double baseAmount;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense copyWith({
    String? expenseId,
    String? tripId,
    String? paidByUserId,
    int? categoryId,
    String? title,
    double? originalAmount,
    String? currencyCode,
    double? exchangeRate,
    double? baseAmount,
    DateTime? expenseDate,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Expense(
        expenseId: expenseId ?? this.expenseId,
        tripId: tripId ?? this.tripId,
        paidByUserId: paidByUserId ?? this.paidByUserId,
        categoryId: categoryId ?? this.categoryId,
        title: title ?? this.title,
        originalAmount: originalAmount ?? this.originalAmount,
        currencyCode: currencyCode ?? this.currencyCode,
        exchangeRate: exchangeRate ?? this.exchangeRate,
        baseAmount: baseAmount ?? this.baseAmount,
        expenseDate: expenseDate ?? this.expenseDate,
        notes: clearNotes ? null : notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (expenseId != null) 'expense_id': expenseId,
        'trip_id': tripId,
        'paid_by_user_id': paidByUserId,
        'category_id': categoryId,
        'title': title,
        'original_amount': originalAmount,
        'currency_code': currencyCode,
        'exchange_rate': exchangeRate,
        'base_amount': baseAmount,
        'expense_date': expenseDate.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        expenseId: map['expense_id']!.toString(),
        tripId: map['trip_id']!.toString(),
        paidByUserId: map['paid_by_user_id']!.toString(),
        categoryId: map['category_id']! as int,
        title: map['title']! as String,
        originalAmount: (map['original_amount']! as num).toDouble(),
        currencyCode: map['currency_code']! as String,
        exchangeRate: (map['exchange_rate']! as num).toDouble(),
        baseAmount: (map['base_amount']! as num).toDouble(),
        expenseDate: DateTime.parse(map['expense_date']! as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );
}
