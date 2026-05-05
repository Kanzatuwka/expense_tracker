import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category.fromMap', () {
    test('parst eine vollständige Map korrekt', () {
      final created = DateTime(2026, 1, 1);

      final category = Category.fromMap({
        'name': 'Essen',
        'icon': 'restaurant',
        'isCustom': false,
        'isDefault': true,
        'createdAt': created,
      }, 'cat_food');

      expect(category.id, 'cat_food');
      expect(category.name, 'Essen');
      expect(category.icon, 'restaurant');
      expect(category.isCustom, isFalse);
      expect(category.isDefault, isTrue);
      expect(category.createdAt, created);
    });

    test('parst eine benutzerdefinierte Kategorie', () {
      final category = Category.fromMap({
        'name': 'Hobby',
        'icon': 'palette',
        'isCustom': true,
        'isDefault': false,
        'createdAt': DateTime(2026, 5, 1),
      }, 'cat_custom');

      expect(category.isCustom, isTrue);
      expect(category.isDefault, isFalse);
    });

    test('wirft, wenn ein Pflichtfeld fehlt', () {
      // Anders als Expense gibt es bei Category keine Backward Compatibility —
      // Kategorien sind eine v2-Funktion mit klarem Schema. Strict by design.
      expect(
        () => Category.fromMap({
          'name': 'Essen',
          // 'icon' fehlt
          'isCustom': false,
          'isDefault': true,
          'createdAt': DateTime.now(),
        }, 'cat_1'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Category.toMap', () {
    test('Round-Trip toMap → fromMap erhält alle Felder', () {
      final original = Category(
        id: 'cat_1',
        name: 'Transport',
        icon: 'directions_car',
        isCustom: false,
        isDefault: true,
        createdAt: DateTime(2026, 3, 15),
      );

      final restored = Category.fromMap(original.toMap(), original.id);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.isCustom, original.isCustom);
      expect(restored.isDefault, original.isDefault);
      expect(restored.createdAt, original.createdAt);
    });

    test('id wird nicht serialisiert', () {
      final category = Category(
        id: 'cat_1',
        name: 'X',
        icon: 'y',
        isCustom: false,
        isDefault: false,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(category.toMap().containsKey('id'), isFalse);
    });
  });
}
