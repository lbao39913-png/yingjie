import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../models/video.dart';
import '../../widgets/async_feedback.dart';
import '../../widgets/poster_card.dart';
import '../../widgets/section_block.dart';
import '../../widgets/skeleton.dart';
import 'home_controller.dart';
import 'widgets/home_banner.dart';
import 'widgets/home_search_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: Column(
        children: [
          HomeSearchBar(onTap: () => context.push('/search')),
          Expanded(child: _HomeBody(state: state, controller: controller)),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.controller});

  final HomeState state;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case HomeStatus.loading:
        return const HomeSkeleton();
      case HomeStatus.error:
        return ErrorPanel(
          message: state.error?.message ?? '网络连接失败，请检查网络',
          onRetry: () {
            controller.load();
          },
        );
      case HomeStatus.empty:
        return const EmptyPanel(message: '暂无影视内容');
      case HomeStatus.ready:
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >
                notification.metrics.maxScrollExtent - 240) {
              controller.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            color: YingjieTheme.accent,
            onRefresh: () => controller.load(refresh: true),
            child: _HomeFeedView(state: state),
          ),
        );
    }
  }
}

class _HomeFeedView extends StatelessWidget {
  const _HomeFeedView({required this.state});

  final HomeState state;

  void _openDetail(BuildContext context, Video video) {
    context.push('/detail/${video.id}');
  }

  @override
  Widget build(BuildContext context) {
    final feed = state.feed!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        HomeBanner(
          items: feed.banners,
          onTap: (video) => _openDetail(context, video),
        ),
        SectionBlock(
          title: '热门影视',
          items: feed.hot,
          onTapVideo: (video) => _openDetail(context, video),
          onMore: () => context.go('/category'),
        ),
        SectionBlock(
          title: '最新更新',
          items: feed.latest,
          onTapVideo: (video) => _openDetail(context, video),
        ),
        SectionBlock(
          title: '电影',
          items: feed.movies,
          onTapVideo: (video) => _openDetail(context, video),
          onMore: () => context.go('/category'),
        ),
        SectionBlock(
          title: '电视剧',
          items: feed.series,
          onTapVideo: (video) => _openDetail(context, video),
          onMore: () => context.go('/category'),
        ),
        SectionBlock(
          title: '动漫',
          items: feed.anime,
          onTapVideo: (video) => _openDetail(context, video),
          onMore: () => context.go('/category'),
        ),
        SectionBlock(
          title: '综艺',
          items: feed.variety,
          onTapVideo: (video) => _openDetail(context, video),
          onMore: () => context.go('/category'),
        ),
        if (state.recommend.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              '更多推荐',
              style: TextStyle(
                color: YingjieTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.recommend.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.52,
              ),
              itemBuilder: (context, index) {
                final video = state.recommend[index];
                return PosterCard(
                  width: null,
                  video: video,
                  onTap: () => _openDetail(context, video),
                );
              },
            ),
          ),
        ],
        if (state.loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
