import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _account = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(authControllerProvider.notifier).login(
          account: _account.text,
          password: _password.text,
        );
    if (!mounted) {
      return;
    }
    if (ok) {
      context.go('/mine');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          TextField(
            key: const Key('login-account'),
            controller: _account,
            enabled: !state.busy,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '手机号 / 邮箱 / 用户名',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('login-password'),
            controller: _password,
            enabled: !state.busy,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
            ),
          ),
          if (state.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage,
              key: const Key('login-error'),
              style: const TextStyle(color: YingjieTheme.danger),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login-submit'),
            onPressed: state.busy ? null : _submit,
            child: Text(state.busy ? '登录中...' : '登录'),
          ),
          const SizedBox(height: 16),
          TextButton(
            key: const Key('login-go-register'),
            onPressed: state.busy ? null : () => context.push('/register'),
            child: const Text('还没有账号？注册'),
          ),
        ],
      ),
    );
  }
}
