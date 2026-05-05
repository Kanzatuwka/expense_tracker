import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/features/expenses/screens/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_category_repository.dart';
import '../../../fakes/in_memory_expense_repository.dart';

class _Fakes {
  final InMemoryAuthRepository auth;
  final InMemoryCategoryRepository categories;
  final InMemoryExpenseRepository expenses;
  _Fakes(this.auth, this.categories, this.expenses);
}

Future<_Fakes> _setupFakes({String userId = 'u'}) async {
  final auth = InMemoryAuthRepository(initialUser: AuthUser(uid: userId));
  final categories = InMemoryCategoryRepository();
  final expenses = InMemoryExpenseRepository();
  // Eine bekannte Kategorie für Dropdown-Auswahl
  await categories.create(userId: userId, name: 'Essen', icon: 'restaurant');
  return _Fakes(auth, categories, expenses);
}

Widget _buildApp(_Fakes fakes, {Expense? existing}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakes.auth),
      categoryRepositoryProvider.overrideWithValue(fakes.categories),
      expenseRepositoryProvider.overrideWithValue(fakes.expenses),
    ],
    child: MaterialApp(home: ExpenseFormScreen(existing: existing)),
  );
}

Future<void> _useTallViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('ExpenseFormScreen — create mode', () {
    testWidgets('Titel ist "Neue Ausgabe", Button "Speichern"', (tester) async {
      final fakes = await _setupFakes();
      addTearDown(fakes.auth.dispose);
      addTearDown(fakes.categories.dispose);
      addTearDown(fakes.expenses.dispose);
      await _useTallViewport(tester);

      await tester.pumpWidget(_buildApp(fakes));
      await tester.pumpAndSettle();

      expect(find.text('Neue Ausgabe'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Speichern'), findsOneWidget);
    });

    testWidgets('Validator: Betrag muss > 0 sein', (tester) async {
      final fakes = await _setupFakes();
      addTearDown(fakes.auth.dispose);
      addTearDown(fakes.categories.dispose);
      addTearDown(fakes.expenses.dispose);
      await _useTallViewport(tester);

      await tester.pumpWidget(_buildApp(fakes));
      await tester.pumpAndSettle();

      // Leerer Betrag
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Bitte Betrag eingeben'), findsOneWidget);

      // Negativer Betrag
      await tester.enterText(find.byType(TextFormField).first, '-5');
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Betrag muss größer als 0 sein'), findsOneWidget);

      // Repository ist unangetastet
      expect(await fakes.expenses.watchByUser('u').first, isEmpty);
    });

    testWidgets('SnackBar wenn Kategorie nicht ausgewählt', (tester) async {
      final fakes = await _setupFakes();
      addTearDown(fakes.auth.dispose);
      addTearDown(fakes.categories.dispose);
      addTearDown(fakes.expenses.dispose);
      await _useTallViewport(tester);

      await tester.pumpWidget(_buildApp(fakes));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '12.50');
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pump();

      expect(find.text('Bitte eine Kategorie auswählen'), findsOneWidget);
      expect(await fakes.expenses.watchByUser('u').first, isEmpty);
    });
  });

  group('ExpenseFormScreen — edit mode', () {
    testWidgets(
      'Pre-fill: Titel "Ausgabe bearbeiten", Button "Aktualisieren", Felder mit bestehenden Werten',
      (tester) async {
        final fakes = await _setupFakes();
        addTearDown(fakes.auth.dispose);
        addTearDown(fakes.categories.dispose);
        addTearDown(fakes.expenses.dispose);
        await _useTallViewport(tester);

        final categoryId = (await fakes.categories.watchByUser('u').first)
            .single
            .id;
        final existing = Expense(
          id: 'e1',
          amount: 42.50,
          categoryId: categoryId,
          date: DateTime(2026, 4, 15),
          note: 'Mittagessen',
          userId: 'u',
          createdAt: DateTime(2026, 4, 15, 12),
        );
        fakes.expenses.seed([existing]);

        await tester.pumpWidget(_buildApp(fakes, existing: existing));
        await tester.pumpAndSettle();

        expect(find.text('Ausgabe bearbeiten'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Aktualisieren'),
          findsOneWidget,
        );
        // Felder vorgeladen
        expect(find.text('42.5'), findsOneWidget); // Betrag
        expect(find.text('Mittagessen'), findsOneWidget); // Notiz
      },
    );

    testWidgets(
      'Speichern aktualisiert die bestehende Ausgabe (gleiche ID, neue Werte)',
      (tester) async {
        final fakes = await _setupFakes();
        addTearDown(fakes.auth.dispose);
        addTearDown(fakes.categories.dispose);
        addTearDown(fakes.expenses.dispose);
        await _useTallViewport(tester);

        final categoryId = (await fakes.categories.watchByUser('u').first)
            .single
            .id;
        final existing = Expense(
          id: 'e1',
          amount: 10.0,
          categoryId: categoryId,
          date: DateTime(2026, 4, 15),
          note: 'alt',
          userId: 'u',
          createdAt: DateTime(2026, 4, 15, 12),
        );
        fakes.expenses.seed([existing]);

        // Stub-Screen davor, damit pop einen Vorgänger hat
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakes.auth),
              categoryRepositoryProvider.overrideWithValue(fakes.categories),
              expenseRepositoryProvider.overrideWithValue(fakes.expenses),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpenseFormScreen(existing: existing),
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Betrag ändern
        await tester.enterText(find.byType(TextFormField).first, '99.99');
        // Notiz ändern (zweites TextFormField — die mehrzeilige Notiz)
        await tester.enterText(find.byType(TextFormField).last, 'neu');

        await tester.tap(find.widgetWithText(FilledButton, 'Aktualisieren'));
        await tester.pumpAndSettle();

        // Pop war erfolgreich
        expect(find.text('Open'), findsOneWidget);

        final list = await fakes.expenses.watchByUser('u').first;
        expect(list, hasLength(1));
        expect(list.first.id, 'e1'); // gleiche ID
        expect(list.first.amount, 99.99);
        expect(list.first.note, 'neu');
        // userId und createdAt unverändert (vom Repository garantiert)
        expect(list.first.userId, 'u');
        expect(list.first.createdAt, DateTime(2026, 4, 15, 12));
      },
    );
  });
}
