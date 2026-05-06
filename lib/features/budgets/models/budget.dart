class Budget {
  final String categoryId;
  final double amount;

  const Budget({required this.categoryId, required this.amount});

  factory Budget.fromMap(Map<String, dynamic> map, String categoryId) {
    return Budget(
      categoryId: categoryId,
      amount: (map['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'amount': amount};
}
