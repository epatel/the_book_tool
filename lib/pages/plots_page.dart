import 'package:the_book_tool/index.dart';

class PlotsPage extends StatefulWidget {
  const PlotsPage({super.key});

  @override
  State<PlotsPage> createState() => _PlotsPageState();
}

class _PlotsPageState extends State<PlotsPage> {
  bool _expandedAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlotProvider>(context, listen: false).loadPlots();
    });
  }

  void _toggleExpandAll() {
    setState(() {
      _expandedAll = !_expandedAll;
    });
  }

  Future<void> _showAddPlotDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => const AddPlotDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<PlotProvider>(context, listen: false).addPlot(
        result['title']!,
        result['description']!,
      );
    }
  }

  Future<void> _showEditPlotDialog(Plot plot) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditPlotDialog(plot: plot),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<PlotProvider>(context, listen: false)
            .deletePlot(plot.id!);
      } else {
        final updatedPlot = plot.copyWith(
          title: result['title'] as String,
          description: result['description'] as String,
        );
        await Provider.of<PlotProvider>(context, listen: false)
            .updatePlot(updatedPlot);
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
              title: 'The Plots',
              actions: [
                IconButton(
                  icon: Icon(_expandedAll ? Icons.unfold_less : Icons.unfold_more),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const DSSpacing.spacing16(),
                          DSText.bodyLarge(
                            'No plot ideas yet',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const DSSpacing.spacing8(),
                          DSText.bodySmall(
                            'Tap the + button to add your first plot idea',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
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
                      Provider.of<PlotProvider>(context, listen: false)
                          .reorderPlots(plots);
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
                              DSText.titleMedium(plot.title),
                              const DSSpacing.spacing8(),
                              DSText.bodyMedium(
                                plot.description,
                                maxLines: _expandedAll ? null : 3,
                                overflow: _expandedAll ? null : TextOverflow.ellipsis,
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
            tooltip: 'Add Plot Idea',
            onPressed: _showAddPlotDialog,
          ),
        ),
      ],
    );
  }
}
