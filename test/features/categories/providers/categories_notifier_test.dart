import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/data/category_repository.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_auth_repository.dart';
import '../../../fakes/in_memory_category_repository.dart';

ProviderContainer _buildContainer({
  required InMemoryAuthRepository auth,
  required InMemoryCategoryRepository categories,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      categoryRepositoryProvider.overrideWithValue(categories),
    ],
  );
}

void main() {
  group('CategoriesNotifier', () {
    test('initDefaultCategories seedt für den aktuellen Benutzer', () async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u_seed'),
      );
      final categories = InMemoryCategoryRepository();

      final container = _buildContainer(auth: auth, categories: categories);
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await container
          .read(categoriesNotifierProvider.notifier)
          .initDefaultCategories();

      final list = await categories.watchByUser('u_seed').first;
      expect(list, hasLength(defaultCategoriesSeed.length));
    });

    test('addCategory legt eine benutzerdefinierte Kategorie an', () async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();

      final container = _buildContainer(auth: auth, categories: categories);
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await container
          .read(categoriesNotifierProvider.notifier)
          .addCategory(name: 'Hobby', icon: 'palette');

      final list = await categories.watchByUser('u').first;
      expect(list, hasLength(1));
      expect(list.first.name, 'Hobby');
      expect(list.first.isCustom, isTrue);
    });

    test('deleteCategory entfernt die Kategorie', () async {
      final auth = InMemoryAuthRepository(
        initialUser: const AuthUser(uid: 'u'),
      );
      final categories = InMemoryCategoryRepository();

      final container = _buildContainer(auth: auth, categories: categories);
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(categories.dispose);

      await categories.create(userId: 'u', name: 'Tmp', icon: 'i');
      final created = (await categories.watchByUser('u').first).single;

      await container
          .read(categoriesNotifierProvider.notifier)
          .deleteCategory(created.id);

      expect(await categories.watchByUser('u').first, isEmpty);
    });

    test(
      'alle Operationen sind No-Ops ohne angemeldeten Benutzer',
      () async {
        final auth = InMemoryAuthRepository(); // niemand angemeldet
        final categories = InMemoryCategoryRepository();

        final container = _buildContainer(auth: auth, categories: categories);
        addTearDown(container.dispose);
        addTearDown(auth.dispose);
        addTearDown(categories.dispose);

        final notifier = container.read(categoriesNotifierProvider.notifier);
        await notifier.initDefaultCategories();
        await notifier.addCategory(name: 'X', icon: 'i');
        await notifier.deleteCategory('any');

        // Keine Seitenwirkung im Repository
        expect(await categories.watchByUser('any').first, isEmpty);
      },
    );
  });
}
