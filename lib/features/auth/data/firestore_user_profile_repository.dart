import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/auth/data/user_profile_repository.dart';

/// Firestore-Implementierung von [UserProfileRepository].
///
/// Schreibt das Profil-Dokument unter `users/{userId}`.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<bool> createIfMissing(String userId) async {
    final doc = _firestore.collection('users').doc(userId);
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
}
