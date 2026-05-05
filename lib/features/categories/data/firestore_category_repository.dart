import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/categories/data/category_repository.dart';
import 'package:expense_tracker/features/categories/models/category.dart';

/// Firestore-basierte Implementierung von [CategoryRepository].
///
/// Konvertiert an der Schichtgrenze: `Timestamp` ↔ `DateTime`.
class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userCategories(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  Category _categoryFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Category.fromMap({
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate(),
    }, doc.id);
  }

  @override
  Stream<List<Category>> watchByUser(String userId) {
    return _userCategories(userId)
        .orderBy('isDefault', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(_categoryFromDoc).toList(),
        );
  }

  @override
  Future<void> initDefaults(String userId) async {
    final ref = _userCategories(userId);

    // Idempotenz: nur seeden, wenn noch keine Kategorie existiert
    final snapshot = await ref.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final category in defaultCategoriesSeed) {
      batch.set(ref.doc(), {...category, 'createdAt': Timestamp.now()});
    }
    await batch.commit();
  }

  @override
  Future<void> create({
    required String userId,
    required String name,
    required String icon,
  }) async {
    await _userCategories(userId).add({
      'name': name,
      'icon': icon,
      'isCustom': true,
      'isDefault': false,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<void> delete({
    required String userId,
    required String categoryId,
  }) async {
    await _userCategories(userId).doc(categoryId).delete();
  }
}
