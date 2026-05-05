import 'dart:async';

import 'package:expense_tracker/features/expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';

/// In-Memory-Implementierung von [ExpenseRepository] für Tests.
///
/// Speichert Ausgaben in einer Map und emittiert Änderungen über einen
/// Broadcast-Stream — verhält sich aus Testperspektive wie Firestore-Snapshots.
class InMemoryExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> _store = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  int _idCounter = 0;
  String _nextId() => 'expense_${++_idCounter}';

  /// Erlaubt Tests, den Anfangszustand zu setzen.
  void seed(Iterable<Expense> expenses) {
    for (final e in expenses) {
      _store[e.id] = e;
    }
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  List<Expense> _sortedByUser(String userId) {
    final list = _store.values.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Stream<List<Expense>> watchByUser(String userId) async* {
    yield _sortedByUser(userId);
    await for (final _ in _changes.stream) {
      yield _sortedByUser(userId);
    }
  }

  @override
  Future<void> create({
    required String userId,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  }) async {
    final expense = Expense(
      id: _nextId(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
      userId: userId,
      createdAt: DateTime.now(),
    );
    _store[expense.id] = expense;
    _emit();
  }

  @override
  Future<void> update({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  }) async {
    final existing = _store[id];
    if (existing == null) return;
    _store[id] = Expense(
      id: existing.id,
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
      userId: existing.userId,
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  /// Aufzuräumen am Testende um Stream-Leaks zu vermeiden.
  Future<void> dispose() => _changes.close();
}
