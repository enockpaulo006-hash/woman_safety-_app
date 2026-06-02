class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final int id;
  final String fullName;
  final String email;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "full_name": fullName,
      "email": email,
    };
  }

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json["id"] as int,
      fullName: json["full_name"] as String? ?? "",
      email: json["email"] as String? ?? "",
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthenticatedUser user;

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "user": user.toJson(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json["token"] as String,
      user: AuthenticatedUser.fromJson(json["user"] as Map<String, dynamic>),
    );
  }

  factory AuthSession.fromAuthResponse(Map<String, dynamic> json) {
    return AuthSession(
      token: json["token"] as String,
      user: AuthenticatedUser.fromJson(json["user"] as Map<String, dynamic>),
    );
  }
}

