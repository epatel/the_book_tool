import 'package:the_book_tool/index.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Future<void> _showDatabaseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const DatabaseSelectionDialog(),
    );

    if (result == true && mounted) {
      // Database was switched, reload all data from all providers
      await Future.wait([
        Provider.of<ChapterProvider>(context, listen: false).loadChapters(),
        Provider.of<CharacterProvider>(context, listen: false).loadCharacters(),
        Provider.of<PlotProvider>(context, listen: false).loadPlots(),
        Provider.of<MiscNoteProvider>(context, listen: false).loadNotes(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Stationary navigation panel
          Container(
            width: AppTheme.sidebarWidth,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: DSText.headlineSmall(
                          'Writing Tool',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.storage,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        tooltip: 'Database',
                        onPressed: _showDatabaseDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _NavItem(
                        icon: Icons.book,
                        title: 'Chapters',
                        path: '/book',
                        currentPath: widget.currentPath,
                      ),
                      _NavItem(
                        icon: Icons.people,
                        title: 'Characters',
                        path: '/characters',
                        currentPath: widget.currentPath,
                      ),
                      _NavItem(
                        icon: Icons.lightbulb,
                        title: 'The Plots',
                        path: '/plots',
                        currentPath: widget.currentPath,
                      ),
                      _NavItem(
                        icon: Icons.note,
                        title: 'Misc',
                        path: '/misc',
                        currentPath: widget.currentPath,
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
              child: widget.child,
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
