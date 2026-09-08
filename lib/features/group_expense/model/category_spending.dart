class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.iconName,
    required this.amount,
    this.percentage = 0,
  });

  final int categoryId;
  final String categoryName;
  final String iconName;
  final double amount;
  final double percentage;

  CategorySpending copyWith({double? percentage}) => CategorySpending(
        categoryId: categoryId,
        categoryName: categoryName,
        iconName: iconName,
        amount: amount,
        percentage: percentage ?? this.percentage,
      );
}
