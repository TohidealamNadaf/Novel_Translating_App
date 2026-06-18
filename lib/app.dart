import 'package:go_router/go_router.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_novel_screen.dart';
import 'screens/novel_detail_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/glossary_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
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
    GoRoute(
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
