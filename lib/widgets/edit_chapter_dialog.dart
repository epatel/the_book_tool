import 'package:the_book_tool/index.dart';

/// Dialog for editing an existing chapter.
///
/// This is a thin wrapper around [EditEntityDialog] configured for chapters.
class EditChapterDialog extends StatelessWidget {
  final Chapter chapter;
  final bool hasApiKey;
  final String? searchQuery;
  final int? searchLineNumber;

  const EditChapterDialog({
    super.key,
    required this.chapter,
    this.hasApiKey = false,
    this.searchQuery,
    this.searchLineNumber,
  });

  @override
  Widget build(BuildContext context) {
    final chapterProvider = Provider.of<ChapterProvider>(
      context,
      listen: false,
    );

    return EditEntityDialog<Chapter>(
      config: EditEntityDialogConfig.chapter,
      entity: chapter,
      hasApiKey: hasApiKey,
      searchQuery: searchQuery,
      searchLineNumber: searchLineNumber,
      getField1Value: (chapter) => chapter.title,
      getField2Value: (chapter) => chapter.content,
      getOrderIndex: (chapter) => chapter.orderIndex,
      getId: (chapter) => chapter.id!,
      copyWith: (chapter, field1, field2) => chapter.copyWith(
        title: field1,
        content: field2,
      ),
      onUpdate: (context, updatedChapter) async {
        await chapterProvider.updateChapter(updatedChapter);
      },
      onDelete: (context, id) async {
        await chapterProvider.deleteChapter(id);
      },
    );
  }
}
