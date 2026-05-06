// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get loginSubtitle => 'Keep an eye on your finances';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginFailedGeneric => 'Sign-in failed. Please try again';

  @override
  String get navRecords => 'Records';

  @override
  String get navChart => 'Chart';

  @override
  String get navReports => 'Budget';

  @override
  String get navMe => 'Me';

  @override
  String get profileTitle => 'Profile';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeChoose => 'Choose theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageChoose => 'Choose language';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get aboutApp => 'About the app';

  @override
  String get appVersion => 'v0.1.0';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutDescription => 'You will be signed out of the app.';

  @override
  String get cancel => 'Cancel';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get expensesTitle => 'My Expenses';

  @override
  String get filterAll => 'All';

  @override
  String get totalAmount => 'Total';

  @override
  String get noExpenses => 'No expenses yet';

  @override
  String get unknownCategory => 'Unknown';

  @override
  String get deleteExpenseQuestion => 'Delete expense?';

  @override
  String get deleteExpenseDescription =>
      'This expense will be permanently deleted.';

  @override
  String get delete => 'Delete';

  @override
  String get newExpense => 'New expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get amountLabel => 'Amount (€)';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'Select a category';

  @override
  String get dateLabel => 'Date';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteLabel => 'Note';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get amountMustBePositive => 'Amount must be greater than 0';

  @override
  String errorSaving(Object error) {
    return 'Error saving: $error';
  }

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get detailsTitle => 'Details';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get newCategoryTooltip => 'New category';

  @override
  String get defaultCategoriesSection => 'Default categories';

  @override
  String get customCategoriesSection => 'Custom categories';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get tapPlusToCreate => 'Tap + to create one';

  @override
  String get deleteCategoryQuestion => 'Delete category?';

  @override
  String deleteCategoryDescription(String name) {
    return '\"$name\" will be permanently deleted. Existing expenses in this category remain, but will no longer show a category name.';
  }

  @override
  String get newCategoryTitle => 'New category';

  @override
  String get nameLabel => 'Name';

  @override
  String get chooseIcon => 'Choose icon';

  @override
  String get pleaseSelectIcon => 'Please select an icon';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get nameTooLong => 'Name must be at most 30 characters';

  @override
  String get chartsTitle => 'Charts';

  @override
  String get byCategorySection => 'Expenses by Category';

  @override
  String get monthlyTrendSection => 'Monthly Trend';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryLeisure => 'Leisure';

  @override
  String get categoryOther => 'Other';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get summarySection => 'Summary';

  @override
  String get topCategoriesSection => 'Top categories';

  @override
  String get dailyAvgLabel => 'Daily avg.';

  @override
  String get vsLastMonth => 'vs. last month';

  @override
  String get noDataForMonth => 'No expenses this month';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get setBudgetTitle => 'Set budget';

  @override
  String get editBudgetTitle => 'Edit budget';

  @override
  String get monthlyLimitLabel => 'Monthly limit (€)';

  @override
  String get noBudgetSet => 'No limit set';
}
