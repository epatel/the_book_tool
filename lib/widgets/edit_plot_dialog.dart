import 'package:the_book_tool/index.dart';

class EditPlotDialog extends StatefulWidget {
  final Plot plot;

  const EditPlotDialog({super.key, required this.plot});

  @override
  State<EditPlotDialog> createState() => _EditPlotDialogState();
}

class _EditPlotDialogState extends State<EditPlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plot.title);
    _descriptionController = TextEditingController(
      text: widget.plot.description,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Edit Plot Idea'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const DSSpacing.spacing16(),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        DSButton.text(
          label: 'Delete',
          onPressed: () => Navigator.of(context).pop({'delete': true}),
        ),
        const Spacer(),
        DSButton.text(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DSButton.primary(
          label: 'Save',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'description': _descriptionController.text,
              });
            }
          },
        ),
      ],
    );
  }
}
