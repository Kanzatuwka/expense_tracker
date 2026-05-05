import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/auth/screens/login_screen.dart';
import 'package:expense_tracker/core/navigation/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // Flutter-Widgets initialisieren
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialisieren
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Authentifizierungsstatus beobachten
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Ausgaben Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Je nach Authentifizierungsstatus den richtigen Screen anzeigen
      home: authState.when(
        data: (user) => user != null ? const MainScreen() : const LoginScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => const LoginScreen(),
      ),
    );
  }
}
