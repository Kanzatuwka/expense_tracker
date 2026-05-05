import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/screens/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_category_repository.dart';

Widget _buildApp({
  required InMemoryAuthRepository auth,
  required InMemoryCategoryRepository categories,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      categoryRepositoryProvider.overrideWithValue(categories),
    ],
    child: const MaterialApp(home: CategoriesScreen()),
  );
}

void main() {
  group('CategoriesScreen', () {
    testWidgets('zeigt Empty State wenn keine Kategorien existieren', (
      tester,
    ) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
      await tester.pumpAndSettle();

      expect(find.text('Keine Kategorien vorhanden'), findsOneWidget);
    });

    testWidgets(
      'gruppiert Standard- und benutzerdefinierte Kategorien',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u'),
        );
        final categories = InMemoryCategoryRepository();
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);

        await categories.initDefaults('u');
        await categories.create(userId: 'u', name: 'Hobby', icon: 'school');

        await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
        await tester.pumpAndSettle();

        expect(find.text('Standardkategorien'), findsOneWidget);
        expect(find.text('Eigene Kategorien'), findsOneWidget);
        expect(find.text('Essen'), findsOneWidget); // Standard
        expect(find.text('Hobby'), findsOneWidget); // Custom
      },
    );

    testWidgets(
      'Lösch-Button erscheint nur für benutzerdefinierte Kategorien',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u'),
        );
        final categories = InMemoryCategoryRepository();
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);

        await categories.initDefaults('u'); // 5 Standardkategorien
        await categories.create(userId: 'u', name: 'Hobby', icon: 'school');

        await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
        await tester.pumpAndSettle();

        // Insgesamt 6 Kategorien, aber nur 1 Lösch-Button (für 'Hobby')
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Lösch-Button öffnet Dialog und entfernt bei Bestätigung',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u'),
        );
        final categories = InMemoryCategoryRepository();
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);

        await categories.create(userId: 'u', name: 'Hobby', icon: 'school');

        await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Kategorie löschen?'), findsOneWidget);

        // FilledButton im Dialog → 'Löschen'
        await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
        await tester.pumpAndSettle();

        expect(find.text('Hobby'), findsNothing);
        expect(await categories.watchByUser('u').first, isEmpty);
      },
    );

    testWidgets('Abbrechen im Lösch-Dialog behält die Kategorie', (
      tester,
    ) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await categories.create(userId: 'u', name: 'Hobby', icon: 'school');

      await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.text('Hobby'), findsOneWidget);
      expect(await categories.watchByUser('u').first, hasLength(1));
    });
  });
}
