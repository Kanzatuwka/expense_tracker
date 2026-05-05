/// Domain-Repräsentation des angemeldeten Benutzers.
///
/// Pure Dart — kein Wissen über Firebase oder Google Sign-In.
/// Wird aus `firebase_auth.User` in [FirebaseAuthRepository] gemappt.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoUrl);

  @override
  String toString() => 'AuthUser(uid: $uid, email: $email)';
}
