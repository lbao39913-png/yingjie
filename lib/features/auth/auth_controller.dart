import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../services/auth_service.dart';

class AuthFormState {
  const AuthFormState({
    this.busy = false,
    this.errorMessage = '',
  });

  final bool busy;
  final String errorMessage;

  AuthFormState copyWith({
    bool? busy,
    String? errorMessage,
  }) {
    return AuthFormState(
      busy: busy ?? this.busy,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthFormState> {
  AuthController(this._auth) : super(const AuthFormState());

  final AuthService _auth;

  Future<bool> login({
    required String account,
    required String password,
  }) {
    return _run(
      () => _auth.login(account: account, password: password),
      fallback: '账号或密码错误',
    );
  }

  Future<bool> register({
    required String account,
    required String password,
    required String confirmPassword,
  }) {
    return _run(
      () => _auth.register(
        account: account,
        password: password,
        confirmPassword: confirmPassword,
      ),
      fallback: '注册失败，请稍后重试',
    );
  }

  Future<bool> _run(
    Future<void> Function() action, {
    required String fallback,
  }) async {
    if (state.busy) {
      return false;
    }
    state = const AuthFormState(busy: true);
    try {
      await action();
      state = const AuthFormState();
      return true;
    } on AppException catch (error) {
      state = AuthFormState(errorMessage: error.message);
      return false;
    } catch (_) {
      state = AuthFormState(errorMessage: fallback);
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider.autoDispose<AuthController, AuthFormState>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
