import 'package:the_book_tool/index.dart';

final router = GoRouter(
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
      ],
    ),
  ],
);
