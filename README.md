# Ausgaben Tracker

A personal expense tracking app for the German-speaking market, built with
Flutter + Firebase. Organized as a long-lived, modular codebase — layered
according to Clean Architecture principles with strict separation between
domain, data, and presentation, and a test suite that runs entirely in pure
Dart with no Firebase initialization required.

**Status:** v2 complete · 104 tests (102 passing) · v2+ features planned.

---

## Stack

- **Flutter** (Dart) with Material 3
- **Riverpod 3** — state management (Notifier + StreamProvider)
- **Firebase Auth** — Google OAuth sign-in
- **Cloud Firestore** — real-time data, per-user security rules
- **fl_chart** — pie chart + bar chart
- **flutter_localizations + intl** — de / en / uk
- **flutter_test** — unit and widget tests via `ProviderContainer` with provider overrides

---

## Architecture

The codebase follows Clean Architecture's dependency rule: **inner layers
know nothing about outer layers**. Concretely:

- **Domain entities** (`Expense`, `Category`, `Budget`, `AuthUser`, …) are pure Dart
  classes. They have no Firebase imports — they don't know Firestore exists.
- **Repository interfaces** declare what the application needs from a data
  source. They live alongside the entities they operate on.
- **Firestore implementations** are the *only* place where `cloud_firestore`
  is imported, and the *only* place where `Timestamp ↔ DateTime`
  conversion happens.
- **Notifiers** orchestrate use cases by calling repository interfaces.
  They never reach for `FirebaseAuth.instance` directly — even auth state
  arrives through `AuthRepository`.
- **UI** consumes Riverpod providers and displays state. It never imports
  anything Firebase-shaped.

This means **every Notifier is testable in pure Dart** by overriding the
repository providers with in-memory fakes. No Firebase init, no platform
channels, no widget tree.

### Type map

| Layer | Examples | Location |
|---|---|---|
| Domain | `Expense`, `Category`, `Budget`, `AuthUser`, `AuthException` | `lib/features/*/models/` |
| Data (interfaces) | `ExpenseRepository`, `CategoryRepository`, `BudgetRepository`, `AuthRepository`, `UserProfileRepository` | `lib/features/*/data/*_repository.dart` |
| Data (Firestore impls) | `FirestoreExpenseRepository`, `FirebaseAuthRepository`, … | `lib/features/*/data/firestore_*_repository.dart` |
| Presentation | Notifiers + StreamProviders | `lib/features/*/providers/` |
| UI | Screens + shared widgets | `lib/features/*/screens/`, `lib/core/widgets/` |

---

## Project structure

```
lib/
  core/
    l10n/locale_provider.dart          — Firestore-persisted locale
    navigation/main_screen.dart        — BottomAppBar + IndexedStack + FAB
    theme/app_theme.dart               — Material 3 theme definitions
    theme/theme_provider.dart          — Firestore-persisted ThemeMode
    widgets/category_icon.dart         — shared icon lookup + CategoryAvatar
  features/
    auth/                              — Google sign-in + user profile
    budgets/                           — monthly budget limits + summary
    categories/                        — category management
    categorization/                    — rule-based auto-categorization
    charts/                            — pie + bar chart
    expenses/                          — expense CRUD
    profile/                           — user settings
    reports/                           — monthly report (not in nav)
  l10n/
    app_{de,en,uk}.arb                 — translation strings
    generated/                         — flutter gen-l10n output
  main.dart
  firebase_options.dart                — gitignored (see Setup)

test/
  core/widgets/                        — icon mapping tests
  fakes/                               — in-memory repository implementations
  features/                            — model / repository / notifier / screen tests
```

---

## Getting started

### Prerequisites

- Flutter 3.11+ (`flutter --version`)
- A Firebase project (free tier is sufficient)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) installed

### Setup

Firebase configuration files are gitignored to keep this public repo free of
project metadata. To run locally, configure your own Firebase project:

```bash
# 1. Clone
git clone https://github.com/Kanzatuwka/expense_tracker.git
cd expense_tracker

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase — creates lib/firebase_options.dart
flutterfire configure

# 4. For Android: copy google-services.json from Firebase Console to:
#    android/app/google-services.json

# 5. Run
flutter run
```

On the first Google sign-in the app will automatically:

- Create a `users/{uid}` profile document
- Seed five default categories (Essen, Transport, Gesundheit, Freizeit,
  Sonstiges)

### Firestore data model

