import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categorization/categorization_service.dart';

class RuleBasedCategorizationService implements CategorizationService {
  // Keys are lowercase Firestore names; values are keyword lists in de/en/uk.
  static const _keywordMap = <String, List<String>>{
    'essen': [
      'restaurant', 'cafe', 'café', 'coffee', 'kaffee', 'pizza', 'sushi',
      'bäckerei', 'bakery', 'supermarkt', 'grocery', 'lebensmittel',
      'lunch', 'mittagessen', 'dinner', 'abendessen', 'frühstück', 'breakfast',
      'їжа', 'кава', 'ресторан', 'піца', 'кафе', 'супермаркет', 'обід',
    ],
    'transport': [
      'bus', 'bahn', 'taxi', 'uber', 'auto', 'car', 'benzin', 'petrol',
      'fuel', 'tanken', 'ticket', 'fahrt', 'metro', 'tram', 'straßenbahn',
      'транспорт', 'таксі', 'автобус', 'метро', 'бензин', 'маршрутка',
    ],
    'gesundheit': [
      'apotheke', 'arzt', 'doctor', 'pharmacy', 'medikament', 'medication',
      'klinik', 'clinic', 'zahnarzt', 'dentist', 'krankenhaus', 'hospital',
      'аптека', 'лікар', 'лікарня', 'ліки', 'клініка',
    ],
    'freizeit': [
      'kino', 'cinema', 'sport', 'gym', 'fitness', 'konzert', 'concert',
      'theater', 'museum', 'buch', 'book', 'spiel', 'game', 'hobby',
      'кіно', 'спорт', 'концерт', 'театр', 'музей', 'книга', 'хобі',
    ],
  };

  @override
  String? suggestCategoryId(String note, List<Category> categories) {
    if (note.trim().isEmpty) return null;
    final lower = note.toLowerCase();
    for (final entry in _keywordMap.entries) {
      if (entry.value.any((k) => lower.contains(k))) {
        final match = categories
            .where((c) => c.name.toLowerCase() == entry.key)
            .firstOrNull;
        if (match != null) return match.id;
      }
    }
    return null;
  }
}
