import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/screens/category_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_category_repository.dart';
import '../../../helpers/localized_app.dart';

Widget _buildApp({
  required InMemoryAuthRepository auth,
  required InMemoryCategoryRepository categories,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      categoryRepositoryProvider.overrideWithValue(categories),
    ],
    child: localizedApp(const CategoryCreateScreen()),
  );
}

// Standardviewport (800x600) ist zu klein — FilledButton liegt unter dem
// Icon-Picker am Ende des Formulars und wäre außerhalb des Viewports.
Future<void> _useTallViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('CategoryCreateScreen', () {
    testWidgets('Name-Validator wirft bei leerem Eingabefeld', (tester) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);
      await _useTallViewport(tester);

      await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
      await tester.pumpAndSettle();

      // Speichern ohne Eingabe
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte einen Namen eingeben'), findsOneWidget);
      // Nichts gespeichert
      expect(await categories.watchByUser('u').first, isEmpty);
    });

    testWidgets(
      'SnackBar wenn Name eingegeben aber kein Icon ausgewählt',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u'),
        );
        final categories = InMemoryCategoryRepository();
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);
        await _useTallViewport(tester);

        await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'Hobby');
        await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
        await tester.pump(); // SnackBar einblenden

        expect(find.text('Bitte ein Icon auswählen'), findsOneWidget);
        expect(await categories.watchByUser('u').first, isEmpty);
      },
    );

    testWidgets('legt Kategorie an und navigiert zurück bei vollständiger Eingabe', (
      tester,
    ) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);
      await _useTallViewport(tester);

      // Wir starten von einem Stub-Screen aus, damit der pop-Aufruf
      // funktioniert (sonst gibt's keinen Vorgänger im Navigator-Stack).
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            categoryRepositoryProvider.overrideWithValue(categories),
          ],
          child: localizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoryCreateScreen(),
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

      await tester.enterText(find.byType(TextFormField), 'Hobby');
      // Icon "school" auswählen
      await tester.tap(find.byKey(const ValueKey('icon_school')));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      // Pop zurück zum Open-Button
      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(CategoryCreateScreen), findsNothing);

      final saved = await categories.watchByUser('u').first;
      expect(saved, hasLength(1));
      expect(saved.first.name, 'Hobby');
      expect(saved.first.icon, 'school');
      expect(saved.first.isCustom, isTrue);
    });

    testWidgets('Validator: Name darf max. 30 Zeichen lang sein', (
      tester,
    ) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);
      await _useTallViewport(tester);

      await tester.pumpWidget(_buildApp(auth: auth, categories: categories));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'A' * 31);
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      expect(
        find.text('Name darf maximal 30 Zeichen lang sein'),
        findsOneWidget,
      );
      expect(await categories.watchByUser('u').first, isEmpty);
    });
  });
}
