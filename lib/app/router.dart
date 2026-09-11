import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/category/category_page.dart';
import '../features/detail/detail_page.dart';
import '../features/favorites/favorites_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/mine/mine_page.dart';
import '../features/player/player_page.dart';
import '../features/search/search_history_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/main_shell.dart';
import 'route_args.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/category',
              name: 'category',
              builder: (context, state) => const CategoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              name: 'history',
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mine',
              name: 'mine',
              builder: (context, state) => const MinePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/search-history',
      name: 'search-history',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SearchHistoryPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = DetailRouteArgs.parse(state.pathParameters['id']);
        return DetailPage(videoId: args.id);
      },
    ),
    GoRoute(
      path: '/player/:id',
      name: 'player',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = PlayerRouteArgs.parse(
          id: state.pathParameters['id'],
          query: state.uri.queryParameters,
        );
        return PlayerPage(
          videoId: args.mediaId,
          title: args.title,
          playUrl: args.playUrl,
          episodeId: args.episodeId,
          sourceId: args.sourceId,
          cover: args.cover,
          year: args.year,
          genres: args.genres,
        );
      },
    ),
  ],
);
