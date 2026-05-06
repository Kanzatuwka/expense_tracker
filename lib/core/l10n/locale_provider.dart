import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unterstützte Locale-Codes — identisch mit den ARB-Dateinamen.
const supportedLanguageCodes = ['de', 'en', 'uk'];

/// Aktuelle Locale, abgeleitet aus [userProfileProvider].
///
/// Liefert `null` wenn kein Profil geladen ist — MaterialApp fällt dann
/// auf System-Locale zurück.
final localeProvider = Provider<Locale?>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return null;
      final code = profile.preferredLanguage;
      if (!supportedLanguageCodes.contains(code)) return null;
      return Locale(code);
    },
    orElse: () => null,
  );
});

/// Notifier zum Ändern der Sprache.
class LocaleNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> setLanguage(String code) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;
    await ref
        .read(userProfileRepositoryProvider)
        .updateLanguage(userId: userId, language: code);
  }
}

final localeNotifierProvider = NotifierProvider<LocaleNotifier, void>(() {
  return LocaleNotifier();
});
