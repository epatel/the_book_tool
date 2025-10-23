/// Configuration for AddEntityDialog
///
/// Defines the field names, labels, and entity type for different entity dialogs.
class AddEntityDialogConfig {
  /// Dialog title (e.g., 'Add Chapter', 'Add Character')
  final String dialogTitle;

  /// Label for the first field (e.g., 'Title', 'Name')
  final String field1Label;

  /// Label for the second field (e.g., 'Content', 'Description')
  final String field2Label;

  /// Return key for first field in the result map (e.g., 'title', 'name')
  final String field1Key;

  /// Return key for second field in the result map (e.g., 'content', 'description')
  final String field2Key;

  /// Entity type for AI context (e.g., 'chapter', 'character', 'plot', 'miscNote')
  final String entityType;

  /// Validation message for empty first field
  final String field1ValidationMessage;

  /// Validation message for empty second field
  final String field2ValidationMessage;

  /// Number of max lines for the second field (default 5)
  final int field2MaxLines;

  /// Hint text for AI prompt field
  final String aiPromptHint;

  const AddEntityDialogConfig({
    required this.dialogTitle,
    required this.field1Label,
    required this.field2Label,
    required this.field1Key,
    required this.field2Key,
    required this.entityType,
    required this.field1ValidationMessage,
    required this.field2ValidationMessage,
    this.field2MaxLines = 5,
    this.aiPromptHint = 'AI will insert at cursor or at end...',
  });

  /// Configuration for Chapter dialogs
  static const chapter = AddEntityDialogConfig(
    dialogTitle: 'Add Chapter',
    field1Label: 'Title',
    field2Label: 'Content',
    field1Key: 'title',
    field2Key: 'content',
    entityType: 'chapter',
    field1ValidationMessage: 'Please enter a title',
    field2ValidationMessage: 'Please enter content',
    field2MaxLines: 5,
    aiPromptHint: 'AI will insert at cursor or at end of content...',
  );

  /// Configuration for Character dialogs
  static const character = AddEntityDialogConfig(
    dialogTitle: 'Add Character',
    field1Label: 'Name',
    field2Label: 'Description',
    field1Key: 'name',
    field2Key: 'description',
    entityType: 'character',
    field1ValidationMessage: 'Please enter a name',
    field2ValidationMessage: 'Please enter a description',
    field2MaxLines: 5,
    aiPromptHint: 'AI will insert at cursor or at end of description...',
  );

  /// Configuration for Plot dialogs
  static const plot = AddEntityDialogConfig(
    dialogTitle: 'Add Plot Idea',
    field1Label: 'Title',
    field2Label: 'Description',
    field1Key: 'title',
    field2Key: 'description',
    entityType: 'plot',
    field1ValidationMessage: 'Please enter a title',
    field2ValidationMessage: 'Please enter a description',
    field2MaxLines: 5,
    aiPromptHint: 'AI will insert at cursor or at end of description...',
  );

  /// Configuration for Misc Note dialogs
  static const miscNote = AddEntityDialogConfig(
    dialogTitle: 'Add Note',
    field1Label: 'Title',
    field2Label: 'Content',
    field1Key: 'title',
    field2Key: 'content',
    entityType: 'miscNote',
    field1ValidationMessage: 'Please enter a title',
    field2ValidationMessage: 'Please enter content',
    field2MaxLines: 5,
    aiPromptHint: 'AI will insert at cursor or at end of content...',
  );
}
