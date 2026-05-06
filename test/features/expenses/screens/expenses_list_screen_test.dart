import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/features/expenses/screens/expenses_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_category_repository.dart';
import '../../../fakes/in_memory_expense_repository.dart';
import '../../../helpers/localized_app.dart';

void main() {
  group('ExpensesListScreen — Swipe-to-Delete', () {
    testWidgets(
      'Swipe öffnet Bestätigungsdialog und löscht bei Bestätigung',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u'),
        );
        final categories = InMemoryCategoryRepository();
        final expenses = InMemoryExpenseRepository();
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);
        addTearDown(expenses.dispose);

        await categories.create(userId: 'u', name: 'Essen', icon: 'restaurant');
        final categoryId = (await categories.watchByUser('u').first).single.id;

        expenses.seed([
          Expense(
            id: 'e1',
            amount: 12.50,
            categoryId: categoryId,
            date: DateTime(2026, 4, 15),
            note: 'Mittagessen',
            userId: 'u',
            createdAt: DateTime(2026, 4, 15, 12),
          ),
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              categoryRepositoryProvider.overrideWithValue(categories),
              expenseRepositoryProvider.overrideWithValue(expenses),
            ],
            child: localizedApp(const ExpensesListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mittagessen'), findsOneWidget);

        // Nach links wischen, um Löschen auszulösen
        await tester.drag(
          find.text('Mittagessen'),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        // Dialog bestätigen
        expect(find.text('Ausgabe löschen?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
        await tester.pumpAndSettle();

        // Ausgabe ist entfernt
        expect(find.text('Mittagessen'), findsNothing);
        expect(await expenses.watchByUser('u').first, isEmpty);
      },
    );

    testWidgets(
      'Abbrechen im Dialog behält die Ausgabe',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u'),
        );
        final categories = InMemoryCategoryRepository();
        final expenses = InMemoryExpenseRepository();
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);
        addTearDown(expenses.dispose);

        await categories.create(userId: 'u', name: 'Essen', icon: 'restaurant');
        final categoryId = (await categories.watchByUser('u').first).single.id;

        expenses.seed([
          Expense(
            id: 'e1',
            amount: 12.50,
            categoryId: categoryId,
            date: DateTime(2026, 4, 15),
            note: 'Mittagessen',
            userId: 'u',
            createdAt: DateTime(2026, 4, 15, 12),
          ),
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              categoryRepositoryProvider.overrideWithValue(categories),
              expenseRepositoryProvider.overrideWithValue(expenses),
            ],
            child: localizedApp(const ExpensesListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.text('Mittagessen'),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();

        // Ausgabe ist immer noch da
        expect(find.text('Mittagessen'), findsOneWidget);
        expect(await expenses.watchByUser('u').first, hasLength(1));
      },
    );
  });
}
