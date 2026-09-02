class DeuNestUser {
  const DeuNestUser(
      {required this.id,
      required this.email,
      this.displayName,
      this.role = 'USER',
      this.ageRange,
      this.gender});

  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? ageRange;
  final String? gender;

  factory DeuNestUser.fromJson(Map<String, dynamic> json) => DeuNestUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        role: json['role'] as String? ?? 'USER',
        ageRange: json['ageRange'] as String?,
        gender: json['gender'] as String?,
      );
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final DeuNestUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        user: DeuNestUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
