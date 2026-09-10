import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/video.dart';
import '../../widgets/async_feedback.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/skeleton.dart';
import 'search_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  SearchController get _controller => ref.read(searchControllerProvider.notifier);

  void _submit([String? value]) {
    final keyword = value ?? _input.text;
    _input.text = keyword;
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    _focus.unfocus();
    _controller.submit(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          _SearchInputBar(
            controller: _input,
            focusNode: _focus,
            onChanged: _controller.onQueryChanged,
            onSubmitted: _submit,
            onClear: () {
              _input.clear();
              _controller.onQueryChanged('');
              setState(() {});
            },
          ),
          Expanded(
            child: _SearchBody(
              state: state,
              onRetry: _controller.retry,
              onRefresh: _controller.refresh,
              onLoadMore: _controller.loadMore,
              onReset: () {
                _input.clear();
                _controller.resetToInitial();
              },
              onTapHistory: (keyword) {
                _input.text = keyword;
                _submit(keyword);
              },
              onRemoveHistory: _controller.removeHistory,
              onClearHistory: _controller.clearHistory,
              onTapSuggestion: (keyword) {
                _input.text = keyword;
                _submit(keyword);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchInputBar extends StatelessWidget {
  const _SearchInputBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: YingjieTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '搜索影片、演员、导演',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => onSubmitted(controller.text),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onReset,
    required this.onTapHistory,
    required this.onRemoveHistory,
    required this.onClearHistory,
    required this.onTapSuggestion,
  });

  final SearchState state;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onReset;
  final ValueChanged<String> onTapHistory;
  final ValueChanged<String> onRemoveHistory;
  final VoidCallback onClearHistory;
  final ValueChanged<String> onTapSuggestion;

  @override
  Widget build(BuildContext context) {
    if (state.suggestions.isNotEmpty &&
        (state.status == SearchStatus.initial ||
            state.status == SearchStatus.success ||
            state.status == SearchStatus.empty)) {
      return _SuggestionList(
        suggestions: state.suggestions,
        onTap: onTapSuggestion,
      );
    }

    switch (state.status) {
      case SearchStatus.initial:
        return _HistoryPanel(
          history: state.history,
          onTap: onTapHistory,
          onRemove: onRemoveHistory,
          onClear: onClearHistory,
        );
      case SearchStatus.searching:
        return const SearchSkeleton();
      case SearchStatus.empty:
        return EmptyPanel(
          message: '没有找到相关影片',
          actionLabel: '重新搜索',
          onAction: onReset,
        );
      case SearchStatus.error:
        if (state.results.isNotEmpty) {
          return _ResultView(
            state: state,
            onRefresh: onRefresh,
            onLoadMore: onLoadMore,
          );
        }
        return ErrorPanel(
          message: state.error?.message ?? '网络连接失败，请检查网络',
          onRetry: onRetry,
        );
      case SearchStatus.success:
        return _ResultView(
          state: state,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
        );
    }
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> history;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyPanel(message: '输入关键词开始搜索');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '最近搜索',
                style: TextStyle(
                  color: YingjieTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('清空')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final keyword in history)
              InputChip(
                label: Text(keyword),
                onPressed: () => onTap(keyword),
                onDeleted: () => onRemove(keyword),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
              ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final keyword = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search_rounded, color: YingjieTheme.textMuted),
          title: Text(keyword),
          onTap: () => onTap(keyword),
        );
      },
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final SearchState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 240) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        color: YingjieTheme.accent,
        onRefresh: onRefresh,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: state.results.length + (state.loadingMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.48,
          ),
          itemBuilder: (context, index) {
            if (index >= state.results.length) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final video = state.results[index];
            return _SearchResultCard(
              video: video,
              onTap: () => context.push('/detail/${video.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.video, required this.onTap});

  final Video video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (video.year != null) '${video.year}',
      ...video.genres.take(2),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: CoverImage(url: video.cover),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: YingjieTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (meta.isNotEmpty)
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YingjieTheme.textMuted,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
