import 'dart:async';

import 'package:expense_tracker/features/auth/data/user_profile_repository.dart';
import 'package:expense_tracker/features/auth/models/user_profile.dart';

/// In-Memory-Implementierung von [UserProfileRepository] für Tests.
class InMemoryUserProfileRepository implements UserProfileRepository {
  /// userId → UserProfile
  final Map<String, UserProfile> _store = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Anzahl der `createIfMissing`-Aufrufe pro userId — für "wurde aufgerufen"
  /// Assertions in bestehenden Tests.
  final Map<String, int> callCounts = {};

  InMemoryUserProfileRepository({Set<String>? existingUsers}) {
    if (existingUsers != null) {
      for (final userId in existingUsers) {
        _store[userId] = _defaultProfile(userId);
      }
    }
  }

  UserProfile _defaultProfile(String userId) => UserProfile(
    userId: userId,
    subscriptionStatus: 'free',
    preferredLanguage: 'de',
    preferredTheme: 'system',
    createdAt: DateTime.now(),
  );

  /// Erlaubt Tests, ein Profil mit konkreten Werten vorzubereiten.
  void seed(UserProfile profile) {
    _store[profile.userId] = profile;
    _emit();
  }

  bool exists(String userId) => _store.containsKey(userId);

  UserProfile? get(String userId) => _store[userId];

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Future<bool> createIfMissing(String userId) async {
    callCounts[userId] = (callCounts[userId] ?? 0) + 1;
    if (_store.containsKey(userId)) return false;
    _store[userId] = _defaultProfile(userId);
    _emit();
    return true;
  }

  @override
  Stream<UserProfile?> watchByUser(String userId) async* {
    yield _store[userId];
    await for (final _ in _changes.stream) {
      yield _store[userId];
    }
  }

  @override
  Future<void> updateTheme({
    required String userId,
    required String theme,
  }) async {
    final existing = _store[userId];
    if (existing == null) return;
    _store[userId] = existing.copyWith(preferredTheme: theme);
    _emit();
  }

  Future<void> dispose() => _changes.close();
}
