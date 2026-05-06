/// Domain-Entität: Benutzerprofil unter `users/{userId}`.
///
/// Pure Dart — keine Abhängigkeit von Firestore oder Flutter.
/// Konvertierung von Firestore-spezifischen Typen erfolgt in
/// [FirestoreUserProfileRepository] an der Datenschicht-Grenze.
class UserProfile {
  final String userId;
  final String subscriptionStatus; // 'free' | 'premium'
  final String preferredLanguage; // 'de' | 'en' | 'uk'
  final String preferredTheme; // 'light' | 'dark' | 'system'
  final DateTime createdAt;
  final int? lastBudgetSummaryYear;
  final int? lastBudgetSummaryMonth;

  const UserProfile({
    required this.userId,
    required this.subscriptionStatus,
    required this.preferredLanguage,
    required this.preferredTheme,
    required this.createdAt,
    this.lastBudgetSummaryYear,
    this.lastBudgetSummaryMonth,
  });

  /// Konvertiert eine Map mit primitiven Dart-Typen in ein [UserProfile].
  /// Fehlende Felder werden mit sicheren Defaults befüllt.
  factory UserProfile.fromMap(Map<String, dynamic> data, String id) {
    return UserProfile(
      userId: id,
      subscriptionStatus: data['subscriptionStatus'] as String? ?? 'free',
      preferredLanguage: data['preferredLanguage'] as String? ?? 'de',
      preferredTheme: data['preferredTheme'] as String? ?? 'system',
      createdAt: data['createdAt'] as DateTime,
      lastBudgetSummaryYear: data['lastBudgetSummaryYear'] as int?,
      lastBudgetSummaryMonth: data['lastBudgetSummaryMonth'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionStatus': subscriptionStatus,
      'preferredLanguage': preferredLanguage,
      'preferredTheme': preferredTheme,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? subscriptionStatus,
    String? preferredLanguage,
    String? preferredTheme,
  }) {
    return UserProfile(
      userId: userId,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredTheme: preferredTheme ?? this.preferredTheme,
      createdAt: createdAt,
      lastBudgetSummaryYear: lastBudgetSummaryYear,
      lastBudgetSummaryMonth: lastBudgetSummaryMonth,
    );
  }
}
