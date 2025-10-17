import 'package:the_book_tool/index.dart';

class PromptsPage extends StatefulWidget {
  const PromptsPage({super.key});

  @override
  State<PromptsPage> createState() => _PromptsPageState();
}

class _PromptsPageState extends State<PromptsPage> {
  bool _expandedAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PromptProvider>(context, listen: false).loadPrompts();
    });
  }

  void _toggleExpandAll() {
    setState(() {
      _expandedAll = !_expandedAll;
    });
  }

  Future<void> _sendPromptToAI(Prompt prompt) async {
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            DSSpacing.spacing16(),
            DSText.bodyMedium('Processing prompt...'),
          ],
        ),
      ),
    );

    try {
      // Gather book data
      final chapterProvider = Provider.of<ChapterProvider>(context, listen: false);
      final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
      final plotProvider = Provider.of<PlotProvider>(context, listen: false);
      final miscProvider = Provider.of<MiscNoteProvider>(context, listen: false);

      final bookData = {
        'chapters': chapterProvider.chapters.map((c) => {
          'title': c.title,
          'content': c.content,
        }).toList(),
        'characters': characterProvider.characters.map((c) => {
          'name': c.name,
          'description': c.description,
        }).toList(),
        'plots': plotProvider.plots.map((p) => {
          'title': p.title,
          'description': p.description,
        }).toList(),
        'miscNotes': miscProvider.notes.map((n) => {
          'title': n.title,
          'content': n.content,
        }).toList(),
      };

      // Send prompt to AI
      final aiService = AIService();
      final response = await aiService.sendPrompt(
        prompt: prompt.content,
        context: {
          'enableCommands': prompt.command,
          'bookData': bookData,
        },
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get AI response. Check your API key.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Handle response
      if (response.commands.isNotEmpty) {
        // Execute commands
        await _executeCommands(response.commands);
      } else if (response.text != null && response.text!.isNotEmpty) {
        // Save response to prompt
        if (mounted) {
          final promptWithResponse = prompt.copyWith(response: response.text);
          await Provider.of<PromptProvider>(
            context,
            listen: false,
          ).updatePrompt(promptWithResponse);
        }

        // Show text response in dialog
        if (mounted) {
          await showDialog(
            context: context,
            builder: (dialogContext) => AIResponseDialog(
              response: response.text!,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _executeCommands(List<AICommand> commands) async {
    int successCount = 0;

    for (final command in commands) {
      try {
        if (command is AddChapterCommand && command.isValid) {
          await Provider.of<ChapterProvider>(context, listen: false).addChapter(
            command.title,
            command.content,
          );
          successCount++;
        } else if (command is AddCharacterCommand && command.isValid) {
          await Provider.of<CharacterProvider>(context, listen: false).addCharacter(
            command.name,
            command.description,
          );
          successCount++;
        } else if (command is AddPlotCommand && command.isValid) {
          await Provider.of<PlotProvider>(context, listen: false).addPlot(
            command.title,
            command.description,
          );
          successCount++;
        } else if (command is AddMiscNoteCommand && command.isValid) {
          await Provider.of<MiscNoteProvider>(context, listen: false).addNote(
            command.title,
            command.content,
          );
          successCount++;
        }
      } catch (e) {
        debugPrint('Failed to execute command ${command.runtimeType}: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully created $successCount items'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showAddPromptDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => const AddPromptDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<PromptProvider>(
        context,
        listen: false,
      ).addPrompt(
        result['title']! as String,
        result['content']! as String,
        command: result['command'] as bool,
        isTemplate: result['isTemplate'] as bool,
      );
    }
  }

  Future<void> _showEditPromptDialog(Prompt prompt) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditPromptDialog(
        prompt: prompt,
      ),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<PromptProvider>(
          context,
          listen: false,
        ).deletePrompt(prompt.id!);
      } else {
        // Create updated prompt with all fields
        final updatedPrompt = Prompt(
          id: prompt.id,
          title: result['title'] as String,
          content: result['content'] as String,
          response: result['response'] as String?,
          command: result['command'] as bool,
          isTemplate: result['isTemplate'] as bool,
          orderIndex: prompt.orderIndex,
          createdAt: prompt.createdAt,
          updatedAt: DateTime.now(),
        );
        await Provider.of<PromptProvider>(
          context,
          listen: false,
        ).updatePrompt(updatedPrompt);

        // Handle send action
        if (result['send'] == true && mounted) {
          await _sendPromptToAI(updatedPrompt);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            DSAppBar(
              title: 'Prompts',
              actions: [
                IconButton(
                  icon: Icon(
                    _expandedAll ? Icons.unfold_less : Icons.unfold_more,
                  ),
                  tooltip: _expandedAll ? 'Collapse All' : 'Expand All',
                  onPressed: _toggleExpandAll,
                ),
              ],
            ),
            Expanded(
              child: Consumer<PromptProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.prompts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const DSSpacing.spacing16(),
                          DSText.bodyLarge(
                            'No prompts yet',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const DSSpacing.spacing8(),
                          DSText.bodySmall(
                            'Tap the + button to add your first prompt',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_expandedAll) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: provider.prompts.length,
                      itemBuilder: (context, index) {
                        final prompt = provider.prompts[index];
                        return Container(
                          key: ValueKey(prompt.id),
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacing12,
                          ),
                          child: DSCard(
                            onTap: () => _showEditPromptDialog(prompt),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    DSText.titleMedium(prompt.title),
                                    const SizedBox(width: 8),
                                    if (prompt.command)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: DSText.bodySmall(
                                          'Command',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    if (prompt.isTemplate) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: DSText.bodySmall(
                                          'Template',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const DSSpacing.spacing8(),
                                DSText.bodyMedium(
                                  prompt.content,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    itemCount: provider.prompts.length,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Material(
                            elevation: 0,
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final prompts = List<Prompt>.from(provider.prompts);
                      final prompt = prompts.removeAt(oldIndex);
                      prompts.insert(newIndex, prompt);
                      Provider.of<PromptProvider>(
                        context,
                        listen: false,
                      ).reorderPrompts(prompts);
                    },
                    itemBuilder: (context, index) {
                      final prompt = provider.prompts[index];
                      return Container(
                        key: ValueKey(prompt.id),
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacing12,
                        ),
                        child: DSCard(
                          onTap: () => _showEditPromptDialog(prompt),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DSText.titleMedium(prompt.title),
                                  const SizedBox(width: 8),
                                  if (prompt.command)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: DSText.bodySmall(
                                        'Command',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  if (prompt.isTemplate) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: DSText.bodySmall(
                                        'Template',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const DSSpacing.spacing8(),
                              DSText.bodyMedium(
                                prompt.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: AppTheme.spacing16,
          bottom: AppTheme.spacing16,
          child: DSFloatingActionButton(
            icon: Icons.add,
            tooltip: 'Add Prompt',
            onPressed: _showAddPromptDialog,
          ),
        ),
      ],
    );
  }
}
