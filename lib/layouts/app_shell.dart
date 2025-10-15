import 'package:the_book_tool/index.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _updateCounter = 0;

  @override
  void initState() {
    super.initState();
    // Listen to all providers for changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChapterProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<CharacterProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<PlotProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<MiscNoteProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
    });
  }

  @override
  void dispose() {
    // Remove listeners
    Provider.of<ChapterProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<CharacterProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<PlotProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<MiscNoteProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _updateCounter++;
      });
    }
  }

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
      // Trigger update of counts
      _onDataChanged();
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
                        tooltip: 'Library',
                        onPressed: _showDatabaseDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: ValueKey(_updateCounter),
                    padding: EdgeInsets.zero,
                    children: [
                      _NavItem(
                        key: ValueKey('chapters_$_updateCounter'),
                        icon: Icons.book,
                        title: 'Chapters',
                        path: '/book',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfChapters(),
                      ),
                      _NavItem(
                        key: ValueKey('characters_$_updateCounter'),
                        icon: Icons.people,
                        title: 'Characters',
                        path: '/characters',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfCharacters(),
                      ),
                      _NavItem(
                        key: ValueKey('plots_$_updateCounter'),
                        icon: Icons.lightbulb,
                        title: 'Plots',
                        path: '/plots',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfPlots(),
                      ),
                      _NavItem(
                        key: ValueKey('misc_$_updateCounter'),
                        icon: Icons.note,
                        title: 'Misc',
                        path: '/misc',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfMiscNotes(),
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
  final Future<int> countFuture;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.path,
    required this.currentPath,
    required this.countFuture,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == path;

    return FutureBuilder<int>(
      future: countFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return DSListTile(
          leading: icon,
          title: title,
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DSText.bodySmall(
              count.toString(),
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          selected: isSelected,
          onTap: () => context.go(path),
        );
      },
    );
  }
}
