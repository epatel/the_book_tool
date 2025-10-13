import 'package:the_book_tool/index.dart';

class DSListTile extends StatelessWidget {
  final IconData? leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const DSListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading != null ? Icon(leading) : null,
      title: DSText.bodyLarge(title),
      subtitle: subtitle != null ? DSText.bodySmall(subtitle!) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
