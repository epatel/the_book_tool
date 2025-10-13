import 'package:the_book_tool/index.dart';

class DSSpacing extends StatelessWidget {
  final double size;

  const DSSpacing(this.size, {super.key});

  const DSSpacing.spacing4({super.key}) : size = AppTheme.spacing4;
  const DSSpacing.spacing8({super.key}) : size = AppTheme.spacing8;
  const DSSpacing.spacing12({super.key}) : size = AppTheme.spacing12;
  const DSSpacing.spacing16({super.key}) : size = AppTheme.spacing16;
  const DSSpacing.spacing20({super.key}) : size = AppTheme.spacing20;
  const DSSpacing.spacing24({super.key}) : size = AppTheme.spacing24;
  const DSSpacing.spacing32({super.key}) : size = AppTheme.spacing32;
  const DSSpacing.spacing40({super.key}) : size = AppTheme.spacing40;
  const DSSpacing.spacing48({super.key}) : size = AppTheme.spacing48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
    );
  }
}
