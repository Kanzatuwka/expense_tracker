import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Konvertierungstabellen zwischen ThemeMode und Firestore-String.
const _stringToMode = <String, ThemeMode>{
  'light': ThemeMode.light,
  'dark': ThemeMode.dark,
  'system': ThemeMode.system,
};
const _modeToString = <ThemeMode, String>{
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
  ThemeMode.system: 'system',
};

/// Parst einen Firestore-Wert in einen [ThemeMode].
/// Unbekannte oder fehlende Werte fallen auf [ThemeMode.system] zurück.
ThemeMode parseThemeMode(String? value) =>
    _stringToMode[value] ?? ThemeMode.system;

/// Serialisiert einen [ThemeMode] in den Firestore-String.
String themeModeToString(ThemeMode mode) => _modeToString[mode] ?? 'system';

/// Aktueller Theme-Modus, abgeleitet aus [userProfileProvider].
///
/// Fällt auf [ThemeMode.system] zurück, wenn kein Benutzer angemeldet ist
/// oder das Profil noch geladen wird — so bleibt das UI bis zum
/// Login-Bildschirm konsistent.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => parseThemeMode(profile?.preferredTheme),
    orElse: () => ThemeMode.system,
  );
});

/// Notifier zum Ändern des Theme-Modus.
///
/// Schreibt in das Firestore-Profil — der Stream-Provider emittiert dann
/// die neue Einstellung, [themeModeProvider] aktualisiert sich automatisch
/// und MaterialApp rebuildet mit dem neuen Theme.
class ThemeModeNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> setThemeMode(ThemeMode mode) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;

    await ref
        .read(userProfileRepositoryProvider)
        .updateTheme(userId: userId, theme: themeModeToString(mode));
  }
}

final themeModeNotifierProvider = NotifierProvider<ThemeModeNotifier, void>(() {
  return ThemeModeNotifier();
});
