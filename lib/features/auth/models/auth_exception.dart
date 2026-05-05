/// Domain-Exception für Authentifizierungsfehler.
///
/// Wird von [AuthRepository] geworfen. Kapselt anbieter-spezifische
/// Fehlertypen (z.B. `FirebaseAuthException`) hinter einem stabilen Interface.
class AuthException implements Exception {
  /// Benutzerlesbare Fehlermeldung (aktuell auf Deutsch — wird zur l10n-Phase
  /// in einen Code refaktoriert, den die UI dann übersetzt).
  final String message;

  /// Optional: anbieter-spezifischer Fehlercode für Logging/Telemetrie.
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException($code): $message';
}
