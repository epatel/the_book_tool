import 'package:the_book_tool/index.dart';

class DatabaseSelectionDialog extends StatefulWidget {
  const DatabaseSelectionDialog({super.key});

  @override
  State<DatabaseSelectionDialog> createState() =>
      _DatabaseSelectionDialogState();
}

class _DatabaseSelectionDialogState extends State<DatabaseSelectionDialog> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<String> _databases = [];
  String _currentDatabase = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databases = await _databaseManager.listDatabaseFiles();
      final currentDb = await _databaseManager.getCurrentDatabaseName();

      if (mounted) {
        setState(() {
          _databases = databases;
          _currentDatabase = currentDb;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading databases: $e')));
      }
    }
  }

  Future<void> _createNewDatabase() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Create New Book'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Book Name',
              border: OutlineInputBorder(),
              hintText: 'my_book',
              helperText: '.db extension will be added automatically',
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              if (value.contains('/') ||
                  value.contains('\\') ||
                  value.contains(':')) {
                return 'Invalid characters in name';
              }
              return null;
            },
          ),
        ),
        actions: [
          DSButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          DSButton.primary(
            label: 'Create',
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(nameController.text);
              }
            },
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final databaseName = await _databaseManager.createNewDatabase(result);

        // Switch to the new database
        await _databaseManager.switchDatabase(databaseName);

        if (mounted) {
          // Close this dialog and signal that database changed
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating database: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectDatabase(String databaseName) async {
    if (databaseName == _currentDatabase) {
      // Already selected
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseManager.switchDatabase(databaseName);

      if (mounted) {
        // Close dialog and signal that database changed
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error switching database: $e')));
      }
    }
  }

  Future<void> _deleteDatabase(String databaseName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Delete Book'),
        content: DSText.bodyMedium(
          'Are you sure you want to delete "$databaseName"? This action cannot be undone and all data will be lost.',
        ),
        actions: [
          DSButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DSButton.primary(
            label: 'Delete',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _databaseManager.deleteDatabase(databaseName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: DSText.bodyMedium('Database deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload the database list
        await _loadDatabases();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: DSText.bodyMedium('Error deleting database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Select Book'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      const DSText.bodyMedium('Current: '),
                      SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: DSText.bodyMedium(
                          _currentDatabase,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const DSSpacing.spacing16(),
                  Expanded(
                    child: _databases.isEmpty
                        ? const Center(
                            child: DSText.bodyMedium('No databases found'),
                          )
                        : ListView.builder(
                            itemCount: _databases.length,
                            itemBuilder: (context, index) {
                              final dbName = _databases[index];
                              final isCurrent = dbName == _currentDatabase;

                              return ListTile(
                                title: DSText.bodyMedium(
                                  dbName,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.storage,
                                  color: isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                trailing: SizedBox(
                                  width: 40,
                                  child: isCurrent
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        )
                                      : PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                          onSelected: (value) {
                                            if (value == 'delete') {
                                              _deleteDatabase(dbName);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                onTap: () => _selectDatabase(dbName),
                                selected: isCurrent,
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        Row(
          children: [
            DSButton.text(
              label: 'Create New',
              onPressed: _isLoading ? null : _createNewDatabase,
            ),
            const Spacer(),
            DSButton.primary(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
