import 'package:expense_tracker/features/auth/data/auth_repository.dart';
import 'package:expense_tracker/features/auth/data/firebase_auth_repository.dart';
import 'package:expense_tracker/features/auth/data/firestore_user_profile_repository.dart';
import 'package:expense_tracker/features/auth/data/user_profile_repository.dart';
import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/models/user_profile.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DI-Provider für [AuthRepository].
/// In Tests via `overrideWithValue(InMemoryAuthRepository())` ersetzbar.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// DI-Provider für [UserProfileRepository].
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository();
});

/// Reactive Auth-Status.
/// Nutzt [authRepositoryProvider] — keine direkte Firebase-Abhängigkeit hier.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Reactive Stream des Benutzerprofils unter `users/{uid}`.
///
/// Folgt der Auth-Status:
///   - Niemand angemeldet → liefert `null`
///   - Angemeldet → liefert das aktuelle Profil (oder `null` falls noch
///     nicht angelegt — das passiert während des ersten Sign-In Flows)
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(userProfileRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return repository.watchByUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

/// Auth-Notifier: orchestriert Sign-In als Use Case.
///
/// Bei einem neuen Benutzer:
///   1. Auth-Provider liefert AuthUser
///   2. UserProfile-Repo legt das `users/{uid}` Dokument an
///   3. Categories-Notifier seedt Standardkategorien
///
/// Diese Schritte wären in der vorherigen Version vermischt mit Firestore-
/// und Firebase-Auth-Calls direkt im Notifier — jetzt sind sie reine
/// Aufrufe gegen Repository-Interfaces.
class AuthNotifier extends Notifier<AsyncValue<AuthUser?>> {
  @override
  AsyncValue<AuthUser?> build() => const AsyncValue.data(null);

  Future<void> signInWithGoogle() async {
    final user = await ref.read(authRepositoryProvider).signInWithGoogle();
    if (user == null) return; // Dialog abgebrochen

    final isNew = await ref
        .read(userProfileRepositoryProvider)
        .createIfMissing(user.uid);

    if (isNew) {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .initDefaultCategories();
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>(() {
  return AuthNotifier();
});