```
users/{userId}
  subscriptionStatus:        'free' | 'premium'
  preferredLanguage:         'de' | 'en' | 'uk'
  preferredTheme:            'light' | 'dark' | 'system'
  lastBudgetSummaryYear:     int?      (tracks monthly summary display)
  lastBudgetSummaryMonth:    int?
  createdAt:                 Timestamp

users/{userId}/categories/{categoryId}
  name, icon, isCustom, isDefault, createdAt

users/{userId}/budgets/{categoryId}     ← doc ID = categoryId
  amount:  double                       (monthly limit in €)

users/{userId}/budgetMonths/{YYYY-MM}   ← e.g. "2026-04"
  budgets: {categoryId: amount}         (snapshot of limits active that month)

expenses/{expenseId}
  userId, categoryId, amount, date, note, createdAt
```

### Firestore security rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /categories/{categoryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /budgets/{budgetId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /budgetMonths/{monthId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /expenses/{expenseId} {
      allow read: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Running tests

```bash
flutter test
```

104 tests covering:

- **Model parsing** including backward compatibility with the legacy
  `category` field on older expense documents
- **In-memory repository fakes** for `Expense`, `Category`, `Auth`, and
  `UserProfile` — used both as test fixtures and as their own test subjects
- **Notifier orchestration** via `ProviderContainer` with provider overrides
  — no Firebase mocks, no platform channels
- **Contract tests** (e.g. every seed icon name has a matching entry in
  `kCategoryIcons` so the UI never silently shows a fallback for a default
  category)
- **Widget tests** for expense list, expense form (create + edit), and
  profile screen

---

## Implemented features

### Authentication
- Google OAuth, `authStateProvider` (StreamProvider)
- On first login: create `users/{uid}` document + seed 5 default categories
- Automatic navigation via auth stream

### Expenses
- Full CRUD: create, edit (`ExpenseFormScreen` for both modes), delete
- **`ExpensesListScreen`**: total amount, category filter chips, month navigation
  (prev / next arrows), swipe-to-delete with confirmation dialog
- **Day-grouped list**: expenses grouped under "Today / Yesterday / 4 May 2026"
  headers, sorted descending; note shown as subtitle only when non-empty
- **`ExpenseFormScreen`** (redesigned): large centered amount input with quick-add
  chips (+5 / +10 / +20 / +50), category icon grid (4 columns), `SegmentedButton`
  date selector (Today / Yesterday / Other date with DatePicker), free-text note
  field with live auto-categorization suggestion; Save disabled when amount = 0
- `ExpenseDetailScreen`: detail view with edit / delete actions

### Categories
- 5 default categories: Essen, Transport, Gesundheit, Freizeit, Sonstiges
- `CategoriesScreen`: list (default + custom), create / delete custom
- `localizedCategoryName()` — localized names for default categories in
  all three languages

### Navigation
- `BottomAppBar` with 4 tabs + central FAB: Records | Chart | + | Budget | Me
- `IndexedStack` preserves state on tab switch

### Profile
- Display name, photo, email
- Theme selector (light / dark / system) — persisted in Firestore
- Language selector (de / en / uk) — persisted in Firestore
- Manage categories shortcut, sign-out with confirmation dialog

### Theming
- Light / Dark / System via `ThemeMode`, persisted per user in Firestore

### Localization
- German / English / Ukrainian via `flutter_localizations` + `intl`
- Generated via `flutter gen-l10n` (`l10n.yaml`)
- `DateFormat('LLLL y', locale)` for nominative month names (fixes Ukrainian)

### Categorization
- `CategorizationService` — abstract interface (DIP)
- `RuleBasedCategorizationService` — v1, keyword-based, unit-tested
- Suggested category updates live as the user types the note

### Charts
- `ChartScreen`: PieChart (spending by category) + BarChart (last 6 months)
- Month navigation with prev / next arrows

### Budgets
- Per-category monthly limits: set, edit, delete
- `LinearProgressIndicator` color-coded: green (<75%), orange (75–99%), red (≥100%)
- **In-app budget warnings**: SnackBar on expense save — orange at ≥75%,
  red when exceeded; edit mode subtracts the old amount before computing
  the new total
- **Monthly summary dialog**: shown on first Budget-tab visit of a new month;
  displays previous month's limit vs. actual spending per category with
  progress bars
- **Historical limit snapshots** (`budgetMonths/{YYYY-MM}`): written on every
  setBudget / deleteBudget so the summary always shows the limits that were
  active last month, not the current ones

---

## Roadmap

### v2+ — planned (do not pre-build)

- `EntitlementService` — feature access control (Free / Premium)
- RevenueCat — subscription management
- AdMob — rewarded ads for limited AI usage on free tier
- Gemini API — AI-powered categorization (`CategorizationService` v2 impl)
- Extended reports screen with premium analytics

---

## License

To be added.
