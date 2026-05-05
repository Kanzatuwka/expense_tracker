/// Abstraktion für das Benutzerprofil-Dokument unter `users/{userId}`.
///
/// Hält Daten getrennt von Authentifizierung (siehe [AuthRepository]).
/// Aktuell minimal — wird in v2 erweitert um preferredLanguage,
/// preferredTheme, subscriptionStatus etc.
abstract class UserProfileRepository {
  /// Legt das Profil-Dokument an, falls es noch nicht existiert.
  ///
  /// Liefert `true` zurück, wenn ein neues Profil angelegt wurde,
  /// `false` wenn das Profil bereits existierte.
  Future<bool> createIfMissing(String userId);
}
