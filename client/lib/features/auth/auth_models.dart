class DeuNestUser {
  const DeuNestUser({
    required this.id,
    required this.email,
    this.displayName,
    this.role = 'USER',
    this.ageRange,
    this.gender,
    this.timeZone = 'Africa/Cairo',
  });

  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? ageRange;
  final String? gender;
  final String timeZone;

  factory DeuNestUser.fromJson(Map<String, dynamic> json) => DeuNestUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        role: json['role'] as String? ?? 'USER',
        ageRange: json['ageRange'] as String?,
        gender: json['gender'] as String?,
        timeZone: json['timeZone'] as String? ?? 'Africa/Cairo',
      );
}

class AuthSession {
  const AuthSession({required this.user, required this.accessToken});

  final DeuNestUser user;
  final String accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: DeuNestUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
      );

  AuthSession copyWith({DeuNestUser? user, String? accessToken}) {
    return AuthSession(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
