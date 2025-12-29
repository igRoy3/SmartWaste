enum UserRole {
  citizen,
  admin,
  collector,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.citizen:
        return 'citizen';
      case UserRole.admin:
        return 'admin';
      case UserRole.collector:
        return 'collector';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'citizen':
        return UserRole.citizen;
      case 'admin':
        return UserRole.admin;
      case 'collector':
        return UserRole.collector;
      default:
        return UserRole.citizen;
    }
  }
}

class User {
  final int id;
  final String uid;
  final String? email;
  final String? name;
  final UserRole role;

  User({
    required this.id,
    required this.uid,
    this.email,
    this.name,
    this.role = UserRole.citizen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      uid: json['uid'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      role: UserRoleExtension.fromString(json['role'] as String? ?? 'citizen'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.value,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
