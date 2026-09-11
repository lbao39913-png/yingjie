import '../../models/user.dart';

abstract class AuthApi {
  Future<AuthSession> register({
    required String account,
    required String password,
  });

  Future<AuthSession> login({
    required String account,
    required String password,
  });

  Future<void> logout({required String accessToken});

  Future<User> getCurrentUser({required String accessToken});

  Future<AuthSession> refreshToken({required String refreshToken});
}
