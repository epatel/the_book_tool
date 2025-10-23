/// Configuration for entity edit dialogs.
///
/// This class defines the display properties and behavior for editing different
/// entity types (chapters, characters, plots, misc notes) in a unified dialog.
class EditEntityDialogConfig {
  final String dialogTitle;
  final String field1Label;
  final String field2Label;
  final String field1Key;
  final String field2Key;
  final String entityType;
  final String field1ValidationMessage;
  final String field2ValidationMessage;
  final int field2MaxLines;
  final String aiPromptHint;
  final String aiPromptHintCommandMode;
  final bool supportsCommandMode;
  final bool supportsImageInsertion;
  final String deleteConfirmationTitle;
  final String deleteConfirmationMessage;
  final String savedMessage;

  const EditEntityDialogConfig({
    required this.dialogTitle,
    required this.field1Label,
    required this.field2Label,
    required this.field1Key,
    required this.field2Key,
    required this.entityType,
    required this.field1ValidationMessage,
    required this.field2ValidationMessage,
    required this.field2MaxLines,
    required this.aiPromptHint,
    required this.aiPromptHintCommandMode,
    required this.supportsCommandMode,
    required this.supportsImageInsertion,
    required this.deleteConfirmationTitle,
    required this.deleteConfirmationMessage,
    required this.savedMessage,
  });

  // Chapter configuration
  static const chapter = EditEntityDialogConfig(
    dialogTitle: 'Edit Chapter',
    field1Label: 'Title',
    field2Label: 'Content',
    field1Key: 'title',
    field2Key: 'content',
    entityType: 'chapter',
    field1ValidationMessage: 'Please enter a title',
    field2ValidationMessage: 'Please enter content',
    field2MaxLines: 10,
    aiPromptHint: 'AI will insert at cursor or replace selection...',
    aiPromptHintCommandMode: '', // Not used for chapters
    supportsCommandMode: false,
    supportsImageInsertion: true,
    deleteConfirmationTitle: 'Delete Chapter',
    deleteConfirmationMessage:
        'Are you sure you want to delete this chapter? This action cannot be undone.',
    savedMessage: 'Chapter saved',
  );

  // Character configuration
  static const character = EditEntityDialogConfig(
    dialogTitle: 'Edit Character',
    field1Label: 'Name',
    field2Label: 'Description',
    field1Key: 'name',
    field2Key: 'description',
    entityType: 'character',
    field1ValidationMessage: 'Please enter a name',
    field2ValidationMessage: 'Please enter a description',
    field2MaxLines: 10,
    aiPromptHint: 'AI will insert at cursor or replace selection...',
    aiPromptHintCommandMode: '', // Not used for characters
    supportsCommandMode: false,
    supportsImageInsertion: false,
    deleteConfirmationTitle: 'Delete Character',
    deleteConfirmationMessage:
        'Are you sure you want to delete this character? This action cannot be undone.',
    savedMessage: 'Character saved',
  );

  // Plot configuration
  static const plot = EditEntityDialogConfig(
    dialogTitle: 'Edit Plot Idea',
    field1Label: 'Title',
    field2Label: 'Description',
    field1Key: 'title',
    field2Key: 'description',
    entityType: 'plot',
    field1ValidationMessage: 'Please enter a title',
    field2ValidationMessage: 'Please enter a description',
    field2MaxLines: 10,
    aiPromptHint: 'AI will insert at cursor or replace selection...',
    aiPromptHintCommandMode: 'AI can create new items with commands...',
    supportsCommandMode: true,
    supportsImageInsertion: false,
    deleteConfirmationTitle: 'Delete Plot',
    deleteConfirmationMessage:
        'Are you sure you want to delete this plot? This action cannot be undone.',
    savedMessage: 'Plot saved',
  );

  // Misc Note configuration
  static const miscNote = EditEntityDialogConfig(
    dialogTitle: 'Edit Note',
    field1Label: 'Title',
    field2Label: 'Content',
    field1Key: 'title',
    field2Key: 'content',
    entityType: 'miscNote',
    field1ValidationMessage: 'Please enter a title',
    field2ValidationMessage: 'Please enter content',
    field2MaxLines: 10,
    aiPromptHint: 'AI will insert at cursor or replace selection...',
    aiPromptHintCommandMode: 'AI can create new items with commands...',
    supportsCommandMode: true,
    supportsImageInsertion: false,
    deleteConfirmationTitle: 'Delete Note',
    deleteConfirmationMessage:
        'Are you sure you want to delete this note? This action cannot be undone.',
    savedMessage: 'Note saved',
  );
}
