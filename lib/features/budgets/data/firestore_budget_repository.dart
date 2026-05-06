import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/budgets/data/budget_repository.dart';
import 'package:expense_tracker/features/budgets/models/budget.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('budgets');

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
    await _budgetsRef(userId).doc(budget.categoryId).set(budget.toMap());
  }

  @override
  Future<void> deleteBudget(String userId, String categoryId) async {
    await _budgetsRef(userId).doc(categoryId).delete();
  }
}
