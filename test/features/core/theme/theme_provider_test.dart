import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/models/user_profile.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_user_profile_repository.dart';

UserProfile _profile({required String theme}) => UserProfile(
  userId: 'u',
  subscriptionStatus: 'free',
  preferredLanguage: 'de',
  preferredTheme: theme,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('parseThemeMode / themeModeToString', () {
    test('parst alle drei gültigen Werte', () {
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('dark'), ThemeMode.dark);
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('fällt auf system zurück bei unbekannten/null Werten', () {
      expect(parseThemeMode('unknown'), ThemeMode.system);
      expect(parseThemeMode(null), ThemeMode.system);
      expect(parseThemeMode(''), ThemeMode.system);
    });

    test('Round-Trip ThemeMode → String → ThemeMode', () {
      for (final mode in ThemeMode.values) {
        expect(parseThemeMode(themeModeToString(mode)), mode);
      }
    });
  });

  group('themeModeProvider', () {
    // userProfileProvider wird direkt überschrieben — wir testen nur,
    // dass themeModeProvider aus dem profile.preferredTheme den richtigen
    // ThemeMode ableitet, ohne den Auth/Repo-Stream-Ketten-Setup.
    test('liefert system bei null-Profil', () async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe damit der StreamProvider aktiv wird
      container.listen(userProfileProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('reflektiert preferredTheme aus dem Profil', () async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_profile(theme: 'dark')),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('liefert system bei unbekanntem preferredTheme-Wert', () async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_profile(theme: 'glow_in_the_dark')),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('ThemeModeNotifier.setThemeMode', () {
    test(
      'ruft updateTheme am UserProfileRepository mit aktuellem userId auf',
      () async {
        final auth = InMemoryAuthRepository(
          initialUser: const AuthUser(uid: 'u_42'),
        );
        final profile = InMemoryUserProfileRepository();
        await profile.createIfMissing('u_42');

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            userProfileRepositoryProvider.overrideWithValue(profile),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(auth.dispose);
        addTearDown(profile.dispose);

        await container
            .read(themeModeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        expect(profile.get('u_42')!.preferredTheme, 'dark');
      },
    );

    test('macht nichts, wenn niemand angemeldet ist', () async {
      final auth = InMemoryAuthRepository(); // niemand
      final profile = InMemoryUserProfileRepository();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(profile),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(profile.dispose);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(profile.exists('u'), isFalse);
    });
  });
}
