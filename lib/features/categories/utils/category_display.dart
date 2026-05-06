import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Liefert den anzuzeigenden Namen einer Kategorie unter Berücksichtigung der
/// aktuellen Locale.
///
/// Standardkategorien (`isDefault: true`) sind in Firestore mit deutschen
/// Namen gespeichert (siehe `defaultCategoriesSeed`). Hier werden sie an der
/// Display-Schicht übersetzt — die Daten in Firestore bleiben unverändert,
/// es ist also keine Migration nötig.
///
/// Benutzerdefinierte Kategorien werden 1:1 angezeigt.
String localizedCategoryName(BuildContext context, Category category) {
  if (!category.isCustom) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.name) {
      case 'Essen':
        return l10n.categoryFood;
      case 'Transport':
        return l10n.categoryTransport;
      case 'Gesundheit':
        return l10n.categoryHealth;
      case 'Freizeit':
        return l10n.categoryLeisure;
      case 'Sonstiges':
        return l10n.categoryOther;
    }
  }
  return category.name;
}
