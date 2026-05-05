import 'package:expense_tracker/features/auth/data/user_profile_repository.dart';

/// In-Memory-Implementierung von [UserProfileRepository] für Tests.
class InMemoryUserProfileRepository implements UserProfileRepository {
  /// Bereits existierende userIds — Aufrufe für diese liefern `false`.
  final Set<String> _existing;

  /// Anzahl der Aufrufe pro userId — nützlich für "wurde aufgerufen" Assertions.
  final Map<String, int> callCounts = {};

  InMemoryUserProfileRepository({Set<String>? existingUsers})
    : _existing = {...?existingUsers};

  @override
  Future<bool> createIfMissing(String userId) async {
    callCounts[userId] = (callCounts[userId] ?? 0) + 1;
    if (_existing.contains(userId)) return false;
    _existing.add(userId);
    return true;
  }

  bool exists(String userId) => _existing.contains(userId);
}
