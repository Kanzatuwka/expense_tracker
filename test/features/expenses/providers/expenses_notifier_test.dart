import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_expense_repository.dart';

ProviderContainer _buildContainer({
  required InMemoryAuthRepository auth,
  required InMemoryExpenseRepository expenses,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      expenseRepositoryProvider.overrideWithValue(expenses),
    ],
  );
}

void main() {
  group('ExpensesNotifier.addExpense', () {
    test(
      'leitet die userId aus AuthRepository an das ExpenseRepository weiter',
      () async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'user_42'),
        );
        final expenses = InMemoryExpenseRepository();

        final container = _buildContainer(auth: auth, expenses: expenses);
        addTearDown(container.dispose);
        addTearDown(auth.dispose);
        addTearDown(expenses.dispose);

        await container
            .read(expensesNotifierProvider.notifier)
            .addExpense(
              amount: 12.50,
              categoryId: 'cat_1',
              date: DateTime(2026, 4, 15),
              note: 'Test',
            );

        final list = await expenses.watchByUser('user_42').first;
        expect(list, hasLength(1));
        expect(list.first.userId, 'user_42');
        expect(list.first.amount, 12.50);
        expect(list.first.categoryId, 'cat_1');
        expect(list.first.note, 'Test');
      },
    );

    test('macht nichts, wenn niemand angemeldet ist', () async {
      final auth = InMemoryAuthRepository(); // initialUser = null
      final expenses = InMemoryExpenseRepository();

      final container = _buildContainer(auth: auth, expenses: expenses);
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(expenses.dispose);

      await container
          .read(expensesNotifierProvider.notifier)
          .addExpense(
            amount: 10.0,
            categoryId: 'c',
            date: DateTime(2026, 1, 1),
            note: '',
          );

      expect(await expenses.watchByUser('any').first, isEmpty);
    });
  });

  group('ExpensesNotifier.updateExpense / deleteExpense', () {
    test('updateExpense ruft das Repository ohne Auth-Check auf', () async {
      // Kein User notwendig — Authorisierung passiert serverseitig via Security Rules.
      final auth = InMemoryAuthRepository();
      final expenses = InMemoryExpenseRepository();

      final container = _buildContainer(auth: auth, expenses: expenses);
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(expenses.dispose);

      // Vorhandene Ausgabe seeden
      await expenses.create(
        userId: 'u',
        amount: 10.0,
        categoryId: 'c',
        date: DateTime(2026, 1, 1),
        note: '',
      );
      final initial = (await expenses.watchByUser('u').first).single;

      await container
          .read(expensesNotifierProvider.notifier)
          .updateExpense(
            id: initial.id,
            amount: 99.0,
            categoryId: 'new',
            date: DateTime(2026, 12, 31),
            note: 'updated',
          );

      final updated = (await expenses.watchByUser('u').first).single;
      expect(updated.amount, 99.0);
      expect(updated.categoryId, 'new');
      expect(updated.note, 'updated');
    });

    test('deleteExpense ruft das Repository auf', () async {
      final auth = InMemoryAuthRepository();
      final expenses = InMemoryExpenseRepository();

      final container = _buildContainer(auth: auth, expenses: expenses);
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(expenses.dispose);

      await expenses.create(
        userId: 'u',
        amount: 10.0,
        categoryId: 'c',
        date: DateTime(2026, 1, 1),
        note: '',
      );
      final initial = (await expenses.watchByUser('u').first).single;

      await container
          .read(expensesNotifierProvider.notifier)
          .deleteExpense(initial.id);

      expect(await expenses.watchByUser('u').first, isEmpty);
    });
  });
}
