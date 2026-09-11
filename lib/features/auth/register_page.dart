import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(authControllerProvider.notifier).register(
          account: _account.text,
          password: _password.text,
          confirmPassword: _confirm.text,
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
      appBar: AppBar(title: const Text('注册')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          TextField(
            key: const Key('register-account'),
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
            key: const Key('register-password'),
            controller: _password,
            enabled: !state.busy,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-confirm'),
            controller: _confirm,
            enabled: !state.busy,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: '确认密码',
              hintText: '再次输入密码',
            ),
          ),
          if (state.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage,
              key: const Key('register-error'),
              style: const TextStyle(color: YingjieTheme.danger),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('register-submit'),
            onPressed: state.busy ? null : _submit,
            child: Text(state.busy ? '注册中...' : '注册'),
          ),
        ],
      ),
    );
  }
}
