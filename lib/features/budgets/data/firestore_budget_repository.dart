import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/budgets/data/budget_repository.dart';
import 'package:expense_tracker/features/budgets/models/budget.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('budgets');

  DocumentReference<Map<String, dynamic>> _monthlySnapshotDoc(
    String userId,
    int year,
    int month,
  ) {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgetMonths')
        .doc(key);
  }

  @override
  Stream<List<Budget>> watchBudgets(String userId) {
    return _budgetsRef(userId).snapshots().map(
          (snap) => snap.docs
              .map((doc) => Budget.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> setBudget(String userId, Budget budget) async {
    final now = DateTime.now();
    await Future.wait([
      _budgetsRef(userId).doc(budget.categoryId).set(budget.toMap()),
      // Record the limit in the current month's snapshot (merge so other
      // categories in the same month are preserved).
      _monthlySnapshotDoc(userId, now.year, now.month).set(
        {'budgets': {budget.categoryId: budget.amount}},
        SetOptions(merge: true),
      ),
    ]);
  }

  @override
  Future<void> deleteBudget(String userId, String categoryId) async {
    final now = DateTime.now();
    await _budgetsRef(userId).doc(categoryId).delete();
    // Remove the category from the current month's snapshot.
    // Ignore errors if the snapshot document doesn't exist yet.
    try {
      await _monthlySnapshotDoc(userId, now.year, now.month)
          .update({'budgets.$categoryId': FieldValue.delete()});
    } catch (_) {}
  }

  @override
  Future<Map<String, double>> getMonthlySnapshot(
    String userId,
    int year,
    int month,
  ) async {
    final doc = await _monthlySnapshotDoc(userId, year, month).get();
    final data = doc.data()?['budgets'];
    if (data == null) return {};
    return (data as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
