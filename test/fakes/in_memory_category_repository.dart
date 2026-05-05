import 'dart:async';

import 'package:expense_tracker/features/categories/data/category_repository.dart';
import 'package:expense_tracker/features/categories/models/category.dart';

/// In-Memory-Implementierung von [CategoryRepository] für Tests.
class InMemoryCategoryRepository implements CategoryRepository {
  /// `userId` → `Map<categoryId, Category>`
  final Map<String, Map<String, Category>> _store = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  int _idCounter = 0;
  String _nextId() => 'category_${++_idCounter}';

  void seed(String userId, Iterable<Category> categories) {
    final bucket = _store.putIfAbsent(userId, () => {});
    for (final c in categories) {
      bucket[c.id] = c;
    }
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  List<Category> _sorted(String userId) {
    final list = (_store[userId]?.values ?? const <Category>[]).toList();
    // isDefault desc — Standardkategorien zuerst, danach beliebige Reihenfolge
    list.sort((a, b) {
      if (a.isDefault == b.isDefault) return 0;
      return a.isDefault ? -1 : 1;
    });
    return list;
  }

  @override
  Stream<List<Category>> watchByUser(String userId) async* {
    yield _sorted(userId);
    await for (final _ in _changes.stream) {
      yield _sorted(userId);
    }
  }

  @override
  Future<void> initDefaults(String userId) async {
    final bucket = _store.putIfAbsent(userId, () => {});
    if (bucket.isNotEmpty) return; // Idempotenz

    for (final seed in defaultCategoriesSeed) {
      final id = _nextId();
      bucket[id] = Category(
        id: id,
        name: seed['name']! as String,
        icon: seed['icon']! as String,
        isCustom: seed['isCustom']! as bool,
        isDefault: seed['isDefault']! as bool,
        createdAt: DateTime.now(),
      );
    }
    _emit();
  }

  @override
  Future<void> create({
    required String userId,
    required String name,
    required String icon,
  }) async {
    final bucket = _store.putIfAbsent(userId, () => {});
    final id = _nextId();
    bucket[id] = Category(
      id: id,
      name: name,
      icon: icon,
      isCustom: true,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> delete({
    required String userId,
    required String categoryId,
  }) async {
    _store[userId]?.remove(categoryId);
    _emit();
  }

  Future<void> dispose() => _changes.close();
}
