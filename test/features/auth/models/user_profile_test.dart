import 'package:expense_tracker/features/auth/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.fromMap', () {
    test('parst eine vollständige Map', () {
      final created = DateTime(2026, 4, 15);
      final profile = UserProfile.fromMap({
        'subscriptionStatus': 'premium',
        'preferredLanguage': 'en',
        'preferredTheme': 'dark',
        'createdAt': created,
      }, 'user_1');

      expect(profile.userId, 'user_1');
      expect(profile.subscriptionStatus, 'premium');
      expect(profile.preferredLanguage, 'en');
      expect(profile.preferredTheme, 'dark');
      expect(profile.createdAt, created);
    });

    test('liefert sichere Defaults für fehlende Felder', () {
      final profile = UserProfile.fromMap({
        'createdAt': DateTime(2026, 1, 1),
      }, 'user_1');

      expect(profile.subscriptionStatus, 'free');
      expect(profile.preferredLanguage, 'de');
      expect(profile.preferredTheme, 'system');
    });
  });

  group('UserProfile.copyWith', () {
    test('überschreibt nur angegebene Felder', () {
      final original = UserProfile(
        userId: 'u',
        subscriptionStatus: 'free',
        preferredLanguage: 'de',
        preferredTheme: 'system',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(preferredTheme: 'dark');

      expect(updated.preferredTheme, 'dark');
      // Andere Felder unverändert
      expect(updated.userId, 'u');
      expect(updated.subscriptionStatus, 'free');
      expect(updated.preferredLanguage, 'de');
      expect(updated.createdAt, DateTime(2026, 1, 1));
    });
  });

  group('Round-Trip', () {
    test('toMap → fromMap erhält alle Felder', () {
      final original = UserProfile(
        userId: 'u',
        subscriptionStatus: 'premium',
        preferredLanguage: 'uk',
        preferredTheme: 'light',
        createdAt: DateTime(2026, 6, 1),
      );

      final restored = UserProfile.fromMap(original.toMap(), original.userId);

      expect(restored.userId, original.userId);
      expect(restored.subscriptionStatus, original.subscriptionStatus);
      expect(restored.preferredLanguage, original.preferredLanguage);
      expect(restored.preferredTheme, original.preferredTheme);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
