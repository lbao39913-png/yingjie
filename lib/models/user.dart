import 'json_values.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar = '',
    this.createdAt,
  });

  final String id;
  final String username;
  final String nickname;
  final String avatar;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    final username = JsonValues.string(json['username']);
    final nickname = JsonValues.string(json['nickname']);
    return User(
      id: JsonValues.string(json['id']),
      username: username,
      nickname: nickname.isEmpty ? username : nickname,
      avatar: JsonValues.string(json['avatar']),
      createdAt: JsonValues.date(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
}

enum AuthStatus {
  unknown,
  loggedOut,
  loading,
  loggedIn,
  error,
}

class AuthSnapshot {
  const AuthSnapshot({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage = '',
  });

  final AuthStatus status;
  final User? user;
  final String errorMessage;

  bool get isLoggedIn => status == AuthStatus.loggedIn && user != null;

  AuthSnapshot copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthSnapshot(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
