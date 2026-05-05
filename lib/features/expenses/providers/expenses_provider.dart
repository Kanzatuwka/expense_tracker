import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/expenses/data/firestore_expense_repository.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider für das ExpenseRepository.
/// In Tests via `overrideWithValue(InMemoryExpenseRepository())` ersetzbar.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FirestoreExpenseRepository();
});

/// StreamProvider: hört auf Änderungen der Ausgaben in Echtzeit.
/// Reagiert automatisch auf An- und Abmeldungen via [authStateProvider].
final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(expenseRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repository.watchByUser(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

/// Notifier: kapselt Schreib-, Bearbeitungs- und Löschoperationen.
/// Auth-Kontext kommt aus [AuthRepository] — keine direkte Firebase-Abhängigkeit.
class ExpensesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  }) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;

    await ref
        .read(expenseRepositoryProvider)
        .create(
          userId: userId,
          amount: amount,
          categoryId: categoryId,
          date: date,
          note: note,
        );
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  }) async {
    await ref
        .read(expenseRepositoryProvider)
        .update(
          id: id,
          amount: amount,
          categoryId: categoryId,
          date: date,
          note: note,
        );
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).delete(id);
  }
}

final expensesNotifierProvider = NotifierProvider<ExpensesNotifier, void>(() {
  return ExpensesNotifier();
});
