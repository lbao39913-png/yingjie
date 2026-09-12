import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_args.dart';
import '../../app/theme.dart';
import '../../models/cloud_video.dart';
import '../../widgets/async_feedback.dart';
import 'private_videos_controller.dart';

class PrivateVideosPage extends ConsumerStatefulWidget {
  const PrivateVideosPage({super.key});

  @override
  ConsumerState<PrivateVideosPage> createState() => _PrivateVideosPageState();
}

class _PrivateVideosPageState extends ConsumerState<PrivateVideosPage> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _open(CloudVideo video) async {
    try {
      final url =
          await ref.read(privateVideosControllerProvider.notifier).playUrlFor(video);
      if (!mounted) {
        return;
      }
      final args = PlayerRouteArgs(
        mediaId: video.id,
        title: video.title,
        playUrl: url,
        cover: video.cover,
      );
      context.pushNamed(
        'player',
        pathParameters: {'id': args.mediaId},
        queryParameters: args.toQuery(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privateVideosControllerProvider);
    final controller = ref.read(privateVideosControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('隐私视频')),
      body: switch (state.gate) {
        PrivateGate.login => EmptyPanel(
            message: '登录后才能查看隐私视频',
            actionLabel: '去登录',
            onAction: () => context.push('/login'),
          ),
        PrivateGate.setupPin => _PinForm(
            title: '设置隐私 PIN',
            subtitle: '请设置 4 到 6 位数字 PIN，用于保护隐私视频',
            pin: _pin,
            confirm: _confirm,
            showConfirm: true,
            busy: state.busy,
            error: state.error?.message,
            submitLabel: '保存 PIN',
            onSubmit: () => controller.setupPin(
              pin: _pin.text,
              confirmPin: _confirm.text,
            ),
          ),
        PrivateGate.locked => _PinForm(
            title: '验证 PIN',
            subtitle: '隐私视频需验证后查看',
            pin: _pin,
            confirm: _confirm,
            showConfirm: false,
            busy: state.busy,
            error: state.error?.message,
            submitLabel: '解锁',
            onSubmit: () => controller.unlock(_pin.text),
          ),
        PrivateGate.open => state.items.isEmpty
            ? const EmptyPanel(message: '还没有隐私视频')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final video = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: YingjieTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: Key('private-video-${video.id}'),
                        onTap: () => _open(video),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: const TextStyle(
                                  color: YingjieTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '仅自己可见',
                                style: TextStyle(
                                  color: YingjieTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    key: Key('private-public-${video.id}'),
                                    onPressed: () => controller.setPublic(video),
                                    child: const Text('移出隐私'),
                                  ),
                                  TextButton(
                                    key: Key('private-delete-${video.id}'),
                                    onPressed: () =>
                                        controller.deleteCloud(video.id),
                                    child: const Text('删除云端'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      },
    );
  }
}

class _PinForm extends StatelessWidget {
  const _PinForm({
    required this.title,
    required this.subtitle,
    required this.pin,
    required this.confirm,
    required this.showConfirm,
    required this.busy,
    required this.submitLabel,
    required this.onSubmit,
    this.error,
  });

  final String title;
  final String subtitle;
  final TextEditingController pin;
  final TextEditingController confirm;
  final bool showConfirm;
  final bool busy;
  final String submitLabel;
  final Future<bool> Function() onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          title,
          style: const TextStyle(
            color: YingjieTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: YingjieTheme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('privacy-pin'),
          controller: pin,
          enabled: !busy,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'PIN',
            hintText: '4 到 6 位数字',
          ),
        ),
        if (showConfirm) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('privacy-pin-confirm'),
            controller: confirm,
            enabled: !busy,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '确认 PIN',
            ),
          ),
        ],
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            key: const Key('privacy-error'),
            style: const TextStyle(color: YingjieTheme.danger),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('privacy-submit'),
          onPressed: busy ? null : onSubmit,
          child: Text(submitLabel),
        ),
      ],
    );
  }
}
