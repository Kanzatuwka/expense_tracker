import 'package:expense_tracker/features/auth/data/auth_repository.dart';
import 'package:expense_tracker/features/auth/models/auth_exception.dart';
import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Auth + Google Sign-In Implementierung von [AuthRepository].
///
/// Mappt `firebase_auth.User` → [AuthUser] und kapselt
/// `FirebaseAuthException` als [AuthException] mit deutscher Meldung.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? fb.FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthUser? _toAuthUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_toAuthUser);
  }

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<AuthUser?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      // Benutzer hat den Dialog abgebrochen
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return _toAuthUser(userCredential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_translate(e.code), code: e.code);
    } catch (_) {
      throw const AuthException('Anmeldung fehlgeschlagen. Bitte erneut versuchen');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // Firebase-Fehlercodes auf Deutsch übersetzen.
  // Wird zur l10n-Phase in die UI verschoben — der Repo wirft dann nur den Code.
  String _translate(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Konto existiert bereits mit anderen Anmeldedaten';
      case 'invalid-credential':
        return 'Ungültige Anmeldedaten';
      case 'user-disabled':
        return 'Dieser Account wurde deaktiviert';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte später erneut versuchen';
      default:
        return 'Anmeldung fehlgeschlagen. Bitte erneut versuchen';
    }
  }
}
