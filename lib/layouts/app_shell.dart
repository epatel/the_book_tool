import 'package:the_book_tool/index.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Stationary navigation panel
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  color: Theme.of(context).colorScheme.primary,
                  width: double.infinity,
                  child: const DSText.headlineSmall(
                    'Book Writing',
                    style: TextStyle(color: AppTheme.onPrimaryColor),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _NavItem(
                        icon: Icons.book,
                        title: 'The Book',
                        path: '/book',
                        currentPath: currentPath,
                      ),
                      _NavItem(
                        icon: Icons.people,
                        title: 'Characters',
                        path: '/characters',
                        currentPath: currentPath,
                      ),
                      _NavItem(
                        icon: Icons.lightbulb,
                        title: 'The Plots',
                        path: '/plots',
                        currentPath: currentPath,
                      ),
                      _NavItem(
                        icon: Icons.note,
                        title: 'Misc',
                        path: '/misc',
                        currentPath: currentPath,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String path;
  final String currentPath;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.path,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == path;

    return DSListTile(
      leading: icon,
      title: title,
      selected: isSelected,
      onTap: () => context.go(path),
    );
  }
}
