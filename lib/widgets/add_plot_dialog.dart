import 'package:the_book_tool/index.dart';

/// Dialog for adding a new plot idea.
///
/// This is a thin wrapper around [AddEntityDialog] configured for plots.
class AddPlotDialog extends StatelessWidget {
  final bool hasApiKey;

  const AddPlotDialog({
    super.key,
    this.hasApiKey = false,
  });

  @override
  Widget build(BuildContext context) {
    return AddEntityDialog(
      config: AddEntityDialogConfig.plot,
      hasApiKey: hasApiKey,
    );
  }
}
