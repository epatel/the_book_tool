import 'package:the_book_tool/index.dart';

class PlotsPage extends StatefulWidget {
  const PlotsPage({super.key});

  @override
  State<PlotsPage> createState() => _PlotsPageState();
}

class _PlotsPageState extends State<PlotsPage> {
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlotProvider>(context, listen: false).loadPlots();
    });
  }

  Future<void> _showAddPlotDialog() async {
    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AddPlotDialog(
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      await Provider.of<PlotProvider>(
        context,
        listen: false,
      ).addPlot(result['title']!, result['description']!);
    }
  }

  Future<void> _showEditPlotDialog(Plot plot) async {
    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditPlotDialog(
        plot: plot,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<PlotProvider>(
          context,
          listen: false,
        ).deletePlot(plot.id!);
      }
    }
  }

  bool _shouldShowNotForAiBadge(String title, String description) {
    return title.contains('{not-for-ai}') ||
        description.contains('{not-for-ai}');
  }

  String _filterNotForAiMarker(String text) {
    return text.replaceAll('{not-for-ai}', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            DSAppBar(
              title: 'Plots',
              titleActions: [
                IconButton(
                  icon: const DSAddIcon(),
                  tooltip: 'Add Plot Idea',
                  onPressed: _showAddPlotDialog,
                ),
              ],
              actions: [
                IconButton(
                  icon: Icon(
                    settings.expandedAll
                        ? Icons.unfold_less
                        : Icons.unfold_more,
                  ),
                  tooltip: settings.expandedAll ? 'Collapse All' : 'Expand All',
                  onPressed: settings.toggleExpandAll,
                ),
              ],
            ),
            Expanded(
              child: Consumer<PlotProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.plots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const DSSpacing.spacing16(),
                          DSText.bodyLarge(
                            'No plot ideas yet',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const DSSpacing.spacing8(),
                          DSText.bodySmall(
                            'Tap the + button to add your first plot idea',
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

                  if (settings.expandedAll) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: provider.plots.length,
                      itemBuilder: (context, index) {
                        final plot = provider.plots[index];
                        return Container(
                          key: ValueKey(plot.id),
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacing12,
                          ),
                          child: DSCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showEditPlotDialog(plot),
                                        child: Row(
                                          children: [
                                            DSText.titleMedium(
                                              _filterNotForAiMarker(plot.title),
                                            ),
                                            if (_shouldShowNotForAiBadge(
                                              plot.title,
                                              plot.description,
                                            )) ...[
                                              const SizedBox(width: 8),
                                              Tooltip(
                                                message:
                                                    'This content is excluded from AI requests',
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
                                                            .colorScheme
                                                            .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: DSText.bodySmall(
                                                    'Not for AI',
                                                    style: TextStyle(
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              )
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      iconSize: 20,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primary.withValues(
                                            alpha: 0.7,
                                          ),
                                      onPressed: () =>
                                          _showEditPlotDialog(plot),
                                      tooltip: 'Edit Plot',
                                    ),
                                  ],
                                ),
                                const DSSpacing.spacing8(),
                                if (settings.markdownEnabled)
                                  MarkdownContent(
                                    data: plot.description,
                                    readingFont: settings.readingFont,
                                    fontSize: settings.fontSize,
                                  )
                                else
                                  Text(
                                    plot.description,
                                    style: settings.readingFont.getTextStyle(
                                      fontSize: settings.fontSize,
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
                    itemCount: provider.plots.length,
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
                      final plots = List<Plot>.from(provider.plots);
                      final plot = plots.removeAt(oldIndex);
                      plots.insert(newIndex, plot);
                      Provider.of<PlotProvider>(
                        context,
                        listen: false,
                      ).reorderPlots(plots);
                    },
                    itemBuilder: (context, index) {
                      final plot = provider.plots[index];
                      return Container(
                        key: ValueKey(plot.id),
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacing12,
                        ),
                        child: DSCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showEditPlotDialog(plot),
                                      child: Row(
                                        children: [
                                          DSText.titleMedium(
                                            _filterNotForAiMarker(plot.title),
                                          ),
                                          if (_shouldShowNotForAiBadge(
                                            plot.title,
                                            plot.description,
                                          )) ...[
                                            const SizedBox(width: 8),
                                            Tooltip(
                                              message:
                                                  'This content is excluded from AI requests',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          )
                                                          .colorScheme
                                                          .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: DSText.bodySmall(
                                                  'Not for AI',
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    iconSize: 20,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                    onPressed: () => _showEditPlotDialog(plot),
                                    tooltip: 'Edit Plot',
                                  ),
                                ],
                              ),
                              const DSSpacing.spacing8(),
                              if (settings.markdownEnabled)
                                MarkdownContent(
                                  data: plot.description,
                                  readingFont: settings.readingFont,
                                  fontSize: settings.fontSize,
                                  collapsed: true,
                                )
                              else
                                DSText.bodyMedium(
                                  plot.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: settings.readingFont.getTextStyle(
                                    fontSize: settings.fontSize,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
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
        );
      },
    );
  }
}
