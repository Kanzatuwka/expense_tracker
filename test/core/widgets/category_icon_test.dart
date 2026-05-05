import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iconDataForCategory', () {
    test('liefert das Icon für bekannte Namen', () {
      expect(iconDataForCategory('restaurant'), Icons.restaurant_outlined);
      expect(
        iconDataForCategory('directions_car'),
        Icons.directions_car_outlined,
      );
      expect(iconDataForCategory('favorite'), Icons.favorite_outline);
      expect(iconDataForCategory('movie'), Icons.movie_outlined);
      expect(iconDataForCategory('receipt'), Icons.receipt_outlined);
    });

    test('liefert das Fallback-Icon für unbekannte Namen', () {
      expect(iconDataForCategory('unknown_category'), kFallbackCategoryIcon);
      expect(iconDataForCategory(''), kFallbackCategoryIcon);
    });

    test('liefert das Fallback-Icon für null', () {
      expect(iconDataForCategory(null), kFallbackCategoryIcon);
    });

    test(
      'enthält Einträge für alle Standardkategorien aus dem Seed',
      () {
        // Die im CategoryRepository definierten Standard-Icons müssen alle
        // in der Mapping-Tabelle vorhanden sein, sonst zeigt die UI das
        // Fallback-Icon für eine Standardkategorie.
        const seedIcons = [
          'restaurant',
          'directions_car',
          'favorite',
          'movie',
          'receipt',
        ];
        for (final icon in seedIcons) {
          expect(
            kCategoryIcons.containsKey(icon),
            isTrue,
            reason: 'Mapping fehlt für Standardkategorie-Icon "$icon"',
          );
        }
      },
    );
  });
}
