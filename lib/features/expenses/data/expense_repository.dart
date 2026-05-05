import 'package:expense_tracker/features/expenses/models/expense.dart';

/// Abstraktion für den Datenzugriff auf Ausgaben.
///
/// Trennt UI/State-Management von der konkreten Datenquelle (Firestore).
/// Dadurch testbar mit In-Memory-Fakes und austauschbar (z.B. für Offline-Cache).
abstract class ExpenseRepository {
  /// Liefert alle Ausgaben des angegebenen Benutzers in Echtzeit,
  /// absteigend nach Datum sortiert.
  Stream<List<Expense>> watchByUser(String userId);

  /// Erstellt eine neue Ausgabe für den angegebenen Benutzer.
  Future<void> create({
    required String userId,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  });

  /// Aktualisiert eine bestehende Ausgabe.
  /// Authorisierung erfolgt serverseitig über Firestore Security Rules.
  Future<void> update({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  });

  /// Löscht eine Ausgabe anhand ihrer ID.
  Future<void> delete(String id);
}
