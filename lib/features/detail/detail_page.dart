import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_args.dart';
import '../../app/theme.dart';
import '../../models/video.dart';
import '../../services/player_service.dart';
import '../../widgets/async_feedback.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/section_block.dart';
import '../../widgets/skeleton.dart';
import 'detail_controller.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(detailControllerProvider(videoId));
    final controller = ref.read(detailControllerProvider(videoId).notifier);

    return switch (state.status) {
      DetailStatus.loading => Scaffold(
          appBar: AppBar(title: const Text('详情')),
          body: const DetailSkeleton(),
        ),
      DetailStatus.error => Scaffold(
          appBar: AppBar(title: const Text('详情')),
          body: ErrorPanel(
            message: state.error?.message ?? '网络连接失败，请检查网络',
            onRetry: controller.load,
          ),
        ),
      DetailStatus.ready => Scaffold(
          body: _DetailReadyView(
            state: state,
            controller: controller,
          ),
        ),
    };
  }
}

class _DetailReadyView extends StatelessWidget {
  const _DetailReadyView({
    required this.state,
    required this.controller,
  });

  final DetailState state;
  final DetailController controller;

  void _play(BuildContext context) {
    _playLaunch(context, controller.resolveLaunch());
  }

  void _playEpisode(BuildContext context, String episodeId) {
    _playLaunch(context, controller.resolveEpisodeLaunch(episodeId));
  }

  void _playLaunch(BuildContext context, PlayLaunch? launch) {
    if (launch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前线路无法播放，请尝试其他线路')),
      );
      return;
    }
    _openPlayer(context, launch);
  }

  void _openPlayer(BuildContext context, PlayLaunch launch) {
    final args = PlayerRouteArgs(
      mediaId: launch.mediaId,
      title: launch.title,
      playUrl: launch.playUrl,
      episodeId: launch.episodeId,
      sourceId: launch.sourceId,
      cover: launch.cover,
      year: launch.year,
      genres: launch.genres,
    );
    context.pushNamed(
      'player',
      pathParameters: {'id': args.mediaId},
      queryParameters: args.toQuery(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = state.video!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          title: Text(video.title),
          actions: [
            IconButton(
              tooltip: state.favorited ? '取消收藏' : '收藏',
              onPressed: controller.toggleFavorite,
              icon: Icon(
                state.favorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: state.favorited ? YingjieTheme.danger : null,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroBackdrop(url: video.heroImage),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleRow(video: video),
                const SizedBox(height: 16),
                if (video.isTv)
                  _EpisodePicker(
                    video: video,
                    onPlay: (episodeId) => _playEpisode(context, episodeId),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _play(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('立即播放'),
                    ),
                  ),
                const SizedBox(height: 20),
                if (video.description.trim().isNotEmpty) ...[
                  const Text(
                    '简介',
                    style: TextStyle(
                      color: YingjieTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    style: const TextStyle(
                      color: YingjieTheme.textMuted,
                      height: 1.6,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (video.director != null && video.director!.trim().isNotEmpty)
                  _MetaLine(label: '导演', value: video.director!),
                if (video.actors.isNotEmpty)
                  _MetaLine(label: '主演', value: video.actors.join(' / ')),
              ],
            ),
          ),
        ),
        if (state.related.isNotEmpty)
          SliverToBoxAdapter(
            child: SectionBlock(
              title: '相关推荐',
              items: state.related,
              onTapVideo: (item) => context.push('/detail/${item.id}'),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CoverImage(url: url, borderRadius: 0),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x880B0D12),
                Color(0x000B0D12),
                YingjieTheme.background,
              ],
              stops: [0, 0.42, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: CoverImage(url: video.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                video.title,
                style: const TextStyle(
                  color: YingjieTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              if (video.subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  video.subtitle,
                  style: const TextStyle(
                    color: YingjieTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                _metaLine(video),
                style: const TextStyle(
                  color: YingjieTheme.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (video.genres.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genre in video.genres)
                      Chip(
                        label: Text(genre),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: YingjieTheme.card,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label：',
              style: const TextStyle(
                color: YingjieTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: YingjieTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _metaLine(Video video) {
  final parts = <String>[
    if (video.year != null) '${video.year}',
    if (video.region != null && video.region!.trim().isNotEmpty) video.region!,
    if (video.durationLabel != null) video.durationLabel!,
    if (video.rating != null) '${video.rating!.toStringAsFixed(1)} 分',
  ];
  return parts.join(' · ');
}

class _EpisodePicker extends StatelessWidget {
  const _EpisodePicker({
    required this.video,
    required this.onPlay,
  });

  final Video video;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选集',
          style: TextStyle(
            color: YingjieTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final episode in video.episodes)
              ActionChip(
                key: Key('episode-${episode.id}'),
                label: Text(episode.name),
                backgroundColor: YingjieTheme.card,
                side: BorderSide.none,
                onPressed: () => onPlay(episode.id),
              ),
          ],
        ),
      ],
    );
  }
}
