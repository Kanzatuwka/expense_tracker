import 'package:expense_tracker/features/auth/models/auth_exception.dart';
import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_category_repository.dart';
import '../../../fakes/in_memory_user_profile_repository.dart';

ProviderContainer _buildContainer({
  required InMemoryAuthRepository auth,
  required InMemoryUserProfileRepository profile,
  required InMemoryCategoryRepository categories,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      userProfileRepositoryProvider.overrideWithValue(profile),
      categoryRepositoryProvider.overrideWithValue(categories),
    ],
  );
}

void main() {
  group('AuthNotifier.signInWithGoogle', () {
    test(
      'erstellt Profil und seedt Standardkategorien beim ersten Login',
      () async {
        final auth = InMemoryAuthRepository();
        final profile = InMemoryUserProfileRepository();
        final categories = InMemoryCategoryRepository();

        final container = _buildContainer(
          auth: auth,
          profile: profile,
          categories: categories,
        );
        addTearDown(container.dispose);
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);

        await container.read(authProvider.notifier).signInWithGoogle();

        // Profil wurde angelegt
        expect(profile.exists('test_user'), isTrue);
        // Standardkategorien wurden für diesen Benutzer geseedet
        final list = await categories.watchByUser('test_user').first;
        expect(list, isNotEmpty);
        expect(list.every((c) => c.isDefault), isTrue);
      },
    );

    test(
      'überspringt Profil-Erstellung und Seed bei wiederkehrendem Benutzer',
      () async {
        final auth = InMemoryAuthRepository();
        final profile = InMemoryUserProfileRepository(
          existingUsers: {'test_user'},
        );
        final categories = InMemoryCategoryRepository();

        final container = _buildContainer(
          auth: auth,
          profile: profile,
          categories: categories,
        );
        addTearDown(container.dispose);
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);

        await container.read(authProvider.notifier).signInWithGoogle();

        // createIfMissing wurde aufgerufen, hat aber false zurückgegeben
        expect(profile.callCounts['test_user'], 1);
        // Keine Seed-Kategorien angelegt
        final list = await categories.watchByUser('test_user').first;
        expect(list, isEmpty);
      },
    );

    test('macht nichts, wenn der Benutzer den Dialog abbricht', () async {
      // signInResult = null simuliert Cancel
      final auth = InMemoryAuthRepository(signInResult: null);
      final profile = InMemoryUserProfileRepository();
      final categories = InMemoryCategoryRepository();

      final container = _buildContainer(
        auth: auth,
        profile: profile,
        categories: categories,
      );
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await container.read(authProvider.notifier).signInWithGoogle();

      expect(profile.callCounts, isEmpty);
      expect(await categories.watchByUser('any').first, isEmpty);
    });

    test('propagiert AuthException ohne Profile-Aufruf', () async {
      final auth = InMemoryAuthRepository(
        signInError: const AuthException('boom', code: 'invalid-credential'),
      );
      final profile = InMemoryUserProfileRepository();
      final categories = InMemoryCategoryRepository();

      final container = _buildContainer(
        auth: auth,
        profile: profile,
        categories: categories,
      );
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await expectLater(
        () => container.read(authProvider.notifier).signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
      expect(profile.callCounts, isEmpty);
    });
  });

  group('AuthNotifier.signOut', () {
    test('delegiert an AuthRepository', () async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final profile = InMemoryUserProfileRepository();
      final categories = InMemoryCategoryRepository();

      final container = _buildContainer(
        auth: auth,
        profile: profile,
        categories: categories,
      );
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      expect(auth.currentUser, isNotNull);
      await container.read(authProvider.notifier).signOut();
      expect(auth.currentUser, isNull);
    });
  });
}
