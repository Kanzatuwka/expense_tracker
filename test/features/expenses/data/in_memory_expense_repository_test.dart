import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_expense_repository.dart';

void main() {
  late InMemoryExpenseRepository repo;

  setUp(() {
    repo = InMemoryExpenseRepository();
  });

  tearDown(() async {
    await repo.dispose();
  });

  group('watchByUser', () {
    test('liefert nur Ausgaben des angegebenen Benutzers', () async {
      repo.seed([
        _expense(id: 'e1', userId: 'user_a'),
        _expense(id: 'e2', userId: 'user_b'),
        _expense(id: 'e3', userId: 'user_a'),
      ]);

      final expenses = await repo.watchByUser('user_a').first;
      expect(expenses.map((e) => e.id), ['e1', 'e3']);
    });

    test('sortiert absteigend nach Datum', () async {
      repo.seed([
        _expense(id: 'old', userId: 'u', date: DateTime(2026, 1, 1)),
        _expense(id: 'new', userId: 'u', date: DateTime(2026, 6, 1)),
        _expense(id: 'mid', userId: 'u', date: DateTime(2026, 3, 1)),
      ]);

      final expenses = await repo.watchByUser('u').first;
      expect(expenses.map((e) => e.id), ['new', 'mid', 'old']);
    });

    test(
      'emittiert eine neue Liste, wenn eine Ausgabe hinzukommt',
      () async {
        // Sammle die ersten zwei Emissionen mit eigenem Timeout
        final emissionsFuture = repo
            .watchByUser('u')
            .take(2)
            .toList()
            .timeout(const Duration(seconds: 2));

        // Microtask-Tick: damit der Subscriber zuerst die initiale Emission
        // erhält, bevor wir die zweite triggern
        await Future<void>.delayed(Duration.zero);

        await repo.create(
          userId: 'u',
          amount: 10.0,
          categoryId: 'c',
          date: DateTime(2026, 1, 1),
          note: '',
        );

        final emissions = await emissionsFuture;
        expect(emissions, hasLength(2));
        expect(emissions.first, isEmpty);
        expect(emissions.last, hasLength(1));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });

  group('create', () {
    test('vergibt eine ID und persistiert die Ausgabe', () async {
      await repo.create(
        userId: 'u',
        amount: 12.5,
        categoryId: 'c',
        date: DateTime(2026, 4, 1),
        note: 'Notiz',
      );

      final expenses = await repo.watchByUser('u').first;
      expect(expenses, hasLength(1));
      expect(expenses.first.id, isNotEmpty);
      expect(expenses.first.amount, 12.5);
      expect(expenses.first.note, 'Notiz');
      expect(expenses.first.categoryId, 'c');
    });
  });

  group('update', () {
    test('ändert Werte, behält ID, userId und createdAt', () async {
      repo.seed([
        _expense(
          id: 'e1',
          userId: 'u',
          amount: 10.0,
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);

      await repo.update(
        id: 'e1',
        amount: 99.0,
        categoryId: 'new',
        date: DateTime(2026, 12, 31),
        note: 'updated',
      );

      final list = await repo.watchByUser('u').first;
      final updated = list.single;
      expect(updated.id, 'e1');
      expect(updated.userId, 'u');
      expect(updated.createdAt, DateTime(2026, 1, 1));
      expect(updated.amount, 99.0);
      expect(updated.categoryId, 'new');
      expect(updated.note, 'updated');
    });

    test('ist ein No-Op für unbekannte ID', () async {
      await repo.update(
        id: 'unknown',
        amount: 1.0,
        categoryId: 'c',
        date: DateTime.now(),
        note: '',
      );

      final list = await repo.watchByUser('u').first;
      expect(list, isEmpty);
    });
  });

  group('delete', () {
    test('entfernt die Ausgabe', () async {
      repo.seed([_expense(id: 'e1', userId: 'u')]);

      await repo.delete('e1');

      final list = await repo.watchByUser('u').first;
      expect(list, isEmpty);
    });
  });
}

Expense _expense({
  required String id,
  required String userId,
  double amount = 10.0,
  String categoryId = 'c',
  DateTime? date,
  String note = '',
  DateTime? createdAt,
}) {
  return Expense(
    id: id,
    amount: amount,
    categoryId: categoryId,
    date: date ?? DateTime(2026, 1, 1),
    note: note,
    userId: userId,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}
