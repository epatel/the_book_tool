import 'package:the_book_tool/index.dart';

enum DSButtonType {
  primary,
  secondary,
  text,
}

class DSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DSButtonType type;
  final IconData? icon;

  const DSButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = DSButtonType.primary,
    this.icon,
  });

  const DSButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : type = DSButtonType.primary;

  const DSButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : type = DSButtonType.secondary;

  const DSButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : type = DSButtonType.text;

  @override
  Widget build(BuildContext context) {
    final buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacing8),
              DSText(label),
            ],
          )
        : DSText(label);

    switch (type) {
      case DSButtonType.primary:
        return FilledButton(
          onPressed: onPressed,
          child: buttonChild,
        );
      case DSButtonType.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          child: buttonChild,
        );
      case DSButtonType.text:
        return TextButton(
          onPressed: onPressed,
          child: buttonChild,
        );
    }
  }
}

class DSIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const DSIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

class DSFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const DSFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
