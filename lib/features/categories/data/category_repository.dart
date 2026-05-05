import 'package:expense_tracker/features/categories/models/category.dart';

/// Abstraktion für den Datenzugriff auf Kategorien.
///
/// Kategorien werden in der Subkollektion `users/{userId}/categories` gespeichert.
abstract class CategoryRepository {
  /// Liefert alle Kategorien des Benutzers in Echtzeit.
  /// Standardkategorien (`isDefault: true`) erscheinen zuerst.
  Stream<List<Category>> watchByUser(String userId);

  /// Legt die Standardkategorien an, falls noch keine existieren.
  /// Idempotent — bei vorhandenen Kategorien passiert nichts.
  Future<void> initDefaults(String userId);

  /// Erstellt eine neue benutzerdefinierte Kategorie.
  Future<void> create({
    required String userId,
    required String name,
    required String icon,
  });

  /// Löscht eine Kategorie. Sollte nur für benutzerdefinierte Kategorien
  /// aufgerufen werden — Aufrufer ist für die Prüfung verantwortlich.
  Future<void> delete({required String userId, required String categoryId});
}

/// Standardkategorien die beim ersten Login angelegt werden.
/// Hier definiert (statt im Firestore-Repository), damit die Liste
/// auch ohne Firestore (z.B. im Test) zugänglich ist.
const defaultCategoriesSeed = [
  {'name': 'Essen', 'icon': 'restaurant', 'isCustom': false, 'isDefault': true},
  {
    'name': 'Transport',
    'icon': 'directions_car',
    'isCustom': false,
    'isDefault': true,
  },
  {
    'name': 'Gesundheit',
    'icon': 'favorite',
    'isCustom': false,
    'isDefault': true,
  },
  {'name': 'Freizeit', 'icon': 'movie', 'isCustom': false, 'isDefault': true},
  {
    'name': 'Sonstiges',
    'icon': 'receipt',
    'isCustom': false,
    'isDefault': true,
  },
];
