import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wrapper für widget-Tests, der die l10n-Delegates registriert.
///
/// Tests behalten ihre `find.text('Profil')` Assertionen — Standard-Locale
/// ist `de`, da die ursprünglichen Tests gegen die deutschen Strings
/// geschrieben wurden.
MaterialApp localizedApp(Widget home, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
