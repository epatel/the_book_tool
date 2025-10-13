import 'package:the_book_tool/index.dart';

/// A design system text field with consistent styling.
class DSTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final void Function(String)? onChanged;

  const DSTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = false,
    this.onChanged,
  });

  /// Creates a required text field with a validator.
  const DSTextField.required({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = false,
    this.onChanged,
  }) : validator = _requiredValidator;

  static String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofocus: autofocus,
      onChanged: onChanged,
    );
  }
}

/// A design system text field without form validation.
class DSTextInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const DSTextInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
