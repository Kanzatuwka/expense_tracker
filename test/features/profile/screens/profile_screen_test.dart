import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/models/user_profile.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_user_profile_repository.dart';
import '../../../helpers/localized_app.dart';

class _Setup {
  final InMemoryAuthRepository auth;
  final InMemoryUserProfileRepository profile;
  _Setup(this.auth, this.profile);
}

_Setup _setup({
  AuthUser? initialUser = const AuthUser(uid: 'u', email: 'x@y.z'),
  UserProfile? seededProfile,
}) {
  final auth = InMemoryAuthRepository(initialUser: initialUser);
  final profile = InMemoryUserProfileRepository();
  if (seededProfile != null) profile.seed(seededProfile);
  return _Setup(auth, profile);
}

Widget _buildApp(_Setup s) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(s.auth),
      userProfileRepositoryProvider.overrideWithValue(s.profile),
    ],
    child: localizedApp(const ProfileScreen()),
  );
}

void main() {
  group('ProfileScreen', () {
    testWidgets('zeigt displayName und email aus AuthUser', (tester) async {
      final s = _setup(
        initialUser: const AuthUser(
          uid: 'u',
          email: 'test@example.com',
          displayName: 'Test User',
        ),
      );
      addTearDown(s.auth.dispose);
      addTearDown(s.profile.dispose);

      await tester.pumpWidget(_buildApp(s));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('zeigt Initialen wenn photoUrl null ist', (tester) async {
      final s = _setup(
        initialUser: const AuthUser(uid: 'u', displayName: 'Klaus'),
      );
      addTearDown(s.auth.dispose);
      addTearDown(s.profile.dispose);

      await tester.pumpWidget(_buildApp(s));
      await tester.pumpAndSettle();

      expect(find.text('K'), findsOneWidget);
    });

    testWidgets('Fallback "Anonym" wenn displayName null', (tester) async {
      final s = _setup();
      addTearDown(s.auth.dispose);
      addTearDown(s.profile.dispose);

      await tester.pumpWidget(_buildApp(s));
      await tester.pumpAndSettle();

      expect(find.text('Anonym'), findsOneWidget);
    });

    testWidgets(
      'Abmelden-Button öffnet Dialog und meldet bei Bestätigung ab',
      (tester) async {
        final s = _setup();
        addTearDown(s.auth.dispose);
        addTearDown(s.profile.dispose);

        await tester.pumpWidget(_buildApp(s));
        await tester.pumpAndSettle();
        expect(s.auth.currentUser, isNotNull);

        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        expect(find.text('Abmelden?'), findsOneWidget);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(s.auth.currentUser, isNull);
      },
    );

    testWidgets(
      'Abmelden-Button: Dialog kann abgebrochen werden ohne Sign-Out',
      (tester) async {
        final s = _setup();
        addTearDown(s.auth.dispose);
        addTearDown(s.profile.dispose);

        await tester.pumpWidget(_buildApp(s));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();

        expect(s.auth.currentUser, isNotNull);
        expect(find.text('Abmelden?'), findsNothing);
      },
    );
  });

  group('ProfileScreen — Theme-Selector', () {
    testWidgets(
      'zeigt aktuellen Theme-Modus als trailing-Text',
      (tester) async {
        final s = _setup(
          seededProfile: UserProfile(
            userId: 'u',
            subscriptionStatus: 'free',
            preferredLanguage: 'de',
            preferredTheme: 'dark',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        addTearDown(s.auth.dispose);
        addTearDown(s.profile.dispose);

        await tester.pumpWidget(_buildApp(s));
        await tester.pumpAndSettle();

        // Trailing-Label "Dunkel" für preferredTheme: 'dark'
        expect(find.text('Dunkel'), findsOneWidget);
      },
    );

    testWidgets(
      'Klick auf Theme öffnet Dialog mit allen drei Modi',
      (tester) async {
        final s = _setup(
          seededProfile: UserProfile(
            userId: 'u',
            subscriptionStatus: 'free',
            preferredLanguage: 'de',
            preferredTheme: 'system',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        addTearDown(s.auth.dispose);
        addTearDown(s.profile.dispose);

        await tester.pumpWidget(_buildApp(s));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        expect(find.text('Theme auswählen'), findsOneWidget);
        expect(find.text('Hell'), findsOneWidget);
        expect(find.text('Dunkel'), findsOneWidget);
        expect(find.text('System'), findsAtLeast(1)); // trailing + dialog
      },
    );

    testWidgets(
      'Auswahl aktualisiert Profile und schließt Dialog',
      (tester) async {
        final s = _setup(
          seededProfile: UserProfile(
            userId: 'u',
            subscriptionStatus: 'free',
            preferredLanguage: 'de',
            preferredTheme: 'system',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        addTearDown(s.auth.dispose);
        addTearDown(s.profile.dispose);

        await tester.pumpWidget(_buildApp(s));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        // Dunkel auswählen
        await tester.tap(find.text('Dunkel'));
        await tester.pumpAndSettle();

        // Dialog ist zu, Profil aktualisiert
        expect(find.text('Theme auswählen'), findsNothing);
        expect(s.profile.get('u')!.preferredTheme, 'dark');
      },
    );
  });
}
