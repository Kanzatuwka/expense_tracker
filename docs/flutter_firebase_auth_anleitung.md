# Flutter + Firebase Auth mit Riverpod
## Schritt-für-Schritt Anleitung

---

## Übersicht

In dieser Anleitung wird ein Flutter-Projekt von Grund auf erstellt und mit Firebase Authentication verbunden. Nach dem Login landet der Benutzer automatisch auf dem Ausgaben-Screen. Nach dem Logout kehrt er zum Login-Screen zurück — ohne manuelle Navigation.

**Verwendete Technologien:**
- Flutter 3.x
- Firebase Authentication (E-Mail / Passwort)
- Cloud Firestore
- Riverpod 2+ (State Management)
- FlutterFire CLI

---

## Schritt 1 – Flutter-Projekt erstellen

```bash
flutter create expense_tracker
cd expense_tracker
```

---

## Schritt 2 – Abhängigkeiten hinzufügen

In `pubspec.yaml` unter `dependencies` eintragen:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^4.6.0
  firebase_auth: ^6.3.0
  cloud_firestore: ^6.2.0
  # State Management
  flutter_riverpod: ^3.3.1
```

Dann im Terminal:

```bash
flutter pub get
```

**Warum diese Pakete?**
- `firebase_core` — Pflicht für jede Firebase-Integration, initialisiert Firebase in der App
- `firebase_auth` — stellt die Authentifizierungsfunktionen bereit (Login, Logout, Auth-Status)
- `cloud_firestore` — Zugriff auf die Firestore-Datenbank
- `flutter_riverpod` — modernes State Management, ermöglicht reaktive UI-Updates

---

## Schritt 3 – Firebase verbinden mit FlutterFire CLI

FlutterFire CLI installieren:

```bash
dart pub global activate flutterfire_cli
```

Firebase-Projekt konfigurieren:

```bash
flutterfire configure
```

Die CLI fragt nach dem Firebase-Projekt und den Zielplattformen (z. B. Android, Web). Danach wird automatisch die Datei `lib/firebase_options.dart` generiert — sie enthält alle plattformspezifischen Firebase-Konfigurationswerte und wird von `Firebase.initializeApp()` verwendet.

---

## Schritt 4 – Projektstruktur anlegen

Feature-first Struktur — jede Funktion hat ihren eigenen Ordner:

```
lib/
  features/
    auth/
      screens/
        login_screen.dart
      providers/
        auth_provider.dart
    expenses/
      screens/
        expenses_list_screen.dart
        expense_detail_screen.dart
        expense_create_screen.dart
      providers/
        expenses_provider.dart
      models/
        expense.dart
  main.dart
  firebase_options.dart
```

Ordner im Terminal erstellen:

```bash
mkdir -p lib/features/auth/screens
mkdir -p lib/features/auth/providers
mkdir -p lib/features/expenses/screens
mkdir -p lib/features/expenses/providers
mkdir -p lib/features/expenses/models
```

**Warum feature-first?**
Jede Funktion (Auth, Expenses) ist in sich geschlossen — eigene Screens, Provider und Modelle. Das macht den Code übersichtlich und leicht erweiterbar.

---

## Schritt 5 – main.dart

```dart
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/auth/screens/login_screen.dart';
import 'package:expense_tracker/features/expenses/screens/expenses_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Flutter-Widgets müssen vor Firebase initialisiert werden
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase mit den generierten Optionen initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // ProviderScope ist die Voraussetzung für Riverpod — umschließt die gesamte App
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authStateProvider beobachten — reagiert auf Login/Logout in Echtzeit
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Ausgaben Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Automatische Navigation je nach Authentifizierungsstatus
      home: authState.when(
        data: (user) => user != null
            ? const ExpensesListScreen()  // eingeloggt
            : const LoginScreen(),        // nicht eingeloggt
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const LoginScreen(),
      ),
    );
  }
}
```

**Wichtige Konzepte:**

`WidgetsFlutterBinding.ensureInitialized()` — stellt sicher, dass Flutter bereit ist, bevor asynchrone Operationen wie `Firebase.initializeApp()` ausgeführt werden.

`ProviderScope` — muss die gesamte App umschließen. Ohne ihn funktioniert Riverpod nicht.

`ConsumerWidget` statt `StatelessWidget` — ermöglicht den Zugriff auf `ref`, mit dem Provider beobachtet werden können.

`authState.when()` — wertet den Zustand des `StreamProvider` aus. Der Stream liefert drei mögliche Zustände: `data` (Daten vorhanden), `loading` (wird geladen), `error` (Fehler aufgetreten). So wechselt die App automatisch zwischen Login- und Ausgaben-Screen — ohne manuelle Navigation.

---

## Schritt 6 – auth_provider.dart

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// StreamProvider: beobachtet den Auth-Status in Echtzeit
// Gibt User-Objekt zurück wenn eingeloggt, null wenn nicht eingeloggt
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Notifier: kapselt die Anmelde- und Abmeldelogik
class AuthNotifier extends Notifier<AsyncValue<User?>> {
  final _auth = FirebaseAuth.instance;

  @override
  AsyncValue<User?> build() => const AsyncValue.data(null);

  // Benutzer anmelden
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Firebase-Fehlercodes in lesbare deutsche Meldungen übersetzen
      throw _translateError(e.code);
    }
  }

  // Benutzer abmelden
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firebase Fehlercodes auf Deutsch übersetzen
  String _translateError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kein Benutzer mit dieser E-Mail gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      case 'user-disabled':
        return 'Dieser Account wurde deaktiviert';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte später erneut versuchen';
      default:
        return 'Anmeldung fehlgeschlagen. Bitte erneut versuchen';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(() {
  return AuthNotifier();
});
```

