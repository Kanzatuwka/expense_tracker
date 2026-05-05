import 'package:expense_tracker/features/categories/data/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_category_repository.dart';

void main() {
  late InMemoryCategoryRepository repo;

  setUp(() {
    repo = InMemoryCategoryRepository();
  });

  tearDown(() async {
    await repo.dispose();
  });

  group('watchByUser', () {
    test('isoliert Kategorien pro Benutzer', () async {
      await repo.create(userId: 'a', name: 'A1', icon: 'i');
      await repo.create(userId: 'b', name: 'B1', icon: 'i');

      final aList = await repo.watchByUser('a').first;
      final bList = await repo.watchByUser('b').first;

      expect(aList.map((c) => c.name), ['A1']);
      expect(bList.map((c) => c.name), ['B1']);
    });

    test('Standardkategorien stehen vor benutzerdefinierten', () async {
      await repo.initDefaults('u');
      await repo.create(userId: 'u', name: 'Custom', icon: 'palette');

      final list = await repo.watchByUser('u').first;

      // Alle isDefault: true müssen vor isDefault: false stehen
      final firstCustomIndex = list.indexWhere((c) => !c.isDefault);
      final lastDefaultIndex = list.lastIndexWhere((c) => c.isDefault);
      expect(firstCustomIndex, greaterThan(lastDefaultIndex));
    });
  });

  group('initDefaults', () {
    test('legt alle Seed-Kategorien an', () async {
      await repo.initDefaults('u');

      final list = await repo.watchByUser('u').first;
      expect(list, hasLength(defaultCategoriesSeed.length));
      expect(
        list.map((c) => c.name).toSet(),
        defaultCategoriesSeed.map((c) => c['name']).toSet(),
      );
      expect(list.every((c) => c.isDefault && !c.isCustom), isTrue);
    });

    test('ist idempotent — legt nicht doppelt an', () async {
      await repo.initDefaults('u');
      await repo.initDefaults('u');

      final list = await repo.watchByUser('u').first;
      expect(list, hasLength(defaultCategoriesSeed.length));
    });

    test(
      'lässt benutzerdefinierte Kategorien anderer Benutzer unberührt',
      () async {
        await repo.create(userId: 'other', name: 'X', icon: 'i');
        await repo.initDefaults('u');

        expect(
          await repo.watchByUser('other').first,
          hasLength(1),
        );
        expect(
          await repo.watchByUser('u').first,
          hasLength(defaultCategoriesSeed.length),
        );
      },
    );
  });

  group('create', () {
    test('erstellt eine benutzerdefinierte Kategorie', () async {
      await repo.create(userId: 'u', name: 'Hobby', icon: 'palette');

      final list = await repo.watchByUser('u').first;
      expect(list, hasLength(1));
      expect(list.first.name, 'Hobby');
      expect(list.first.icon, 'palette');
      expect(list.first.isCustom, isTrue);
      expect(list.first.isDefault, isFalse);
    });
  });

  group('delete', () {
    test('entfernt die Kategorie', () async {
      await repo.create(userId: 'u', name: 'Tmp', icon: 'i');
      final created = (await repo.watchByUser('u').first).single;

      await repo.delete(userId: 'u', categoryId: created.id);

      expect(await repo.watchByUser('u').first, isEmpty);
    });

    test('löscht keine Kategorie eines anderen Benutzers', () async {
      await repo.create(userId: 'a', name: 'A1', icon: 'i');
      final aCategory = (await repo.watchByUser('a').first).single;

      // userId stimmt nicht überein → no-op
      await repo.delete(userId: 'b', categoryId: aCategory.id);

      expect(await repo.watchByUser('a').first, hasLength(1));
    });
  });
}
