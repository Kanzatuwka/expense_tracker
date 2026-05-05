import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense.fromMap', () {
    test('parst eine vollständige Map korrekt', () {
      final date = DateTime(2026, 4, 15);
      final created = DateTime(2026, 4, 15, 12, 30);

      final expense = Expense.fromMap({
        'amount': 19.99,
        'categoryId': 'cat_food',
        'date': date,
        'note': 'Mittagessen',
        'userId': 'user_1',
        'createdAt': created,
      }, 'expense_1');

      expect(expense.id, 'expense_1');
      expect(expense.amount, 19.99);
      expect(expense.categoryId, 'cat_food');
      expect(expense.date, date);
      expect(expense.note, 'Mittagessen');
      expect(expense.userId, 'user_1');
      expect(expense.createdAt, created);
    });

    test('konvertiert int amount zu double', () {
      final expense = Expense.fromMap({
        'amount': 20, // int — kommt aus serialisierten Daten manchmal so
        'categoryId': 'cat_1',
        'date': DateTime(2026, 1, 1),
        'userId': 'user_1',
        'createdAt': DateTime(2026, 1, 1),
      }, 'expense_1');

      expect(expense.amount, 20.0);
      expect(expense.amount, isA<double>());
    });

    group('Backward Compatibility', () {
      test(
        'fällt auf altes "category"-Feld zurück wenn categoryId fehlt',
        () {
          final expense = Expense.fromMap({
            'amount': 10.0,
            'category': 'legacy_category_name', // altes Feld
            'date': DateTime(2026, 1, 1),
            'userId': 'user_1',
            'createdAt': DateTime(2026, 1, 1),
          }, 'expense_legacy');

          expect(expense.categoryId, 'legacy_category_name');
        },
      );

      test('bevorzugt categoryId wenn beide Felder vorhanden sind', () {
        final expense = Expense.fromMap({
          'amount': 10.0,
          'categoryId': 'new_id',
          'category': 'old_id', // sollte ignoriert werden
          'date': DateTime(2026, 1, 1),
          'userId': 'user_1',
          'createdAt': DateTime(2026, 1, 1),
        }, 'expense_1');

        expect(expense.categoryId, 'new_id');
      });

      test('liefert leeren String wenn beide Kategoriefelder fehlen', () {
        final expense = Expense.fromMap({
          'amount': 10.0,
          'date': DateTime(2026, 1, 1),
          'userId': 'user_1',
          'createdAt': DateTime(2026, 1, 1),
        }, 'expense_1');

        expect(expense.categoryId, '');
      });
    });

    test('liefert leere Notiz wenn das Feld fehlt', () {
      final expense = Expense.fromMap({
        'amount': 10.0,
        'categoryId': 'cat_1',
        'date': DateTime(2026, 1, 1),
        'userId': 'user_1',
        'createdAt': DateTime(2026, 1, 1),
      }, 'expense_1');

      expect(expense.note, '');
    });
  });

  group('Expense.toMap', () {
    test('liefert die Map mit primitiven Dart-Typen zurück', () {
      final date = DateTime(2026, 4, 15);
      final created = DateTime(2026, 4, 15, 10);

      final expense = Expense(
        id: 'expense_1',
        amount: 12.50,
        categoryId: 'cat_1',
        date: date,
        note: 'Test',
        userId: 'user_1',
        createdAt: created,
      );

      final map = expense.toMap();

      expect(map['amount'], 12.50);
      expect(map['categoryId'], 'cat_1');
      expect(map['note'], 'Test');
      expect(map['userId'], 'user_1');
      expect(map['date'], date);
      expect(map['createdAt'], created);
      expect(map['date'], isA<DateTime>());
      expect(map['createdAt'], isA<DateTime>());
      // id wird nicht serialisiert (kommt aus DocumentSnapshot.id)
      expect(map.containsKey('id'), isFalse);
    });

    test('Round-Trip toMap → fromMap erhält alle Felder', () {
      final original = Expense(
        id: 'expense_1',
        amount: 99.99,
        categoryId: 'cat_xyz',
        date: DateTime(2026, 6, 1),
        note: 'Round trip',
        userId: 'user_42',
        createdAt: DateTime(2026, 6, 1, 14, 30),
      );

      final restored = Expense.fromMap(original.toMap(), original.id);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.categoryId, original.categoryId);
      expect(restored.date, original.date);
      expect(restored.note, original.note);
      expect(restored.userId, original.userId);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
