import 'package:expense_tracker/features/budgets/models/budget.dart';

abstract class BudgetRepository {
  Stream<List<Budget>> watchBudgets(String userId);
  Future<void> setBudget(String userId, Budget budget);
  Future<void> deleteBudget(String userId, String categoryId);

  /// Returns the budget limits that were in effect during [year]/[month].
  /// Path: users/{uid}/budgetMonths/{YYYY-MM} → {budgets: {categoryId: amount}}
  /// Returns an empty map if no snapshot exists for that month.
  Future<Map<String, double>> getMonthlySnapshot(
    String userId,
    int year,
    int month,
  );
}
