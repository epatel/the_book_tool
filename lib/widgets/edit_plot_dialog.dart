import 'package:the_book_tool/index.dart';

/// Dialog for editing an existing plot idea.
///
/// This is a thin wrapper around [EditEntityDialog] configured for plots.
class EditPlotDialog extends StatelessWidget {
  final Plot plot;
  final bool hasApiKey;
  final String? searchQuery;
  final int? searchLineNumber;

  const EditPlotDialog({
    super.key,
    required this.plot,
    this.hasApiKey = false,
    this.searchQuery,
    this.searchLineNumber,
  });

  @override
  Widget build(BuildContext context) {
    final plotProvider = Provider.of<PlotProvider>(
      context,
      listen: false,
    );

    return EditEntityDialog<Plot>(
      config: EditEntityDialogConfig.plot,
      entity: plot,
      hasApiKey: hasApiKey,
      searchQuery: searchQuery,
      searchLineNumber: searchLineNumber,
      getField1Value: (plot) => plot.title,
      getField2Value: (plot) => plot.description,
      getId: (plot) => plot.id!,
      copyWith: (plot, field1, field2) => plot.copyWith(
        title: field1,
        description: field2,
      ),
      onUpdate: (context, updatedPlot) async {
        await plotProvider.updatePlot(updatedPlot);
      },
      onDelete: (context, id) async {
        await plotProvider.deletePlot(id);
      },
    );
  }
}
