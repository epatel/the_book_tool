import 'package:the_book_tool/index.dart';

class PromptHistoryDialog extends StatefulWidget {
  const PromptHistoryDialog({super.key});

  @override
  State<PromptHistoryDialog> createState() => _PromptHistoryDialogState();
}

class _PromptHistoryDialogState extends State<PromptHistoryDialog> {
  final PromptHistoryRepository _historyRepo = PromptHistoryRepository();
  List<PromptHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await _historyRepo.getAll();

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Clear All History?'),
        content: const DSText.bodyMedium(
          'Are you sure you want to delete all prompt history? This cannot be undone.',
        ),
        actions: [
          DSButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DSButton.primary(
            label: 'Clear All',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyRepo.deleteAll();
      await _loadHistory();
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat.Hm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat.Hm().format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.yMMMd().add_Hm().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const DSText.titleLarge('Prompt History'),
          const Spacer(),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Clear All History',
            ),
        ],
      ),
      content: SizedBox(
        width: 800,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
            ? const Center(
                child: DSText.bodyLarge('No prompt history yet'),
              )
            : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final entry = _history[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DSText.titleSmall(
                                    '${entry.contextType.capitalize()} • ${entry.contextName}',
                                  ),
                                  const SizedBox(
                                    width: AppTheme.spacing8,
                                  ),
                                  if (entry.wasCommand)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacing8,
                                        vertical: AppTheme.spacing4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall,
                                        ),
                                      ),
                                      child: DSText.labelSmall(
                                        'Command',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                height: AppTheme.spacing4,
                              ),
                              DSText.bodySmall(
                                entry.totalTokens != null
                                    ? '${_formatTimestamp(entry.createdAt)} Tokens: ${entry.promptTokens ?? 0} + ${entry.completionTokens ?? 0} = ${entry.totalTokens}${entry.model != null ? ' (${entry.model})' : ''}'
                                    : _formatTimestamp(entry.createdAt),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          // Prompt
                          DSText.bodyMedium(
                            '"${entry.promptText}"',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (entry.responseText != null) ...[
                            const SizedBox(height: AppTheme.spacing12),
                            // DSText.labelSmall(
                            //   'Response:',
                            //   style: TextStyle(
                            //     color: Theme.of(
                            //       context,
                            //     ).colorScheme.onSurface.withValues(alpha: 0.6),
                            //   ),
                            // ),
                            // const SizedBox(height: AppTheme.spacing4),
                            DSText.bodyMedium(entry.responseText!),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        DSButton.primary(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