**Wichtige Konzepte:**

`StreamProvider<User?>` — abonniert den Firebase Auth-Stream `authStateChanges()`. Dieser Stream sendet automatisch ein neues Ereignis, wenn sich der Auth-Status ändert (Login oder Logout). Der `main.dart` reagiert darauf und wechselt den Screen.

`Notifier` — moderner Riverpod 2+ Ersatz für den veralteten `StateNotifier`. Die Methode `build()` gibt den Anfangszustand zurück.

`FirebaseAuthException` — Firebase wirft bei Fehlern immer diese Exception mit einem `code`-Feld. Es ist wichtig, genau diesen Typ abzufangen, um die Fehlercodes auswerten zu können.

`NotifierProvider` — registriert den `AuthNotifier` als Provider, damit er in der gesamten App über `ref.read(authProvider.notifier)` verfügbar ist.

---

## Schritt 7 – login_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // Controller freigeben wenn Screen entfernt wird — verhindert Memory Leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Anmeldung durchführen
  Future<void> _signIn() async {
    // Formular validieren — bricht ab wenn Felder ungültig sind
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    } catch (e) {
      // Fehlermeldung als SnackBar anzeigen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Ladezustand zurücksetzen — auch bei Fehler
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titel
                Text(
                  'Ausgaben Tracker',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // E-Mail Eingabefeld
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte E-Mail eingeben';
                    }
                    if (!value.contains('@')) {
                      return 'Ungültige E-Mail-Adresse';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Passwort Eingabefeld
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Passwort eingeben';
                    }
                    if (value.length < 6) {
                      return 'Passwort muss mindestens 6 Zeichen haben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Anmelden Button — deaktiviert während des Ladens
                FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Anmelden'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Wichtige Konzepte:**

`ConsumerStatefulWidget` — Kombination aus `StatefulWidget` und Riverpod `ConsumerWidget`. Notwendig wenn sowohl lokaler State (`setState`) als auch Riverpod-Provider (`ref`) gebraucht werden.

`GlobalKey<FormState>` — ermöglicht den Zugriff auf den Formular-Zustand von außen. Mit `_formKey.currentState!.validate()` werden alle Validatoren der Felder ausgeführt.

`TextEditingController` — steuert den Text in einem `TextField`. Muss in `dispose()` freigegeben werden, um Memory Leaks zu vermeiden.

`mounted` — prüft ob der Widget noch im Widget-Tree vorhanden ist. Wichtig bei asynchronen Operationen — ohne diese Prüfung kann es zu Fehlern kommen wenn der Screen während des Ladens verlassen wird.

`ref.read()` statt `ref.watch()` — in Event-Handlern wie `_signIn()` wird `ref.read()` verwendet, weil kein Rebuild ausgelöst werden soll. `ref.watch()` gehört nur in die `build()`-Methode.

---

## Schritt 8 – expenses_list_screen.dart (vorläufig)

Temporärer Screen als Platzhalter — wird in der nächsten Lektion ausgebaut:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Ausgaben'),
        actions: [
          // Abmelden — löst authStateProvider aus, App wechselt zu LoginScreen
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Ausgaben werden hier angezeigt'),
      ),
    );
  }
}
```

---

## Auth Flow — Zusammenfassung

```
App startet
    │
    ▼
Firebase.initializeApp()
    │
    ▼
authStateProvider (Stream) beobachten
    │
    ├── user == null  →  LoginScreen
    │       │
    │       └── signIn() aufrufen
    │               │
    │               └── Erfolg → Firebase sendet neues Event
    │                               │
    │                               └── user != null → ExpensesListScreen
    │
    └── user != null  →  ExpensesListScreen
            │
            └── signOut() aufrufen
                    │
                    └── Firebase sendet neues Event
                            │
                            └── user == null → LoginScreen
```

Der entscheidende Punkt: Die Navigation passiert **automatisch** durch den Stream — es wird kein `Navigator.push()` benötigt. Wenn Firebase den Auth-Status ändert, sendet `authStateChanges()` ein neues Event, `authStateProvider` aktualisiert sich, und `main.dart` rendert den richtigen Screen.
