import 'package:expense_tracker/features/categories/models/category.dart';

abstract class CategorizationService {
  /// Returns a [Category.id] suggestion based on [note], or null if no match.
  String? suggestCategoryId(String note, List<Category> categories);
}
