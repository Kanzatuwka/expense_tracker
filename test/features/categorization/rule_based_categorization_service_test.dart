import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categorization/rule_based_categorization_service.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      icon: 'category',
      isCustom: false,
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    );

final _categories = [
  _cat('id_essen', 'Essen'),
  _cat('id_transport', 'Transport'),
  _cat('id_gesundheit', 'Gesundheit'),
  _cat('id_freizeit', 'Freizeit'),
  _cat('id_sonstiges', 'Sonstiges'),
];

void main() {
  late RuleBasedCategorizationService service;

  setUp(() => service = RuleBasedCategorizationService());

  group('RuleBasedCategorizationService', () {
    group('Deutsch', () {
      test('restaurant → Essen', () {
        expect(service.suggestCategoryId('restaurant', _categories), 'id_essen');
      });

      test('Taxi → Transport (case-insensitive)', () {
        expect(service.suggestCategoryId('Taxi', _categories), 'id_transport');
      });

      test('Apotheke → Gesundheit', () {
        expect(
          service.suggestCategoryId('Apotheke', _categories),
          'id_gesundheit',
        );
      });

      test('Kino → Freizeit', () {
        expect(service.suggestCategoryId('Kino', _categories), 'id_freizeit');
      });
    });

    group('Englisch', () {
      test('grocery → Essen', () {
        expect(
          service.suggestCategoryId('grocery shopping', _categories),
          'id_essen',
        );
      });

      test('hospital → Gesundheit', () {
        expect(
          service.suggestCategoryId('hospital', _categories),
          'id_gesundheit',
        );
      });

      test('gym → Freizeit', () {
        expect(service.suggestCategoryId('gym session', _categories), 'id_freizeit');
      });
    });

    group('Ukrainisch', () {
      test('ресторан → Essen', () {
        expect(
          service.suggestCategoryId('ресторан', _categories),
          'id_essen',
        );
      });

      test('маршрутка → Transport', () {
        expect(
          service.suggestCategoryId('маршрутка', _categories),
          'id_transport',
        );
      });

      test('аптека → Gesundheit', () {
        expect(
          service.suggestCategoryId('аптека', _categories),
          'id_gesundheit',
        );
      });

      test('кіно → Freizeit', () {
        expect(service.suggestCategoryId('кіно', _categories), 'id_freizeit');
      });
    });

    group('Grenzfälle', () {
      test('leerer String → null', () {
        expect(service.suggestCategoryId('', _categories), isNull);
      });

      test('nur Leerzeichen → null', () {
        expect(service.suggestCategoryId('   ', _categories), isNull);
      });

      test('kein Keyword → null', () {
        expect(service.suggestCategoryId('xyzzy', _categories), isNull);
      });

      test('Keyword erkannt wenn Category-Liste leer → null', () {
        expect(service.suggestCategoryId('restaurant', []), isNull);
      });

      test('Keyword im Satz erkannt', () {
        expect(
          service.suggestCategoryId('ich war im Supermarkt', _categories),
          'id_essen',
        );
      });

      test('GROSSBUCHSTABEN → match (case-insensitive)', () {
        expect(
          service.suggestCategoryId('РЕСТОРАН', _categories),
          'id_essen',
        );
      });
    });
  });
}
