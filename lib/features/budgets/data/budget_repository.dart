import 'package:expense_tracker/features/budgets/models/budget.dart';

abstract class BudgetRepository {
  Stream<List<Budget>> watchBudgets(String userId);
  Future<void> setBudget(String userId, Budget budget);
  Future<void> deleteBudget(String userId, String categoryId);
}
