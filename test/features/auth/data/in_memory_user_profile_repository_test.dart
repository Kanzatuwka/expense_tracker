import 'package:expense_tracker/features/auth/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_user_profile_repository.dart';

void main() {
  late InMemoryUserProfileRepository repo;

  setUp(() {
    repo = InMemoryUserProfileRepository();
  });

  tearDown(() async {
    await repo.dispose();
  });

  group('createIfMissing', () {
    test('legt ein neues Profil mit Defaults an', () async {
      final wasNew = await repo.createIfMissing('u');

      expect(wasNew, isTrue);
      final profile = repo.get('u');
      expect(profile, isNotNull);
      expect(profile!.subscriptionStatus, 'free');
      expect(profile.preferredLanguage, 'de');
      expect(profile.preferredTheme, 'system');
    });

    test('liefert false bei wiederkehrendem Benutzer', () async {
      await repo.createIfMissing('u');
      final wasNew = await repo.createIfMissing('u');

      expect(wasNew, isFalse);
      expect(repo.callCounts['u'], 2);
    });
  });

  group('watchByUser', () {
    test('emittiert null bevor das Profil existiert', () async {
      final value = await repo.watchByUser('u').first;
      expect(value, isNull);
    });

    test('emittiert das Profil nach createIfMissing', () async {
      final emissions = repo.watchByUser('u').take(2).toList().timeout(
        const Duration(seconds: 2),
      );

      // Microtask-Tick für initiale Emission
      await Future<void>.delayed(Duration.zero);
      await repo.createIfMissing('u');

      final result = await emissions;
      expect(result.first, isNull);
      expect(result.last, isNotNull);
      expect(result.last!.preferredTheme, 'system');
    });
  });

  group('updateTheme', () {
    test('aktualisiert nur preferredTheme, behält andere Felder', () async {
      repo.seed(
        UserProfile(
          userId: 'u',
          subscriptionStatus: 'premium',
          preferredLanguage: 'en',
          preferredTheme: 'system',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await repo.updateTheme(userId: 'u', theme: 'dark');

      final profile = repo.get('u')!;
      expect(profile.preferredTheme, 'dark');
      expect(profile.subscriptionStatus, 'premium');
      expect(profile.preferredLanguage, 'en');
      expect(profile.createdAt, DateTime(2026, 1, 1));
    });

    test('ist No-Op bei nicht existierendem Profil', () async {
      await repo.updateTheme(userId: 'unknown', theme: 'dark');
      expect(repo.exists('unknown'), isFalse);
    });

    test('Stream emittiert das aktualisierte Profil', () async {
      await repo.createIfMissing('u');

      final emissions = repo.watchByUser('u').take(2).toList().timeout(
        const Duration(seconds: 2),
      );

      await Future<void>.delayed(Duration.zero);
      await repo.updateTheme(userId: 'u', theme: 'dark');

      final result = await emissions;
      expect(result.first!.preferredTheme, 'system');
      expect(result.last!.preferredTheme, 'dark');
    });
  });

  group('existingUsers constructor param', () {
    test('seedet die angegebenen userIds mit default-Profilen', () {
      final repo = InMemoryUserProfileRepository(
        existingUsers: {'a', 'b'},
      );
      addTearDown(repo.dispose);

      expect(repo.exists('a'), isTrue);
      expect(repo.exists('b'), isTrue);
      expect(repo.exists('c'), isFalse);
      expect(repo.get('a')!.preferredTheme, 'system');
    });
  });
}
