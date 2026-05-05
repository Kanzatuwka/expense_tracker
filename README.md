# Ausgaben Tracker

A personal expense tracking app for the German-speaking market, built with
Flutter + Firebase. Organized as a long-lived, modular codebase — layered
according to Clean Architecture principles with strict separation between
domain, data, and presentation, and a test suite that runs entirely in pure
Dart with no Firebase initialization required.

**Status:** v1 (core CRUD + auth) complete · **45 tests passing** ·
v2 features in progress.

---

## Stack

- **Flutter** (Dart) with Material 3
- **Riverpod 3** — state management (Notifier + StreamProvider)
- **Firebase Auth** — Google OAuth sign-in
- **Cloud Firestore** — real-time data, per-user security rules
- **flutter_test** — unit tests via `ProviderContainer` with provider overrides

---

## Architecture

The codebase follows Clean Architecture's dependency rule: **inner layers
know nothing about outer layers**. Concretely:

- **Domain entities** (`Expense`, `Category`, `AuthUser`, …) are pure Dart
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
| Domain | `Expense`, `Category`, `AuthUser`, `AuthException` | `lib/features/*/models/` |
| Data (interfaces) | `ExpenseRepository`, `CategoryRepository`, `AuthRepository`, `UserProfileRepository` | `lib/features/*/data/*_repository.dart` |
| Data (Firestore impls) | `FirestoreExpenseRepository`, `FirebaseAuthRepository`, … | `lib/features/*/data/firestore_*_repository.dart` |
| Presentation | Notifiers + StreamProviders | `lib/features/*/providers/` |
| UI | Screens + shared widgets | `lib/features/*/screens/`, `lib/core/widgets/` |

---

## Project structure

```
lib/
  core/
    navigation/main_screen.dart        — bottom-nav shell + central FAB
    widgets/category_icon.dart          — shared icon lookup + CategoryAvatar
  features/
    auth/                               — Google sign-in
      data/                             — AuthRepository, UserProfileRepository
      models/                           — AuthUser, AuthException (pure Dart)
      providers/                        — AuthNotifier (orchestrates sign-in)
      screens/                          — LoginScreen
    expenses/                           — expense CRUD
      data/                             — ExpenseRepository + Firestore impl
      models/expense.dart               — pure Dart entity
      providers/                        — ExpensesNotifier + StreamProvider
      screens/                          — list / detail / create
    categories/                         — category management
    charts/                             — placeholder (v2)
    reports/                            — placeholder (v2)
    profile/                            — placeholder (v2)
  main.dart
  firebase_options.dart                  — gitignored (see Setup)

test/
  core/widgets/                          — icon mapping tests
  fakes/                                 — in-memory repository implementations
  features/                              — model / repository / notifier tests
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
git clone https://github.com/<your-username>/expense-tracker.git
cd expense-tracker

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
  subscriptionStatus:  'free' | 'premium'
  preferredLanguage:   'de' | 'en' | 'uk'
  preferredTheme:      'light' | 'dark' | 'system'
  createdAt:           Timestamp

users/{userId}/categories/{categoryId}
  name, icon, isCustom, isDefault, createdAt

expenses/{expenseId}
  userId, categoryId, amount, date, note, createdAt
```

### Firestore security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /categories/{categoryId} {
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

45 tests covering:

- **Model parsing** including backward compatibility with the legacy
  `category` field on older expense documents
- **In-memory repository fakes** for `Expense`, `Category`, `Auth`, and
  `UserProfile` — used both as test fixtures and as their own test subjects
- **Notifier orchestration** via `ProviderContainer` with provider overrides
  — no Firebase mocks, no platform channels
- **Contract tests** (e.g. every seed icon name has a matching entry in
  `kCategoryIcons` so the UI never silently shows a fallback for a default
  category)

---

## Roadmap

### Implemented (v1)

- Google sign-in with auto user-profile + default-categories seeding
- Expense CRUD with category filter and real-time Firestore streams
- Bottom-nav shell with central FAB

### v2 — in progress

- Profile screen (display name, photo, sign-out, settings)
- Categories screen (list / create custom / delete)
- Expense edit screen + swipe-to-delete on the list
- Theming (light / dark / system, persisted in Firestore)
- Localization: de / en / uk via `flutter_localizations` + `.arb`

### v2+ — planned

- `CategorizationService` interface with two implementations:
  - keyword-based (free, v1)
  - Gemini API (premium, v2)
- ChartScreen — pie chart by category, bar chart by month
- ReportScreen — monthly summary, top categories, month-over-month diff
- Premium tier via RevenueCat + ad-supported AI quota via AdMob for free tier

---

## License

To be added.
