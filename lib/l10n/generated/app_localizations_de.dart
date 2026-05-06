// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Ausgaben Tracker';

  @override
  String get loginSubtitle => 'Behalte deine Finanzen im Blick';

  @override
  String get loginWithGoogle => 'Mit Google anmelden';

  @override
  String get loginFailedGeneric =>
      'Anmeldung fehlgeschlagen. Bitte erneut versuchen';

  @override
  String get navRecords => 'Records';

  @override
  String get navChart => 'Chart';

  @override
  String get navReports => 'Reports';

  @override
  String get navMe => 'Me';

  @override
  String get profileTitle => 'Profil';

  @override
  String get anonymous => 'Anonym';

  @override
  String get comingSoon => 'Bald verfügbar';

  @override
  String get manageCategories => 'Kategorien verwalten';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeChoose => 'Theme auswählen';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get languageChoose => 'Sprache auswählen';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get aboutApp => 'Über die App';

  @override
  String get appVersion => 'v0.1.0';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutQuestion => 'Abmelden?';

  @override
  String get signOutDescription => 'Du wirst von der App abgemeldet.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get notSignedIn => 'Nicht angemeldet';

  @override
  String get expensesTitle => 'Meine Ausgaben';

  @override
  String get filterAll => 'Alle';

  @override
  String get totalAmount => 'Gesamtbetrag';

  @override
  String get noExpenses => 'Keine Ausgaben vorhanden';

  @override
  String get unknownCategory => 'Unbekannt';

  @override
  String get deleteExpenseQuestion => 'Ausgabe löschen?';

  @override
  String get deleteExpenseDescription =>
      'Diese Ausgabe wird unwiderruflich gelöscht.';

  @override
  String get delete => 'Löschen';

  @override
  String get newExpense => 'Neue Ausgabe';

  @override
  String get editExpense => 'Ausgabe bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get update => 'Aktualisieren';

  @override
  String get amountLabel => 'Betrag (€)';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get categoryHint => 'Kategorie auswählen';

  @override
  String get dateLabel => 'Datum';

  @override
  String get noteOptional => 'Notiz (optional)';

  @override
  String get noteLabel => 'Notiz';

  @override
  String get pleaseSelectCategory => 'Bitte eine Kategorie auswählen';

  @override
  String get pleaseEnterAmount => 'Bitte Betrag eingeben';

  @override
  String get invalidAmount => 'Ungültiger Betrag';

  @override
  String get amountMustBePositive => 'Betrag muss größer als 0 sein';

  @override
  String errorSaving(Object error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String errorPrefix(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get detailsTitle => 'Details';

  @override
  String get editTooltip => 'Bearbeiten';

  @override
  String get deleteTooltip => 'Löschen';

  @override
  String get categoriesTitle => 'Kategorien';

  @override
  String get newCategoryTooltip => 'Neue Kategorie';

  @override
  String get defaultCategoriesSection => 'Standardkategorien';

  @override
  String get customCategoriesSection => 'Eigene Kategorien';

  @override
  String get noCategoriesYet => 'Keine Kategorien vorhanden';

  @override
  String get tapPlusToCreate => 'Tippe auf + um eine zu erstellen';

  @override
  String get deleteCategoryQuestion => 'Kategorie löschen?';

  @override
  String deleteCategoryDescription(String name) {
    return '\"$name\" wird unwiderruflich gelöscht. Bestehende Ausgaben in dieser Kategorie bleiben erhalten, zeigen aber keinen Kategorie-Namen mehr an.';
  }

  @override
  String get newCategoryTitle => 'Neue Kategorie';

  @override
  String get nameLabel => 'Name';

  @override
  String get chooseIcon => 'Icon auswählen';

  @override
  String get pleaseSelectIcon => 'Bitte ein Icon auswählen';

  @override
  String get pleaseEnterName => 'Bitte einen Namen eingeben';

  @override
  String get nameTooLong => 'Name darf maximal 30 Zeichen lang sein';

  @override
  String get categoryFood => 'Essen';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHealth => 'Gesundheit';

  @override
  String get categoryLeisure => 'Freizeit';

  @override
  String get categoryOther => 'Sonstiges';
}
