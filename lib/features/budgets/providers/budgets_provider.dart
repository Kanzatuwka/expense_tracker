import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/budgets/data/budget_repository.dart';
import 'package:expense_tracker/features/budgets/data/firestore_budget_repository.dart';
import 'package:expense_tracker/features/budgets/models/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return FirestoreBudgetRepository();
});

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(budgetRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repository.watchBudgets(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

class BudgetsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> setBudget(Budget budget) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;
    await ref.read(budgetRepositoryProvider).setBudget(userId, budget);
  }

  Future<void> deleteBudget(String categoryId) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;
    await ref.read(budgetRepositoryProvider).deleteBudget(userId, categoryId);
  }
}

final budgetsNotifierProvider = NotifierProvider<BudgetsNotifier, void>(() {
  return BudgetsNotifier();
});
