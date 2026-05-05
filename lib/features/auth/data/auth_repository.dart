import 'package:expense_tracker/features/auth/models/auth_user.dart';

/// Abstraktion für Authentifizierung.
///
/// Trennt die Anwendung von einem konkreten Auth-Anbieter (aktuell Firebase Auth
/// via Google Sign-In). Notifier und UI hängen nur von diesem Interface ab.
abstract class AuthRepository {
  /// Reactive Stream des Auth-Status.
  /// Emittiert [AuthUser] beim Login und `null` beim Logout/initial.
  Stream<AuthUser?> authStateChanges();

  /// Aktuell angemeldeter Benutzer (synchron, ohne Warten).
  AuthUser? get currentUser;

  /// Convenience-Getter für die UID — `null` falls nicht angemeldet.
  /// Implementierung typischerweise: `currentUser?.uid`.
  String? get currentUserId;

  /// Startet den Google Sign-In Flow.
  ///
  /// Liefert den angemeldeten [AuthUser] zurück, oder `null` falls der Benutzer
  /// den Dialog abgebrochen hat. Wirft [AuthException] bei Fehlern.
  Future<AuthUser?> signInWithGoogle();

  /// Meldet den Benutzer ab (Firebase + Google).
  Future<void> signOut();
}
