import 'package:expense_tracker/features/auth/models/user_profile.dart';

/// Abstraktion für das Benutzerprofil-Dokument unter `users/{userId}`.
///
/// Hält Daten getrennt von Authentifizierung (siehe [AuthRepository]).
abstract class UserProfileRepository {
  /// Legt das Profil-Dokument an, falls es noch nicht existiert.
  ///
  /// Liefert `true` zurück, wenn ein neues Profil angelegt wurde,
  /// `false` wenn das Profil bereits existierte.
  Future<bool> createIfMissing(String userId);

  /// Reactive Stream des Profils. Emittiert `null`, wenn das Dokument
  /// noch nicht existiert (z.B. bevor [createIfMissing] aufgerufen wurde).
  Stream<UserProfile?> watchByUser(String userId);

  /// Aktualisiert nur das `preferredTheme`-Feld.
  /// Andere Profilfelder bleiben unverändert.
  Future<void> updateTheme({
    required String userId,
    required String theme,
  });

  /// Aktualisiert nur das `preferredLanguage`-Feld.
  /// Andere Profilfelder bleiben unverändert.
  Future<void> updateLanguage({
    required String userId,
    required String language,
  });
}
