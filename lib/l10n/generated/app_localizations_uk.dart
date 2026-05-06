// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Трекер витрат';

  @override
  String get loginSubtitle => 'Тримай свої фінанси під контролем';

  @override
  String get loginWithGoogle => 'Увійти через Google';

  @override
  String get loginFailedGeneric => 'Не вдалося увійти. Спробуйте ще раз';

  @override
  String get navRecords => 'Записи';

  @override
  String get navChart => 'Графік';

  @override
  String get navReports => 'Звіти';

  @override
  String get navMe => 'Я';

  @override
  String get profileTitle => 'Профіль';

  @override
  String get anonymous => 'Анонім';

  @override
  String get comingSoon => 'Скоро з\'явиться';

  @override
  String get manageCategories => 'Керування категоріями';

  @override
  String get themeLabel => 'Тема';

  @override
  String get themeChoose => 'Виберіть тему';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get themeSystem => 'Системна';

  @override
  String get languageLabel => 'Мова';

  @override
  String get languageChoose => 'Виберіть мову';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get aboutApp => 'Про додаток';

  @override
  String get appVersion => 'v0.1.0';

  @override
  String get signOut => 'Вийти';

  @override
  String get signOutQuestion => 'Вийти?';

  @override
  String get signOutDescription => 'Ви вийдете зі свого акаунту в додатку.';

  @override
  String get cancel => 'Скасувати';

  @override
  String get notSignedIn => 'Не виконано вхід';

  @override
  String get expensesTitle => 'Мої витрати';

  @override
  String get filterAll => 'Усі';

  @override
  String get totalAmount => 'Усього';

  @override
  String get noExpenses => 'Витрат поки немає';

  @override
  String get unknownCategory => 'Невідомо';

  @override
  String get deleteExpenseQuestion => 'Видалити витрату?';

  @override
  String get deleteExpenseDescription =>
      'Цю витрату буде безповоротно видалено.';

  @override
  String get delete => 'Видалити';

  @override
  String get newExpense => 'Нова витрата';

  @override
  String get editExpense => 'Редагувати витрату';

  @override
  String get save => 'Зберегти';

  @override
  String get update => 'Оновити';

  @override
  String get amountLabel => 'Сума (€)';

  @override
  String get categoryLabel => 'Категорія';

  @override
  String get categoryHint => 'Виберіть категорію';

  @override
  String get dateLabel => 'Дата';

  @override
  String get noteOptional => 'Нотатка (необов\'язково)';

  @override
  String get noteLabel => 'Нотатка';

  @override
  String get pleaseSelectCategory => 'Будь ласка, виберіть категорію';

  @override
  String get pleaseEnterAmount => 'Будь ласка, введіть суму';

  @override
  String get invalidAmount => 'Некоректна сума';

  @override
  String get amountMustBePositive => 'Сума має бути більшою за 0';

  @override
  String errorSaving(Object error) {
    return 'Помилка збереження: $error';
  }

  @override
  String errorPrefix(Object error) {
    return 'Помилка: $error';
  }

  @override
  String get detailsTitle => 'Деталі';

  @override
  String get editTooltip => 'Редагувати';

  @override
  String get deleteTooltip => 'Видалити';

  @override
  String get categoriesTitle => 'Категорії';

  @override
  String get newCategoryTooltip => 'Нова категорія';

  @override
  String get defaultCategoriesSection => 'Стандартні категорії';

  @override
  String get customCategoriesSection => 'Власні категорії';

  @override
  String get noCategoriesYet => 'Категорій поки немає';

  @override
  String get tapPlusToCreate => 'Торкніться + щоб створити';

  @override
  String get deleteCategoryQuestion => 'Видалити категорію?';

  @override
  String deleteCategoryDescription(String name) {
    return '«$name» буде безповоротно видалено. Наявні витрати в цій категорії залишаться, але вже не показуватимуть назву категорії.';
  }

  @override
  String get newCategoryTitle => 'Нова категорія';

  @override
  String get nameLabel => 'Назва';

  @override
  String get chooseIcon => 'Виберіть іконку';

  @override
  String get pleaseSelectIcon => 'Будь ласка, виберіть іконку';

  @override
  String get pleaseEnterName => 'Будь ласка, введіть назву';

  @override
  String get nameTooLong => 'Назва має містити не більше 30 символів';
}
