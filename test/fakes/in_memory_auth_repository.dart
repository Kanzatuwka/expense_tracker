import 'dart:async';

import 'package:expense_tracker/features/auth/data/auth_repository.dart';
import 'package:expense_tracker/features/auth/models/auth_exception.dart';
import 'package:expense_tracker/features/auth/models/auth_user.dart';

/// In-Memory-Implementierung von [AuthRepository] für Tests.
///
/// Erlaubt Tests, einen Login zu simulieren ohne Firebase-Initialisierung.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({
    AuthUser? initialUser,
    AuthUser? signInResult = const AuthUser(
      uid: 'test_user',
      email: 'test@example.com',
      displayName: 'Test User',
    ),
    AuthException? signInError,
  }) : _user = initialUser,
       _signInResult = signInResult,
       _signInError = signInError;

  AuthUser? _user;
  final AuthUser? _signInResult;
  final AuthException? _signInError;
  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();

  /// Setzt den aktuellen Benutzer manuell und emittiert auf den Stream.
  /// Hilfreich um Test-Szenarien wie "Benutzer ist bereits angemeldet" aufzubauen.
  void setUser(AuthUser? user) {
    _user = user;
    if (!_changes.isClosed) _changes.add(user);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  String? get currentUserId => _user?.uid;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<AuthUser?> signInWithGoogle() async {
    if (_signInError != null) throw _signInError;
    setUser(_signInResult);
    return _signInResult;
  }

  @override
  Future<void> signOut() async {
    setUser(null);
  }

  Future<void> dispose() => _changes.close();
}
