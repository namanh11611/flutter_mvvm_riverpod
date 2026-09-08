class ExpenseCategory {
  const ExpenseCategory({
    required this.categoryId,
    required this.name,
    required this.iconName,
  });

  final int categoryId;
  final String name;
  final String iconName;

  factory ExpenseCategory.fromMap(Map<String, Object?> map) => ExpenseCategory(
        categoryId: map['category_id']! as int,
        name: map['name']! as String,
        iconName: map['icon_name']! as String,
      );
}
