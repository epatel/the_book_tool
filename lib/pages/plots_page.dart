import 'package:the_book_tool/index.dart';

class PlotsPage extends StatefulWidget {
  const PlotsPage({super.key});

  @override
  State<PlotsPage> createState() => _PlotsPageState();
}

class _PlotsPageState extends State<PlotsPage> {
  final ManifestRepository _manifestRepository = ManifestRepository();
  final AIService _aiService = AIService();
  bool _expandedAll = false;
  bool _markdownEnabled = false;
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlotProvider>(context, listen: false).loadPlots();
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();
    if (mounted) {
      setState(() {
        _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
        _readingFont = ReadingFont.fromString(manifest['ReadingFont']);
        _fontSize = double.tryParse(manifest['FontSize'] ?? '14.0') ?? 14.0;
        _expandedAll = manifest['ExpandedAll']?.toLowerCase() == 'true';
      });
    }
  }

  Future<void> _toggleExpandAll() async {
    setState(() {
      _expandedAll = !_expandedAll;
    });
    await _manifestRepository.set('ExpandedAll', _expandedAll.toString());
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
                _expandedAll ? Icons.unfold_less : Icons.unfold_more,
              ),
              tooltip: _expandedAll ? 'Collapse All' : 'Expand All',
              onPressed: _toggleExpandAll,
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

              if (_expandedAll) {
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
                        onTap: () => _showEditPlotDialog(plot),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                        'Not for AI',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const DSSpacing.spacing8(),
                            if (_markdownEnabled)
                              MarkdownBody(
                                data: plot.description,
                                sizedImageBuilder: (config) =>
                                    MarkdownAssetImageBuilder(
                                      uri: config.uri,
                                      title: config.title,
                                      altText: config.alt,
                                      width: config.width,
                                      height: config.height,
                                    ),
                                styleSheet: MarkdownStyleSheet(
                                  p: _readingFont.getTextStyle(
                                    fontSize: _fontSize,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  code: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: _fontSize * 0.9,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  codeblockPadding: const EdgeInsets.all(12),
                                ),
                              )
                            else
                              Text(
                                plot.description,
                                style: _readingFont.getTextStyle(
                                  fontSize: _fontSize,
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
                      onTap: () => _showEditPlotDialog(plot),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                      'Not for AI',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const DSSpacing.spacing8(),
                          if (_markdownEnabled)
                            SizedBox(
                              height: AppTheme.collapsedContentHeight,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: MarkdownBody(
                                  data: plot.description,
                                  sizedImageBuilder: (config) =>
                                      MarkdownAssetImageBuilder(
                                        uri: config.uri,
                                        title: config.title,
                                        altText: config.alt,
                                        width: config.width,
                                        height: config.height,
                                      ),
                                  styleSheet: MarkdownStyleSheet(
                                    p: _readingFont.getTextStyle(
                                      fontSize: _fontSize,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            DSText.bodyMedium(
                              plot.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: _readingFont.getTextStyle(
                                fontSize: _fontSize,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
  }
}
