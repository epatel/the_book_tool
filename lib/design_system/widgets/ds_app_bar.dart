import 'package:the_book_tool/index.dart';

class DSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? titleActions;
  final List<Widget>? actions;

  const DSAppBar({
    super.key,
    required this.title,
    this.titleActions,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: titleActions != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [DSText.titleLarge(title), ...titleActions!],
            )
          : DSText.titleLarge(title),
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
