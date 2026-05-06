import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/auth/data/user_profile_repository.dart';
import 'package:expense_tracker/features/auth/models/user_profile.dart';

/// Firestore-Implementierung von [UserProfileRepository].
///
/// Konvertiert an der Schichtgrenze: `Timestamp` ↔ `DateTime`.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection('users').doc(userId);

  UserProfile? _profileFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) return null;
    final data = doc.data()!;
    return UserProfile.fromMap({
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate(),
    }, doc.id);
  }

  @override
  Future<bool> createIfMissing(String userId) async {
    final doc = _doc(userId);
    final snapshot = await doc.get();

    if (snapshot.exists) return false;

    await doc.set({
      'subscriptionStatus': 'free',
      'aiUsagesToday': 0,
      'aiUsagesResetDate': Timestamp.now(),
      'preferredLanguage': 'de',
      'preferredTheme': 'system',
      'createdAt': Timestamp.now(),
    });
    return true;
  }

  @override
  Stream<UserProfile?> watchByUser(String userId) {
    return _doc(userId).snapshots().map(_profileFromSnapshot);
  }

  @override
  Future<void> updateTheme({
    required String userId,
    required String theme,
  }) async {
    await _doc(userId).update({'preferredTheme': theme});
  }

  @override
  Future<void> updateLanguage({
    required String userId,
    required String language,
  }) async {
    await _doc(userId).update({'preferredLanguage': language});
  }
}
