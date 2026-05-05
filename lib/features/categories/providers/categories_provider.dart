import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/data/category_repository.dart';
import 'package:expense_tracker/features/categories/data/firestore_category_repository.dart';
import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider für das CategoryRepository.
/// In Tests via `overrideWithValue(InMemoryCategoryRepository())` ersetzbar.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return FirestoreCategoryRepository();
});

/// StreamProvider: liefert kombinierte Liste aus Standard- und benutzerdefinierten Kategorien.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(categoryRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repository.watchByUser(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

/// Notifier: kapselt Schreib- und Löschoperationen für Kategorien.
class CategoriesNotifier extends Notifier<void> {
  @override
  void build() {}

  String? get _userId => ref.read(authRepositoryProvider).currentUserId;

  /// Standardkategorien beim ersten Login anlegen.
  Future<void> initDefaultCategories() async {
    final userId = _userId;
    if (userId == null) return;
    await ref.read(categoryRepositoryProvider).initDefaults(userId);
  }

  /// Neue benutzerdefinierte Kategorie anlegen.
  Future<void> addCategory({
    required String name,
    required String icon,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    await ref
        .read(categoryRepositoryProvider)
        .create(userId: userId, name: name, icon: icon);
  }

  /// Kategorie löschen — der Aufrufer muss sicherstellen,
  /// dass nur benutzerdefinierte Kategorien gelöscht werden.
  Future<void> deleteCategory(String categoryId) async {
    final userId = _userId;
    if (userId == null) return;
    await ref
        .read(categoryRepositoryProvider)
        .delete(userId: userId, categoryId: categoryId);
  }
}

final categoriesNotifierProvider = NotifierProvider<CategoriesNotifier, void>(
  () {
    return CategoriesNotifier();
  },
);
