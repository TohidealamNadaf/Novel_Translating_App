import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_novel_screen.dart';
import 'screens/novel_detail_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/glossary_screen.dart';

import 'screens/main_navigation_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationScreen(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/add',
          name: 'add',
          builder: (context, state) => const AddNovelScreen(),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/novel/:novelId',
      name: 'novel-detail',
      builder: (context, state) {
        final novelId = state.pathParameters['novelId']!;
        return NovelDetailScreen(novelId: novelId);
      },
      routes: [
        GoRoute(
          path: 'read',
          name: 'reader',
          builder: (context, state) {
            final novelId = state.pathParameters['novelId']!;
            return ReaderScreen(novelId: novelId);
          },
        ),
        GoRoute(
          path: 'glossary',
          name: 'glossary',
          builder: (context, state) {
            final novelId = state.pathParameters['novelId']!;
            return GlossaryScreen(novelId: novelId);
          },
        ),
      ],
    ),
  ],
);
