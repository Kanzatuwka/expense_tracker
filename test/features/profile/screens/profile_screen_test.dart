import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';

Widget _buildApp({required InMemoryAuthRepository auth}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(auth)],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  group('ProfileScreen', () {
    testWidgets('zeigt displayName und email aus AuthUser', (tester) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(
          uid: 'u',
          email: 'test@example.com',
          displayName: 'Test User',
        ),
      );
      addTearDown(auth.dispose);

      await tester.pumpWidget(_buildApp(auth: auth));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets(
      'zeigt Initialen wenn photoUrl null ist',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u', displayName: 'Klaus'),
        );
        addTearDown(auth.dispose);

        await tester.pumpWidget(_buildApp(auth: auth));
        await tester.pumpAndSettle();

        // Erste Buchstabe von "Klaus"
        expect(find.text('K'), findsOneWidget);
      },
    );

    testWidgets('Fallback "Anonym" wenn displayName null', (tester) async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u', email: 'x@y.z'),
      );
      addTearDown(auth.dispose);

      await tester.pumpWidget(_buildApp(auth: auth));
      await tester.pumpAndSettle();

      expect(find.text('Anonym'), findsOneWidget);
    });

    testWidgets(
      'Klick auf Theme-Eintrag zeigt "Bald verfügbar" SnackBar',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u', email: 'x@y.z'),
        );
        addTearDown(auth.dispose);

        await tester.pumpWidget(_buildApp(auth: auth));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Theme'));
        await tester.pump(); // SnackBar einblenden

        expect(find.text('Bald verfügbar'), findsOneWidget);
      },
    );

    testWidgets(
      'Abmelden-Button öffnet Dialog und meldet bei Bestätigung ab',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u', email: 'x@y.z'),
        );
        addTearDown(auth.dispose);

        await tester.pumpWidget(_buildApp(auth: auth));
        await tester.pumpAndSettle();
        expect(auth.currentUser, isNotNull);

        // Auf Abmelden-Button tippen (OutlinedButton auf dem Screen)
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        // Dialog ist sichtbar
        expect(find.text('Abmelden?'), findsOneWidget);

        // Bestätigen — das ist der einzige FilledButton im Tree
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(auth.currentUser, isNull);
      },
    );

    testWidgets(
      'Abmelden-Button: Dialog kann abgebrochen werden ohne Sign-Out',
      (tester) async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u', email: 'x@y.z'),
        );
        addTearDown(auth.dispose);

        await tester.pumpWidget(_buildApp(auth: auth));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        // Auf Abbrechen tippen
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();

        // Benutzer ist immer noch angemeldet
        expect(auth.currentUser, isNotNull);
        expect(find.text('Abmelden?'), findsNothing);
      },
    );
  });
}
