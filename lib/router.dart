import 'package:the_book_tool/index.dart';

// Global key to force page rebuilds when settings change
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/book',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(currentPath: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/book',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const BookPage()),
        ),
        GoRoute(
          path: '/characters',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CharactersPage(),
          ),
        ),
        GoRoute(
          path: '/plots',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const PlotsPage()),
        ),
        GoRoute(
          path: '/misc',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const MiscPage()),
        ),
        GoRoute(
          path: '/prompts',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const PromptsPage()),
        ),
        GoRoute(
          path: '/assets',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const AssetsPage()),
        ),
      ],
    ),
  ],
);
