import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_args.dart';
import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../models/cloud_video.dart';
import '../../models/local_video.dart';
import '../../widgets/async_feedback.dart';
import 'library_controller.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  Future<void> _openCloud(
    BuildContext context,
    WidgetRef ref,
    CloudVideo video,
  ) async {
    try {
      final url = await ref
          .read(libraryControllerProvider.notifier)
          .playUrlFor(video);
      if (!context.mounted) {
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
      if (!context.mounted) {
        return;
      }
      final message = error is Exception ? error.toString() : '播放失败，请检查网络后重试';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _openLocal(BuildContext context, LocalVideo video) {
    final args = PlayerRouteArgs(
      mediaId: video.id,
      title: video.title,
      playUrl: video.playUrl,
      cover: video.cover,
    );
    context.pushNamed(
      'player',
      pathParameters: {'id': args.mediaId},
      queryParameters: args.toQuery(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryControllerProvider);
    final controller = ref.read(libraryControllerProvider.notifier);

    ref.listen<String>(
      libraryControllerProvider.select((value) => value.notice),
      (previous, next) {
        if (next.isEmpty) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
        controller.clearNotice();
      },
    );
    ref.listen<String?>(
      libraryControllerProvider.select((value) => value.error?.message),
      (previous, next) {
        if (next == null || next.isEmpty) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      },
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的视频'),
          actions: [
            TextButton(
              key: const Key('library-import'),
              onPressed: controller.importLocal,
              child: const Text('导入'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('library-tab-local'), text: '本地'),
              Tab(key: Key('library-tab-cloud'), text: '云端'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (AppConfig.useMockApi)
              const Material(
                color: YingjieTheme.surface,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    '当前为模拟云端，视频不会真正上传到服务器',
                    style: TextStyle(
                      color: YingjieTheme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _LocalPane(
                    items: state.local,
                    busyId: state.busyId,
                    loggedIn: state.loggedIn,
                    onOpen: (video) => _openLocal(context, video),
                    onRemove: (video) => controller.removeLocal(video.id),
                    onUpload: (video) => controller.uploadLocal(video),
                    onImport: controller.importLocal,
                  ),
                  _CloudPane(
                    loggedIn: state.loggedIn,
                    items: state.cloud,
                    busyId: state.busyId,
                    onLogin: () => context.push('/login'),
                    onOpen: (video) => _openCloud(context, ref, video),
                    onDelete: (video) => controller.deleteCloud(video.id),
                    onRetry: controller.retryCloud,
                    onPrivate: (video) => controller.setPrivate(video, true),
                    onRefresh: controller.pullCloud,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalPane extends StatelessWidget {
  const _LocalPane({
    required this.items,
    required this.busyId,
    required this.loggedIn,
    required this.onOpen,
    required this.onRemove,
    required this.onUpload,
    required this.onImport,
  });

  final List<LocalVideo> items;
  final String busyId;
  final bool loggedIn;
  final ValueChanged<LocalVideo> onOpen;
  final ValueChanged<LocalVideo> onRemove;
  final ValueChanged<LocalVideo> onUpload;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyPanel(
        message: '还没有导入本地视频',
        actionLabel: '导入视频',
        onAction: onImport,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final video = items[index];
        return _VideoTile(
          key: Key('local-video-${video.id}'),
          title: video.title,
          subtitle: _sizeLabel(video.sizeBytes),
          badge: '本地',
          busy: busyId == video.id,
          onTap: () => onOpen(video),
          actions: [
            if (loggedIn)
              TextButton(
                key: Key('local-upload-${video.id}'),
                onPressed: busyId == video.id ? null : () => onUpload(video),
                child: const Text('上传云端'),
              )
            else
              const SizedBox.shrink(),
            TextButton(
              key: Key('local-remove-${video.id}'),
              onPressed: () => onRemove(video),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
  }
}

class _CloudPane extends StatelessWidget {
  const _CloudPane({
    required this.loggedIn,
    required this.items,
    required this.busyId,
    required this.onLogin,
    required this.onOpen,
    required this.onDelete,
    required this.onRetry,
    required this.onPrivate,
    required this.onRefresh,
  });

  final bool loggedIn;
  final List<CloudVideo> items;
  final String busyId;
  final VoidCallback onLogin;
  final ValueChanged<CloudVideo> onOpen;
  final ValueChanged<CloudVideo> onDelete;
  final ValueChanged<CloudVideo> onRetry;
  final ValueChanged<CloudVideo> onPrivate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return EmptyPanel(
        message: '登录后查看云视频',
        actionLabel: '去登录',
        onAction: onLogin,
      );
    }
    if (items.isEmpty) {
      return EmptyPanel(
        message: '还没有云视频',
        actionLabel: '刷新',
        onAction: onRefresh,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final video = items[index];
        return _VideoTile(
          key: Key('cloud-video-${video.id}'),
          title: video.title,
          subtitle: _cloudSubtitle(video),
          badge: '云端',
          busy: busyId == video.id || video.isUploading,
          progress: video.isUploading ? video.progress : null,
          onTap: video.isUploaded ? () => onOpen(video) : null,
          actions: [
            if (video.isFailed)
              TextButton(
                key: Key('cloud-retry-${video.id}'),
                onPressed: () => onRetry(video),
                child: const Text('重试'),
              ),
            if (video.isUploaded)
              TextButton(
                key: Key('cloud-private-${video.id}'),
                onPressed: () => onPrivate(video),
                child: const Text('设为隐私'),
              ),
            TextButton(
              key: Key('cloud-delete-${video.id}'),
              onPressed: () => onDelete(video),
              child: const Text('删除云端'),
            ),
          ],
        );
      },
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.actions,
    this.onTap,
    this.busy = false,
    this.progress,
  });

  final String title;
  final String subtitle;
  final String badge;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final bool busy;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: YingjieTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: YingjieTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: YingjieTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: YingjieTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (busy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: YingjieTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sizeLabel(int bytes) {
  if (bytes <= 0) {
    return '本地视频';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _cloudSubtitle(CloudVideo video) {
  if (video.isFailed) {
    return '上传失败，可重试';
  }
  if (video.isUploading) {
    return '正在上传 ${(video.progress * 100).clamp(0, 100).toStringAsFixed(0)}%';
  }
  if (!video.isUploaded) {
    return '等待上传';
  }
  return _sizeLabel(video.sizeBytes);
}
