import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';

/// Firestore-basierte Implementierung von [ExpenseRepository].
///
/// Konvertiert an der Schichtgrenze: `Timestamp` ↔ `DateTime`.
/// Die Domain-Entität [Expense] kennt Firestore nicht.
class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('expenses');

  /// Map → Expense mit Timestamp → DateTime Normalisierung.
  Expense _expenseFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Expense.fromMap({
      ...data,
      'date': (data['date'] as Timestamp).toDate(),
      'createdAt': (data['createdAt'] as Timestamp).toDate(),
    }, doc.id);
  }

  @override
  Stream<List<Expense>> watchByUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(_expenseFromDoc).toList(),
        );
  }

  @override
  Future<void> create({
    required String userId,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  }) async {
    await _collection.add({
      'amount': amount,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'userId': userId,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<void> update({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    required String note,
  }) async {
    await _collection.doc(id).update({
      'amount': amount,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note,
    });
  }

  @override
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
