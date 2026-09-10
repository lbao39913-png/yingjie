import 'package:flutter/material.dart';

import '../app/theme.dart';

class PulseSkeleton extends StatefulWidget {
  const PulseSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.8).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: YingjieTheme.card,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PulseSkeleton(width: double.infinity, height: 180, radius: 20),
        const SizedBox(height: 24),
        const PulseSkeleton(width: 120, height: 18, radius: 8),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return const PulseSkeleton(width: 118, height: 180);
            },
          ),
        ),
        const SizedBox(height: 24),
        const PulseSkeleton(width: 120, height: 18, radius: 8),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return const PulseSkeleton(width: 118, height: 180);
            },
          ),
        ),
      ],
    );
  }
}

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.52,
      ),
      itemBuilder: (context, index) {
        return const PulseSkeleton(width: double.infinity, height: double.infinity);
      },
    );
  }
}

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PulseSkeleton(width: double.infinity, height: 180, radius: 20),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PulseSkeleton(width: 108, height: 162, radius: 16),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PulseSkeleton(width: 180, height: 22, radius: 8),
                  SizedBox(height: 10),
                  PulseSkeleton(width: 120, height: 14, radius: 8),
                  SizedBox(height: 10),
                  PulseSkeleton(width: 160, height: 14, radius: 8),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const PulseSkeleton(width: double.infinity, height: 44, radius: 14),
        const SizedBox(height: 24),
        const PulseSkeleton(width: 80, height: 18, radius: 8),
        const SizedBox(height: 10),
        const PulseSkeleton(width: double.infinity, height: 14, radius: 8),
        const SizedBox(height: 8),
        const PulseSkeleton(width: double.infinity, height: 14, radius: 8),
        const SizedBox(height: 24),
        const PulseSkeleton(width: 100, height: 18, radius: 8),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return const PulseSkeleton(width: 118, height: 180);
            },
          ),
        ),
      ],
    );
  }
}
