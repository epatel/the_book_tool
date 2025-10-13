import 'package:the_book_tool/index.dart';

/// A design system dialog with consistent styling.
class DSDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double? width;

  const DSDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.width = AppTheme.dialogWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: DSText.titleLarge(title),
      content: width != null ? SizedBox(width: width, child: content) : content,
      actions: actions,
    );
  }
}

/// A confirmation dialog for destructive actions.
class DSConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const DSConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
  });

  /// Shows a delete confirmation dialog.
  static Future<bool> showDelete({
    required BuildContext context,
    required String itemName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DSConfirmDialog(
        title: 'Delete $itemName',
        message:
            'Are you sure you want to delete this $itemName? This action cannot be undone.',
        confirmLabel: 'Delete',
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: DSText.titleLarge(title),
      content: DSText.bodyMedium(message),
      actions: [
        DSButton.text(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DSButton.primary(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// A dialog for forms with consistent layout.
class DSFormDialog extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final List<Widget>? leadingActions;
  final double? width;

  const DSFormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.fields,
    required this.onConfirm,
    this.confirmLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.leadingActions,
    this.width = AppTheme.dialogWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: DSText.titleLarge(title),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: width,
          child: Column(mainAxisSize: MainAxisSize.min, children: fields),
        ),
      ),
      actions: [
        if (leadingActions != null)
          Row(
            children: [
              ...leadingActions!,
              const Spacer(),
              DSButton.text(
                label: cancelLabel,
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
              ),
              DSButton.primary(
                label: confirmLabel,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    onConfirm();
                  }
                },
              ),
            ],
          )
        else ...[
          DSButton.text(
            label: cancelLabel,
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
          ),
          DSButton.primary(
            label: confirmLabel,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onConfirm();
              }
            },
          ),
        ],
      ],
    );
  }
}
